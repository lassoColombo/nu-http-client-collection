# Auto-generated client for Email Activity (beta) v1.0.0
# Source: https://api.apis.guru/v2/specs/sendgrid.com/1.0.0/openapi.json
# Auth: --token flag or $env.EMAIL_ACTIVITY_BETA_TOKEN

const CLIENT = {
  base_url: "http://api.sendgrid.com/v3"
  token_env_var: "EMAIL_ACTIVITY_BETA_TOKEN"
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

def base-url-completer [] { ["http://api.sendgrid.com/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["stats_notification" "usage_limit"] }
def aggregated-by-completer [] { ["day" "month" "week"] }
def editor-completer [] { ["code" "design"] }
def sort-by-direction-completer [] { ["asc" "desc"] }
def client-type-completer [] { ["desktop" "phone" "tablet" "webmail"] }
def delete-contacts-completer [] { ["false" "true"] }
def country-completer [] { ["CA" "US"] }
def file-type-completer [] { ["csv" "json"] }
def file-type-completer-1 [] { ["csv"] }
def field-type-completer [] { ["Date" "Number" "Text"] }
def send-at-completer [] { ["now"] }
def aggregated-by-completer-1 [] { ["day" "total"] }
def ab-phase-id-completer [] { ["send" "test"] }
def sort-by-metric-completer [] { ["blocks" "bounces" "clicks" "delivered" "opens" "requests" "unique_clicks" "unique_opens" "unsubscribes"] }
def generations-completer [] { ["dynamic" "legacy" "legacy,dynamic"] }
def generation-completer [] { ["dynamic" "legacy"] }
def active-completer [] { ["0" "1"] }
def status-completer [] { ["cancel" "pause"] }
def default-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-access-settings-activity: "record<result: table<allowed: bool, auth_method: string, first_at: int, ip: string, last_at: int, location: string>>"
    delete-access-settings-whitelist: "record"
    get-access-settings-whitelist: "record<result: table<created_at: int, id: int, ip: string, updated_at: int>>"
    post-access-settings-whitelist: "record<result: table<created_at: int, id: int, ip: string, updated_at: int>>"
    delete-access-settings-whitelist-rule-id: "record"
    get-access-settings-whitelist-rule-id: "record<result: table<created_at: int, id: int, ip: string, updated_at: int>>"
    get-alerts: "table<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int>"
    post-alerts: "record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int>"
    delete-alerts-alert-id: "record"
    get-alerts-alert-id: "record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int>"
    patch-alerts-alert-id: "record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int>"
    get-api-keys: "record<result: table<api_key_id: string, name: string>>"
    create-api-keys: "record<api_key: string, api_key_id: string, name: string, scopes: list<string>>"
    get-api-keys-api-key-id: "record<result: table<scopes: list, api_key_id: string, name: string>>"
    patch-api-keys-api-key-id: "record<api_key_id: string, name: string>"
    put-api-keys-api-key-id: "record<scopes: list<string>, api_key_id: string, name: string>"
    get-asm-groups: "table<description: string, id: float, is_default: bool, last_email_sent_at: any, name: string, unsubscribes: int>"
    post-asm-groups: "record<description: string, id: int, is_default: bool, name: string>"
    delete-asm-groups-group-id: "record"
    get-asm-groups-group-id: "record<description: string, is_default: bool, name: string, id: int, last_email_sent_at: string, unsubscribes: int>"
    patch-asm-groups-group-id: "record<description: string, id: float, is_default: bool, last_email_sent_at: any, name: string, unsubscribes: int>"
    get-asm-groups-group-id-suppressions: "list<string>"
    post-asm-groups-group-id-suppressions: "record<recipient_emails: list<string>>"
    post-asm-groups-group-id-suppressions-search: "list<string>"
    get-asm-suppressions: "table<created_at: int, email: string, group_id: int, group_name: string>"
    post-asm-suppressions-global: "record<recipient_emails: list<string>>"
    delete-asm-suppressions-global-email: "record"
    get-asm-suppressions-global-email: "record<recipient_email: string>"
    get-asm-suppressions-email: "record<suppressions: table<description: string, id: int, is_default: bool, name: string, suppressed: bool>>"
    get-browsers-stats: "table<date: string, stats: list<record>>"
    get-campaigns: "record<result: table<categories: list, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list, plain_content: string, segment_ids: list, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string>>"
    post-campaigns: "record<categories: list<string>, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string>"
    get-campaigns-campaign-id: "record<categories: list<string>, custom_unsubscribe_url: string, html_content: string, id: int, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, status: string, subject: string, suppression_group_id: int, title: string>"
    patch-campaigns-campaign-id: "record<categories: list<string>, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string>"
    get-campaigns-campaign-id-schedules: "record<send_at: int>"
    patch-campaigns-campaign-id-schedules: "record<id: int, send_at: int, status: string>"
    post-campaigns-campaign-id-schedules: "record<id: int, send_at: int, status: string>"
    post-campaigns-campaign-id-schedules-now: "record<id: int, status: string>"
    post-campaigns-campaign-id-schedules-test: "record<to: string>"
    get-categories: "table<category: string>"
    get-categories-stats: "table<date: string, stats: list<record>>"
    get-categories-stats-sums: "record<date: string, stats: table<metrics: record, name: string, type: string>>"
    get-clients-stats: "table<date: string, stats: list<record>>"
    get-clients-client-type-stats: "table<date: string, stats: list<record>>"
    get-contactdb-custom-fields: "record<custom_fields: table<name: string, type: string, id: float>>"
    post-contactdb-custom-fields: "record<name: string, type: string, id: float>"
    delete-contactdb-custom-fields-custom-field-id: "record<errors: table<field: string, help: record, message: string>, id: string>"
    get-contactdb-custom-fields-custom-field-id: "record<name: string, type: string, id: float>"
    get-contactdb-lists: "record<lists: table<id: int, name: string, recipient_count: int>>"
    post-contactdb-lists: "record<id: int, name: string, recipient_count: int>"
    get-contactdb-lists-list-id: "record<id: int, name: string, recipient_count: int>"
    patch-contactdb-lists-list-id: "record<id: int, name: string, recipient_count: int>"
    get-contactdb-lists-list-id-recipients: "record<recipients: table<recipients: list>>"
    delete-contactdb-recipients: "record"
    get-contactdb-recipients: "record<recipients: list<record>>"
    patch-contactdb-recipients: "record<error_count: float, error_indices: list<float>, errors: table<error_indices: list, message: string>, new_count: float, persisted_recipients: list<string>, updated_count: float>"
    post-contactdb-recipients: "record<error_count: float, error_indices: list<float>, errors: table<error_indices: list, message: string>, new_count: float, persisted_recipients: list<string>, updated_count: float>"
    get-contactdb-recipients-billable-count: "record<recipient_count: float>"
    get-contactdb-recipients-count: "record<recipient_count: float>"
    get-contactdb-recipients-search: "record<recipients: table<recipients: list>>"
    post-contactdb-recipients-search: "record<recipient_count: int, recipients: table<created_at: int, custom_fields: list, email: string, first_name: string, id: string, last_clicked: int, last_emailed: int, last_opened: int, updated_at: int>>"
    delete-contactdb-recipients-recipient-id: "record"
    get-contactdb-recipients-recipient-id: "record<recipients: table<created_at: float, custom_fields: list, email: string, first_name: string, id: string, last_clicked: float, last_emailed: float, last_name: string, last_opened: float, updated_at: float>>"
    get-contactdb-recipients-recipient-id-lists: "record<lists: table<id: int, name: string, recipient_count: int>>"
    get-contactdb-reserved-fields: "record<reserved_fields: table<name: string, type: string>>"
    get-contactdb-segments: "record<segments: table<conditions: list, list_id: int, name: string, recipient_count: float>>"
    post-contactdb-segments: "record<id: float, conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float>"
    get-contactdb-segments-segment-id: "record<conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float>"
    patch-contactdb-segments-segment-id: "record<conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float>"
    get-contactdb-segments-segment-id-recipients: "record<recipients: table<recipients: list>>"
    get-contactdb-status: "record<status: table<\"\": string, id: string, value: string>>"
    list-designs: "record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list, generate_plain_content: bool, subject: string>>"
    post-designs: "record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>"
    list-sendgrid-pre-built-designs: "record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list, generate_plain_content: bool, subject: string>>"
    get-sendgrid-pre-built-design: "record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>"
    post-sendgrid-pre-built-design: "record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>"
    delete-design: "record"
    get-design: "record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>"
    put-design: "record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>"
    post-design: "record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>"
    get-devices-stats: "table<date: string, stats: list<record>>"
    get-geo-stats: "table<date: string, stats: list<record>>"
    get-ips: "table<assigned_at: int, ip: string, pools: list<string>, rdns: string, start_date: float, subusers: list<string>, warmup: bool, whitelabeled: bool>"
    post-ips: "record<ips: table<ip: string, subusers: list>, remaining_ips: int, warmup: bool>"
    get-ips-assigned: "table<ip: string, pools: list<string>, start_date: int, warmup: bool>"
    get-ips-pools: "table<name: string>"
    post-ips-pools: "record<name: string>"
    delete-ips-pools-pool-name: "record"
    get-ips-pools-pool-name: "record<ips: list<string>, pool_name: string>"
    put-ips-pools-pool-name: "record<name: string>"
    post-ips-pools-pool-name-ips: "record<ip: string, pools: list<string>, start_date: int, warmup: bool>"
    delete-ips-pools-pool-name-ips-ip: "record"
    get-ips-remaining: "record<results: table<period: string, price_per_ip: float, remaining: int>>"
    get-ips-warmup: "table<ip: string, start_date: int>"
    post-ips-warmup: "table<ip: string, start_date: int>"
    delete-ips-warmup-ip-address: "record"
    get-ips-warmup-ip-address: "table<ip: string, start_date: int>"
    get-ips-ip-address: "record<ip: string, pools: list<string>, rdns: string, start_date: int, subusers: list<string>, warmup: bool, whitelabeled: bool>"
    post-mail-batch: "record<batch_id: string>"
    get-mail-batch-batch-id: "record<batch_id: string>"
    get-mail-settings: "record<result: table<description: string, enabled: bool, name: string, title: string>>"
    get-mail-settings-address-whitelist: "record<enabled: bool, list: list<string>>"
    patch-mail-settings-address-whitelist: "record<enabled: bool, list: list<string>>"
    get-mail-settings-bounce-purge: "record<enabled: bool, hard_bounces: int, soft_bounces: int>"
    patch-mail-settings-bounce-purge: "record<enabled: bool, hard_bounces: int, soft_bounces: int>"
    get-mail-settings-footer: "record<enabled: bool, html_content: string, plain_content: string>"
    patch-mail-settings-footer: "record<enabled: bool, html_content: string, plain_content: string>"
    get-mail-settings-forward-bounce: "record<email: string, enabled: bool>"
    patch-mail-settings-forward-bounce: "record<email: string, enabled: bool>"
    get-mail-settings-forward-spam: "record<email: string, enabled: bool>"
    patch-mail-settings-forward-spam: "record<email: string, enabled: bool>"
    get-mail-settings-template: "record<enabled: bool, html_content: string>"
    patch-mail-settings-template: "record<enabled: bool, html_content: string>"
    get-mailbox-providers-stats: "table<date: string, stats: list<record>>"
    delete-mc-contacts: "record<job_id: record>"
    get-mc-contats: "record<_metadata: record<self: string>, contact_count: int, result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>>"
    put-mc-contacts: "record<job_id: string>"
    post-marketing-contacts-batch: "record<result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>>"
    get-mc-contacts-count: "record<billable_breakdown: record<breakdown: record, total: int>, billable_count: int, contact_count: int>"
    get-marketing-contacts-exports: "record<_metadata: record<next: string, prev: string, self: string>, result: table<_metadata: record, completed_at: string, created_at: string, expires_at: string, export_type: string, id: string, lists: list, segments: list, status: string, urls: list, user_id: string>>"
    post-mc-contacts-exports: "record<_metadata: record<count: float, next: string, prev: string, self: string>, id: string>"
    get-mc-contacts-exports-id: "record<_metadata: record<count: float, next: string, prev: string, self: string>, completed_at: string, contact_count: int, created_at: string, expires_at: string, id: string, message: string, status: string, updated_at: string, urls: list<string>>"
    put-mc-contacts-imports: "record<job_id: string, upload_headers: table<header: string, value: string>, upload_uri: string>"
    get-marketing-contacts-imports-id: "record<finished_at: string, id: string, job_type: string, results: record<created_count: float, deleted_count: float, errored_count: float, errors_url: string, requested_count: float, updated_count: float>, started_at: string, status: string>"
    post-mc-contacts-search: "record<_metadata: record<self: string>, contact_count: float, result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>>"
    post-marketing-contacts-search-emails: "record<result: record>"
    get-mc-contacts-id: "record<_metadata: record<self: string>, address_line_1: string, address_line_2: string, alternate_emails: list<string>, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list<string>, phone_number: string, postal_code: string, segment_ids: list<string>, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>"
    get-mc-field-definitions: "record<_metadata: record<count: int, next: string, prev: string, self: string>, custom_fields: table<field_type: string, id: string, name: string>, reserved_fields: table<field_type: string, name: string, read_only: bool>>"
    post-mc-field-definitions: "record<field_type: string, id: string, name: string, _metadata: record<count: int, next: string, prev: string, self: string>>"
    patch-mc-field-definitions-custom-field-id: "record<field_type: string, id: string, name: string, _metadata: record<count: int, next: string, prev: string, self: string>>"
    get-mc-lists: "record<_metadata: record<count: float, next: string, prev: string, self: string>, result: table<_metadata: record, contact_count: int, id: string, name: string>>"
    post-mc-lists: "record<_metadata: record<self: string>, contact_count: int, id: string, name: string>"
    delete-lists-id: "record<job_id: string>"
    get-mc-lists-id: "record<_metadata: record<self: string>, contact_count: int, id: string, name: string, contact_sample: record<_metadata: record<self: string>, address_line_1: string, address_line_2: string, alternate_emails: list<string>, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list<string>, phone_number: string, postal_code: string, segment_ids: list<string>, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>>"
    patch-mc-lists-id: "record<_metadata: record<self: string>, contact_count: int, id: string, name: string>"
    delete-mc-lists-id-contacts: "record<job_id: string>"
    get-mc-lists-id-contacts-count: "record<billable_count: int, contact_count: int>"
    get-marketing-segments: "record<results: table<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string>>"
    post-marketing-segments: "record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string>"
    get-segments: "record<_metadata: record<count: int, next: string, prev: string, self: string>, contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string>"
    post-segments: "record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string>"
    get-segments-segment-id: "record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string>"
    patch-segments-segment-id: "record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string>"
    post-marketing-segments-delete: "record<errors: table<error: string, id: string, resources: record>>"
    delete-marketing-segments-segment-id: "record"
    get-marketing-segments-segment-id: "record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string>"
    patch-marketing-segments-segment-id: "record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string>"
    post-marketing-senders: "record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>"
    get-marketing-singlesends: "record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<abtest: record, categories: list, created_at: string, id: string, is_abtest: bool, name: string, send_at: string, status: string, updated_at: string>>"
    post-marketing-singlesends: "record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>>"
    get-marketing-singlesends-categories: "record<categories: list<string>>"
    post-marketing-singlesends-search: "record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<abtest: record, categories: list, created_at: string, id: string, is_abtest: bool, name: string, send_at: string, status: string, updated_at: string>>"
    get-marketing-singlesends-id: "record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>>"
    patch-marketing-singlesends-id: "record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>>"
    post-marketing-singlesends-id: "record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>>"
    delete-marketing-singlesends-id-schedule: "record<send_at: string, status: string>"
    put-marketing-singlesends-id-schedule: "record<send_at: string, status: string>"
    getall-automation-stats: "record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<aggregation: string, id: string, stats: record, step_id: string>>"
    get-automations-stats-export: "string"
    get-automation-stat: "record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<aggregation: string, id: string, stats: record, step_id: string>>"
    get-automation-link-stat: "record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<clicks: int, step_id: string, url: string, url_location: int>, total_clicks: int>"
    getall-singlesend-stats: "record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, aggregation: string, id: string, stats: record>>"
    get-singlesend-stats-export: "string"
    get-singlesend-stat: "record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, aggregation: string, id: string, stats: record>>"
    get-singlesend-link-stat: "record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, clicks: int, url: string, url_location: int>, total_clicks: int>"
    post-marketing-test-send-email: "record"
    get-messages: "record<messages: table<clicks_count: int, from_email: string, last_event_time: int, msg_id: string, opens_count: int, status: string, subject: string, to_email: string>>"
    post-v3-messages-download: "record<message: string, status: string>"
    get-v3-messages-download-download-uuid: "record<csv: string, presigned_url: string>"
    get-v3-messages-msg-id: "record<api_key_id: string, asm_group_id: int, categories: list<string>, events: table<attempt_num: int, bounce_type: string, event_name: string, http_user_agent: string, mx_server: string, processed: string, reason: string, url: string>, from_email: string, msg_id: string, originating_ip: string, outbound_ip: string, outbound_ip_type: string, status: string, subject: string, teammate: string, template_id: string, to_email: string, unique_args: string>"
    get-partner-settings: "record<result: table<description: string, enabled: bool, name: string, title: string>>"
    get-partner-settings-new-relic: "record<enable_subuser_statistics: bool, enabled: bool, license_key: string>"
    patch-partner-settings-new-relic: "record<enable_subuser_statistics: bool, enabled: bool, license_key: string>"
    get-scopes: "record<scopes: list<string>>"
    get-v3-scopes-requests: "table<email: string, first_name: string, id: int, last_name: string, scope_group_name: string, username: string>"
    patch-v3-scopes-requests-approve-id: "record<scope_group_name: string>"
    get-v3-senders: "record<result: table<address: string, address_2: string, city: string, country: string, from: record, nickname: string, reply_to: record, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>>"
    post-senders: "record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>"
    delete-v3-senders-sender-id: "record"
    get-v3-senders-sender-id: "record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>"
    patch-v3-senders-sender-id: "record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>"
    post-v3-senders-sender-id-resend-verification: "record"
    post-sso-certificates: "record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string>"
    delete-sso-certificates-cert-id: "record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string>"
    get-sso-certificates-cert-id: "record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string>"
    get-sso-integrations: "table<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string>"
    post-sso-integrations: "record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string>"
    get-sso-integrations-id: "record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string>"
    patch-sso-integrations-id: "record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string>"
    get-sso-integrations-integration-id-certificates: "table<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string>"
    post-sso-teammates: "record<email: string, first_name: string, is_admin: bool, is_read_only: bool, last_name: string, is_sso: bool, username: string>"
    patch-sso-teammates-username: "record<email: string, first_name: string, is_admin: bool, is_read_only: bool, last_name: string, is_sso: bool, username: string, address: string, address2: string, city: string, company: string, country: string, phone: string, scopes: list<string>, state: string, user_type: string, website: string, zip: string>"
    get-stats: "table<date: string, stats: list<record>>"
    get-subusers: "table<disabled: bool, email: string, id: float, username: string>"
    post-subusers: "record<authorization_token: string, credit_allocation: record<type: string>, email: string, signup_session_token: string, user_id: float, username: string>"
    get-subusers-reputations: "table<reputation: float, username: string>"
    get-subusers-stats: "record<date: string, stats: table<metrics: record, name: string, type: string>>"
    get-subusers-stats-monthly: "record<date: string, stats: table<first_name: string, last_name: string, metrics: record, name: string, type: string>>"
    get-subusers-stats-sums: "record<date: string, stats: table<metrics: record, name: string, type: string>>"
    delete-subusers-subuser-name: "record"
    patch-subusers-subuser-name: "record"
    put-subusers-subuser-name-ips: "record<ips: list<string>>"
    delete-subusers-subuser-name-monitor: "record"
    get-subusers-subuser-name-monitor: "record<email: string, frequency: float>"
    post-subusers-subuser-name-monitor: "record<email: string, frequency: float>"
    put-subusers-subuser-name-monitor: "record<email: string, frequency: float>"
    get-subusers-subuser-name-stats-monthly: "record<date: string, stats: table<first_name: string, last_name: string, metrics: record, name: string, type: string>>"
    delete-suppression-blocks: "record"
    get-suppression-blocks: "table<created: int, email: string, reason: string, status: string>"
    delete-suppression-blocks-email: "record"
    get-suppression-blocks-email: "table<created: int, email: string, reason: string, status: string>"
    get-suppression-bounces: "table<created: float, email: string, reason: string, status: string>"
    delete-suppression-bounces-email: "record"
    get-suppression-bounces-email: "table<created: float, email: string, reason: string, status: string>"
    delete-suppression-invalid-emails: "record"
    get-suppression-invalid-emails: "table<created: int, email: string, reason: string>"
    delete-suppression-invalid-emails-email: "record"
    get-suppression-invalid-emails-email: "table<created: int, email: string, reason: string>"
    delete-suppression-spam-reports: "record"
    get-suppression-spam-reports: "table<created: int, email: string, ip: string>"
    delete-suppression-spam-reports-email: "record"
    get-suppression-spam-reports-email: "table<created: int, email: string, ip: string>"
    get-suppression-unsubscribes: "table<created: int, email: string>"
    get-v3-teammates: "record<result: table<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, state: string, user_type: string, username: string, website: string, zip: string>>"
    post-v3-teammates: "record<email: string, is_admin: bool, scopes: list<any>, token: string>"
    get-v3-teammates-pending: "record<result: table<email: string, expiration_date: int, is_admin: bool, scopes: list, token: string>>"
    post-v3-teammates-pending-token-resend: "record<email: string, is_admin: bool, scopes: list<string>, token: string>"
    delete-v3-teammates-username: "record<errors: table<field: string, message: string>>"
    get-v3-teammates-username: "record<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, scopes: list<any>, state: string, user_type: string, username: string, website: string, zip: string>"
    patch-v3-teammates-username: "record<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, scopes: list<string>, state: string, user_type: string, username: string, website: string, zip: string>"
    get-templates: "record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<generation: string, id: string, name: string, \"updated_at \": string, versions: list>>"
    post-templates: "record<generation: string, id: string, name: string, \"updated_at \": string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>>"
    delete-templates-template-id: "record"
    get-templates-template-id: "record<generation: string, id: string, name: string, \"updated_at \": string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>>"
    patch-templates-template-id: "record<generation: string, id: string, name: string, \"updated_at \": string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>>"
    post-templates-template-id: "record<generation: string, id: string, name: string, \"updated_at \": string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>>"
    post-templates-template-id-versions: "record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string>"
    get-templates-template-id-versions-version-id: "record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string>"
    patch-templates-template-id-versions-version-id: "record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string>"
    post-templates-template-id-versions-version-id-activate: "record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string>"
    get-tracking-settings: "record<result: table<description: string, enabled: bool, name: string, title: string>>"
    get-tracking-settings-click: "record<enable_text: bool, enabled: bool>"
    patch-tracking-settings-click: "record<enable_text: bool, enabled: bool>"
    get-tracking-settings-google-analytics: "record<enabled: bool, utm_campaign: string, utm_content: string, utm_medium: string, utm_source: string, utm_term: string>"
    patch-tracking-settings-google-analytics: "record<enabled: bool, utm_campaign: string, utm_content: string, utm_medium: string, utm_source: string, utm_term: string>"
    get-tracking-settings-open: "record<enabled: bool>"
    patch-tracking-settings-open: "record<enabled: bool>"
    get-tracking-settings-subscription: "record<enabled: bool, html_content: string, landing: string, plain_content: string, replace: string, url: string>"
    patch-tracking-settings-subscription: "record<enabled: bool, html_content: string, landing: string, plain_content: string, replace: string, url: string>"
    get-user-account: "record<reputation: float, type: string>"
    get-user-credits: "record<last_reset: string, next_reset: string, overage: int, remain: int, reset_frequency: string, total: int, used: int>"
    get-user-email: "record<email: string>"
    put-user-email: "record<email: string>"
    put-user-password: "record"
    get-user-profile: "record<address: string, address2: string, city: string, company: string, country: string, first_name: string, last_name: string, phone: string, state: string, website: string, zip: string>"
    patch-user-profile: "record<address: string, address2: string, city: string, company: string, country: string, first_name: string, last_name: string, phone: string, state: string, website: string, zip: string>"
    get-user-scheduled-sends: "table<batch_id: string, status: string>"
    post-user-scheduled-sends: "record<batch_id: string, status: string>"
    get-user-scheduled-sends-batch-id: "table<batch_id: string, status: string>"
    get-user-settings-enforced-tls: "record<require_tls: bool, require_valid_cert: bool>"
    patch-user-settings-enforced-tls: "record<require_tls: bool, require_valid_cert: bool>"
    get-user-username: "record<user_id: int, username: string>"
    put-user-username: "record<username: string>"
    get-user-webhooks-event-settings: "record<bounce: bool, click: bool, deferred: bool, delivered: bool, dropped: bool, enabled: bool, group_resubscribe: bool, group_unsubscribe: bool, oauth_client_id: string, oauth_token_url: string, open: bool, processed: bool, spam_report: bool, unsubscribe: bool, url: string>"
    patch-user-webhooks-event-settings: "record<bounce: bool, click: bool, deferred: bool, delivered: bool, dropped: bool, enabled: bool, group_resubscribe: bool, group_unsubscribe: bool, oauth_client_id: string, oauth_token_url: string, open: bool, processed: bool, spam_report: bool, unsubscribe: bool, url: string>"
    get-user-webhooks-event-settings-signed: "record<public_key: string>"
    patch-user-webhooks-event-settings-signed: "record<public_key: string>"
    get-user-webhooks-parse-settings: "record<result: table<hostname: string, send_raw: bool, spam_check: bool, url: string>>"
    post-user-webhooks-parse-settings: "record<hostname: string, send_raw: bool, spam_check: bool, url: string>"
    delete-user-webhooks-parse-settings-hostname: "record"
    get-user-webhooks-parse-settings-hostname: "record<hostname: string, send_raw: bool, spam_check: bool, url: string>"
    patch-user-webhooks-parse-settings-hostname: "record<hostname: string, send_raw: bool, spam_check: bool, url: string>"
    get-user-webhooks-parse-stats: "table<date: string, stats: list<record>>"
    post-validations-email: "record<result: record<checks: record<additional: record, domain: record, local_part: record>, email: string, host: string, ip_address: string, local: string, score: float, source: string, suggestion: string, verdict: string>>"
    get-verified-senders: "record<results: table<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string>>"
    post-verified-senders: "record<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string>"
    get-verified-senders-domains: "record<results: record<hard_failures: list<string>, soft_failures: list<string>>>"
    post-verified-senders-resend-id: "record"
    get-verified-senders-steps-completed: "record<results: record<domain_verified: bool, sender_verified: bool>>"
    delete-verified-senders-id: "record"
    patch-verified-senders-id: "record<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string>"
    get-whitelabel-domains: "table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>>"
    post-whitelabel-domains: "record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record<data: string, host: string, type: string, valid: bool>, dkim2: record<data: string, host: string, type: string, valid: bool>, mail_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool>"
    get-whitelabel-domains-default: "table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>>"
    delete-whitelabel-domains-subuser: "record"
    get-whitelabel-domains-subuser: "record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    delete-whitelabel-domains-domain-id: "record"
    get-whitelabel-domains-domain-id: "record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record<data: string, host: string, type: string, valid: bool>, dkim2: record<data: string, host: string, type: string, valid: bool>, mail_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool>"
    patch-whitelabel-domains-domain-id: "table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>>"
    post-whitelabel-domains-domain-id-subuser: "record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    post-whitelabel-domains-id-ips: "record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    delete-whitelabel-domains-id-ips-ip: "record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    post-whitelabel-domains-id-validate: "record<id: int, valid: bool, validation_results: record<dkim1: record<reason: string, valid: bool>, dkim2: record<reason: string, valid: bool>, mail_cname: record<reason: string, valid: bool>, spf: record<reason: string, valid: bool>>>"
    get-whitelabel-ips: "table<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: list<record>, valid: bool>"
    post-whitelabel-ips: "record<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: table<user_id: int, username: string>, valid: bool>"
    delete-whitelabel-ips-id: "record"
    get-whitelabel-ips-id: "record<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: table<user_id: int, username: string>, valid: bool>"
    post-whitelabel-ips-id-validate: "record<id: int, valid: bool, validation_results: record<a_record: record<reason: string, valid: bool>>>"
    get-whitelabel-links: "table<default: bool, dns: record<domain_cname: record, owner_cname: record>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    post-whitelabel-links: "record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    get-whitelabel-links-default: "record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    delete-whitelabel-links-subuser: "record"
    get-whitelabel-links-subuser: "record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    delete-whitelabel-links-id: "record"
    get-whitelabel-links-id: "record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    patch-whitelabel-links-id: "record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
    post-whitelabel-links-id-validate: "record<id: int, valid: bool, validation_results: record<domain_cname: record<reason: string, valid: bool>, owner_cname: record<reason: string, valid: bool>>>"
    post-whitelabel-links-link-id-subuser: "record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-access-settings-activity" "delete-access-settings-whitelist" "get-access-settings-whitelist" "post-access-settings-whitelist" "delete-access-settings-whitelist-rule-id" "get-access-settings-whitelist-rule-id" "get-alerts" "post-alerts" "delete-alerts-alert-id" "get-alerts-alert-id" "patch-alerts-alert-id" "get-api-keys" "create-api-keys" "delete-api-keys-api-key-id" "get-api-keys-api-key-id" "patch-api-keys-api-key-id" "put-api-keys-api-key-id" "get-asm-groups" "post-asm-groups" "delete-asm-groups-group-id" "get-asm-groups-group-id" "patch-asm-groups-group-id" "get-asm-groups-group-id-suppressions" "post-asm-groups-group-id-suppressions" "post-asm-groups-group-id-suppressions-search" "delete-asm-groups-group-id-suppressions-email" "get-asm-suppressions" "post-asm-suppressions-global" "delete-asm-suppressions-global-email" "get-asm-suppressions-global-email" "get-asm-suppressions-email" "get-browsers-stats" "get-campaigns" "post-campaigns" "delete-campaigns-campaign-id" "get-campaigns-campaign-id" "patch-campaigns-campaign-id" "delete-campaigns-campaign-id-schedules" "get-campaigns-campaign-id-schedules" "patch-campaigns-campaign-id-schedules" "post-campaigns-campaign-id-schedules" "post-campaigns-campaign-id-schedules-now" "post-campaigns-campaign-id-schedules-test" "get-categories" "get-categories-stats" "get-categories-stats-sums" "get-clients-stats" "get-clients-client-type-stats" "get-contactdb-custom-fields" "post-contactdb-custom-fields" "delete-contactdb-custom-fields-custom-field-id" "get-contactdb-custom-fields-custom-field-id" "delete-contactdb-lists" "get-contactdb-lists" "post-contactdb-lists" "delete-contactdb-lists-list-id" "get-contactdb-lists-list-id" "patch-contactdb-lists-list-id" "get-contactdb-lists-list-id-recipients" "post-contactdb-lists-list-id-recipients" "delete-contactdb-lists-list-id-recipients-recipient-id" "post-contactdb-lists-list-id-recipients-recipient-id" "delete-contactdb-recipients" "get-contactdb-recipients" "patch-contactdb-recipients" "post-contactdb-recipients" "get-contactdb-recipients-billable-count" "get-contactdb-recipients-count" "get-contactdb-recipients-search" "post-contactdb-recipients-search" "delete-contactdb-recipients-recipient-id" "get-contactdb-recipients-recipient-id" "get-contactdb-recipients-recipient-id-lists" "get-contactdb-reserved-fields" "get-contactdb-segments" "post-contactdb-segments" "delete-contactdb-segments-segment-id" "get-contactdb-segments-segment-id" "patch-contactdb-segments-segment-id" "get-contactdb-segments-segment-id-recipients" "get-contactdb-status" "list-designs" "post-designs" "list-sendgrid-pre-built-designs" "get-sendgrid-pre-built-design" "post-sendgrid-pre-built-design" "delete-design" "get-design" "put-design" "post-design" "get-devices-stats" "get-geo-stats" "get-ips" "post-ips" "get-ips-assigned" "get-ips-pools" "post-ips-pools" "delete-ips-pools-pool-name" "get-ips-pools-pool-name" "put-ips-pools-pool-name" "post-ips-pools-pool-name-ips" "delete-ips-pools-pool-name-ips-ip" "get-ips-remaining" "get-ips-warmup" "post-ips-warmup" "delete-ips-warmup-ip-address" "get-ips-warmup-ip-address" "get-ips-ip-address" "post-mail-batch" "get-mail-batch-batch-id" "post-mail-send" "get-mail-settings" "get-mail-settings-address-whitelist" "patch-mail-settings-address-whitelist" "get-mail-settings-bounce-purge" "patch-mail-settings-bounce-purge" "get-mail-settings-footer" "patch-mail-settings-footer" "get-mail-settings-forward-bounce" "patch-mail-settings-forward-bounce" "get-mail-settings-forward-spam" "patch-mail-settings-forward-spam" "get-mail-settings-template" "patch-mail-settings-template" "get-mailbox-providers-stats" "delete-mc-contacts" "get-mc-contats" "put-mc-contacts" "post-marketing-contacts-batch" "get-mc-contacts-count" "get-marketing-contacts-exports" "post-mc-contacts-exports" "get-mc-contacts-exports-id" "put-mc-contacts-imports" "get-marketing-contacts-imports-id" "post-mc-contacts-search" "post-marketing-contacts-search-emails" "get-mc-contacts-id" "get-mc-field-definitions" "post-mc-field-definitions" "delete-mc-field-definitions-custom-field-id" "patch-mc-field-definitions-custom-field-id" "get-mc-lists" "post-mc-lists" "delete-lists-id" "get-mc-lists-id" "patch-mc-lists-id" "delete-mc-lists-id-contacts" "get-mc-lists-id-contacts-count" "get-marketing-segments" "post-marketing-segments" "get-segments" "post-segments" "delete-segments-segment-id" "get-segments-segment-id" "patch-segments-segment-id" "post-marketing-segments-delete" "delete-marketing-segments-segment-id" "get-marketing-segments-segment-id" "patch-marketing-segments-segment-id" "post-marketing-senders" "delete-marketing-singlesends" "get-marketing-singlesends" "post-marketing-singlesends" "get-marketing-singlesends-categories" "post-marketing-singlesends-search" "delete-marketing-singlesends-id" "get-marketing-singlesends-id" "patch-marketing-singlesends-id" "post-marketing-singlesends-id" "delete-marketing-singlesends-id-schedule" "put-marketing-singlesends-id-schedule" "getall-automation-stats" "get-automations-stats-export" "get-automation-stat" "get-automation-link-stat" "getall-singlesend-stats" "get-singlesend-stats-export" "get-singlesend-stat" "get-singlesend-link-stat" "post-marketing-test-send-email" "get-messages" "post-v3-messages-download" "get-v3-messages-download-download-uuid" "get-v3-messages-msg-id" "get-partner-settings" "get-partner-settings-new-relic" "patch-partner-settings-new-relic" "get-scopes" "get-v3-scopes-requests" "delete-v3-scopes-requests-request-id" "patch-v3-scopes-requests-approve-id" "get-v3-senders" "post-senders" "delete-v3-senders-sender-id" "get-v3-senders-sender-id" "patch-v3-senders-sender-id" "post-v3-senders-sender-id-resend-verification" "post-sso-certificates" "delete-sso-certificates-cert-id" "get-sso-certificates-cert-id" "patch-sso-certificates-cert-id" "get-sso-integrations" "post-sso-integrations" "delete-sso-integrations-id" "get-sso-integrations-id" "patch-sso-integrations-id" "get-sso-integrations-integration-id-certificates" "post-sso-teammates" "patch-sso-teammates-username" "get-stats" "get-subusers" "post-subusers" "get-subusers-reputations" "get-subusers-stats" "get-subusers-stats-monthly" "get-subusers-stats-sums" "delete-subusers-subuser-name" "patch-subusers-subuser-name" "put-subusers-subuser-name-ips" "delete-subusers-subuser-name-monitor" "get-subusers-subuser-name-monitor" "post-subusers-subuser-name-monitor" "put-subusers-subuser-name-monitor" "get-subusers-subuser-name-stats-monthly" "delete-suppression-blocks" "get-suppression-blocks" "delete-suppression-blocks-email" "get-suppression-blocks-email" "delete-suppression-bounces" "get-suppression-bounces" "delete-suppression-bounces-email" "get-suppression-bounces-email" "delete-suppression-invalid-emails" "get-suppression-invalid-emails" "delete-suppression-invalid-emails-email" "get-suppression-invalid-emails-email" "delete-suppression-spam-reports" "get-suppression-spam-reports" "delete-suppression-spam-reports-email" "get-suppression-spam-reports-email" "get-suppression-unsubscribes" "get-v3-teammates" "post-v3-teammates" "get-v3-teammates-pending" "delete-v3-teammates-pending-token" "post-v3-teammates-pending-token-resend" "delete-v3-teammates-username" "get-v3-teammates-username" "patch-v3-teammates-username" "get-templates" "post-templates" "delete-templates-template-id" "get-templates-template-id" "patch-templates-template-id" "post-templates-template-id" "post-templates-template-id-versions" "delete-templates-template-id-versions-version-id" "get-templates-template-id-versions-version-id" "patch-templates-template-id-versions-version-id" "post-templates-template-id-versions-version-id-activate" "get-tracking-settings" "get-tracking-settings-click" "patch-tracking-settings-click" "get-tracking-settings-google-analytics" "patch-tracking-settings-google-analytics" "get-tracking-settings-open" "patch-tracking-settings-open" "get-tracking-settings-subscription" "patch-tracking-settings-subscription" "get-user-account" "get-user-credits" "get-user-email" "put-user-email" "put-user-password" "get-user-profile" "patch-user-profile" "get-user-scheduled-sends" "post-user-scheduled-sends" "delete-user-scheduled-sends-batch-id" "get-user-scheduled-sends-batch-id" "patch-user-scheduled-sends-batch-id" "get-user-settings-enforced-tls" "patch-user-settings-enforced-tls" "get-user-username" "put-user-username" "get-user-webhooks-event-settings" "patch-user-webhooks-event-settings" "get-user-webhooks-event-settings-signed" "patch-user-webhooks-event-settings-signed" "post-user-webhooks-event-test" "get-user-webhooks-parse-settings" "post-user-webhooks-parse-settings" "delete-user-webhooks-parse-settings-hostname" "get-user-webhooks-parse-settings-hostname" "patch-user-webhooks-parse-settings-hostname" "get-user-webhooks-parse-stats" "post-validations-email" "get-verified-senders" "post-verified-senders" "get-verified-senders-domains" "post-verified-senders-resend-id" "get-verified-senders-steps-completed" "get-verified-senders-verify-token" "delete-verified-senders-id" "patch-verified-senders-id" "post-whitelabel-dns-email" "get-whitelabel-domains" "post-whitelabel-domains" "get-whitelabel-domains-default" "delete-whitelabel-domains-subuser" "get-whitelabel-domains-subuser" "delete-whitelabel-domains-domain-id" "get-whitelabel-domains-domain-id" "patch-whitelabel-domains-domain-id" "post-whitelabel-domains-domain-id-subuser" "post-whitelabel-domains-id-ips" "delete-whitelabel-domains-id-ips-ip" "post-whitelabel-domains-id-validate" "get-whitelabel-ips" "post-whitelabel-ips" "delete-whitelabel-ips-id" "get-whitelabel-ips-id" "post-whitelabel-ips-id-validate" "get-whitelabel-links" "post-whitelabel-links" "get-whitelabel-links-default" "delete-whitelabel-links-subuser" "get-whitelabel-links-subuser" "delete-whitelabel-links-id" "get-whitelabel-links-id" "patch-whitelabel-links-id" "post-whitelabel-links-id-validate" "post-whitelabel-links-link-id-subuser" "commands"] | sort) } | get name | first)
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

# Retrieve all recent access attempts
#
# GET /access_settings/activity
# Returns: record<result: table<allowed: bool, auth_method: string, first_at: int, ip: string, last_at: int, location: string>>
# operationId: GET_access_settings-activity
export def "get-access-settings-activity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limits the number of IPs to return. (default: 20)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/access_settings/activity"
    query: [{name: limit, var: limit}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove one or more IPs from the allow list
#
# DELETE /access_settings/whitelist
# Returns: record
# operationId: DELETE_access_settings-whitelist
export def "delete-access-settings-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --ids: list<int> # An array of the IDs of the IP address that you want to remove from your allow list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/access_settings/whitelist"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of currently allowed IPs
#
# GET /access_settings/whitelist
# Returns: record<result: table<created_at: int, id: int, ip: string, updated_at: int>>
# operationId: GET_access_settings-whitelist
export def "get-access-settings-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/access_settings/whitelist"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add one or more IPs to the allow list
#
# POST /access_settings/whitelist
# Returns: record<result: table<created_at: int, id: int, ip: string, updated_at: int>>
# operationId: POST_access_settings-whitelist
export def "post-access-settings-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  ips: list # An array containing the IP(s) you want to allow. — item shape: {ip: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/access_settings/whitelist"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: ips, var: ips}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, ips: $ips
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a specific IP from the allowed list
#
# DELETE /access_settings/whitelist/{rule_id}
# Returns: record
# operationId: DELETE_access_settings-whitelist-rule_id
export def "delete-access-settings-whitelist-rule-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/access_settings/whitelist/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    rule_id: $rule_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a specific allowed IP
#
# GET /access_settings/whitelist/{rule_id}
# Returns: record<result: table<created_at: int, id: int, ip: string, updated_at: int>>
# operationId: GET_access_settings-whitelist-rule_id
export def "get-access-settings-whitelist-rule-id" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/access_settings/whitelist/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all alerts
#
# GET /alerts
# Returns: table<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int>
# operationId: GET_alerts
export def "get-alerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/alerts"
    header: [{name: Authorization, var: authorization}, {name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Alert
#
# POST /alerts
# Returns: record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int>
# operationId: POST_alerts
export def "post-alerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string
  --on-behalf-of: string
  --email-to: string # The email address the alert will be sent to. Example: test@example.com (nullable, format: email)
  --frequency: string # Required for stats_notification. How frequently the alert will be sent. Example: daily
  --percentage: int # Required for usage_alert. When this usage threshold is reached, the alert will be sent. Example: 90
  type: string@type-completer # The type of alert you want to create. Can be either usage_limit or stats_notification. Example: usage_limit
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/alerts"
    header: [{name: Authorization, var: authorization}, {name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_to, var: email_to}, {name: frequency, var: frequency}, {name: percentage, var: percentage}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, on_behalf_of: $on_behalf_of, email_to: $email_to, frequency: $frequency, percentage: $percentage, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an alert
#
# DELETE /alerts/{alert_id}
# Returns: record
# operationId: DELETE_alerts-alert_id
export def "delete-alerts-alert-id" [
  alert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/alerts/{alert_id}"
    path_params: [{name: alert_id, var: alert_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    alert_id: $alert_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a specific alert
#
# GET /alerts/{alert_id}
# Returns: record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int>
# operationId: GET_alerts-alert_id
export def "get-alerts-alert-id" [
  alert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/alerts/{alert_id}"
    path_params: [{name: alert_id, var: alert_id}]
    header: [{name: Authorization, var: authorization}, {name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id, authorization: $authorization, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an alert
#
# PATCH /alerts/{alert_id}
# Returns: record<created_at: int, email_to: string, frequency: string, id: int, percentage: int, type: string, updated_at: int>
# operationId: PATCH_alerts-alert_id
export def "patch-alerts-alert-id" [
  alert_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --email-to: string # The new email address you want your alert to be sent to. Example: test@example.com
  --frequency: string # The new frequency at which to send the stats_notification alert. Example: monthly
  --percentage: int # The new percentage threshold at which the usage_limit alert will be sent. Example: 90
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/alerts/{alert_id}"
    path_params: [{name: alert_id, var: alert_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_to, var: email_to}, {name: frequency, var: frequency}, {name: percentage, var: percentage}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id, on_behalf_of: $on_behalf_of, email_to: $email_to, frequency: $frequency, percentage: $percentage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all API Keys belonging to the authenticated user
#
# GET /api_keys
# Returns: record<result: table<api_key_id: string, name: string>>
# operationId: GET_api_keys
export def "get-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api_keys"
    query: [{name: limit, var: limit}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create API keys
#
# POST /api_keys
# Returns: record<api_key: string, api_key_id: string, name: string, scopes: list<string>>
# operationId: create-api-keys
export def "create-api-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  name: string # The name you will use to describe this API Key.
  --scopes: list<string> # The individual permissions that you are giving to this API Key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api_keys"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, name: $name, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete API keys
#
# DELETE /api_keys/{api_key_id}
# operationId: DELETE_api_keys-api_key_id
export def "delete-api-keys-api-key-id" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/api_keys/{api_key_id}"
    path_params: [{name: api_key_id, var: api_key_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    api_key_id: $api_key_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing API Key
#
# GET /api_keys/{api_key_id}
# Returns: record<result: table<scopes: list, api_key_id: string, name: string>>
# operationId: GET_api_keys-api_key_id
export def "get-api-keys-api-key-id" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api_keys/{api_key_id}"
    path_params: [{name: api_key_id, var: api_key_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key_id: $api_key_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update API key name
#
# PATCH /api_keys/{api_key_id}
# Returns: record<api_key_id: string, name: string>
# operationId: PATCH_api_keys-api_key_id
export def "patch-api-keys-api-key-id" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  name: string # The new name of the API Key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/api_keys/{api_key_id}"
    path_params: [{name: api_key_id, var: api_key_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key_id: $api_key_id, on_behalf_of: $on_behalf_of, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update API key name and scopes
#
# PUT /api_keys/{api_key_id}
# Returns: record<scopes: list<string>, api_key_id: string, name: string>
# operationId: PUT_api_keys-api_key_id
export def "put-api-keys-api-key-id" [
  api_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  name: string
  --scopes: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api_keys/{api_key_id}"
    path_params: [{name: api_key_id, var: api_key_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key_id: $api_key_id, on_behalf_of: $on_behalf_of, name: $name, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all suppression groups associated with the user.
#
# GET /asm/groups
# Returns: table<description: string, id: float, is_default: bool, last_email_sent_at: any, name: string, unsubscribes: int>
# operationId: GET_asm-groups
export def "get-asm-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/asm/groups"
    query: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new suppression group
#
# POST /asm/groups
# Returns: record<description: string, id: int, is_default: bool, name: string>
# operationId: POST_asm-groups
export def "post-asm-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --description: string # A brief description of your suppression group. Required when creating a group.
  --is-default: oneof<nothing, bool> # Indicates if you would like this to be your default suppression group.
  --name: string # The name of your suppression group. Required when creating a group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/asm/groups"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: is_default, var: is_default}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, description: $description, is_default: $is_default, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Suppression Group
#
# DELETE /asm/groups/{group_id}
# Returns: record
# operationId: DELETE_asm-groups-group_id
export def "delete-asm-groups-group-id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/asm/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get information on a single suppression group.
#
# GET /asm/groups/{group_id}
# Returns: record<description: string, is_default: bool, name: string, id: int, last_email_sent_at: string, unsubscribes: int>
# operationId: GET_asm-groups-group_id
export def "get-asm-groups-group-id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/asm/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a suppression group.
#
# PATCH /asm/groups/{group_id}
# Returns: record<description: string, id: float, is_default: bool, last_email_sent_at: any, name: string, unsubscribes: int>
# operationId: PATCH_asm-groups-group_id
export def "patch-asm-groups-group-id" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --description: string # A brief description of your suppression group. Required when creating a group.
  --is-default: oneof<nothing, bool> # Indicates if you would like this to be your default suppression group.
  --name: string # The name of your suppression group. Required when creating a group.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/asm/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: is_default, var: is_default}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    group_id: $group_id, on_behalf_of: $on_behalf_of, description: $description, is_default: $is_default, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all suppressions for a suppression group
#
# GET /asm/groups/{group_id}/suppressions
# Returns: list<string>
# operationId: GET_asm-groups-group_id-suppressions
export def "get-asm-groups-group-id-suppressions" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/asm/groups/{group_id}/suppressions"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add suppressions to a suppression group
#
# POST /asm/groups/{group_id}/suppressions
# Returns: record<recipient_emails: list<string>>
# operationId: POST_asm-groups-group_id-suppressions
export def "post-asm-groups-group-id-suppressions" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  recipient_emails: list<string> # The array of email addresses to add or find.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/asm/groups/{group_id}/suppressions"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: recipient_emails, var: recipient_emails}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    group_id: $group_id, on_behalf_of: $on_behalf_of, recipient_emails: $recipient_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for suppressions within a group
#
# POST /asm/groups/{group_id}/suppressions/search
# Returns: list<string>
# operationId: POST_asm-groups-group_id-suppressions-search
export def "post-asm-groups-group-id-suppressions-search" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  recipient_emails: list<string> # The array of email addresses to add or find.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/asm/groups/{group_id}/suppressions/search"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: recipient_emails, var: recipient_emails}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, on_behalf_of: $on_behalf_of, recipient_emails: $recipient_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a suppression from a suppression group
#
# DELETE /asm/groups/{group_id}/suppressions/{email}
# operationId: DELETE_asm-groups-group_id-suppressions-email
export def "delete-asm-groups-group-id-suppressions-email" [
  group_id: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/asm/groups/{group_id}/suppressions/{email}"
    path_params: [{name: group_id, var: group_id}, {name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all suppressions
#
# GET /asm/suppressions
# Returns: table<created_at: int, email: string, group_id: int, group_name: string>
# operationId: GET_asm-suppressions
export def "get-asm-suppressions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/asm/suppressions"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add recipient addresses to the global suppression group.
#
# POST /asm/suppressions/global
# Returns: record<recipient_emails: list<string>>
# operationId: POST_asm-suppressions-global
export def "post-asm-suppressions-global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  recipient_emails: list<string> # The array of email addresses to add or find.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/asm/suppressions/global"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: recipient_emails, var: recipient_emails}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, recipient_emails: $recipient_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Global Suppression
#
# DELETE /asm/suppressions/global/{email}
# Returns: record
# operationId: DELETE_asm-suppressions-global-email
export def "delete-asm-suppressions-global-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/asm/suppressions/global/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Global Suppression
#
# GET /asm/suppressions/global/{email}
# Returns: record<recipient_email: string>
# operationId: GET_asm-suppressions-global-email
export def "get-asm-suppressions-global-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/asm/suppressions/global/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all suppression groups for an email address
#
# GET /asm/suppressions/{email}
# Returns: record<suppressions: table<description: string, id: int, is_default: bool, name: string, suppressed: bool>>
# operationId: GET_asm-suppressions-email
export def "get-asm-suppressions-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/asm/suppressions/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve email statistics by browser.
#
# GET /browsers/stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_browsers-stats
export def "get-browsers-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --browsers: string # The browsers to get statistics for. You can include up to 10 different browsers by including this parameter multiple times.
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/browsers/stats"
    query: [{name: browsers, var: browsers}, {name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    browsers: $browsers, limit: $limit, offset: $offset, aggregated_by: $aggregated_by, start_date: $start_date, end_date: $end_date, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all Campaigns
#
# GET /campaigns
# Returns: record<result: table<categories: list, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list, plain_content: string, segment_ids: list, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string>>
# operationId: GET_campaigns
export def "get-campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of results you would like to receive at a time. (default: 10)
  --offset: int # The index of the first campaign to return, where 0 is the first campaign. (default: 0)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/campaigns"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Campaign
#
# POST /campaigns
# Returns: record<categories: list<string>, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string>
# operationId: POST_campaigns
export def "post-campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --categories: list<string> # The categories you would like associated to this campaign. (nullable)
  --custom-unsubscribe-url: string # This is the url of the custom unsubscribe page that you provide for customers to unsubscribe from your suppression groups. (nullable)
  --editor: string@editor-completer # The editor used in the UI.
  --html-content: string # The HTML of your marketing email. (nullable)
  --ip-pool: string # The pool of IPs that you would like to send this email from. (nullable)
  --list-ids: list<int> # The IDs of the lists you are sending this campaign to. You can have both segment IDs and list IDs (nullable)
  --plain-content: string # The plain text content of your emails. (nullable)
  --segment-ids: list<int> # The segment IDs that you are sending this list to. You can have both segment IDs and list IDs. Segments are limited to 10 segment IDs. (nullable)
  --sender-id: int # The ID of the "sender" identity that you have created. Your recipients will see this as the "from" on your marketing emails. (nullable)
  --subject: string # The subject of your campaign that your recipients will see. (nullable)
  --suppression-group-id: int # The suppression group that this marketing email belongs to, allowing recipients to opt-out of emails of this type. (nullable)
  title: string # The display title of your campaign. This will be viewable by you in the Marketing Campaigns UI.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/campaigns"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: custom_unsubscribe_url, var: custom_unsubscribe_url}, {name: editor, var: editor}, {name: html_content, var: html_content}, {name: ip_pool, var: ip_pool}, {name: list_ids, var: list_ids}, {name: plain_content, var: plain_content}, {name: segment_ids, var: segment_ids}, {name: sender_id, var: sender_id}, {name: subject, var: subject}, {name: suppression_group_id, var: suppression_group_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, categories: $categories, custom_unsubscribe_url: $custom_unsubscribe_url, editor: $editor, html_content: $html_content, ip_pool: $ip_pool, list_ids: $list_ids, plain_content: $plain_content, segment_ids: $segment_ids, sender_id: $sender_id, subject: $subject, suppression_group_id: $suppression_group_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Campaign
#
# DELETE /campaigns/{campaign_id}
# operationId: DELETE_campaigns-campaign_id
export def "delete-campaigns-campaign-id" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/campaigns/{campaign_id}"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single campaign
#
# GET /campaigns/{campaign_id}
# Returns: record<categories: list<string>, custom_unsubscribe_url: string, html_content: string, id: int, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, status: string, subject: string, suppression_group_id: int, title: string>
# operationId: GET_campaigns-campaign_id
export def "get-campaigns-campaign-id" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/campaigns/{campaign_id}"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Campaign
#
# PATCH /campaigns/{campaign_id}
# Returns: record<categories: list<string>, custom_unsubscribe_url: string, editor: string, html_content: string, ip_pool: string, list_ids: list<int>, plain_content: string, segment_ids: list<int>, sender_id: int, subject: string, suppression_group_id: int, title: string, id: int, status: string>
# operationId: PATCH_campaigns-campaign_id
export def "patch-campaigns-campaign-id" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  categories: list<string> # The categories you want to tag on this campaign.
  html_content: string # The HTML content of this campaign.
  plain_content: string # The plain content of this campaign.
  subject: string # The subject line for your campaign.
  title: string # The title of the campaign.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/campaigns/{campaign_id}"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: html_content, var: html_content}, {name: plain_content, var: plain_content}, {name: subject, var: subject}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of, categories: $categories, html_content: $html_content, plain_content: $plain_content, subject: $subject, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unschedule a Scheduled Campaign
#
# DELETE /campaigns/{campaign_id}/schedules
# operationId: DELETE_campaigns-campaign_id-schedules
export def "delete-campaigns-campaign-id-schedules" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/campaigns/{campaign_id}/schedules"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View Scheduled Time of a Campaign
#
# GET /campaigns/{campaign_id}/schedules
# Returns: record<send_at: int>
# operationId: GET_campaigns-campaign_id-schedules
export def "get-campaigns-campaign-id-schedules" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/campaigns/{campaign_id}/schedules"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Scheduled Campaign
#
# PATCH /campaigns/{campaign_id}/schedules
# Returns: record<id: int, send_at: int, status: string>
# operationId: PATCH_campaigns-campaign_id-schedules
export def "patch-campaigns-campaign-id-schedules" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  send_at: int # format: int64
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/campaigns/{campaign_id}/schedules"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: send_at, var: send_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of, send_at: $send_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule a Campaign
#
# POST /campaigns/{campaign_id}/schedules
# Returns: record<id: int, send_at: int, status: string>
# operationId: POST_campaigns-campaign_id-schedules
export def "post-campaigns-campaign-id-schedules" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  send_at: int # The unix timestamp for the date and time you would like your campaign to be sent out.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/campaigns/{campaign_id}/schedules"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: send_at, var: send_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of, send_at: $send_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a Campaign
#
# POST /campaigns/{campaign_id}/schedules/now
# Returns: record<id: int, status: string>
# operationId: POST_campaigns-campaign_id-schedules-now
export def "post-campaigns-campaign-id-schedules-now" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/campaigns/{campaign_id}/schedules/now"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a Test Campaign
#
# POST /campaigns/{campaign_id}/schedules/test
# Returns: record<to: string>
# operationId: POST_campaigns-campaign_id-schedules-test
export def "post-campaigns-campaign-id-schedules-test" [
  campaign_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  to: string # The email address that should receive the test campaign. (format: email)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/campaigns/{campaign_id}/schedules/test"
    path_params: [{name: campaign_id, var: campaign_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: to, var: to}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    campaign_id: $campaign_id, on_behalf_of: $on_behalf_of, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all categories
#
# GET /categories
# Returns: table<category: string>
# operationId: GET_categories
export def "get-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of categories to display per page. (default: 50)
  --category: string # Allows you to perform a prefix search on this particular category.
  --offset: int # The point in the list that you would like to begin displaying results. (default: 0)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories"
    query: [{name: limit, var: limit}, {name: category, var: category}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, category: $category, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Email Statistics for Categories
#
# GET /categories/stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_categories-stats
export def "get-categories-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --categories: string # The individual categories that you want to retrieve statistics for. You may include up to 10 different categories. (required)
  --limit: int # The number of results to include. (default: 500)
  --offset: int # The number of results to skip.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/categories/stats"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}, {name: categories, var: categories, required: true}, {name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, categories: $categories, limit: $limit, offset: $offset, aggregated_by: $aggregated_by, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve sums of email stats for each category [Needs: Stats object defined, has category ID?]
#
# GET /categories/stats/sums
# Returns: record<date: string, stats: table<metrics: record, name: string, type: string>>
# operationId: GET_categories-stats-sums
export def "get-categories-stats-sums" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by-metric: string # The metric that you want to sort by. Must be a single metric. (default: delivered)
  --sort-by-direction: string@sort-by-direction-completer # The direction you want to sort. (default: desc)
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --limit: int # Limits the number of results returned. (default: 5)
  --offset: int # The point in the list to begin retrieving results. (default: 0)
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories/stats/sums"
    query: [{name: sort_by_metric, var: sort_by_metric}, {name: sort_by_direction, var: sort_by_direction}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort_by_metric: $sort_by_metric, sort_by_direction: $sort_by_direction, start_date: $start_date, end_date: $end_date, limit: $limit, offset: $offset, aggregated_by: $aggregated_by, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve email statistics by client type.
#
# GET /clients/stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_clients-stats
export def "get-clients-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/clients/stats"
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}, {name: aggregated_by, var: aggregated_by}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, end_date: $end_date, aggregated_by: $aggregated_by, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve stats by a specific client type.
#
# GET /clients/{client_type}/stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_clients-client_type-stats
export def "get-clients-client-type-stats" [
  client_type: string@client-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/clients/{client_type}/stats"
    path_params: [{name: client_type, var: client_type}]
    query: [{name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}, {name: aggregated_by, var: aggregated_by}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_type: $client_type, start_date: $start_date, end_date: $end_date, aggregated_by: $aggregated_by, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all custom fields
#
# GET /contactdb/custom_fields
# Returns: record<custom_fields: table<name: string, type: string, id: float>>
# operationId: GET_contactdb-custom_fields
export def "get-contactdb-custom-fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/custom_fields"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Custom Field
#
# POST /contactdb/custom_fields
# Returns: record<name: string, type: string, id: float>
# operationId: POST_contactdb-custom_fields
export def "post-contactdb-custom-fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --name: string
  --type: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contactdb/custom_fields"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Custom Field
#
# DELETE /contactdb/custom_fields/{custom_field_id}
# Returns: record<errors: table<field: string, help: record, message: string>, id: string>
# operationId: DELETE_contactdb-custom_fields-custom_field_id
export def "delete-contactdb-custom-fields-custom-field-id" [
  custom_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/contactdb/custom_fields/{custom_field_id}"
    path_params: [{name: custom_field_id, var: custom_field_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    custom_field_id: $custom_field_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Custom Field
#
# GET /contactdb/custom_fields/{custom_field_id}
# Returns: record<name: string, type: string, id: float>
# operationId: GET_contactdb-custom_fields-custom_field_id
export def "get-contactdb-custom-fields-custom-field-id" [
  custom_field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/custom_fields/{custom_field_id}"
    path_params: [{name: custom_field_id, var: custom_field_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_field_id: $custom_field_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Multiple lists
#
# DELETE /contactdb/lists
# operationId: DELETE_contactdb-lists
export def "delete-contactdb-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: list
]: any -> any {
  $in | http-request {
    method: delete
    path: "/contactdb/lists"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all lists
#
# GET /contactdb/lists
# Returns: record<lists: table<id: int, name: string, recipient_count: int>>
# operationId: GET_contactdb-lists
export def "get-contactdb-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/lists"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a List
#
# POST /contactdb/lists
# Returns: record<id: int, name: string, recipient_count: int>
# operationId: POST_contactdb-lists
export def "post-contactdb-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contactdb/lists"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a List
#
# DELETE /contactdb/lists/{list_id}
# operationId: DELETE_contactdb-lists-list_id
export def "delete-contactdb-lists-list-id" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-contacts: oneof<nothing, bool> # Adds the ability to delete all contacts on the list in addition to deleting the list.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: record
]: any -> any {
  $in | http-request {
    method: delete
    path: "/contactdb/lists/{list_id}"
    path_params: [{name: list_id, var: list_id}]
    query: [{name: delete_contacts, var: delete_contacts}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    list_id: $list_id, delete_contacts: $delete_contacts, on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single list
#
# GET /contactdb/lists/{list_id}
# Returns: record<id: int, name: string, recipient_count: int>
# operationId: GET_contactdb-lists-list_id
export def "get-contactdb-lists-list-id" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-list-id: int # The ID of the list to retrieve. (spec name: list_id)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/lists/{list_id}"
    path_params: [{name: list_id, var: list_id}]
    query: [{name: list_id, var: qp_list_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    list_id: $list_id, qp_list_id: $qp_list_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a List
#
# PATCH /contactdb/lists/{list_id}
# Returns: record<id: int, name: string, recipient_count: int>
# operationId: PATCH_contactdb-lists-list_id
export def "patch-contactdb-lists-list-id" [
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-list-id: int # The ID of the list you are updating. (required) (spec name: list_id)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  name: string # The new name for your list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/contactdb/lists/{list_id}"
    path_params: [{name: list_id, var: list_id}]
    query: [{name: list_id, var: qp_list_id, required: true}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    list_id: $list_id, qp_list_id: $qp_list_id, on_behalf_of: $on_behalf_of, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all recipients on a List
#
# GET /contactdb/lists/{list_id}/recipients
# Returns: record<recipients: table<recipients: list>>
# operationId: GET_contactdb-lists-list_id-recipients
export def "get-contactdb-lists-list-id-recipients" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page index of first recipient to return (must be a positive integer)
  --page-size: int # Number of recipients to return at a time (must be a positive integer between 1 and 1000)
  --qp-list-id: int # The ID of the list whose recipients you are requesting. (required) (spec name: list_id)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/lists/{list_id}/recipients"
    path_params: [{name: list_id, var: list_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}, {name: list_id, var: qp_list_id, required: true}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    list_id: $list_id, page: $page, page_size: $page_size, qp_list_id: $qp_list_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Multiple Recipients to a List
#
# POST /contactdb/lists/{list_id}/recipients
# operationId: POST_contactdb-lists-list_id-recipients
export def "post-contactdb-lists-list-id-recipients" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: list
]: any -> any {
  $in | http-request {
    method: post
    path: "/contactdb/lists/{list_id}/recipients"
    path_params: [{name: list_id, var: list_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    list_id: $list_id, on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Single Recipient from a Single List
#
# DELETE /contactdb/lists/{list_id}/recipients/{recipient_id}
# operationId: DELETE_contactdb-lists-list_id-recipients-recipient_id
export def "delete-contactdb-lists-list-id-recipients-recipient-id" [
  list_id: int
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-list-id: int # The ID of the list you are taking this recipient away from. (required) (spec name: list_id)
  --qp-recipient-id: int # The ID of the recipient to take off the list. (required) (spec name: recipient_id)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: record
]: any -> any {
  $in | http-request {
    method: delete
    path: "/contactdb/lists/{list_id}/recipients/{recipient_id}"
    path_params: [{name: list_id, var: list_id}, {name: recipient_id, var: recipient_id}]
    query: [{name: list_id, var: qp_list_id, required: true}, {name: recipient_id, var: qp_recipient_id, required: true}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    list_id: $list_id, recipient_id: $recipient_id, qp_list_id: $qp_list_id, qp_recipient_id: $qp_recipient_id, on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a Single Recipient to a List
#
# POST /contactdb/lists/{list_id}/recipients/{recipient_id}
# operationId: POST_contactdb-lists-list_id-recipients-recipient_id
export def "post-contactdb-lists-list-id-recipients-recipient-id" [
  list_id: int
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> any {
  http-request {
    method: post
    path: "/contactdb/lists/{list_id}/recipients/{recipient_id}"
    path_params: [{name: list_id, var: list_id}, {name: recipient_id, var: recipient_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    list_id: $list_id, recipient_id: $recipient_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Recipients
#
# DELETE /contactdb/recipients
# Returns: record
# operationId: DELETE_contactdb-recipients
export def "delete-contactdb-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/contactdb/recipients"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve recipients
#
# GET /contactdb/recipients
# Returns: record<recipients: list<record>>
# operationId: GET_contactdb-recipients
export def "get-contactdb-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page index of first recipients to return (must be a positive integer)
  --page-size: int # Number of recipients to return at a time (must be a positive integer between 1 and 1000)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/recipients"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Recipient
#
# PATCH /contactdb/recipients
# Returns: record<error_count: float, error_indices: list<float>, errors: table<error_indices: list, message: string>, new_count: float, persisted_recipients: list<string>, updated_count: float>
# operationId: PATCH_contactdb-recipients
export def "patch-contactdb-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/contactdb/recipients"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add recipients
#
# POST /contactdb/recipients
# Returns: record<error_count: float, error_indices: list<float>, errors: table<error_indices: list, message: string>, new_count: float, persisted_recipients: list<string>, updated_count: float>
# operationId: POST_contactdb-recipients
export def "post-contactdb-recipients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contactdb/recipients"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the count of billable recipients
#
# GET /contactdb/recipients/billable_count
# Returns: record<recipient_count: float>
# operationId: GET_contactdb-recipients-billable_count
export def "get-contactdb-recipients-billable-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/recipients/billable_count"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Count of Recipients
#
# GET /contactdb/recipients/count
# Returns: record<recipient_count: float>
# operationId: GET_contactdb-recipients-count
export def "get-contactdb-recipients-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/recipients/count"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search recipients
#
# GET /contactdb/recipients/search
# Returns: record<recipients: table<recipients: list>>
# operationId: GET_contactdb-recipients-search
export def "get-contactdb-recipients-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-name: string
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/recipients/search"
    query: [{name: "{field_name}", var: field_name}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    field_name: $field_name, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search recipients
#
# POST /contactdb/recipients/search
# Returns: record<recipient_count: int, recipients: table<created_at: int, custom_fields: list, email: string, first_name: string, id: string, last_clicked: int, last_emailed: int, last_opened: int, updated_at: int>>
# operationId: POST_contactdb-recipients-search
export def "post-contactdb-recipients-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  conditions: list
  list_id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contactdb/recipients/search"
    body: {content_type: "application/json", kind: json, fields: [{name: conditions, var: conditions}, {name: list_id, var: list_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conditions: $conditions, list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Recipient
#
# DELETE /contactdb/recipients/{recipient_id}
# Returns: record
# operationId: DELETE_contactdb-recipients-recipient_id
export def "delete-contactdb-recipients-recipient-id" [
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/contactdb/recipients/{recipient_id}"
    path_params: [{name: recipient_id, var: recipient_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    recipient_id: $recipient_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single recipient
#
# GET /contactdb/recipients/{recipient_id}
# Returns: record<recipients: table<created_at: float, custom_fields: list, email: string, first_name: string, id: string, last_clicked: float, last_emailed: float, last_name: string, last_opened: float, updated_at: float>>
# operationId: GET_contactdb-recipients-recipient_id
export def "get-contactdb-recipients-recipient-id" [
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/recipients/{recipient_id}"
    path_params: [{name: recipient_id, var: recipient_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    recipient_id: $recipient_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the lists that a recipient is on
#
# GET /contactdb/recipients/{recipient_id}/lists
# Returns: record<lists: table<id: int, name: string, recipient_count: int>>
# operationId: GET_contactdb-recipients-recipient_id-lists
export def "get-contactdb-recipients-recipient-id-lists" [
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/recipients/{recipient_id}/lists"
    path_params: [{name: recipient_id, var: recipient_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    recipient_id: $recipient_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve reserved fields
#
# GET /contactdb/reserved_fields
# Returns: record<reserved_fields: table<name: string, type: string>>
# operationId: GET_contactdb-reserved_fields
export def "get-contactdb-reserved-fields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/reserved_fields"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all segments
#
# GET /contactdb/segments
# Returns: record<segments: table<conditions: list, list_id: int, name: string, recipient_count: float>>
# operationId: GET_contactdb-segments
export def "get-contactdb-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/segments"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Segment
#
# POST /contactdb/segments
# Returns: record<id: float, conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float>
# operationId: POST_contactdb-segments
export def "post-contactdb-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  conditions: list # The conditions for a recipient to be included in this segment. — item shape: {and_or?: "and"|"or"|"", field: string, operator: "eq"|"ne"|"lt"|"gt"|"contains", value: string}
  --list-id: int # The list id from which to make this segment. Not including this ID will mean your segment is created from the main contactdb rather than a list.
  name: string # The name of this segment.
  --recipient-count: float # The count of recipients in this list. This is not included on creation of segments.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/contactdb/segments"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: conditions, var: conditions}, {name: list_id, var: list_id}, {name: name, var: name}, {name: recipient_count, var: recipient_count}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, conditions: $conditions, list_id: $list_id, name: $name, recipient_count: $recipient_count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a segment
#
# DELETE /contactdb/segments/{segment_id}
# operationId: DELETE_contactdb-segments-segment_id
export def "delete-contactdb-segments-segment-id" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-contacts: oneof<nothing, bool> # True to delete all contacts matching the segment in addition to deleting the segment
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: record
]: any -> any {
  $in | http-request {
    method: delete
    path: "/contactdb/segments/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    query: [{name: delete_contacts, var: delete_contacts}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    segment_id: $segment_id, delete_contacts: $delete_contacts, on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a segment
#
# GET /contactdb/segments/{segment_id}
# Returns: record<conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float>
# operationId: GET_contactdb-segments-segment_id
export def "get-contactdb-segments-segment-id" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-segment-id: int # The ID of the segment you want to request. (required) (spec name: segment_id)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/segments/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    query: [{name: segment_id, var: qp_segment_id, required: true}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id, qp_segment_id: $qp_segment_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a segment
#
# PATCH /contactdb/segments/{segment_id}
# Returns: record<conditions: table<and_or: string, field: string, operator: string, value: string>, list_id: int, name: string, recipient_count: float>
# operationId: PATCH_contactdb-segments-segment_id
export def "patch-contactdb-segments-segment-id" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-segment-id: string # The ID of the segment you are updating. (spec name: segment_id)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --conditions: list # The conditions by which this segment should be created. — item shape: {and_or?: "and"|"or"|"", field: string, operator: "eq"|"ne"|"lt"|"gt"|"contains", value: string}
  --list-id: float # The list ID you would like this segment to be built from.
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/contactdb/segments/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    query: [{name: segment_id, var: qp_segment_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: conditions, var: conditions}, {name: list_id, var: list_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id, qp_segment_id: $qp_segment_id, on_behalf_of: $on_behalf_of, conditions: $conditions, list_id: $list_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve recipients on a segment
#
# GET /contactdb/segments/{segment_id}/recipients
# Returns: record<recipients: table<recipients: list>>
# operationId: GET_contactdb-segments-segment_id-recipients
export def "get-contactdb-segments-segment-id-recipients" [
  segment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int
  --page-size: int
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/segments/{segment_id}/recipients"
    path_params: [{name: segment_id, var: segment_id}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id, page: $page, page_size: $page_size, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Recipient Upload Status
#
# GET /contactdb/status
# Returns: record<status: table<"": string, id: string, value: string>>
# operationId: GET_contactdb-status
export def "get-contactdb-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/contactdb/status"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Designs
#
# GET /designs
# Returns: record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list, generate_plain_content: bool, subject: string>>
# operationId: LIST-designs
export def "list-designs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # number of results to return (default: 100)
  --page-token: string # token corresponding to a specific page of results, as provided by metadata
  --summary: oneof<nothing, bool> # set to false to return all fields (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/designs"
    query: [{name: page_size, var: page_size}, {name: page_token, var: page_token}, {name: summary, var: summary}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, summary: $summary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Design
#
# POST /designs
# Returns: record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>
export def "post-designs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --editor: string@editor-completer # The editor used in the UI.
  --name: string # The name of the new design. (default: Duplicate: <original design name>)
  --categories: list<string> # The list of categories applied to the design
  --generate-plain-content: oneof<nothing, bool> # If true, plain_content is always generated from html_content. If false, plain_content is not altered. (default: true)
  --subject: string # Subject of the Design.
  html_content: string # The HTML content of the Design.
  --plain-content: string # Plain text content of the Design. (default: <generated from html_content if left empty>)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/designs"
    body: {content_type: "application/json", kind: json, fields: [{name: editor, var: editor}, {name: name, var: name}, {name: categories, var: categories}, {name: generate_plain_content, var: generate_plain_content}, {name: subject, var: subject}, {name: html_content, var: html_content}, {name: plain_content, var: plain_content}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    editor: $editor, name: $name, categories: $categories, generate_plain_content: $generate_plain_content, subject: $subject, html_content: $html_content, plain_content: $plain_content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List SendGrid Pre-built Designs
#
# GET /designs/pre-builts
# Returns: record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list, generate_plain_content: bool, subject: string>>
# operationId: LIST-Sendgrid-Pre-built-designs
export def "list-sendgrid-pre-built-designs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # number of results to return (default: 100)
  --page-token: string # token corresponding to a specific page of results, as provided by metadata
  --summary: oneof<nothing, bool> # set to false to return all fields (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/designs/pre-builts"
    query: [{name: page_size, var: page_size}, {name: page_token, var: page_token}, {name: summary, var: summary}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, summary: $summary
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SendGrid Pre-built Design
#
# GET /designs/pre-builts/{id}
# Returns: record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>
# operationId: GET-sendgrid-pre-built-design
export def "get-sendgrid-pre-built-design" [
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
    path: "/designs/pre-builts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate SendGrid Pre-built Design
#
# POST /designs/pre-builts/{id}
# Returns: record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>
# operationId: POST-sendgrid-pre-built-design
export def "post-sendgrid-pre-built-design" [
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
  --editor: string@editor-completer # The editor used in the UI.
  --name: string # The name of the new design. (default: Duplicate: <original design name>)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/designs/pre-builts/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: editor, var: editor}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, editor: $editor, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Design
#
# DELETE /designs/{id}
# Returns: record
# operationId: DELETE-design
export def "delete-design" [
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
    method: delete
    path: "/designs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Design
#
# GET /designs/{id}
# Returns: record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>
# operationId: GET-design
export def "get-design" [
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
    path: "/designs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Design
#
# PATCH /designs/{id}
# Returns: record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>
# operationId: PUT-design
export def "put-design" [
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
  --categories: list<string> # The list of categories applied to the design
  --generate-plain-content: oneof<nothing, bool> # If true, plain_content is always generated from html_content. If false, plain_content is not altered. (default: true)
  --html-content: string # The HTML content of the Design.
  --name: string # Name of the Design. (default: My Design)
  --plain-content: string # Plain text content of the Design. (default: <generated from html_content if left empty>)
  --subject: string # Subject of the Design.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/designs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: generate_plain_content, var: generate_plain_content}, {name: html_content, var: html_content}, {name: name, var: name}, {name: plain_content, var: plain_content}, {name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, categories: $categories, generate_plain_content: $generate_plain_content, html_content: $html_content, name: $name, plain_content: $plain_content, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate Design
#
# POST /designs/{id}
# Returns: record<created_at: string, id: string, thumbnail_url: string, updated_at: string, editor: string, name: string, categories: list<string>, generate_plain_content: bool, subject: string, html_content: string, plain_content: string>
# operationId: POST-design
export def "post-design" [
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
  --editor: string@editor-completer # The editor used in the UI.
  --name: string # The name of the new design. (default: Duplicate: <original design name>)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/designs/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: editor, var: editor}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, editor: $editor, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve email statistics by device type.
#
# GET /devices/stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_devices-stats
export def "get-devices-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/devices/stats"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, aggregated_by: $aggregated_by, start_date: $start_date, end_date: $end_date, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve email statistics by country and state/province.
#
# GET /geo/stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_geo-stats
export def "get-geo-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string@country-completer # The country you would like to see statistics for. Currently only supported for US and CA.
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/geo/stats"
    query: [{name: country, var: country}, {name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, limit: $limit, offset: $offset, aggregated_by: $aggregated_by, start_date: $start_date, end_date: $end_date, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all IP addresses
#
# GET /ips
# Returns: table<assigned_at: int, ip: string, pools: list<string>, rdns: string, start_date: float, subusers: list<string>, warmup: bool, whitelabeled: bool>
# operationId: GET_ips
export def "get-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # The IP address to get
  --exclude-whitelabels: oneof<nothing, bool> # Should we exclude reverse DNS records (whitelabels)?
  --limit: int # The number of IPs you want returned at the same time. (default: 10)
  --offset: int # The offset for the number of IPs that you are requesting. (default: 0)
  --subuser: string # The subuser you are requesting for.
  --sort-by-direction: string@sort-by-direction-completer # The direction to sort the results.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ips"
    query: [{name: ip, var: ip}, {name: exclude_whitelabels, var: exclude_whitelabels}, {name: limit, var: limit}, {name: offset, var: offset}, {name: subuser, var: subuser}, {name: sort_by_direction, var: sort_by_direction}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip: $ip, exclude_whitelabels: $exclude_whitelabels, limit: $limit, offset: $offset, subuser: $subuser, sort_by_direction: $sort_by_direction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add IPs
#
# POST /ips
# Returns: record<ips: table<ip: string, subusers: list>, remaining_ips: int, warmup: bool>
# operationId: POST_ips
export def "post-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  count: int # The amount of IPs to add to the account.
  --subusers: list<string> # Array of usernames to be assigned a send IP.
  --warmup: oneof<nothing, bool> # Whether or not to warmup the IPs being added. (default: false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips"
    body: {content_type: "application/json", kind: json, fields: [{name: count, var: count}, {name: subusers, var: subusers}, {name: warmup, var: warmup}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    count: $count, subusers: $subusers, warmup: $warmup
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all assigned IPs
#
# GET /ips/assigned
# Returns: table<ip: string, pools: list<string>, start_date: int, warmup: bool>
# operationId: GET_ips-assigned
export def "get-ips-assigned" [
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
    path: "/ips/assigned"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all IP pools
#
# GET /ips/pools
# Returns: table<name: string>
# operationId: GET_ips-pools
export def "get-ips-pools" [
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
    path: "/ips/pools"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an IP pool
#
# POST /ips/pools
# Returns: record<name: string>
# operationId: POST_ips-pools
export def "post-ips-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of your new IP pool.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/pools"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an IP pool
#
# DELETE /ips/pools/{pool_name}
# Returns: record
# operationId: DELETE_ips-pools-pool_name
export def "delete-ips-pools-pool-name" [
  pool_name: string
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
    path: "/ips/pools/{pool_name}"
    path_params: [{name: pool_name, var: pool_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    pool_name: $pool_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all the IPs in a specified pool
#
# GET /ips/pools/{pool_name}
# Returns: record<ips: list<string>, pool_name: string>
# operationId: GET_ips-pools-pool_name
export def "get-ips-pools-pool-name" [
  pool_name: string
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
    path: "/ips/pools/{pool_name}"
    path_params: [{name: pool_name, var: pool_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_name: $pool_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rename an IP pool
#
# PUT /ips/pools/{pool_name}
# Returns: record<name: string>
# operationId: PUT_ips-pools-pool_name
export def "put-ips-pools-pool-name" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for your IP pool.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/ips/pools/{pool_name}"
    path_params: [{name: pool_name, var: pool_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    pool_name: $pool_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an IP address to a pool
#
# POST /ips/pools/{pool_name}/ips
# Returns: record<ip: string, pools: list<string>, start_date: int, warmup: bool>
# operationId: POST_ips-pools-pool_name-ips
export def "post-ips-pools-pool-name-ips" [
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # The IP address that you want to add to the named pool.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/pools/{pool_name}/ips"
    path_params: [{name: pool_name, var: pool_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    pool_name: $pool_name, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an IP address from a pool
#
# DELETE /ips/pools/{pool_name}/ips/{ip}
# Returns: record
# operationId: DELETE_ips-pools-pool_name-ips-ip
export def "delete-ips-pools-pool-name-ips-ip" [
  pool_name: string
  ip: string
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
    path: "/ips/pools/{pool_name}/ips/{ip}"
    path_params: [{name: pool_name, var: pool_name}, {name: ip, var: ip}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    pool_name: $pool_name, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get remaining IPs count
#
# GET /ips/remaining
# Returns: record<results: table<period: string, price_per_ip: float, remaining: int>>
# operationId: GET_ips-remaining
export def "get-ips-remaining" [
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
    path: "/ips/remaining"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all IPs currently in warmup
#
# GET /ips/warmup
# Returns: table<ip: string, start_date: int>
# operationId: GET_ips-warmup
export def "get-ips-warmup" [
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
    path: "/ips/warmup"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start warming up an IP address
#
# POST /ips/warmup
# Returns: table<ip: string, start_date: int>
# operationId: POST_ips-warmup
export def "post-ips-warmup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # The IP address that you want to begin warming up.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ips/warmup"
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop warming up an IP address
#
# DELETE /ips/warmup/{ip_address}
# Returns: record
# operationId: DELETE_ips-warmup-ip_address
export def "delete-ips-warmup-ip-address" [
  ip_address: string
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
    path: "/ips/warmup/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the warmup status for a specific IP address
#
# GET /ips/warmup/{ip_address}
# Returns: table<ip: string, start_date: int>
# operationId: GET_ips-warmup-ip_address
export def "get-ips-warmup-ip-address" [
  ip_address: string
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
    path: "/ips/warmup/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all IP pools an IP address belongs to
#
# GET /ips/{ip_address}
# Returns: record<ip: string, pools: list<string>, rdns: string, start_date: int, subusers: list<string>, warmup: bool, whitelabeled: bool>
# operationId: GET_ips-ip_address
export def "get-ips-ip-address" [
  ip_address: string
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
    path: "/ips/{ip_address}"
    path_params: [{name: ip_address, var: ip_address}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ip_address: $ip_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a batch ID
#
# POST /mail/batch
# Returns: record<batch_id: string>
# operationId: POST_mail-batch
export def "post-mail-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/mail/batch"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate batch ID
#
# GET /mail/batch/{batch_id}
# Returns: record<batch_id: string>
# operationId: GET_mail-batch-batch_id
export def "get-mail-batch-batch-id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mail/batch/{batch_id}"
    path_params: [{name: batch_id, var: batch_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_id: $batch_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# v3 Mail Send
#
# POST /mail/send
# operationId: POST_mail-send
export def "post-mail-send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asm: record # An object allowing you to specify how to handle unsubscribes. — shape: {group_id: int, groups_to_display?: list<int>}
  --attachments: list # An array of objects where you can specify any attachments you want to include. — item shape: {content: string, content_id?: string, disposition?: "inline"|"attachment", filename: string, type?: string}
  --batch-id: string # An ID representing a batch of emails to be sent at the same time. Including a `batch_id` in your request allows you include this email in that batch. It also enables you to cancel or pause the delivery of that batch. For more information, see the [Cancel Scheduled Sends API](https://sendgrid.com/docs/api-reference/).
  --categories: list<string> # An array of category names for this message. Each category name may not exceed 255 characters.
  content: list # An array where you can specify the content of your email. You can include multiple [MIME types](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types) of content, but you must specify at least one MIME type. To include more than one MIME type, add another object to the array containing the `type` and `value` parameters. — item shape: {type: string, value: string}
  --custom-args: string # Values that are specific to the entire send that will be carried along with the email and its activity data. Key/value pairs must be strings. Substitutions will not be made on custom arguments, so any string that is entered into this parameter will be assumed to be the custom argument that you would like to be used. This parameter is overridden by `custom_args` set at the personalizations level. Total `custom_args` size may not exceed 10,000 bytes.
  from: record # e.g. {email: jane_doe@example.com, name: Jane Doe} — shape: {email: string, name?: string}
  --headers: record # An object containing key/value pairs of header names and the value to substitute for them. The key/value pairs must be strings. You must ensure these are properly encoded if they contain unicode characters. These headers cannot be one of the reserved headers.
  --ip-pool-name: string # The IP Pool that you would like to send this email from.
  --mail-settings: record # A collection of different mail settings that you can use to specify how you would like this email to be handled. — shape: {bypass_bounce_management?: record, bypass_list_management?: record, bypass_spam_management?: record, bypass_unsubscribe_management?: record, footer?: record, sandbox_mode?: record}
  personalizations: list # An array of messages and their metadata. Each object within personalizations can be thought of as an envelope - it defines who should receive an individual message and how that message should be handled. See our [Personalizations documentation](https://sendgrid.com/docs/for-developers/sending-email/personalizations/) for examples. — item shape: {bcc?: list, cc?: list, custom_args?: record, dynamic_template_data?: record, from?: record, headers?: record, send_at?: int, subject?: string, substitutions?: record, to: list}
  --reply-to: record # e.g. {email: jane_doe@example.com, name: Jane Doe} — shape: {email: string, name?: string}
  --reply-to-list: list # An array of recipients who will receive replies and/or bounces. Each object in this array must contain the recipient's email address. Each object in the array may optionally contain the recipient's name. You can either choose to use “reply_to” field or “reply_to_list” but not both. — item shape: {email: string, name?: string}
  --send-at: int # A unix timestamp allowing you to specify when you want your email to be delivered. This may be overridden by the `send_at` parameter set at the personalizations level. Delivery cannot be scheduled more than 72 hours in advance. If you have the flexibility, it's better to schedule mail for off-peak times. Most emails are scheduled and sent at the top of the hour or half hour. Scheduling email to avoid peak times — for example, scheduling at 10:53 — can result in lower deferral rates due to the reduced traffic during off-peak times.
  subject: string # The global or 'message level' subject of your email. This may be overridden by subject lines set in personalizations.
  --template-id: string # An email template ID. A template that contains a subject and content — either text or html — will override any subject and content values specified at the personalizations or message level.
  --tracking-settings: record # Settings to determine how you would like to track the metrics of how your recipients interact with your email. — shape: {click_tracking?: record, ganalytics?: record, open_tracking?: record, subscription_tracking?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/mail/send"
    body: {content_type: "application/json", kind: json, fields: [{name: asm, var: asm}, {name: attachments, var: attachments}, {name: batch_id, var: batch_id}, {name: categories, var: categories}, {name: content, var: content}, {name: custom_args, var: custom_args}, {name: from, var: from}, {name: headers, var: headers}, {name: ip_pool_name, var: ip_pool_name}, {name: mail_settings, var: mail_settings}, {name: personalizations, var: personalizations}, {name: reply_to, var: reply_to}, {name: reply_to_list, var: reply_to_list}, {name: send_at, var: send_at}, {name: subject, var: subject}, {name: template_id, var: template_id}, {name: tracking_settings, var: tracking_settings}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    asm: $asm, attachments: $attachments, batch_id: $batch_id, categories: $categories, content: $content, custom_args: $custom_args, from: $from, headers: $headers, ip_pool_name: $ip_pool_name, mail_settings: $mail_settings, personalizations: $personalizations, reply_to: $reply_to, reply_to_list: $reply_to_list, send_at: $send_at, subject: $subject, template_id: $template_id, tracking_settings: $tracking_settings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all mail settings
#
# GET /mail_settings
# Returns: record<result: table<description: string, enabled: bool, name: string, title: string>>
# operationId: GET_mail_settings
export def "get-mail-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of settings to return.
  --offset: int # Where in the list of results to begin displaying settings.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mail_settings"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve address whitelist mail settings
#
# GET /mail_settings/address_whitelist
# Returns: record<enabled: bool, list: list<string>>
# operationId: GET_mail_settings-address_whitelist
export def "get-mail-settings-address-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mail_settings/address_whitelist"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update address whitelist mail settings
#
# PATCH /mail_settings/address_whitelist
# Returns: record<enabled: bool, list: list<string>>
# operationId: PATCH_mail_settings-address_whitelist
export def "patch-mail-settings-address-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool> # Indicates if your email address whitelist is enabled.
  --list: list<string> # Either a single email address that you want whitelisted or a domain, for which all email addresses belonging to this domain will be whitelisted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/mail_settings/address_whitelist"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: list, var: list}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled, list: $list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve bounce purge mail settings
#
# GET /mail_settings/bounce_purge
# Returns: record<enabled: bool, hard_bounces: int, soft_bounces: int>
# operationId: GET_mail_settings-bounce_purge
export def "get-mail-settings-bounce-purge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mail_settings/bounce_purge"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update bounce purge mail settings
#
# PATCH /mail_settings/bounce_purge
# Returns: record<enabled: bool, hard_bounces: int, soft_bounces: int>
# operationId: PATCH_mail_settings-bounce_purge
export def "patch-mail-settings-bounce-purge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool> # Indicates if the bounce purge mail setting is enabled.
  --hard-bounces: int # The number of days after which SendGrid will purge all contacts from your hard bounces suppression lists. (nullable)
  --soft-bounces: int # The number of days after which SendGrid will purge all contacts from your soft bounces suppression lists. (nullable)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/mail_settings/bounce_purge"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: hard_bounces, var: hard_bounces}, {name: soft_bounces, var: soft_bounces}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled, hard_bounces: $hard_bounces, soft_bounces: $soft_bounces
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve footer mail settings
#
# GET /mail_settings/footer
# Returns: record<enabled: bool, html_content: string, plain_content: string>
# operationId: GET_mail_settings-footer
export def "get-mail-settings-footer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mail_settings/footer"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update footer mail settings
#
# PATCH /mail_settings/footer
# Returns: record<enabled: bool, html_content: string, plain_content: string>
# operationId: PATCH_mail_settings-footer
export def "patch-mail-settings-footer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool> # Indicates if the Footer mail setting is currently enabled.
  --html-content: string # The custom HTML content of your email footer.
  --plain-content: string # The plain text content of your email footer.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/mail_settings/footer"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: html_content, var: html_content}, {name: plain_content, var: plain_content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled, html_content: $html_content, plain_content: $plain_content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve forward bounce mail settings
#
# GET /mail_settings/forward_bounce
# Returns: record<email: string, enabled: bool>
# operationId: GET_mail_settings-forward_bounce
export def "get-mail-settings-forward-bounce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mail_settings/forward_bounce"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update forward bounce mail settings
#
# PATCH /mail_settings/forward_bounce
# Returns: record<email: string, enabled: bool>
# operationId: PATCH_mail_settings-forward_bounce
export def "patch-mail-settings-forward-bounce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --email: string # The email address that you would like your bounce reports forwarded to. (nullable)
  --enabled: oneof<nothing, bool> # Indicates if the bounce forwarding mail setting is enabled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/mail_settings/forward_bounce"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, email: $email, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve forward spam mail settings
#
# GET /mail_settings/forward_spam
# Returns: record<email: string, enabled: bool>
# operationId: GET_mail_settings-forward_spam
export def "get-mail-settings-forward-spam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mail_settings/forward_spam"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update forward spam mail settings
#
# PATCH /mail_settings/forward_spam
# Returns: record<email: string, enabled: bool>
# operationId: PATCH_mail_settings-forward_spam
export def "patch-mail-settings-forward-spam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --email: string # The email address where you would like the spam reports to be forwarded.
  --enabled: oneof<nothing, bool> # Indicates if the Forward Spam setting is enabled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/mail_settings/forward_spam"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, email: $email, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve legacy template mail settings
#
# GET /mail_settings/template
# Returns: record<enabled: bool, html_content: string>
# operationId: GET_mail_settings-template
export def "get-mail-settings-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mail_settings/template"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update template mail settings
#
# PATCH /mail_settings/template
# Returns: record<enabled: bool, html_content: string>
# operationId: PATCH_mail_settings-template
export def "patch-mail-settings-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool> # Indicates if you want to enable the legacy email template mail setting.
  --html-content: string # The new HTML content for your legacy email template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/mail_settings/template"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: html_content, var: html_content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled, html_content: $html_content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve email statistics by mailbox provider.
#
# GET /mailbox_providers/stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_mailbox_providers-stats
export def "get-mailbox-providers-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mailbox-providers: string # The mail box providers to get statistics for. You can include up to 10 by including this parameter multiple times.
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mailbox_providers/stats"
    query: [{name: mailbox_providers, var: mailbox_providers}, {name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mailbox_providers: $mailbox_providers, limit: $limit, offset: $offset, aggregated_by: $aggregated_by, start_date: $start_date, end_date: $end_date, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Contacts
#
# DELETE /marketing/contacts
# Returns: record<job_id: record>
# operationId: DELETE_mc-contacts
export def "delete-mc-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-all-contacts: string # Must be set to `"true"` to delete all contacts.
  --ids: string # A comma-separated list of contact IDs.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/marketing/contacts"
    query: [{name: delete_all_contacts, var: delete_all_contacts}, {name: ids, var: ids}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    delete_all_contacts: $delete_all_contacts, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Sample Contacts
#
# GET /marketing/contacts
# Returns: record<_metadata: record<self: string>, contact_count: int, result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>>
# operationId: GET_mc-contats
export def "get-mc-contats" [
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
    path: "/marketing/contacts"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or Update a Contact
#
# PUT /marketing/contacts
# Returns: record<job_id: string>
# operationId: PUT_mc-contacts
export def "put-mc-contacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  contacts: list # One or more contacts objects that you intend to upsert. The available fields for a contact, including the required `email` field are described below. — item shape: {address_line_1?: string, address_line_2?: string, alternate_emails?: list<string>, city?: string, country?: string, custom_fields?: record, email: string, first_name?: string, last_name?: string, postal_code?: string, state_province_region?: string}
  --list-ids: list<string> # An array of List ID strings that this contact will be added to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/marketing/contacts"
    body: {content_type: "application/json", kind: json, fields: [{name: contacts, var: contacts}, {name: list_ids, var: list_ids}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    contacts: $contacts, list_ids: $list_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Batched Contacts by IDs
#
# POST /marketing/contacts/batch
# Returns: record<result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>>
# operationId: POST_marketing-contacts-batch
export def "post-marketing-contacts-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/contacts/batch"
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Total Contact Count
#
# GET /marketing/contacts/count
# Returns: record<billable_breakdown: record<breakdown: record, total: int>, billable_count: int, contact_count: int>
# operationId: GET_mc-contacts-count
export def "get-mc-contacts-count" [
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
    path: "/marketing/contacts/count"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Existing Exports
#
# GET /marketing/contacts/exports
# Returns: record<_metadata: record<next: string, prev: string, self: string>, result: table<_metadata: record, completed_at: string, created_at: string, expires_at: string, export_type: string, id: string, lists: list, segments: list, status: string, urls: list, user_id: string>>
# operationId: GET_marketing-contacts-exports
export def "get-marketing-contacts-exports" [
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
    path: "/marketing/contacts/exports"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Contacts
#
# POST /marketing/contacts/exports
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, id: string>
# operationId: POST_mc-contacts-exports
export def "post-mc-contacts-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-type: string@file-type-completer # File type for export file. Choose from `json` or `csv`. (default: csv)
  --list-ids: list<string> # IDs of the contact lists you want to export.
  --max-file-size: int # The maximum size of an export file in MB. Note that when this option is specified, multiple output files may be returned from the export. (default: 5000)
  --notifications: record # shape: {email?: bool}
  --segment-ids: list<string> # IDs of the contact segments you want to export.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/contacts/exports"
    body: {content_type: "application/json", kind: json, fields: [{name: file_type, var: file_type}, {name: list_ids, var: list_ids}, {name: max_file_size, var: max_file_size}, {name: notifications, var: notifications}, {name: segment_ids, var: segment_ids}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    file_type: $file_type, list_ids: $list_ids, max_file_size: $max_file_size, notifications: $notifications, segment_ids: $segment_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Contacts Status
#
# GET /marketing/contacts/exports/{id}
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, completed_at: string, contact_count: int, created_at: string, expires_at: string, id: string, message: string, status: string, updated_at: string, urls: list<string>>
# operationId: GET_mc-contacts-exports-id
export def "get-mc-contacts-exports-id" [
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
    path: "/marketing/contacts/exports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import Contacts
#
# PUT /marketing/contacts/imports
# Returns: record<job_id: string, upload_headers: table<header: string, value: string>, upload_uri: string>
# operationId: PUT_mc-contacts-imports
export def "put-mc-contacts-imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  field_mappings: list # Import file header to reserved/custom field mapping.
  file_type: string@file-type-completer-1 # Upload file type.
  --list-ids: list<string> # All contacts will be added to each of the specified lists.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/marketing/contacts/imports"
    body: {content_type: "application/json", kind: json, fields: [{name: field_mappings, var: field_mappings}, {name: file_type, var: file_type}, {name: list_ids, var: list_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    field_mappings: $field_mappings, file_type: $file_type, list_ids: $list_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import Contacts Status
#
# GET /marketing/contacts/imports/{id}
# Returns: record<finished_at: string, id: string, job_type: string, results: record<created_count: float, deleted_count: float, errored_count: float, errors_url: string, requested_count: float, updated_count: float>, started_at: string, status: string>
# operationId: GET_marketing-contacts-imports-id
export def "get-marketing-contacts-imports-id" [
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
    path: "/marketing/contacts/imports/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Contacts
#
# POST /marketing/contacts/search
# Returns: record<_metadata: record<self: string>, contact_count: float, result: table<_metadata: record, address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list, phone_number: string, postal_code: string, segment_ids: list, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>>
# operationId: POST_mc-contacts-search
export def "post-mc-contacts-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  query: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/contacts/search"
    body: {content_type: "application/json", kind: json, fields: [{name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Contacts by Emails
#
# POST /marketing/contacts/search/emails
# Returns: record<result: record>
# operationId: POST_marketing-contacts-search-emails
export def "post-marketing-contacts-search-emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emails: list<string> # One or more primary emails and/or alternate emails to search through your contacts for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/contacts/search/emails"
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Contact by ID
#
# GET /marketing/contacts/{id}
# Returns: record<_metadata: record<self: string>, address_line_1: string, address_line_2: string, alternate_emails: list<string>, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list<string>, phone_number: string, postal_code: string, segment_ids: list<string>, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>
# operationId: GET_mc-contacts-id
export def "get-mc-contacts-id" [
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
    path: "/marketing/contacts/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Field Definitions
#
# GET /marketing/field_definitions
# Returns: record<_metadata: record<count: int, next: string, prev: string, self: string>, custom_fields: table<field_type: string, id: string, name: string>, reserved_fields: table<field_type: string, name: string, read_only: bool>>
# operationId: GET_mc-field_definitions
export def "get-mc-field-definitions" [
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
    path: "/marketing/field_definitions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Custom Field Definition
#
# POST /marketing/field_definitions
# Returns: record<field_type: string, id: string, name: string, _metadata: record<count: int, next: string, prev: string, self: string>>
# operationId: POST_mc-field_definitions
export def "post-mc-field-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  field_type: string@field-type-completer
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/field_definitions"
    body: {content_type: "application/json", kind: json, fields: [{name: field_type, var: field_type}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    field_type: $field_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Custom Field Definition
#
# DELETE /marketing/field_definitions/{custom_field_id}
# operationId: DELETE_mc-field_definitions-custom_field_id
export def "delete-mc-field-definitions-custom-field-id" [
  custom_field_id: string
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
    path: "/marketing/field_definitions/{custom_field_id}"
    path_params: [{name: custom_field_id, var: custom_field_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    custom_field_id: $custom_field_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Custom Field Definition
#
# PATCH /marketing/field_definitions/{custom_field_id}
# Returns: record<field_type: string, id: string, name: string, _metadata: record<count: int, next: string, prev: string, self: string>>
# operationId: PATCH_mc-field_definitions-custom_field_id
export def "patch-mc-field-definitions-custom-field-id" [
  custom_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/marketing/field_definitions/{custom_field_id}"
    path_params: [{name: custom_field_id, var: custom_field_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_field_id: $custom_field_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Lists
#
# GET /marketing/lists
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, result: table<_metadata: record, contact_count: int, id: string, name: string>>
# operationId: GET_mc-lists
export def "get-mc-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: float # Maximum number of elements to return. Defaults to 100, returns 1000 max (default: 100)
  --page-token: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/lists"
    query: [{name: page_size, var: page_size}, {name: page_token, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create List
#
# POST /marketing/lists
# Returns: record<_metadata: record<self: string>, contact_count: int, id: string, name: string>
# operationId: POST_mc-lists
export def "post-mc-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Your name for your list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/lists"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a list
#
# DELETE /marketing/lists/{id}
# Returns: record<job_id: string>
# operationId: DELETE_lists-id
export def "delete-lists-id" [
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
  --delete-contacts: oneof<nothing, bool> # Flag indicates that all contacts on the list are also to be deleted. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/marketing/lists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: delete_contacts, var: delete_contacts}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, delete_contacts: $delete_contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a List by ID
#
# GET /marketing/lists/{id}
# Returns: record<_metadata: record<self: string>, contact_count: int, id: string, name: string, contact_sample: record<_metadata: record<self: string>, address_line_1: string, address_line_2: string, alternate_emails: list<string>, city: string, country: string, created_at: string, custom_fields: record, email: string, facebook: string, first_name: string, id: string, last_name: string, line: string, list_ids: list<string>, phone_number: string, postal_code: string, segment_ids: list<string>, state_province_region: string, unique_name: string, updated_at: string, whatsapp: string>>
# operationId: GET_mc-lists-id
export def "get-mc-lists-id" [
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
  --contact-sample: oneof<nothing, bool> # Setting this parameter to the true will cause the contact_sample to be returned (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/lists/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: contact_sample, var: contact_sample}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, contact_sample: $contact_sample
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update List
#
# PATCH /marketing/lists/{id}
# Returns: record<_metadata: record<self: string>, contact_count: int, id: string, name: string>
# operationId: PATCH_mc-lists-id
export def "patch-mc-lists-id" [
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
  --name: string # Your name for your list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/marketing/lists/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Contacts from a List
#
# DELETE /marketing/lists/{id}/contacts
# Returns: record<job_id: string>
# operationId: DELETE_mc-lists-id-contacts
export def "delete-mc-lists-id-contacts" [
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
  --contact-ids: string # comma separated list of contact ids (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/marketing/lists/{id}/contacts"
    path_params: [{name: id, var: id}]
    query: [{name: contact_ids, var: contact_ids, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, contact_ids: $contact_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List Contact Count
#
# GET /marketing/lists/{id}/contacts/count
# Returns: record<billable_count: int, contact_count: int>
# operationId: GET_mc-lists-id-contacts-count
export def "get-mc-lists-id-contacts-count" [
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
    path: "/marketing/lists/{id}/contacts/count"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Segments
#
# GET /marketing/segments
# Returns: record<results: table<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string>>
# operationId: GET_marketing-segments
export def "get-marketing-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-list-ids: string # A comma separated list of list ids to be used when searching for segments with the specified parent_list_id, no more than 50 is allowed
  --no-parent-list-id: oneof<nothing, bool> # If set to `true` segments with an empty value of `parent_list_id` will be returned in the filter. If the value is not present it defaults to 'false'. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/segments"
    query: [{name: parent_list_ids, var: parent_list_ids}, {name: no_parent_list_id, var: no_parent_list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent_list_ids: $parent_list_ids, no_parent_list_id: $no_parent_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Segment
#
# POST /marketing/segments
# Returns: record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string>
# operationId: POST_marketing-segments
export def "post-marketing-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the segment.
  --parent-list-ids: list<string> # The array of list ids to filter contacts on when building this segment. It allows only one such list id for now. We will support more in future
  query_dsl: string # SQL query which will filter contacts based on the conditions provided
  --parent-list-id: string # The id of the list if this segment is a child of a list. This implies the query is rewritten as `(${query_dsl}) AND CONTAINS(list_ids, ${parent_list_id})` (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/segments"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent_list_ids, var: parent_list_ids}, {name: query_dsl, var: query_dsl}, {name: parent_list_id, var: parent_list_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, parent_list_ids: $parent_list_ids, query_dsl: $query_dsl, parent_list_id: $parent_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get List of Segments
#
# GET /marketing/segments/2.0
# Returns: record<_metadata: record<count: int, next: string, prev: string, self: string>, contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string>
# operationId: GET_segments
export def "get-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-list-ids: string # A comma separated list up to 50 in size, to filter segments on. Only segments that have any of these list ids as the parent list will be retrieved. This is different from the parameter of the same name used when creating a segment.
  --no-parent-list-id: oneof<nothing, bool> # If set to `true` segments with an empty value of `parent_list_id` will be returned in the filter. If the value is not present it defaults to 'false'. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/segments/2.0"
    query: [{name: parent_list_ids, var: parent_list_ids}, {name: no_parent_list_id, var: no_parent_list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent_list_ids: $parent_list_ids, no_parent_list_id: $no_parent_list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Segment
#
# POST /marketing/segments/2.0
# Returns: record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string>
# operationId: POST_segments
export def "post-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the segment.
  --parent-list-ids: list<string> # The array of list ids to filter contacts on when building this segment. It allows only one such list id for now. We will support more in future
  query_dsl: string # SQL query which will filter contacts based on the conditions provided
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/segments/2.0"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent_list_ids, var: parent_list_ids}, {name: query_dsl, var: query_dsl}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, parent_list_ids: $parent_list_ids, query_dsl: $query_dsl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete segment
#
# DELETE /marketing/segments/2.0/{segment_id}
# operationId: DELETE_segments-segment_id
export def "delete-segments-segment-id" [
  segment_id: string
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
    path: "/marketing/segments/2.0/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Segment by ID
#
# GET /marketing/segments/2.0/{segment_id}
# Returns: record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string>
# operationId: GET_segments-segment_id
export def "get-segments-segment-id" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contacts-sample: oneof<nothing, bool> # Defaults to `true`. Set to `false` to exclude the contacts_sample in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/segments/2.0/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    query: [{name: contacts_sample, var: contacts_sample}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id, contacts_sample: $contacts_sample
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Segment
#
# PATCH /marketing/segments/2.0/{segment_id}
# Returns: record<contacts_count: int, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, created_at: string, id: string, name: string, next_sample_update: string, parent_list_ids: list<string>, query_dsl: string, query_version: string, sample_updated_at: string, status: record<error_message: string, query_validation: string>, updated_at: string>
# operationId: PATCH_segments-segment_id
export def "patch-segments-segment-id" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the segment.
  --query-dsl: string # SQL query which will filter contacts based on the conditions provided
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/marketing/segments/2.0/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: query_dsl, var: query_dsl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id, name: $name, query_dsl: $query_dsl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk Delete Segments
#
# POST /marketing/segments/delete
# Returns: record<errors: table<error: string, id: string, resources: record>>
# operationId: POST_marketing-segments-delete
export def "post-marketing-segments-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/segments/delete"
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Segment
#
# DELETE /marketing/segments/{segment_id}
# Returns: record
# operationId: DELETE_marketing-segments-segment_id
export def "delete-marketing-segments-segment-id" [
  segment_id: string
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
    path: "/marketing/segments/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    segment_id: $segment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Segment by ID
#
# GET /marketing/segments/{segment_id}
# Returns: record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string>
# operationId: GET_marketing-segments-segment_id
export def "get-marketing-segments-segment-id" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query-json: oneof<nothing, bool> # Defaults to `false`. Set to `true` to return the parsed SQL AST as a JSON object in the field `query_json`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/segments/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    query: [{name: query_json, var: query_json}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id, query_json: $query_json
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Segment
#
# PATCH /marketing/segments/{segment_id}
# Returns: record<contacts_count: int, created_at: string, id: string, name: string, next_sample_update: string, parent_list_id: string, sample_updated_at: string, updated_at: string, contacts_sample: table<address_line_1: string, address_line_2: string, alternate_emails: list, city: string, country: string, custom_fields: record, email: string, first_name: string, id: string, last_name: string, list_ids: list, postal_code: int, segment_ids: list, state_province_region: string>, query_json: record, parent_list_ids: list<string>, query_dsl: string>
# operationId: PATCH_marketing-segments-segment_id
export def "patch-marketing-segments-segment-id" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the segment.
  --parent-list-ids: list<string> # The array of list ids to filter contacts on when building this segment. It allows only one such list id for now. We will support more in future
  query_dsl: string # SQL query which will filter contacts based on the conditions provided
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/marketing/segments/{segment_id}"
    path_params: [{name: segment_id, var: segment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parent_list_ids, var: parent_list_ids}, {name: query_dsl, var: query_dsl}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    segment_id: $segment_id, name: $name, parent_list_ids: $parent_list_ids, query_dsl: $query_dsl
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Sender Identity
#
# POST /marketing/senders
# Returns: record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>
# operationId: POST_marketing-senders
export def "post-marketing-senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  address: string # The physical address of the sender identity.
  --address-2: string # Additional sender identity address information.
  city: string # The city of the sender identity.
  country: string # The country of the sender identity.
  from: record # shape: {email: string, name: string}
  nickname: string # A nickname for the sender identity. Not used for sending.
  --reply-to: record # shape: {email: string, name?: string}
  --state: string # The state of the sender identity.
  --zip: string # The zipcode of the sender identity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/senders"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: address_2, var: address_2}, {name: city, var: city}, {name: country, var: country}, {name: from, var: from}, {name: nickname, var: nickname}, {name: reply_to, var: reply_to}, {name: state, var: state}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, address: $address, address_2: $address_2, city: $city, country: $country, from: $from, nickname: $nickname, reply_to: $reply_to, state: $state, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk Delete Single Sends
#
# DELETE /marketing/singlesends
# operationId: DELETE_marketing-singlesends
export def "delete-marketing-singlesends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # Single Send IDs to delete
]: nothing -> any {
  http-request {
    method: delete
    path: "/marketing/singlesends"
    query: [{name: ids, var: ids, style: csv}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Single Sends
#
# GET /marketing/singlesends
# Returns: record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<abtest: record, categories: list, created_at: string, id: string, is_abtest: bool, name: string, send_at: string, status: string, updated_at: string>>
# operationId: GET_marketing-singlesends
export def "get-marketing-singlesends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int
  --page-token: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/singlesends"
    query: [{name: page_size, var: page_size}, {name: page_token, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Single Send
#
# POST /marketing/singlesends
# Returns: record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>>
# operationId: POST_marketing-singlesends
export def "post-marketing-singlesends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # The categories to associate with this Single Send.
  --email-config: record # shape: {custom_unsubscribe_url?: string, design_id?: string, editor?: "code"|"design", generate_plain_content?: bool, html_content?: string, ip_pool?: string, plain_content?: string, sender_id?: int, subject?: string, suppression_group_id?: int}
  name: string # The name of the Single Send.
  --send-at: string # The ISO 8601 time at which to send the Single Send — this must be set for a future time. (format: date-time)
  --send-to: record # shape: {all?: bool, list_ids?: list<string>, segment_ids?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/singlesends"
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: email_config, var: email_config}, {name: name, var: name}, {name: send_at, var: send_at}, {name: send_to, var: send_to}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    categories: $categories, email_config: $email_config, name: $name, send_at: $send_at, send_to: $send_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Categories
#
# GET /marketing/singlesends/categories
# Returns: record<categories: list<string>>
# operationId: GET_marketing-singlesends-categories
export def "get-marketing-singlesends-categories" [
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
    path: "/marketing/singlesends/categories"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Single Sends Search
#
# POST /marketing/singlesends/search
# Returns: record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<abtest: record, categories: list, created_at: string, id: string, is_abtest: bool, name: string, send_at: string, status: string, updated_at: string>>
# operationId: POST_marketing-singlesends-search
export def "post-marketing-singlesends-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int
  --page-token: string
  --categories: list<string> # categories to associate with this Single Send, match any single send that has at least one of the categories
  --name: string # leading and trailing wildcard search on name of the Single Send
  --status: list<string> # current status of the Single Send
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/singlesends/search"
    query: [{name: page_size, var: page_size}, {name: page_token, var: page_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: name, var: name}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_size: $page_size, page_token: $page_token, categories: $categories, name: $name, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Single Send by ID
#
# DELETE /marketing/singlesends/{id}
# operationId: DELETE_marketing-singlesends-id
export def "delete-marketing-singlesends-id" [
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
    path: "/marketing/singlesends/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Single Send by ID
#
# GET /marketing/singlesends/{id}
# Returns: record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>>
# operationId: GET_marketing-singlesends-id
export def "get-marketing-singlesends-id" [
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
    path: "/marketing/singlesends/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Single Send
#
# PATCH /marketing/singlesends/{id}
# Returns: record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>>
# operationId: PATCH_marketing-singlesends-id
export def "patch-marketing-singlesends-id" [
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
  --categories: list<string> # The categories to associate with this Single Send.
  --email-config: record # shape: {custom_unsubscribe_url?: string, design_id?: string, editor?: "code"|"design", generate_plain_content?: bool, html_content?: string, ip_pool?: string, plain_content?: string, sender_id?: int, subject?: string, suppression_group_id?: int}
  name: string # The name of the Single Send.
  --send-at: string # The ISO 8601 time at which to send the Single Send — this must be set for a future time. (format: date-time)
  --send-to: record # shape: {all?: bool, list_ids?: list<string>, segment_ids?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/marketing/singlesends/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: categories, var: categories}, {name: email_config, var: email_config}, {name: name, var: name}, {name: send_at, var: send_at}, {name: send_to, var: send_to}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    id: $id, categories: $categories, email_config: $email_config, name: $name, send_at: $send_at, send_to: $send_to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate Single Send
#
# POST /marketing/singlesends/{id}
# Returns: record<categories: list<string>, email_config: record<custom_unsubscribe_url: string, design_id: string, editor: string, generate_plain_content: bool, html_content: string, ip_pool: string, plain_content: string, sender_id: int, subject: string, suppression_group_id: int>, name: string, send_at: string, send_to: record<all: bool, list_ids: list<string>, segment_ids: list<string>>, created_at: string, id: string, status: string, updated_at: string, warnings: table<field: string, message: string, warning_id: string>>
# operationId: POST_marketing-singlesends-id
export def "post-marketing-singlesends-id" [
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
  --name: string # The name of the duplicate Single Send. If you choose to leave the name field blank, your duplicate will be assigned the name of the Single Send it was copied from with the text 'Copy of ' prepended to it. The end of the new Single Send name, including 'Copy of ', will be trimmed if the name exceeds the character limit.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/singlesends/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Single Send Schedule
#
# DELETE /marketing/singlesends/{id}/schedule
# Returns: record<send_at: string, status: string>
# operationId: DELETE_marketing-singlesends-id-schedule
export def "delete-marketing-singlesends-id-schedule" [
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
    method: delete
    path: "/marketing/singlesends/{id}/schedule"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Schedule Single Send
#
# PUT /marketing/singlesends/{id}/schedule
# Returns: record<send_at: string, status: string>
# operationId: PUT_marketing-singlesends-id-schedule
export def "put-marketing-singlesends-id-schedule" [
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
  send_at: string@send-at-completer # This is the ISO 8601 time at which to send the Single Send; must be in future, or the string "now" (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/marketing/singlesends/{id}/schedule"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: send_at, var: send_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, send_at: $send_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Automation Stats
#
# GET /marketing/stats/automations
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<aggregation: string, id: string, stats: record, step_id: string>>
# operationId: getall-automation-stats
export def "getall-automation-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --automation-ids: list<string> # This endpoint returns all automation IDs if no `automation_ids` are specified.
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/stats/automations"
    query: [{name: automation_ids, var: automation_ids, style: csv}, {name: page_size, var: page_size}, {name: page_token, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    automation_ids: $automation_ids, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Automation Stats
#
# GET /marketing/stats/automations/export
# Returns: string
# operationId: get-automations-stats-export
export def "get-automations-stats-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The IDs of Automations for which to export stats.
  --timezone: string # The [IANA Area/Region](https://en.wikipedia.org/wiki/Tz_database#Names_of_time_zones) string representing the timezone in which the stats are to be presented; i.e. `"America/Chicago"`. This parameter changes the timezone format only; it does not alter which stats are returned. (default: UTC)
]: nothing -> any {
  http-request {
    method: get
    path: "/marketing/stats/automations/export"
    query: [{name: ids, var: ids, style: csv}, {name: timezone, var: timezone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, timezone: $timezone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Automation Stats by ID
#
# GET /marketing/stats/automations/{id}
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<aggregation: string, id: string, stats: record, step_id: string>>
# operationId: get-automation-stat
export def "get-automation-stat" [
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
  --group-by: list<string> # Automations can have multiple steps. Including `step_id` as a `group_by` metric allows further granularity of stats.
  --step-ids: list<string> # Comma-separated list of `step_ids` that you want the link stats for.
  --aggregated-by: string@aggregated-by-completer-1 # Dictates how the stats are time-sliced. Currently, `"total"` and `"day"` are supported. (default: total)
  --start-date: string # Format: `YYYY-MM-DD`. If this parameter is included, the stats' start date is included in the search. (format: date, default: "")
  --end-date: string # Format: `YYYY-MM-DD`.If this parameter is included, the stats' end date is included in the search. (format: date, default: "")
  --timezone: string # [IANA Area/Region](https://en.wikipedia.org/wiki/Tz_database#Names_of_time_zones) string representing the timezone in which the stats are to be presented, e.g., "America/Chicago". (default: UTC)
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/stats/automations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: group_by, var: group_by, style: csv}, {name: step_ids, var: step_ids, style: csv}, {name: aggregated_by, var: aggregated_by}, {name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: timezone, var: timezone}, {name: page_size, var: page_size}, {name: page_token, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, group_by: $group_by, step_ids: $step_ids, aggregated_by: $aggregated_by, start_date: $start_date, end_date: $end_date, timezone: $timezone, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Automation Click Tracking Stats by ID
#
# GET /marketing/stats/automations/{id}/links
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<clicks: int, step_id: string, url: string, url_location: int>, total_clicks: int>
# operationId: get-automation-link-stat
export def "get-automation-link-stat" [
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
  --group-by: list<string> # Automations can have multiple steps. Including `step_id` as a `group_by` metric allows further granularity of stats.
  --step-ids: list<string> # Comma-separated list of `step_ids` that you want the link stats for.
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/stats/automations/{id}/links"
    path_params: [{name: id, var: id}]
    query: [{name: group_by, var: group_by, style: csv}, {name: step_ids, var: step_ids, style: csv}, {name: page_size, var: page_size}, {name: page_token, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, group_by: $group_by, step_ids: $step_ids, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Single Sends Stats
#
# GET /marketing/stats/singlesends
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, aggregation: string, id: string, stats: record>>
# operationId: getall-singlesend-stats
export def "getall-singlesend-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --singlesend-ids: list<string> # This endpoint returns all Single Send IDs if no IDs are included in `singlesend_ids`.
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/stats/singlesends"
    query: [{name: singlesend_ids, var: singlesend_ids, style: csv}, {name: page_size, var: page_size}, {name: page_token, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    singlesend_ids: $singlesend_ids, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export Single Send Stats
#
# GET /marketing/stats/singlesends/export
# Returns: string
# operationId: get-singlesend-stats-export
export def "get-singlesend-stats-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The IDs of Single Sends for which to export stats.
  --timezone: string # The [IANA Area/Region](https://en.wikipedia.org/wiki/Tz_database#Names_of_time_zones) string representing the timezone in which the stats are to be presented; i.e. `"America/Chicago"`. This parameter changes the timezone format only; it does not alter which stats are returned. (default: UTC)
]: nothing -> any {
  http-request {
    method: get
    path: "/marketing/stats/singlesends/export"
    query: [{name: ids, var: ids, style: csv}, {name: timezone, var: timezone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, timezone: $timezone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Single Send Stats by ID
#
# GET /marketing/stats/singlesends/{id}
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, aggregation: string, id: string, stats: record>>
# operationId: get-singlesend-stat
export def "get-singlesend-stat" [
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
  --aggregated-by: string@aggregated-by-completer-1 # Dictates how the stats are time-sliced. Currently, `"total"` and `"day"` are supported. (default: total)
  --start-date: string # Format: `YYYY-MM-DD`. If this parameter is included, the stats' start date is included in the search. (format: date, default: "")
  --end-date: string # Format: `YYYY-MM-DD`.If this parameter is included, the stats' end date is included in the search. (format: date, default: "")
  --timezone: string # [IANA Area/Region](https://en.wikipedia.org/wiki/Tz_database#Names_of_time_zones) string representing the timezone in which the stats are to be presented, e.g., "America/Chicago". (default: UTC)
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
  --group-by: list<string> # A/B Single Sends have multiple variation IDs and phase IDs. Including these additional fields allows further granularity of stats by these fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/stats/singlesends/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: aggregated_by, var: aggregated_by}, {name: start_date, var: start_date}, {name: end_date, var: end_date}, {name: timezone, var: timezone}, {name: page_size, var: page_size}, {name: page_token, var: page_token}, {name: group_by, var: group_by, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, aggregated_by: $aggregated_by, start_date: $start_date, end_date: $end_date, timezone: $timezone, page_size: $page_size, page_token: $page_token, group_by: $group_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Single Send Click Tracking Stats by ID
#
# GET /marketing/stats/singlesends/{id}/links
# Returns: record<_metadata: record<count: float, next: string, prev: string, self: string>, results: table<ab_phase: string, ab_variation: string, clicks: int, url: string, url_location: int>, total_clicks: int>
# operationId: get-singlesend-link-stat
export def "get-singlesend-link-stat" [
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
  --page-size: int # The number of elements you want returned on each page. (default: 50)
  --page-token: string # The stats endpoints are paginated. To get the next page, call the passed `_metadata.next` URL. If `_metadata.prev` doesn't exist, you're at the first page. Similarly, if `_metadata.next` is not present, you're at the last page.
  --group-by: list<string> # A/B Single Sends have multiple variation IDs and phase IDs. Including these additional fields allows further granularity of stats by these fields.
  --ab-variation-id: string # format: uuid
  --ab-phase-id: string@ab-phase-id-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/marketing/stats/singlesends/{id}/links"
    path_params: [{name: id, var: id}]
    query: [{name: page_size, var: page_size}, {name: page_token, var: page_token}, {name: group_by, var: group_by, style: csv}, {name: ab_variation_id, var: ab_variation_id}, {name: ab_phase_id, var: ab_phase_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page_size: $page_size, page_token: $page_token, group_by: $group_by, ab_variation_id: $ab_variation_id, ab_phase_id: $ab_phase_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send a Test Marketing Email
#
# POST /marketing/test/send_email
# Returns: record
# operationId: POST_marketing-test-send_email
export def "post-marketing-test-send-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-unsubscribe-url: string # A custom unsubscribe URL.
  emails: list<string> # An array of email addresses you want to send the test message to.
  --from-address: string # You can either specify this address or specify a verified sender ID. (format: email)
  --sender-id: int # This ID must belong to a verified sender. Alternatively, you may supply a `from_address` email.
  --suppression-group-id: int
  template_id: string # The ID of the template that you would like to use. If you use a template that contains a subject and content (either text or HTML), then those values specified at the personalizations or message level will not be used. (format: uuid)
  --version-id-override: string # You can override the active template with an alternative template version by passing the version ID in this field. If this field is blank, the active template version will be used. (format: uuid)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/marketing/test/send_email"
    body: {content_type: "application/json", kind: json, fields: [{name: custom_unsubscribe_url, var: custom_unsubscribe_url}, {name: emails, var: emails}, {name: from_address, var: from_address}, {name: sender_id, var: sender_id}, {name: suppression_group_id, var: suppression_group_id}, {name: template_id, var: template_id}, {name: version_id_override, var: version_id_override}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    custom_unsubscribe_url: $custom_unsubscribe_url, emails: $emails, from_address: $from_address, sender_id: $sender_id, suppression_group_id: $suppression_group_id, template_id: $template_id, version_id_override: $version_id_override
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Filter all messages
#
# GET /messages
# Returns: record<messages: table<clicks_count: int, from_email: string, last_event_time: int, msg_id: string, opens_count: int, status: string, subject: string, to_email: string>>
# operationId: GET-messages
export def "get-messages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Use the query syntax to filter your email activity. (required)
  --limit: float # The number of messages returned. This parameter must be greater than 0 and less than or equal to 1000 (default: 10)
  --x-query-id: string
  --x-cursor: string
  --authorization: string # required, default: Bearer <<YOUR_API_KEY_HERE>>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages"
    query: [{name: query, var: query, required: true}, {name: limit, var: limit}]
    header: [{name: X-Query-Id, var: x_query_id}, {name: X-Cursor, var: x_cursor}, {name: Authorization, var: authorization, required: true, default: "Bearer <<YOUR_API_KEY_HERE>>"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query, limit: $limit, x_query_id: $x_query_id, x_cursor: $x_cursor, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request CSV
#
# POST /messages/download
# Returns: record<message: string, status: string>
# operationId: POST_v3-messages-download
export def "post-v3-messages-download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Uses a SQL like syntax to indicate which messages to include in the CSV
  --authorization: string # required, default: Bearer <<YOUR_API_KEY_HERE>>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/messages/download"
    query: [{name: query, var: query}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer <<YOUR_API_KEY_HERE>>"}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    query: $query, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download CSV
#
# GET /messages/download/{download_uuid}
# Returns: record<csv: string, presigned_url: string>
# operationId: GET_v3-messages-download-download_uuid
export def "get-v3-messages-download-download-uuid" [
  download_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # required, default: Bearer <<YOUR_API_KEY_HERE>>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/download/{download_uuid}"
    path_params: [{name: download_uuid, var: download_uuid}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer <<YOUR_API_KEY_HERE>>"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    download_uuid: $download_uuid, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Filter messages by message ID
#
# GET /messages/{msg_id}
# Returns: record<api_key_id: string, asm_group_id: int, categories: list<string>, events: table<attempt_num: int, bounce_type: string, event_name: string, http_user_agent: string, mx_server: string, processed: string, reason: string, url: string>, from_email: string, msg_id: string, originating_ip: string, outbound_ip: string, outbound_ip_type: string, status: string, subject: string, teammate: string, template_id: string, to_email: string, unique_args: string>
# operationId: GET-v3-messages-msg_id
export def "get-v3-messages-msg-id" [
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # required, default: Bearer <<YOUR_API_KEY_HERE>>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/messages/{msg_id}"
    path_params: [{name: msg_id, var: msg_id}]
    header: [{name: Authorization, var: authorization, required: true, default: "Bearer <<YOUR_API_KEY_HERE>>"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    msg_id: $msg_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all partner settings.
#
# GET /partner_settings
# Returns: record<result: table<description: string, enabled: bool, name: string, title: string>>
# operationId: GET_partner_settings
export def "get-partner-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of settings to return per page.
  --offset: int # The paging offset.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/partner_settings"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all New Relic partner settings.
#
# GET /partner_settings/new_relic
# Returns: record<enable_subuser_statistics: bool, enabled: bool, license_key: string>
# operationId: GET_partner_settings-new_relic
export def "get-partner-settings-new-relic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/partner_settings/new_relic"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates New Relic partner settings.
#
# PATCH /partner_settings/new_relic
# Returns: record<enable_subuser_statistics: bool, enabled: bool, license_key: string>
# operationId: PATCH_partner_settings-new_relic
export def "patch-partner-settings-new-relic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enable-subuser-statistics: oneof<nothing, bool> # Indicates if your subuser statistics will be sent to your New Relic Dashboard.
  --enabled: oneof<nothing, bool> # Indicates if this partner setting is enabled.
  --license-key: string # The license key for your New Relic account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/partner_settings/new_relic"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enable_subuser_statistics, var: enable_subuser_statistics}, {name: enabled, var: enabled}, {name: license_key, var: license_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enable_subuser_statistics: $enable_subuser_statistics, enabled: $enabled, license_key: $license_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of scopes for which this user has access.
#
# GET /scopes
# Returns: record<scopes: list<string>>
# operationId: GET_scopes
export def "get-scopes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/scopes"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve access requests
#
# GET /scopes/requests
# Returns: table<email: string, first_name: string, id: int, last_name: string, scope_group_name: string, username: string>
# operationId: GET_v3-scopes-requests
export def "get-v3-scopes-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Optional field to limit the number of results returned. (default: 50)
  --offset: int # Optional beginning point in the list to retrieve from. (default: 0)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/scopes/requests"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deny access request
#
# DELETE /scopes/requests/{request_id}
# operationId: DELETE_v3-scopes-requests-request_id
export def "delete-v3-scopes-requests-request-id" [
  request_id: string
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
    path: "/scopes/requests/{request_id}"
    path_params: [{name: request_id, var: request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve access request
#
# PATCH /scopes/requests/{request_id}/approve
# Returns: record<scope_group_name: string>
# operationId: PATCH_v3-scopes-requests-approve-id
export def "patch-v3-scopes-requests-approve-id" [
  request_id: string
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
    path: "/scopes/requests/{request_id}/approve"
    path_params: [{name: request_id, var: request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Sender Identities
#
# GET /senders
# Returns: record<result: table<address: string, address_2: string, city: string, country: string, from: record, nickname: string, reply_to: record, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>>
# operationId: GET_v3-senders
export def "get-v3-senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/senders"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a Sender Identity
#
# POST /senders
# Returns: record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>
# operationId: POST_senders
export def "post-senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  address: string # The physical address of the sender identity.
  --address-2: string # Additional sender identity address information.
  city: string # The city of the sender identity.
  country: string # The country of the sender identity.
  --from: record
  nickname: string # A nickname for the sender identity. Not used for sending.
  --reply-to: record
  --state: string # The state of the sender identity.
  --zip: string # The zipcode of the sender identity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/senders"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: address_2, var: address_2}, {name: city, var: city}, {name: country, var: country}, {name: from, var: from}, {name: nickname, var: nickname}, {name: reply_to, var: reply_to}, {name: state, var: state}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, address: $address, address_2: $address_2, city: $city, country: $country, from: $from, nickname: $nickname, reply_to: $reply_to, state: $state, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Sender Identity
#
# DELETE /senders/{sender_id}
# Returns: record
# operationId: DELETE_v3-senders-sender_id
export def "delete-v3-senders-sender-id" [
  sender_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/senders/{sender_id}"
    path_params: [{name: sender_id, var: sender_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    sender_id: $sender_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a Sender Identity
#
# GET /senders/{sender_id}
# Returns: record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>
# operationId: GET_v3-senders-sender_id
export def "get-v3-senders-sender-id" [
  sender_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/senders/{sender_id}"
    path_params: [{name: sender_id, var: sender_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sender_id: $sender_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Sender Identity
#
# PATCH /senders/{sender_id}
# Returns: record<address: string, address_2: string, city: string, country: string, from: record<email: string, name: string>, nickname: string, reply_to: record<email: string, name: string>, state: string, zip: string, created_at: int, id: int, locked: bool, updated_at: int, verified: bool>
# operationId: PATCH_v3-senders-sender_id
export def "patch-v3-senders-sender-id" [
  sender_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --address: string # The physical address of the sender identity.
  --address-2: string # Additional sender identity address information.
  --city: string # The city of the sender identity.
  --country: string # The country of the sender identity.
  --from: record # shape: {email?: string, name?: string}
  --nickname: string # A nickname for the sender identity. Not used for sending.
  --reply-to: record # shape: {email?: string, name?: string}
  --state: string # The state of the sender identity.
  --zip: string # The zipcode of the sender identity.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/senders/{sender_id}"
    path_params: [{name: sender_id, var: sender_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: address_2, var: address_2}, {name: city, var: city}, {name: country, var: country}, {name: from, var: from}, {name: nickname, var: nickname}, {name: reply_to, var: reply_to}, {name: state, var: state}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sender_id: $sender_id, on_behalf_of: $on_behalf_of, address: $address, address_2: $address_2, city: $city, country: $country, from: $from, nickname: $nickname, reply_to: $reply_to, state: $state, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Sender Identity Verification
#
# POST /senders/{sender_id}/resend_verification
# Returns: record
# operationId: POST_v3-senders-sender_id-resend_verification
export def "post-v3-senders-sender-id-resend-verification" [
  sender_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/senders/{sender_id}/resend_verification"
    path_params: [{name: sender_id, var: sender_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    sender_id: $sender_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an SSO Certificate
#
# POST /sso/certificates
# Returns: record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string>
# operationId: POST_sso-certificates
export def "post-sso-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Indicates if the certificate is enabled.
  integration_id: string # An ID that matches a certificate to a specific IdP integration. This is the `id` returned by the "Get All SSO Integrations" endpoint.
  public_certificate: string # This public certificate allows SendGrid to verify that SAML requests it receives are signed by an IdP that it recognizes.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sso/certificates"
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: integration_id, var: integration_id}, {name: public_certificate, var: public_certificate}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    enabled: $enabled, integration_id: $integration_id, public_certificate: $public_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an SSO Certificate
#
# DELETE /sso/certificates/{cert_id}
# Returns: record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string>
# operationId: DELETE_sso-certificates-cert_id
export def "delete-sso-certificates-cert-id" [
  cert_id: string
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
    path: "/sso/certificates/{cert_id}"
    path_params: [{name: cert_id, var: cert_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cert_id: $cert_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an SSO Certificate
#
# GET /sso/certificates/{cert_id}
# Returns: record<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string>
# operationId: GET_sso-certificates-cert_id
export def "get-sso-certificates-cert-id" [
  cert_id: string
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
    path: "/sso/certificates/{cert_id}"
    path_params: [{name: cert_id, var: cert_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cert_id: $cert_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update SSO Certificate
#
# PATCH /sso/certificates/{cert_id}
# operationId: PATCH_sso-certificates-cert_id
export def "patch-sso-certificates-cert-id" [
  cert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Indicates whether or not the certificate is enabled.
  --integration-id: string # An ID that matches a certificate to a specific IdP integration.
  --public-certificate: string # This public certificate allows SendGrid to verify that SAML requests it receives are signed by an IdP that it recognizes.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/sso/certificates/{cert_id}"
    path_params: [{name: cert_id, var: cert_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: integration_id, var: integration_id}, {name: public_certificate, var: public_certificate}]}
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    cert_id: $cert_id, enabled: $enabled, integration_id: $integration_id, public_certificate: $public_certificate
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All SSO Integrations
#
# GET /sso/integrations
# Returns: table<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string>
# operationId: GET_sso-integrations
export def "get-sso-integrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --si: oneof<nothing, bool> # If this parameter is set to `true`, the response will include the `completed_integration` field.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sso/integrations"
    query: [{name: si, var: si}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    si: $si
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an SSO Integration
#
# POST /sso/integrations
# Returns: record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string>
# operationId: POST_sso-integrations
export def "post-sso-integrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --completed-integration: oneof<nothing, bool> # Indicates if the integration is complete.
  --enabled: oneof<nothing, bool> # Indicates if the integration is enabled.
  entity_id: string # An identifier provided by your IdP to identify Twilio SendGrid in the SAML interaction. This is called the "SAML Issuer ID" in the Twilio SendGrid UI.
  name: string # The name of your integration. This name can be anything that makes sense for your organization (eg. Twilio SendGrid)
  signin_url: string # The IdP's SAML POST endpoint. This endpoint should receive requests and initiate an SSO login flow. This is called the "Embed Link" in the Twilio SendGrid UI.
  signout_url: string # This URL is relevant only for an IdP-initiated authentication flow. If a user authenticates from their IdP, this URL will return them to their IdP when logging out.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sso/integrations"
    body: {content_type: "application/json", kind: json, fields: [{name: completed_integration, var: completed_integration}, {name: enabled, var: enabled, required: true}, {name: entity_id, var: entity_id}, {name: name, var: name}, {name: signin_url, var: signin_url}, {name: signout_url, var: signout_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    completed_integration: $completed_integration, enabled: $enabled, entity_id: $entity_id, name: $name, signin_url: $signin_url, signout_url: $signout_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an SSO Integration
#
# DELETE /sso/integrations/{id}
# operationId: DELETE_sso-integrations-id
export def "delete-sso-integrations-id" [
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
    path: "/sso/integrations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an SSO Integration
#
# GET /sso/integrations/{id}
# Returns: record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string>
# operationId: GET_sso-integrations-id
export def "get-sso-integrations-id" [
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
  --si: oneof<nothing, bool> # If this parameter is set to `true`, the response will include the `completed_integration` field.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sso/integrations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: si, var: si}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, si: $si
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an SSO Integration
#
# PATCH /sso/integrations/{id}
# Returns: record<completed_integration: bool, enabled: bool, entity_id: string, name: string, signin_url: string, signout_url: string, audience_url: string, id: string, last_updated: float, single_signon_url: string>
# operationId: PATCH_sso-integrations-id
export def "patch-sso-integrations-id" [
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
  --si: oneof<nothing, bool> # If this parameter is set to `true`, the response will include the `completed_integration` field.
  --completed-integration: oneof<nothing, bool> # Indicates if the integration is complete.
  --enabled: oneof<nothing, bool> # Indicates if the integration is enabled.
  entity_id: string # An identifier provided by your IdP to identify Twilio SendGrid in the SAML interaction. This is called the "SAML Issuer ID" in the Twilio SendGrid UI.
  name: string # The name of your integration. This name can be anything that makes sense for your organization (eg. Twilio SendGrid)
  signin_url: string # The IdP's SAML POST endpoint. This endpoint should receive requests and initiate an SSO login flow. This is called the "Embed Link" in the Twilio SendGrid UI.
  signout_url: string # This URL is relevant only for an IdP-initiated authentication flow. If a user authenticates from their IdP, this URL will return them to their IdP when logging out.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sso/integrations/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: si, var: si}]
    body: {content_type: "application/json", kind: json, fields: [{name: completed_integration, var: completed_integration}, {name: enabled, var: enabled, required: true}, {name: entity_id, var: entity_id}, {name: name, var: name}, {name: signin_url, var: signin_url}, {name: signout_url, var: signout_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, si: $si, completed_integration: $completed_integration, enabled: $enabled, entity_id: $entity_id, name: $name, signin_url: $signin_url, signout_url: $signout_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All SSO Certificates by Integration
#
# GET /sso/integrations/{integration_id}/certificates
# Returns: table<id: float, intergration_id: string, not_after: float, not_before: float, public_certificate: string>
# operationId: GET_sso-integrations-integration_id-certificates
export def "get-sso-integrations-integration-id-certificates" [
  integration_id: string
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
    path: "/sso/integrations/{integration_id}/certificates"
    path_params: [{name: integration_id, var: integration_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    integration_id: $integration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create SSO Teammate
#
# POST /sso/teammates
# Returns: record<email: string, first_name: string, is_admin: bool, is_read_only: bool, last_name: string, is_sso: bool, username: string>
# operationId: POST_sso-teammates
export def "post-sso-teammates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The Teammate’s email address. This email address will also function as the Teammate’s username and must match the address assigned to the user in your IdP. This address cannot be changed after the Teammate is created. (format: email)
  first_name: string # The Teammate’s first name.
  --is-admin: oneof<nothing, bool> # Indicates if the Teammate has admin permissions.
  --is-read-only: oneof<nothing, bool> # Indicates if the Teammate has read_only permissions.
  last_name: string # The Teammate’s last name.
  scopes: list<string> # The permission scopes assigned to the Teammate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sso/teammates"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: first_name, var: first_name}, {name: is_admin, var: is_admin}, {name: is_read_only, var: is_read_only}, {name: last_name, var: last_name}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    email: $email, first_name: $first_name, is_admin: $is_admin, is_read_only: $is_read_only, last_name: $last_name, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit an SSO Teammate
#
# PATCH /sso/teammates/{username}
# Returns: record<email: string, first_name: string, is_admin: bool, is_read_only: bool, last_name: string, is_sso: bool, username: string, address: string, address2: string, city: string, company: string, country: string, phone: string, scopes: list<string>, state: string, user_type: string, website: string, zip: string>
# operationId: PATCH_sso-teammates-username
export def "patch-sso-teammates-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --is-admin: oneof<nothing, bool>
  --last-name: string
  --scopes: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/sso/teammates/{username}"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: first_name, var: first_name}, {name: is_admin, var: is_admin}, {name: last_name, var: last_name}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, first_name: $first_name, is_admin: $is_admin, last_name: $last_name, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve global email statistics
#
# GET /stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_stats
export def "get-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of results to return.
  --offset: int # The point in the list to begin retrieving results.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/stats"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, aggregated_by: $aggregated_by, start_date: $start_date, end_date: $end_date, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all Subusers
#
# GET /subusers
# Returns: table<disabled: bool, email: string, id: float, username: string>
# operationId: GET_subusers
export def "get-subusers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of this subuser.
  --limit: int # The number of results you would like to get in each request.
  --offset: int # The number of subusers to skip.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subusers"
    query: [{name: username, var: username}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Subuser
#
# POST /subusers
# Returns: record<authorization_token: string, credit_allocation: record<type: string>, email: string, signup_session_token: string, user_id: float, username: string>
# operationId: POST_subusers
export def "post-subusers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address of the subuser. (format: email)
  ips: list<string> # The IP addresses that should be assigned to this subuser.
  password: string # The password this subuser will use when logging into SendGrid.
  username: string # The username for this subuser.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subusers"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: ips, var: ips}, {name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, ips: $ips, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Subuser Reputations
#
# GET /subusers/reputations
# Returns: table<reputation: float, username: string>
# operationId: GET_subusers-reputations
export def "get-subusers-reputations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --usernames: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subusers/reputations"
    query: [{name: usernames, var: usernames}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    usernames: $usernames
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve email statistics for your subusers.
#
# GET /subusers/stats
# Returns: record<date: string, stats: table<metrics: record, name: string, type: string>>
# operationId: GET_subusers-stats
export def "get-subusers-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limits the number of results returned per page.
  --offset: int # The point in the list to begin retrieving results from.
  --aggregated-by: string@aggregated-by-completer # How to group the statistics. Must be either "day", "week", or "month".
  --subusers: string # The subuser you want to retrieve statistics for. You may include this parameter up to 10 times to retrieve statistics for multiple subusers. (required)
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subusers/stats"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}, {name: subusers, var: subusers, required: true}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, aggregated_by: $aggregated_by, subusers: $subusers, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve monthly stats for all subusers
#
# GET /subusers/stats/monthly
# Returns: record<date: string, stats: table<first_name: string, last_name: string, metrics: record, name: string, type: string>>
# operationId: GET_subusers-stats-monthly
export def "get-subusers-stats-monthly" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date of the month to retrieve statistics for. Must be formatted YYYY-MM-DD (required)
  --subuser: string # A substring search of your subusers.
  --sort-by-metric: string@sort-by-metric-completer # The metric that you want to sort by. Metrics that you can sort by are: `blocks`, `bounces`, `clicks`, `delivered`, `opens`, `requests`, `unique_clicks`, `unique_opens`, and `unsubscribes`.' (default: delivered)
  --sort-by-direction: string@sort-by-direction-completer # The direction you want to sort. (default: desc)
  --limit: int # Optional field to limit the number of results returned. (default: 5)
  --offset: int # Optional beginning point in the list to retrieve from. (default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subusers/stats/monthly"
    query: [{name: date, var: date, required: true}, {name: subuser, var: subuser}, {name: sort_by_metric, var: sort_by_metric}, {name: sort_by_direction, var: sort_by_direction}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date: $date, subuser: $subuser, sort_by_metric: $sort_by_metric, sort_by_direction: $sort_by_direction, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the totals for each email statistic metric for all subusers.
#
# GET /subusers/stats/sums
# Returns: record<date: string, stats: table<metrics: record, name: string, type: string>>
# operationId: GET_subusers-stats-sums
export def "get-subusers-stats-sums" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by-direction: string@sort-by-direction-completer # The direction you want to sort. (default: desc)
  --start-date: string # The starting date of the statistics to retrieve. Must follow format YYYY-MM-DD. (required)
  --end-date: string # The end date of the statistics to retrieve. Defaults to today. Must follow format YYYY-MM-DD.
  --limit: int # Limits the number of results returned per page. (default: 5)
  --offset: int # The point in the list to begin retrieving results from. (default: 0)
  --aggregated-by: string # How to group the statistics. Defaults to today. Must follow format YYYY-MM-DD.
  --sort-by-metric: string # The metric that you want to sort by. Must be a single metric. (default: delivered)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subusers/stats/sums"
    query: [{name: sort_by_direction, var: sort_by_direction}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}, {name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}, {name: sort_by_metric, var: sort_by_metric}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort_by_direction: $sort_by_direction, start_date: $start_date, end_date: $end_date, limit: $limit, offset: $offset, aggregated_by: $aggregated_by, sort_by_metric: $sort_by_metric
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a subuser
#
# DELETE /subusers/{subuser_name}
# Returns: record
# operationId: DELETE_subusers-subuser_name
export def "delete-subusers-subuser-name" [
  subuser_name: string
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
    path: "/subusers/{subuser_name}"
    path_params: [{name: subuser_name, var: subuser_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subuser_name: $subuser_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable/disable a subuser
#
# PATCH /subusers/{subuser_name}
# Returns: record
# operationId: PATCH_subusers-subuser_name
export def "patch-subusers-subuser-name" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disabled: oneof<nothing, bool> # Whether or not this subuser is disabled. True means disabled, False means enabled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subusers/{subuser_name}"
    path_params: [{name: subuser_name, var: subuser_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: disabled, var: disabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subuser_name: $subuser_name, disabled: $disabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update IPs assigned to a subuser
#
# PUT /subusers/{subuser_name}/ips
# Returns: record<ips: list<string>>
# operationId: PUT_subusers-subuser_name-ips
export def "put-subusers-subuser-name-ips" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subusers/{subuser_name}/ips"
    path_params: [{name: subuser_name, var: subuser_name}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subuser_name: $subuser_name, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete monitor settings
#
# DELETE /subusers/{subuser_name}/monitor
# Returns: record
# operationId: DELETE_subusers-subuser_name-monitor
export def "delete-subusers-subuser-name-monitor" [
  subuser_name: string
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
    path: "/subusers/{subuser_name}/monitor"
    path_params: [{name: subuser_name, var: subuser_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subuser_name: $subuser_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve monitor settings for a subuser
#
# GET /subusers/{subuser_name}/monitor
# Returns: record<email: string, frequency: float>
# operationId: GET_subusers-subuser_name-monitor
export def "get-subusers-subuser-name-monitor" [
  subuser_name: string
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
    path: "/subusers/{subuser_name}/monitor"
    path_params: [{name: subuser_name, var: subuser_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subuser_name: $subuser_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create monitor settings
#
# POST /subusers/{subuser_name}/monitor
# Returns: record<email: string, frequency: float>
# operationId: POST_subusers-subuser_name-monitor
export def "post-subusers-subuser-name-monitor" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address to which Sendgrid should send emails for monitoring. (format: email)
  frequency: float # The frequency at which to forward monitoring emails. An email will be sent when your subuser sends this many (e.g., 1,000) emails.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subusers/{subuser_name}/monitor"
    path_params: [{name: subuser_name, var: subuser_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: frequency, var: frequency}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subuser_name: $subuser_name, email: $email, frequency: $frequency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Monitor Settings for a subuser
#
# PUT /subusers/{subuser_name}/monitor
# Returns: record<email: string, frequency: float>
# operationId: PUT_subusers-subuser_name-monitor
export def "put-subusers-subuser-name-monitor" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address to which Sendgrid should send emails for monitoring. (format: email)
  frequency: float # The frequency at which to forward monitoring emails. An email will be sent when your subuser sends this many (e.g., 1,000) emails.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subusers/{subuser_name}/monitor"
    path_params: [{name: subuser_name, var: subuser_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: frequency, var: frequency}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subuser_name: $subuser_name, email: $email, frequency: $frequency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the monthly email statistics for a single subuser
#
# GET /subusers/{subuser_name}/stats/monthly
# Returns: record<date: string, stats: table<first_name: string, last_name: string, metrics: record, name: string, type: string>>
# operationId: GET_subusers-subuser_name-stats-monthly
export def "get-subusers-subuser-name-stats-monthly" [
  subuser_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date of the month to retrieve statistics for. Must be formatted YYYY-MM-DD (required)
  --sort-by-metric: string # The metric that you want to sort by. Metrics that you can sort by are: `blocks`, `bounces`, `clicks`, `delivered`, `opens`, `requests`, `unique_clicks`, `unique_opens`, and `unsubscribes`.' (default: delivered)
  --sort-by-direction: string@sort-by-direction-completer # The direction you want to sort. (default: desc)
  --limit: int # Optional field to limit the number of results returned. (default: 5)
  --offset: int # Optional beginning point in the list to retrieve from. (default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subusers/{subuser_name}/stats/monthly"
    path_params: [{name: subuser_name, var: subuser_name}]
    query: [{name: date, var: date, required: true}, {name: sort_by_metric, var: sort_by_metric}, {name: sort_by_direction, var: sort_by_direction}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subuser_name: $subuser_name, date: $date, sort_by_metric: $sort_by_metric, sort_by_direction: $sort_by_direction, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete blocks
#
# DELETE /suppression/blocks
# Returns: record
# operationId: DELETE_suppression-blocks
export def "delete-suppression-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --delete-all: oneof<nothing, bool> # Indicates if you want to delete all blocked email addresses.
  --emails: list<string> # The specific blocked email addresses that you want to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/suppression/blocks"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete_all, var: delete_all}, {name: emails, var: emails}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, delete_all: $delete_all, emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all blocks
#
# GET /suppression/blocks
# Returns: table<created: int, email: string, reason: string, status: string>
# operationId: GET_suppression-blocks
export def "get-suppression-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: int # The start of the time range when a blocked email was created (inclusive). This is a unix timestamp.
  --end-time: int # The end of the time range when a blocked email was created (inclusive). This is a unix timestamp.
  --limit: int # Limit the number of results to be displayed per page.
  --offset: int # The point in the list to begin displaying results.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/blocks"
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_time: $start_time, end_time: $end_time, limit: $limit, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific block
#
# DELETE /suppression/blocks/{email}
# Returns: record
# operationId: DELETE_suppression-blocks-email
export def "delete-suppression-blocks-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/suppression/blocks/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a specific block
#
# GET /suppression/blocks/{email}
# Returns: table<created: int, email: string, reason: string, status: string>
# operationId: GET_suppression-blocks-email
export def "get-suppression-blocks-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/blocks/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete bounces
#
# DELETE /suppression/bounces
# operationId: DELETE_suppression-bounces
export def "delete-suppression-bounces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --delete-all: oneof<nothing, bool> # This parameter allows you to delete **every** email in your bounce list. This should not be used with the emails parameter.
  --emails: list<string> # Delete multiple emails from your bounce list at the same time. This should not be used with the delete_all parameter.
]: any -> any {
  $in | http-request {
    method: delete
    path: "/suppression/bounces"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete_all, var: delete_all}, {name: emails, var: emails}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, delete_all: $delete_all, emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all bounces
#
# GET /suppression/bounces
# Returns: table<created: float, email: string, reason: string, status: string>
# operationId: GET_suppression-bounces
export def "get-suppression-bounces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: int # Refers start of the time range in unix timestamp when a bounce was created (inclusive).
  --end-time: int # Refers end of the time range in unix timestamp when a bounce was created (inclusive).
  --hdr-accept: string # required, default: application/json (spec name: Accept)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/bounces"
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}]
    header: [{name: Accept, var: hdr_accept, required: true, default: "application/json"}, {name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_time: $start_time, end_time: $end_time, hdr_accept: $hdr_accept, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a bounce
#
# DELETE /suppression/bounces/{email}
# Returns: record
# operationId: DELETE_suppression-bounces-email
export def "delete-suppression-bounces-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-address: string # The email address you would like to remove from the bounce list. (required, format: email)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/suppression/bounces/{email}"
    path_params: [{name: email, var: email}]
    query: [{name: email_address, var: email_address, required: true}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email, email_address: $email_address, on_behalf_of: $on_behalf_of, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a Bounce
#
# GET /suppression/bounces/{email}
# Returns: table<created: float, email: string, reason: string, status: string>
# operationId: GET_suppression-bounces-email
export def "get-suppression-bounces-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/bounces/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete invalid emails
#
# DELETE /suppression/invalid_emails
# Returns: record
# operationId: DELETE_suppression-invalid_emails
export def "delete-suppression-invalid-emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --delete-all: oneof<nothing, bool> # Indicates if you want to remove all email address from the invalid emails list.
  --emails: list<string> # The list of specific email addresses that you want to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/suppression/invalid_emails"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete_all, var: delete_all}, {name: emails, var: emails}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, delete_all: $delete_all, emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all invalid emails
#
# GET /suppression/invalid_emails
# Returns: table<created: int, email: string, reason: string>
# operationId: GET_suppression-invalid_emails
export def "get-suppression-invalid-emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: int # Refers start of the time range in unix timestamp when an invalid email was created (inclusive).
  --end-time: int # Refers end of the time range in unix timestamp when an invalid email was created (inclusive).
  --limit: int # Limit the number of results to be displayed per page.
  --offset: int # Paging offset. The point in the list to begin displaying results.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/invalid_emails"
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_time: $start_time, end_time: $end_time, limit: $limit, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific invalid email
#
# DELETE /suppression/invalid_emails/{email}
# Returns: record
# operationId: DELETE_suppression-invalid_emails-email
export def "delete-suppression-invalid-emails-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/suppression/invalid_emails/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a specific invalid email
#
# GET /suppression/invalid_emails/{email}
# Returns: table<created: int, email: string, reason: string>
# operationId: GET_suppression-invalid_emails-email
export def "get-suppression-invalid-emails-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/invalid_emails/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete spam reports
#
# DELETE /suppression/spam_reports
# Returns: record
# operationId: DELETE_suppression-spam_reports
export def "delete-suppression-spam-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --delete-all: oneof<nothing, bool> # Indicates if you want to delete all email addresses on the spam report list.
  --emails: list<string> # A list of specific email addresses that you want to remove from the spam report list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/suppression/spam_reports"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: delete_all, var: delete_all}, {name: emails, var: emails}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, delete_all: $delete_all, emails: $emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all spam reports
#
# GET /suppression/spam_reports
# Returns: table<created: int, email: string, ip: string>
# operationId: GET_suppression-spam_reports
export def "get-suppression-spam-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: int # The start of the time range when a spam report was created (inclusive). This is a unix timestamp.
  --end-time: int # The end of the time range when a spam report was created (inclusive). This is a unix timestamp.
  --limit: int # Limit the number of results to be displayed per page.
  --offset: int # Paging offset. The point in the list to begin displaying results.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/spam_reports"
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_time: $start_time, end_time: $end_time, limit: $limit, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a specific spam report
#
# DELETE /suppression/spam_reports/{email}
# Returns: record
# operationId: DELETE_suppression-spam_reports-email
export def "delete-suppression-spam-reports-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/suppression/spam_reports/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a specific spam report
#
# GET /suppression/spam_reports/{email}
# Returns: table<created: int, email: string, ip: string>
# operationId: GET_suppression-spam_reports-email
export def "get-suppression-spam-reports-email" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/spam_reports/{email}"
    path_params: [{name: email, var: email}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all global suppressions
#
# GET /suppression/unsubscribes
# Returns: table<created: int, email: string>
# operationId: GET_suppression-unsubscribes
export def "get-suppression-unsubscribes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: int # Refers start of the time range in unix timestamp when an unsubscribe email was created (inclusive).
  --end-time: int # Refers end of the time range in unix timestamp when an unsubscribe email was created (inclusive).
  --limit: int # The number of results to display on each page.
  --offset: int # The point in the list of results to begin displaying global suppressions.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/suppression/unsubscribes"
    query: [{name: start_time, var: start_time}, {name: end_time, var: end_time}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_time: $start_time, end_time: $end_time, limit: $limit, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all teammates
#
# GET /teammates
# Returns: record<result: table<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, state: string, user_type: string, username: string, website: string, zip: string>>
# operationId: GET_v3-teammates
export def "get-v3-teammates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of items to return (default: 500)
  --offset: int # Paging offset (default: 0)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teammates"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite teammate
#
# POST /teammates
# Returns: record<email: string, is_admin: bool, scopes: list<any>, token: string>
# operationId: POST_v3-teammates
export def "post-v3-teammates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  email: string # New teammate's email
  --is-admin: oneof<nothing, bool> # Set to true if teammate should be an admin user (default: false)
  scopes: list<string> # Set to specify list of scopes that teammate should have. Should be empty if teammate is an admin.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teammates"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: is_admin, var: is_admin, required: true}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, email: $email, is_admin: $is_admin, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all pending teammates
#
# GET /teammates/pending
# Returns: record<result: table<email: string, expiration_date: int, is_admin: bool, scopes: list, token: string>>
# operationId: GET_v3-teammates-pending
export def "get-v3-teammates-pending" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teammates/pending"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete pending teammate
#
# DELETE /teammates/pending/{token}
# operationId: DELETE_v3-teammates-pending-token
export def "delete-v3-teammates-pending-token" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/teammates/pending/{token}"
    path_params: [{name: token, var: token_arg}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    token_arg: $token_arg, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend teammate invite
#
# POST /teammates/pending/{token}/resend
# Returns: record<email: string, is_admin: bool, scopes: list<string>, token: string>
# operationId: POST_v3-teammates-pending-token-resend
export def "post-v3-teammates-pending-token-resend" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/teammates/pending/{token}/resend"
    path_params: [{name: token, var: token_arg}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete teammate
#
# DELETE /teammates/{username}
# Returns: record<errors: table<field: string, message: string>>
# operationId: DELETE_v3-teammates-username
export def "delete-v3-teammates-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/teammates/{username}"
    path_params: [{name: username, var: username}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    username: $username, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve specific teammate
#
# GET /teammates/{username}
# Returns: record<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, scopes: list<any>, state: string, user_type: string, username: string, website: string, zip: string>
# operationId: GET_v3-teammates-username
export def "get-v3-teammates-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teammates/{username}"
    path_params: [{name: username, var: username}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update teammate's permissions
#
# PATCH /teammates/{username}
# Returns: record<address: string, address2: string, city: string, country: string, email: string, first_name: string, is_admin: bool, last_name: string, phone: string, scopes: list<string>, state: string, user_type: string, username: string, website: string, zip: string>
# operationId: PATCH_v3-teammates-username
export def "patch-v3-teammates-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --is-admin: oneof<nothing, bool> # Set to True if this teammate should be promoted to an admin user. If True, scopes should be an empty array.
  scopes: list<string> # Provide list of scopes that should be given to teammate. If specifying list of scopes, is_admin should be set to False.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/teammates/{username}"
    path_params: [{name: username, var: username}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_admin, var: is_admin, required: true}, {name: scopes, var: scopes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, on_behalf_of: $on_behalf_of, is_admin: $is_admin, scopes: $scopes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve paged transactional templates.
#
# GET /templates
# Returns: record<_metadata: record<count: int, next: string, prev: string, self: string>, result: table<generation: string, id: string, name: string, "updated_at ": string, versions: list>>
# operationId: GET_templates
export def "get-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --generations: string@generations-completer # Comma-delimited list specifying which generations of templates to return. Options are `legacy`, `dynamic` or `legacy,dynamic`. (default: legacy)
  --page-size: float # The number of templates to be returned in each page of results (required)
  --page-token: string # A token corresponding to a specific page of results, as provided by metadata
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates"
    query: [{name: generations, var: generations}, {name: page_size, var: page_size, required: true}, {name: page_token, var: page_token}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    generations: $generations, page_size: $page_size, page_token: $page_token, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a transactional template.
#
# POST /templates
# Returns: record<generation: string, id: string, name: string, "updated_at ": string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>>
# operationId: POST_templates
export def "post-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --generation: string@generation-completer # Defines whether the template supports dynamic replacement. (default: legacy)
  name: string # The name for the new transactional template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: generation, var: generation}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, generation: $generation, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a template.
#
# DELETE /templates/{template_id}
# Returns: record
# operationId: DELETE_templates-template_id
export def "delete-templates-template-id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    template_id: $template_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single transactional template.
#
# GET /templates/{template_id}
# Returns: record<generation: string, id: string, name: string, "updated_at ": string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>>
# operationId: GET_templates-template_id
export def "get-templates-template-id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a transactional template.
#
# PATCH /templates/{template_id}
# Returns: record<generation: string, id: string, name: string, "updated_at ": string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>>
# operationId: PATCH_templates-template_id
export def "patch-templates-template-id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --name: string # The name of the transactional template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, on_behalf_of: $on_behalf_of, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate a transactional template.
#
# POST /templates/{template_id}
# Returns: record<generation: string, id: string, name: string, "updated_at ": string, versions: table<active: int, editor: string, generate_plain_content: bool, id: string, name: string, subject: string, template_id: string, thumbnail_url: string, updated_at: string>, warning: record<message: string>>
# operationId: POST_templates-template_id
export def "post-templates-template-id" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --name: string # The name for the new transactional template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/{template_id}"
    path_params: [{name: template_id, var: template_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    template_id: $template_id, on_behalf_of: $on_behalf_of, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new transactional template version.
#
# POST /templates/{template_id}/versions
# Returns: record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string>
# operationId: POST_templates-template_id-versions
export def "post-templates-template-id-versions" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --active: int@active-completer # Set the version as the active version associated with the template (0 is inactive, 1 is active). Only one version of a template can be active. The first version created for a template will automatically be set to Active.
  --editor: string@editor-completer # The editor used in the UI.
  --generate-plain-content: oneof<nothing, bool> # If true, plain_content is always generated from html_content. If false, plain_content is not altered. (default: true)
  --html-content: string # The HTML content of the version. Maximum of 1048576 bytes allowed.
  name: string # Name of the transactional template version.
  --plain-content: string # Text/plain content of the transactional template version. Maximum of 1048576 bytes allowed. (default: <generated from html_content if left empty>)
  subject: string # Subject of the new transactional template version.
  --test-data: string # For dynamic templates only, the mock json data that will be used for template preview and test sends.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/templates/{template_id}/versions"
    path_params: [{name: template_id, var: template_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: editor, var: editor}, {name: generate_plain_content, var: generate_plain_content}, {name: html_content, var: html_content}, {name: name, var: name}, {name: plain_content, var: plain_content}, {name: subject, var: subject}, {name: test_data, var: test_data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    template_id: $template_id, on_behalf_of: $on_behalf_of, active: $active, editor: $editor, generate_plain_content: $generate_plain_content, html_content: $html_content, name: $name, plain_content: $plain_content, subject: $subject, test_data: $test_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a transactional template version.
#
# DELETE /templates/{template_id}/versions/{version_id}
# operationId: DELETE_templates-template_id-versions-version_id
export def "delete-templates-template-id-versions-version-id" [
  template_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/templates/{template_id}/versions/{version_id}"
    path_params: [{name: template_id, var: template_id}, {name: version_id, var: version_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    template_id: $template_id, version_id: $version_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a specific transactional template version.
#
# GET /templates/{template_id}/versions/{version_id}
# Returns: record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string>
# operationId: GET_templates-template_id-versions-version_id
export def "get-templates-template-id-versions-version-id" [
  template_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/templates/{template_id}/versions/{version_id}"
    path_params: [{name: template_id, var: template_id}, {name: version_id, var: version_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, version_id: $version_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a transactional template version.
#
# PATCH /templates/{template_id}/versions/{version_id}
# Returns: record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string>
# operationId: PATCH_templates-template_id-versions-version_id
export def "patch-templates-template-id-versions-version-id" [
  template_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --active: int@active-completer # Set the version as the active version associated with the template (0 is inactive, 1 is active). Only one version of a template can be active. The first version created for a template will automatically be set to Active.
  --editor: string@editor-completer # The editor used in the UI.
  --generate-plain-content: oneof<nothing, bool> # If true, plain_content is always generated from html_content. If false, plain_content is not altered. (default: true)
  --html-content: string # The HTML content of the version. Maximum of 1048576 bytes allowed.
  name: string # Name of the transactional template version.
  --plain-content: string # Text/plain content of the transactional template version. Maximum of 1048576 bytes allowed. (default: <generated from html_content if left empty>)
  subject: string # Subject of the new transactional template version.
  --test-data: string # For dynamic templates only, the mock json data that will be used for template preview and test sends.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/templates/{template_id}/versions/{version_id}"
    path_params: [{name: template_id, var: template_id}, {name: version_id, var: version_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: editor, var: editor}, {name: generate_plain_content, var: generate_plain_content}, {name: html_content, var: html_content}, {name: name, var: name}, {name: plain_content, var: plain_content}, {name: subject, var: subject}, {name: test_data, var: test_data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, version_id: $version_id, on_behalf_of: $on_behalf_of, active: $active, editor: $editor, generate_plain_content: $generate_plain_content, html_content: $html_content, name: $name, plain_content: $plain_content, subject: $subject, test_data: $test_data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate a transactional template version.
#
# POST /templates/{template_id}/versions/{version_id}/activate
# Returns: record<warnings: table<message: string>, active: int, editor: string, generate_plain_content: bool, html_content: string, name: string, plain_content: string, subject: string, test_data: string, id: string, template_id: string, thumbnail_url: string, updated_at: string>
# operationId: POST_templates-template_id-versions-version_id-activate
export def "post-templates-template-id-versions-version-id-activate" [
  template_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/templates/{template_id}/versions/{version_id}/activate"
    path_params: [{name: template_id, var: template_id}, {name: version_id, var: version_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    template_id: $template_id, version_id: $version_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Tracking Settings
#
# GET /tracking_settings
# Returns: record<result: table<description: string, enabled: bool, name: string, title: string>>
# operationId: GET_tracking_settings
export def "get-tracking-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracking_settings"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Click Track Settings
#
# GET /tracking_settings/click
# Returns: record<enable_text: bool, enabled: bool>
# operationId: GET_tracking_settings-click
export def "get-tracking-settings-click" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracking_settings/click"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Click Tracking Settings
#
# PATCH /tracking_settings/click
# Returns: record<enable_text: bool, enabled: bool>
# operationId: PATCH_tracking_settings-click
export def "patch-tracking-settings-click" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool> # The setting you want to use for click tracking.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tracking_settings/click"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Google Analytics Settings
#
# GET /tracking_settings/google_analytics
# Returns: record<enabled: bool, utm_campaign: string, utm_content: string, utm_medium: string, utm_source: string, utm_term: string>
# operationId: GET_tracking_settings-google_analytics
export def "get-tracking-settings-google-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracking_settings/google_analytics"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Google Analytics Settings
#
# PATCH /tracking_settings/google_analytics
# Returns: record<enabled: bool, utm_campaign: string, utm_content: string, utm_medium: string, utm_source: string, utm_term: string>
# operationId: PATCH_tracking_settings-google_analytics
export def "patch-tracking-settings-google-analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool> # Indicates if Google Analytics is enabled.
  --utm-campaign: string # The name of the campaign.
  --utm-content: string # Used to differentiate ads
  --utm-medium: string # Name of the marketing medium (e.g. "Email").
  --utm-source: string # Name of the referrer source.
  --utm-term: string # Any paid keywords.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tracking_settings/google_analytics"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: utm_campaign, var: utm_campaign}, {name: utm_content, var: utm_content}, {name: utm_medium, var: utm_medium}, {name: utm_source, var: utm_source}, {name: utm_term, var: utm_term}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled, utm_campaign: $utm_campaign, utm_content: $utm_content, utm_medium: $utm_medium, utm_source: $utm_source, utm_term: $utm_term
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Open Tracking Settings
#
# GET /tracking_settings/open
# Returns: record<enabled: bool>
# operationId: GET_tracking_settings-open
export def "get-tracking-settings-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracking_settings/open"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Open Tracking Settings
#
# PATCH /tracking_settings/open
# Returns: record<enabled: bool>
# operationId: PATCH_tracking_settings-open
export def "patch-tracking-settings-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool> # The new status that you want to set for open tracking.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tracking_settings/open"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Subscription Tracking Settings
#
# GET /tracking_settings/subscription
# Returns: record<enabled: bool, html_content: string, landing: string, plain_content: string, replace: string, url: string>
# operationId: GET_tracking_settings-subscription
export def "get-tracking-settings-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracking_settings/subscription"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Subscription Tracking Settings
#
# PATCH /tracking_settings/subscription
# Returns: record<enabled: bool, html_content: string, landing: string, plain_content: string, replace: string, url: string>
# operationId: PATCH_tracking_settings-subscription
export def "patch-tracking-settings-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool> # Indicates if subscription tracking is enabled.
  --html-content: string # The information and HTML for your unsubscribe link.
  --landing: string # The HTML that will be displayed on the page that your customers will see after clicking unsubscribe, hosted on SendGrid’s server.
  --plain-content: string # The information in plain text for your unsubscribe link. You should have the “<% %>” tag in your content, otherwise the user will have no URL for unsubscribing.
  --replace: string # Your custom defined replacement tag for your templates. Use this tag to place your unsubscribe content anywhere in your emailtemplate.
  --url: string # The URL where you would like your users sent to unsubscribe. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/tracking_settings/subscription"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: html_content, var: html_content}, {name: landing, var: landing}, {name: plain_content, var: plain_content}, {name: replace, var: replace}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled, html_content: $html_content, landing: $landing, plain_content: $plain_content, replace: $replace, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's account information.
#
# GET /user/account
# Returns: record<reputation: float, type: string>
# operationId: GET_user-account
export def "get-user-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/account"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve your credit balance
#
# GET /user/credits
# Returns: record<last_reset: string, next_reset: string, overage: int, remain: int, reset_frequency: string, total: int, used: int>
# operationId: GET_user-credits
export def "get-user-credits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/credits"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve your account email address
#
# GET /user/email
# Returns: record<email: string>
# operationId: GET_user-email
export def "get-user-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/email"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update your account email address
#
# PUT /user/email
# Returns: record<email: string>
# operationId: PUT_user-email
export def "put-user-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --email: string # The new email address that you would like to use for your account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/user/email"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update your password
#
# PUT /user/password
# Returns: record
# operationId: PUT_user-password
export def "put-user-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  new_password: string # The new password you would like to use for your account.
  old_password: string # The old password for your account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/user/password"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: new_password, var: new_password}, {name: old_password, var: old_password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's profile
#
# GET /user/profile
# Returns: record<address: string, address2: string, city: string, company: string, country: string, first_name: string, last_name: string, phone: string, state: string, website: string, zip: string>
# operationId: GET_user-profile
export def "get-user-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/profile"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user's profile
#
# PATCH /user/profile
# Returns: record<address: string, address2: string, city: string, company: string, country: string, first_name: string, last_name: string, phone: string, state: string, website: string, zip: string>
# operationId: PATCH_user-profile
export def "patch-user-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --address: string # The street address for this user profile.
  --address2: string # An optional second line for the street address of this user profile.
  --city: string # The city for the user profile.
  --company: string # That company that this user profile is associated with.
  --country: string # Th country of this user profile.
  --first-name: string # The first name of the user.
  --last-name: string # The last name of the user.
  --phone: string # The phone number for the user.
  --state: string # The state for this user.
  --website: string # The website associated with this user.
  --zip: string # The zip code for this user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/user/profile"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: address2, var: address2}, {name: city, var: city}, {name: company, var: company}, {name: country, var: country}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: phone, var: phone}, {name: state, var: state}, {name: website, var: website}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, address: $address, address2: $address2, city: $city, company: $company, country: $country, first_name: $first_name, last_name: $last_name, phone: $phone, state: $state, website: $website, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all scheduled sends
#
# GET /user/scheduled_sends
# Returns: table<batch_id: string, status: string>
# operationId: GET_user-scheduled_sends
export def "get-user-scheduled-sends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/scheduled_sends"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel or pause a scheduled send
#
# POST /user/scheduled_sends
# Returns: record<batch_id: string, status: string>
# operationId: POST_user-scheduled_sends
export def "post-user-scheduled-sends" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  batch_id: string # The batch ID is the identifier that your scheduled mail sends share.
  status: string@status-completer # The status of the send you would like to implement. This can be pause or cancel. To delete a pause or cancel status see DELETE /v3/user/scheduled_sends/{batch_id} (default: pause)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/scheduled_sends"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: batch_id, var: batch_id}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, batch_id: $batch_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a cancellation or pause from a scheduled send
#
# DELETE /user/scheduled_sends/{batch_id}
# operationId: DELETE_user-scheduled_sends-batch_id
export def "delete-user-scheduled-sends-batch-id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> any {
  http-request {
    method: delete
    path: "/user/scheduled_sends/{batch_id}"
    path_params: [{name: batch_id, var: batch_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    batch_id: $batch_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve scheduled send
#
# GET /user/scheduled_sends/{batch_id}
# Returns: table<batch_id: string, status: string>
# operationId: GET_user-scheduled_sends-batch_id
export def "get-user-scheduled-sends-batch-id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/scheduled_sends/{batch_id}"
    path_params: [{name: batch_id, var: batch_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_id: $batch_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a scheduled send
#
# PATCH /user/scheduled_sends/{batch_id}
# operationId: PATCH_user-scheduled_sends-batch_id
export def "patch-user-scheduled-sends-batch-id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  status: string@status-completer # The status you would like the scheduled send to have.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/user/scheduled_sends/{batch_id}"
    path_params: [{name: batch_id, var: batch_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    batch_id: $batch_id, on_behalf_of: $on_behalf_of, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve current Enforced TLS settings.
#
# GET /user/settings/enforced_tls
# Returns: record<require_tls: bool, require_valid_cert: bool>
# operationId: GET_user-settings-enforced_tls
export def "get-user-settings-enforced-tls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/settings/enforced_tls"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Enforced TLS settings
#
# PATCH /user/settings/enforced_tls
# Returns: record<require_tls: bool, require_valid_cert: bool>
# operationId: PATCH_user-settings-enforced_tls
export def "patch-user-settings-enforced-tls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --require-tls: oneof<nothing, bool> # Indicates if you want to require your recipients to support TLS.
  --require-valid-cert: oneof<nothing, bool> # Indicates if you want to require your recipients to have a valid certificate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/user/settings/enforced_tls"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: require_tls, var: require_tls}, {name: require_valid_cert, var: require_valid_cert}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, require_tls: $require_tls, require_valid_cert: $require_valid_cert
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve your username
#
# GET /user/username
# Returns: record<user_id: int, username: string>
# operationId: GET_user-username
export def "get-user-username" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/username"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update your username
#
# PUT /user/username
# Returns: record<username: string>
# operationId: PUT_user-username
export def "put-user-username" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --username: string # The new username you would like to use for your account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/user/username"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Event Webhook settings
#
# GET /user/webhooks/event/settings
# Returns: record<bounce: bool, click: bool, deferred: bool, delivered: bool, dropped: bool, enabled: bool, group_resubscribe: bool, group_unsubscribe: bool, oauth_client_id: string, oauth_token_url: string, open: bool, processed: bool, spam_report: bool, unsubscribe: bool, url: string>
# operationId: GET_user-webhooks-event-settings
export def "get-user-webhooks-event-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/webhooks/event/settings"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Event Notification Settings
#
# PATCH /user/webhooks/event/settings
# Returns: record<bounce: bool, click: bool, deferred: bool, delivered: bool, dropped: bool, enabled: bool, group_resubscribe: bool, group_unsubscribe: bool, oauth_client_id: string, oauth_token_url: string, open: bool, processed: bool, spam_report: bool, unsubscribe: bool, url: string>
# operationId: PATCH_user-webhooks-event-settings
export def "patch-user-webhooks-event-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --bounce: oneof<nothing, bool> # Receiving server could not or would not accept message.
  --click: oneof<nothing, bool> # Recipient clicked on a link within the message. You need to enable Click Tracking for getting this type of event.
  --deferred: oneof<nothing, bool> # Recipient's email server temporarily rejected message.
  --delivered: oneof<nothing, bool> # Message has been successfully delivered to the receiving server.
  --dropped: oneof<nothing, bool> # You may see the following drop reasons: Invalid SMTPAPI header, Spam Content (if spam checker app enabled), Unsubscribed Address, Bounced Address, Spam Reporting Address, Invalid, Recipient List over Package Quota
  --enabled: oneof<nothing, bool> # Indicates if the event webhook is enabled.
  --group-resubscribe: oneof<nothing, bool> # Recipient resubscribes to specific group by updating preferences. You need to enable Subscription Tracking for getting this type of event.
  --group-unsubscribe: oneof<nothing, bool> # Recipient unsubscribe from specific group, by either direct link or updating preferences. You need to enable Subscription Tracking for getting this type of event.
  --oauth-client-id: string # The client ID Twilio SendGrid sends to your OAuth server or service provider to generate an OAuth access token. When passing data in this field, you must also include the oauth_token_url field.
  --oauth-client-secret: string # This secret is needed only once to create an access token. SendGrid will store this secret, allowing you to update your Client ID and Token URL without passing the secret to SendGrid again. When passing data in this field, you must also include the oauth_client_id and oauth_token_url fields.
  --oauth-token-url: string # The URL where Twilio SendGrid sends the Client ID and Client Secret to generate an access token. This should be your OAuth server or service provider. When passing data in this field, you must also include the oauth_client_id field.
  --open: oneof<nothing, bool> # Recipient has opened the HTML message. You need to enable Open Tracking for getting this type of event.
  --processed: oneof<nothing, bool> # Message has been received and is ready to be delivered.
  --spam-report: oneof<nothing, bool> # Recipient marked a message as spam.
  --unsubscribe: oneof<nothing, bool> # Recipient clicked on message's subscription management link. You need to enable Subscription Tracking for getting this type of event.
  url: string # The URL that you want the event webhook to POST to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/user/webhooks/event/settings"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: bounce, var: bounce, required: true}, {name: click, var: click, required: true}, {name: deferred, var: deferred, required: true}, {name: delivered, var: delivered, required: true}, {name: dropped, var: dropped, required: true}, {name: enabled, var: enabled, required: true}, {name: group_resubscribe, var: group_resubscribe, required: true}, {name: group_unsubscribe, var: group_unsubscribe, required: true}, {name: oauth_client_id, var: oauth_client_id}, {name: oauth_client_secret, var: oauth_client_secret}, {name: oauth_token_url, var: oauth_token_url}, {name: open, var: open, required: true}, {name: processed, var: processed, required: true}, {name: spam_report, var: spam_report, required: true}, {name: unsubscribe, var: unsubscribe, required: true}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, bounce: $bounce, click: $click, deferred: $deferred, delivered: $delivered, dropped: $dropped, enabled: $enabled, group_resubscribe: $group_resubscribe, group_unsubscribe: $group_unsubscribe, oauth_client_id: $oauth_client_id, oauth_client_secret: $oauth_client_secret, oauth_token_url: $oauth_token_url, open: $open, processed: $processed, spam_report: $spam_report, unsubscribe: $unsubscribe, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Signed Webhook Public Key
#
# GET /user/webhooks/event/settings/signed
# Returns: record<public_key: string>
# operationId: GET_user-webhooks-event-settings-signed
export def "get-user-webhooks-event-settings-signed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/webhooks/event/settings/signed"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable/Disable Signed Webhook
#
# PATCH /user/webhooks/event/settings/signed
# Returns: record<public_key: string>
# operationId: PATCH_user-webhooks-event-settings-signed
export def "patch-user-webhooks-event-settings-signed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --enabled: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/user/webhooks/event/settings/signed"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test Event Notification Settings
#
# POST /user/webhooks/event/test
# operationId: POST_user-webhooks-event-test
export def "post-user-webhooks-event-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --oauth-client-id: string # The client ID Twilio SendGrid sends to your OAuth server or service provider to generate an OAuth access token. When passing data in this field, you must also include the oauth_client_secret and oauth_token_url fields.
  --oauth-client-secret: string # This secret is needed only once to create an access token. SendGrid will store this secret, allowing you to update your Client ID and Token URL without passing the secret to SendGrid again. When passing data in this field, you must also include the oauth_client_id and oauth_token_url fields.
  --oauth-token-url: string # The URL where Twilio SendGrid sends the Client ID and Client Secret to generate an access token. This should be your OAuth server or service provider. When passing data in this field, you must also include the oauth_client_id and oauth_client_secret fields.
  --url: string # The URL where you would like the test notification to be sent.
]: any -> any {
  $in | http-request {
    method: post
    path: "/user/webhooks/event/test"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: oauth_client_id, var: oauth_client_id}, {name: oauth_client_secret, var: oauth_client_secret}, {name: oauth_token_url, var: oauth_token_url}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, oauth_client_id: $oauth_client_id, oauth_client_secret: $oauth_client_secret, oauth_token_url: $oauth_token_url, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all parse settings
#
# GET /user/webhooks/parse/settings
# Returns: record<result: table<hostname: string, send_raw: bool, spam_check: bool, url: string>>
# operationId: GET_user-webhooks-parse-settings
export def "get-user-webhooks-parse-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/webhooks/parse/settings"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a parse setting
#
# POST /user/webhooks/parse/settings
# Returns: record<hostname: string, send_raw: bool, spam_check: bool, url: string>
# operationId: POST_user-webhooks-parse-settings
export def "post-user-webhooks-parse-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --hostname: string # A specific and unique domain or subdomain that you have created to use exclusively to parse your incoming email. For example, `parse.yourdomain.com`.
  --send-raw: oneof<nothing, bool> # Indicates if you would like SendGrid to post the original MIME-type content of your parsed email. When this parameter is set to `true`, SendGrid will send a JSON payload of the content of your email.
  --spam-check: oneof<nothing, bool> # Indicates if you would like SendGrid to check the content parsed from your emails for spam before POSTing them to your domain.
  --url: string # The public URL where you would like SendGrid to POST the data parsed from your email. Any emails sent with the given hostname provided (whose MX records have been updated to point to SendGrid) will be parsed and POSTed to this URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/webhooks/parse/settings"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: hostname, var: hostname}, {name: send_raw, var: send_raw}, {name: spam_check, var: spam_check}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, hostname: $hostname, send_raw: $send_raw, spam_check: $spam_check, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a parse setting
#
# DELETE /user/webhooks/parse/settings/{hostname}
# Returns: record
# operationId: DELETE_user-webhooks-parse-settings-hostname
export def "delete-user-webhooks-parse-settings-hostname" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/user/webhooks/parse/settings/{hostname}"
    path_params: [{name: hostname, var: hostname}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    hostname: $hostname, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a specific parse setting
#
# GET /user/webhooks/parse/settings/{hostname}
# Returns: record<hostname: string, send_raw: bool, spam_check: bool, url: string>
# operationId: GET_user-webhooks-parse-settings-hostname
export def "get-user-webhooks-parse-settings-hostname" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/webhooks/parse/settings/{hostname}"
    path_params: [{name: hostname, var: hostname}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hostname: $hostname, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a parse setting
#
# PATCH /user/webhooks/parse/settings/{hostname}
# Returns: record<hostname: string, send_raw: bool, spam_check: bool, url: string>
# operationId: PATCH_user-webhooks-parse-settings-hostname
export def "patch-user-webhooks-parse-settings-hostname" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --body-hostname: string # A specific and unique domain or subdomain that you have created to use exclusively to parse your incoming email. For example, `parse.yourdomain.com`. (spec name: hostname)
  --send-raw: oneof<nothing, bool> # Indicates if you would like SendGrid to post the original MIME-type content of your parsed email. When this parameter is set to `true`, SendGrid will send a JSON payload of the content of your email.
  --spam-check: oneof<nothing, bool> # Indicates if you would like SendGrid to check the content parsed from your emails for spam before POSTing them to your domain.
  --url: string # The public URL where you would like SendGrid to POST the data parsed from your email. Any emails sent with the given hostname provided (whose MX records have been updated to point to SendGrid) will be parsed and POSTed to this URL.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/user/webhooks/parse/settings/{hostname}"
    path_params: [{name: hostname, var: hostname}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: hostname, var: body_hostname}, {name: send_raw, var: send_raw}, {name: spam_check, var: spam_check}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hostname: $hostname, on_behalf_of: $on_behalf_of, body_hostname: $body_hostname, send_raw: $send_raw, spam_check: $spam_check, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves Inbound Parse Webhook statistics.
#
# GET /user/webhooks/parse/stats
# Returns: table<date: string, stats: list<record>>
# operationId: GET_user-webhooks-parse-stats
export def "get-user-webhooks-parse-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # The number of statistics to return on each page.
  --offset: string # The number of statistics to skip.
  --aggregated-by: string@aggregated-by-completer # How you would like the statistics to by grouped.
  --start-date: string # The starting date of the statistics you want to retrieve. Must be in the format YYYY-MM-DD (required)
  --end-date: string # The end date of the statistics you want to retrieve. Must be in the format YYYY-MM-DD (default: The day the request is made.)
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/user/webhooks/parse/stats"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: aggregated_by, var: aggregated_by}, {name: start_date, var: start_date, required: true}, {name: end_date, var: end_date}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, aggregated_by: $aggregated_by, start_date: $start_date, end_date: $end_date, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate an email
#
# POST /validations/email
# Returns: record<result: record<checks: record<additional: record, domain: record, local_part: record>, email: string, host: string, ip_address: string, local: string, score: float, source: string, suggestion: string, verdict: string>>
# operationId: POST_validations-email
export def "post-validations-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address that you want to validate.
  --source: string # A one-word classifier for where this validation originated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/validations/email"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get All Verified Senders
#
# GET /verified_senders
# Returns: record<results: table<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string>>
# operationId: GET_verified_senders
export def "get-verified-senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float
  --last-seen-id: float
  --id: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/verified_senders"
    query: [{name: limit, var: limit}, {name: lastSeenID, var: last_seen_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, last_seen_id: $last_seen_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Verified Sender Request
#
# POST /verified_senders
# Returns: record<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string>
# operationId: POST_verified_senders
export def "post-verified-senders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string
  --address2: string
  --city: string
  --country: string
  from_email: string # format: email
  --from-name: string
  nickname: string
  reply_to: string # format: email
  --reply-to-name: string
  --state: string
  --zip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verified_senders"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: address2, var: address2}, {name: city, var: city}, {name: country, var: country}, {name: from_email, var: from_email}, {name: from_name, var: from_name}, {name: nickname, var: nickname}, {name: reply_to, var: reply_to}, {name: reply_to_name, var: reply_to_name}, {name: state, var: state}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    address: $address, address2: $address2, city: $city, country: $country, from_email: $from_email, from_name: $from_name, nickname: $nickname, reply_to: $reply_to, reply_to_name: $reply_to_name, state: $state, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Domain Warn List
#
# GET /verified_senders/domains
# Returns: record<results: record<hard_failures: list<string>, soft_failures: list<string>>>
# operationId: GET_verified_senders-domains
export def "get-verified-senders-domains" [
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
    path: "/verified_senders/domains"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Verified Sender Request
#
# POST /verified_senders/resend/{id}
# Returns: record
# operationId: POST_verified_senders-resend-id
export def "post-verified-senders-resend-id" [
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
    method: post
    path: "/verified_senders/resend/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completed Steps
#
# GET /verified_senders/steps_completed
# Returns: record<results: record<domain_verified: bool, sender_verified: bool>>
# operationId: GET_verified_senders-steps_completed
export def "get-verified-senders-steps-completed" [
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
    path: "/verified_senders/steps_completed"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Sender Request
#
# GET /verified_senders/verify/{token}
# operationId: GET_verified_senders-verify-token
export def "get-verified-senders-verify-token" [
  token_arg: string
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
    method: get
    path: "/verified_senders/verify/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Verified Sender
#
# DELETE /verified_senders/{id}
# Returns: record
# operationId: DELETE_verified_senders-id
export def "delete-verified-senders-id" [
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
    method: delete
    path: "/verified_senders/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit Verified Sender
#
# PATCH /verified_senders/{id}
# Returns: record<address: string, address2: string, city: string, country: string, from_email: string, from_name: string, id: int, locked: bool, nickname: string, reply_to: string, reply_to_name: string, state: string, verified: bool, zip: string>
# operationId: PATCH_verified_senders-id
export def "patch-verified-senders-id" [
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
  --address: string
  --address2: string
  --city: string
  --country: string
  from_email: string # format: email
  --from-name: string
  nickname: string
  reply_to: string # format: email
  --reply-to-name: string
  --state: string
  --zip: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/verified_senders/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: address2, var: address2}, {name: city, var: city}, {name: country, var: country}, {name: from_email, var: from_email}, {name: from_name, var: from_name}, {name: nickname, var: nickname}, {name: reply_to, var: reply_to}, {name: reply_to_name, var: reply_to_name}, {name: state, var: state}, {name: zip, var: zip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, address: $address, address2: $address2, city: $city, country: $country, from_email: $from_email, from_name: $from_name, nickname: $nickname, reply_to: $reply_to, reply_to_name: $reply_to_name, state: $state, zip: $zip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Email DNS records to a co-worker
#
# POST /whitelabel/dns/email
# operationId: POST_whitelabel-dns-email
export def "post-whitelabel-dns-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  domain_id: int # The ID of your SendGrid domain record.
  email: string # The email address to send the DNS information to. (format: email)
  link_id: int
  --message: string # A custom text block to include in the email body sent with the records. (default: Please set these DNS records in our hosting solution.)
]: any -> any {
  $in | http-request {
    method: post
    path: "/whitelabel/dns/email"
    body: {content_type: "application/json", kind: json, fields: [{name: domain_id, var: domain_id}, {name: email, var: email}, {name: link_id, var: link_id}, {name: message, var: message}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_id: $domain_id, email: $email, link_id: $link_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all authenticated domains
#
# GET /whitelabel/domains
# Returns: table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>>
# operationId: GET_whitelabel-domains
export def "get-whitelabel-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of domains to return.
  --offset: int # Paging offset.
  --exclude-subusers: oneof<nothing, bool> # Exclude subuser domains from the result.
  --username: string # The username associated with an authenticated domain.
  --domain: string # Search for authenticated domains.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/domains"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: exclude_subusers, var: exclude_subusers}, {name: username, var: username}, {name: domain, var: domain}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, exclude_subusers: $exclude_subusers, username: $username, domain: $domain, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate a domain
#
# POST /whitelabel/domains
# Returns: record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record<data: string, host: string, type: string, valid: bool>, dkim2: record<data: string, host: string, type: string, valid: bool>, mail_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool>
# operationId: POST_whitelabel-domains
export def "post-whitelabel-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --automatic-security: oneof<nothing, bool> # Whether to allow SendGrid to manage your SPF records, DKIM keys, and DKIM key rotation.
  --custom-dkim-selector: string # Add a custom DKIM selector. Accepts three letters or numbers.
  --custom-spf: oneof<nothing, bool> # Specify whether to use a custom SPF or allow SendGrid to manage your SPF. This option is only available to authenticated domains set up for manual security.
  --default: oneof<nothing, bool> # Whether to use this authenticated domain as the fallback if no authenticated domains match the sender's domain.
  domain: string # Domain being authenticated.
  --ips: list<string> # The IP addresses that will be included in the custom SPF record for this authenticated domain.
  --subdomain: string # The subdomain to use for this authenticated domain.
  --username: string # The username associated with this domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelabel/domains"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: automatic_security, var: automatic_security}, {name: custom_dkim_selector, var: custom_dkim_selector}, {name: custom_spf, var: custom_spf}, {name: default, var: default}, {name: domain, var: domain}, {name: ips, var: ips}, {name: subdomain, var: subdomain}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, automatic_security: $automatic_security, custom_dkim_selector: $custom_dkim_selector, custom_spf: $custom_spf, default: $default, domain: $domain, ips: $ips, subdomain: $subdomain, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the default authentication
#
# GET /whitelabel/domains/default
# Returns: table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>>
# operationId: GET_whitelabel-domains-default
export def "get-whitelabel-domains-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The domain to find a default authentication.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/domains/default"
    query: [{name: domain, var: domain}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociate an authenticated domain from a given user.
#
# DELETE /whitelabel/domains/subuser
# Returns: record
# operationId: DELETE_whitelabel-domains-subuser
export def "delete-whitelabel-domains-subuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username for the subuser to find associated authenticated domain.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/whitelabel/domains/subuser"
    query: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the authenticated domain associated with the given user.
#
# GET /whitelabel/domains/subuser
# Returns: record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: GET_whitelabel-domains-subuser
export def "get-whitelabel-domains-subuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Username for the subuser to find associated authenticated domain. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/domains/subuser"
    query: [{name: username, var: username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an authenticated domain.
#
# DELETE /whitelabel/domains/{domain_id}
# Returns: record
# operationId: DELETE_whitelabel-domains-domain_id
export def "delete-whitelabel-domains-domain-id" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/whitelabel/domains/{domain_id}"
    path_params: [{name: domain_id, var: domain_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_id: $domain_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an authenticated domain
#
# GET /whitelabel/domains/{domain_id}
# Returns: record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record<data: string, host: string, type: string, valid: bool>, dkim2: record<data: string, host: string, type: string, valid: bool>, mail_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool>
# operationId: GET_whitelabel-domains-domain_id
export def "get-whitelabel-domains-domain-id" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/domains/{domain_id}"
    path_params: [{name: domain_id, var: domain_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an authenticated domain
#
# PATCH /whitelabel/domains/{domain_id}
# Returns: table<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim1: record, dkim2: record, mail_cname: record>, domain: string, id: float, ips: list<string>, legacy: bool, subdomain: string, user_id: float, username: string, valid: bool, last_validation_attempt_at: int, subusers: list<record>>
# operationId: PATCH_whitelabel-domains-domain_id
export def "patch-whitelabel-domains-domain-id" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --custom-spf: oneof<nothing, bool> # Indicates whether to generate a custom SPF record for manual security. (default: false)
  --default: oneof<nothing, bool> # Indicates whether this is the default authenticated domain. (default: false)
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/whitelabel/domains/{domain_id}"
    path_params: [{name: domain_id, var: domain_id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_spf, var: custom_spf}, {name: default, var: default}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_id: $domain_id, on_behalf_of: $on_behalf_of, custom_spf: $custom_spf, default: $default
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate an authenticated domain with a given user.
#
# POST /whitelabel/domains/{domain_id}/subuser
# Returns: record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: POST_whitelabel-domains-domain_id-subuser
export def "post-whitelabel-domains-domain-id-subuser" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string # Username to associate with the authenticated domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelabel/domains/{domain_id}/subuser"
    path_params: [{name: domain_id, var: domain_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_id: $domain_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an IP to an authenticated domain
#
# POST /whitelabel/domains/{id}/ips
# Returns: record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: POST_whitelabel-domains-id-ips
export def "post-whitelabel-domains-id-ips" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  ip: string # IP to associate with the domain. Used for manually specifying IPs for custom SPF.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelabel/domains/{id}/ips"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: ip, var: ip}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of, ip: $ip
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an IP from an authenticated domain.
#
# DELETE /whitelabel/domains/{id}/ips/{ip}
# Returns: record<automatic_security: bool, custom_spf: bool, default: bool, dns: record<dkim: record<data: string, host: string, type: string, valid: bool>, domain_spf: record<data: string, host: string, type: string, valid: bool>, mail_server: record<data: string, host: string, type: string, valid: bool>, subdomain_spf: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, ips: list<any>, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: DELETE_whitelabel-domains-id-ips-ip
export def "delete-whitelabel-domains-id-ips-ip" [
  id: int
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/whitelabel/domains/{id}/ips/{ip}"
    path_params: [{name: id, var: id}, {name: ip, var: ip}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ip: $ip, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate a domain authentication.
#
# POST /whitelabel/domains/{id}/validate
# Returns: record<id: int, valid: bool, validation_results: record<dkim1: record<reason: string, valid: bool>, dkim2: record<reason: string, valid: bool>, mail_cname: record<reason: string, valid: bool>, spf: record<reason: string, valid: bool>>>
# operationId: POST_whitelabel-domains-id-validate
export def "post-whitelabel-domains-id-validate" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/whitelabel/domains/{id}/validate"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all reverse DNS records
#
# GET /whitelabel/ips
# Returns: table<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: list<record>, valid: bool>
# operationId: GET_whitelabel-ips
export def "get-whitelabel-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to retrieve.
  --offset: int # The point in the list of results to begin retrieving IP addresses from.
  --ip: string # The IP address segment that you'd like to use in a prefix search.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/ips"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: ip, var: ip}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, ip: $ip, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set up reverse DNS
#
# POST /whitelabel/ips
# Returns: record<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: table<user_id: int, username: string>, valid: bool>
# operationId: POST_whitelabel-ips
export def "post-whitelabel-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  domain: string # The root, or sending, domain that will be used to send message from the IP address.
  ip: string # The IP address for which you want to set up reverse DNS.
  --subdomain: string # The subdomain that will be used to send emails from the IP address. This should be the same as the subdomain used to set up an authenticated domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelabel/ips"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain, var: domain}, {name: ip, var: ip}, {name: subdomain, var: subdomain}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, domain: $domain, ip: $ip, subdomain: $subdomain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a reverse DNS record
#
# DELETE /whitelabel/ips/{id}
# Returns: record
# operationId: DELETE_whitelabel-ips-id
export def "delete-whitelabel-ips-id" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/whitelabel/ips/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a reverse DNS record
#
# GET /whitelabel/ips/{id}
# Returns: record<a_record: record<data: string, host: string, type: string, valid: bool>, domain: string, id: int, ip: string, last_validation_attempt_at: int, legacy: bool, rdns: string, subdomain: string, users: table<user_id: int, username: string>, valid: bool>
# operationId: GET_whitelabel-ips-id
export def "get-whitelabel-ips-id" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/ips/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate a reverse DNS record
#
# POST /whitelabel/ips/{id}/validate
# Returns: record<id: int, valid: bool, validation_results: record<a_record: record<reason: string, valid: bool>>>
# operationId: POST_whitelabel-ips-id-validate
export def "post-whitelabel-ips-id-validate" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/whitelabel/ips/{id}/validate"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve all branded links
#
# GET /whitelabel/links
# Returns: table<default: bool, dns: record<domain_cname: record, owner_cname: record>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: GET_whitelabel-links
export def "get-whitelabel-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limits the number of results returned per page.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/links"
    query: [{name: limit, var: limit}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a branded link
#
# POST /whitelabel/links
# Returns: record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: POST_whitelabel-links
export def "post-whitelabel-links" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --default: oneof<nothing, bool> # Indicates if you want to use this link branding as the default or fallback. When setting a new default, the existing default link branding will have its default status removed automatically.
  domain: string # The root domain for the subdomain that you are creating the link branding for. This should match your FROM email address.
  --subdomain: string # The subdomain to create the link branding for. Must be different from the subdomain you used for authenticating your domain.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelabel/links"
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}, {name: domain, var: domain}, {name: subdomain, var: subdomain}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    on_behalf_of: $on_behalf_of, default: $default, domain: $domain, subdomain: $subdomain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the default branded link
#
# GET /whitelabel/links/default
# Returns: record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: GET_whitelabel-links-default
export def "get-whitelabel-links-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The domain to match against when finding the default branded link.
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/links/default"
    query: [{name: domain, var: domain}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociate a branded link from a subuser
#
# DELETE /whitelabel/links/subuser
# Returns: record
# operationId: DELETE_whitelabel-links-subuser
export def "delete-whitelabel-links-subuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of the subuser account that you want to disassociate a branded link from. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/whitelabel/links/subuser"
    query: [{name: username, var: username, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a subuser's branded link
#
# GET /whitelabel/links/subuser
# Returns: record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: GET_whitelabel-links-subuser
export def "get-whitelabel-links-subuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of the subuser to retrieve associated branded links for. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/links/subuser"
    query: [{name: username, var: username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a branded link
#
# DELETE /whitelabel/links/{id}
# Returns: record
# operationId: DELETE_whitelabel-links-id
export def "delete-whitelabel-links-id" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/whitelabel/links/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a branded link
#
# GET /whitelabel/links/{id}
# Returns: record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: GET_whitelabel-links-id
export def "get-whitelabel-links-id" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/whitelabel/links/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a branded link
#
# PATCH /whitelabel/links/{id}
# Returns: record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: PATCH_whitelabel-links-id
export def "patch-whitelabel-links-id" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
  --default: oneof<nothing, bool> # Indicates if the branded link is set as the default. When setting a new default, the existing default link branding will have its default status removed automatically.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/whitelabel/links/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    body: {content_type: "application/json", kind: json, fields: [{name: default, var: default}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of, default: $default
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate a branded link
#
# POST /whitelabel/links/{id}/validate
# Returns: record<id: int, valid: bool, validation_results: record<domain_cname: record<reason: string, valid: bool>, owner_cname: record<reason: string, valid: bool>>>
# operationId: POST_whitelabel-links-id-validate
export def "post-whitelabel-links-id-validate" [
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
  --on-behalf-of: string # default: The subuser's username. This header generates the API call as if the subuser account was making the call.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/whitelabel/links/{id}/validate"
    path_params: [{name: id, var: id}]
    header: [{name: on-behalf-of, var: on_behalf_of}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, on_behalf_of: $on_behalf_of
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate a branded link with a subuser
#
# POST /whitelabel/links/{link_id}/subuser
# Returns: record<default: bool, dns: record<domain_cname: record<data: string, host: string, type: string, valid: bool>, owner_cname: record<data: string, host: string, type: string, valid: bool>>, domain: string, id: int, legacy: bool, subdomain: string, user_id: int, username: string, valid: bool>
# operationId: POST_whitelabel-links-link_id-subuser
export def "post-whitelabel-links-link-id-subuser" [
  link_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of the subuser account that you want to associate the branded link with.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/whitelabel/links/{link_id}/subuser"
    path_params: [{name: link_id, var: link_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    link_id: $link_id, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
