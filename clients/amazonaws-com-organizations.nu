# Auto-generated client for AWS Organizations v2016-11-28
# Source: https://api.apis.guru/v2/specs/amazonaws.com/organizations/2016-11-28/openapi.json
# Auth: --token flag or $env.AWS_ORGANIZATIONS_TOKEN

const CLIENT = {
  base_url: "http://organizations.us-east-1.amazonaws.com"
  token_env_var: "AWS_ORGANIZATIONS_TOKEN"
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

def base-url-completer [] { ["http://organizations.us-east-1.amazonaws.com" "http://organizations.us-east-2.amazonaws.com" "http://organizations.us-west-1.amazonaws.com" "http://organizations.us-west-2.amazonaws.com" "http://organizations.us-gov-west-1.amazonaws.com" "http://organizations.us-gov-east-1.amazonaws.com" "http://organizations.ca-central-1.amazonaws.com" "http://organizations.eu-north-1.amazonaws.com" "http://organizations.eu-west-1.amazonaws.com" "http://organizations.eu-west-2.amazonaws.com" "http://organizations.eu-west-3.amazonaws.com" "http://organizations.eu-central-1.amazonaws.com" "http://organizations.eu-south-1.amazonaws.com" "http://organizations.af-south-1.amazonaws.com" "http://organizations.ap-northeast-1.amazonaws.com" "http://organizations.ap-northeast-2.amazonaws.com" "http://organizations.ap-northeast-3.amazonaws.com" "http://organizations.ap-southeast-1.amazonaws.com" "http://organizations.ap-southeast-2.amazonaws.com" "http://organizations.ap-east-1.amazonaws.com" "http://organizations.ap-south-1.amazonaws.com" "http://organizations.sa-east-1.amazonaws.com" "http://organizations.me-south-1.amazonaws.com" "https://organizations.us-east-1.amazonaws.com" "https://organizations.us-east-2.amazonaws.com" "https://organizations.us-west-1.amazonaws.com" "https://organizations.us-west-2.amazonaws.com" "https://organizations.us-gov-west-1.amazonaws.com" "https://organizations.us-gov-east-1.amazonaws.com" "https://organizations.ca-central-1.amazonaws.com" "https://organizations.eu-north-1.amazonaws.com" "https://organizations.eu-west-1.amazonaws.com" "https://organizations.eu-west-2.amazonaws.com" "https://organizations.eu-west-3.amazonaws.com" "https://organizations.eu-central-1.amazonaws.com" "https://organizations.eu-south-1.amazonaws.com" "https://organizations.af-south-1.amazonaws.com" "https://organizations.ap-northeast-1.amazonaws.com" "https://organizations.ap-northeast-2.amazonaws.com" "https://organizations.ap-northeast-3.amazonaws.com" "https://organizations.ap-southeast-1.amazonaws.com" "https://organizations.ap-southeast-2.amazonaws.com" "https://organizations.ap-east-1.amazonaws.com" "https://organizations.ap-south-1.amazonaws.com" "https://organizations.sa-east-1.amazonaws.com" "https://organizations.me-south-1.amazonaws.com" "http://organizations.cn-north-1.amazonaws.com.cn" "http://organizations.cn-northwest-1.amazonaws.com.cn" "https://organizations.cn-north-1.amazonaws.com.cn" "https://organizations.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSOrganizationsV20161128.AcceptHandshake"] }
def x-amz-target-completer-1 [] { ["AWSOrganizationsV20161128.AttachPolicy"] }
def x-amz-target-completer-2 [] { ["AWSOrganizationsV20161128.CancelHandshake"] }
def x-amz-target-completer-3 [] { ["AWSOrganizationsV20161128.CloseAccount"] }
def iam-user-access-to-billing-completer [] { ["ALLOW" "DENY"] }
def x-amz-target-completer-4 [] { ["AWSOrganizationsV20161128.CreateAccount"] }
def x-amz-target-completer-5 [] { ["AWSOrganizationsV20161128.CreateGovCloudAccount"] }
def feature-set-completer [] { ["ALL" "CONSOLIDATED_BILLING"] }
def x-amz-target-completer-6 [] { ["AWSOrganizationsV20161128.CreateOrganization"] }
def x-amz-target-completer-7 [] { ["AWSOrganizationsV20161128.CreateOrganizationalUnit"] }
def type-completer [] { ["AISERVICES_OPT_OUT_POLICY" "BACKUP_POLICY" "SERVICE_CONTROL_POLICY" "TAG_POLICY"] }
def x-amz-target-completer-8 [] { ["AWSOrganizationsV20161128.CreatePolicy"] }
def x-amz-target-completer-9 [] { ["AWSOrganizationsV20161128.DeclineHandshake"] }
def x-amz-target-completer-10 [] { ["AWSOrganizationsV20161128.DeleteOrganization"] }
def x-amz-target-completer-11 [] { ["AWSOrganizationsV20161128.DeleteOrganizationalUnit"] }
def x-amz-target-completer-12 [] { ["AWSOrganizationsV20161128.DeletePolicy"] }
def x-amz-target-completer-13 [] { ["AWSOrganizationsV20161128.DeleteResourcePolicy"] }
def x-amz-target-completer-14 [] { ["AWSOrganizationsV20161128.DeregisterDelegatedAdministrator"] }
def x-amz-target-completer-15 [] { ["AWSOrganizationsV20161128.DescribeAccount"] }
def x-amz-target-completer-16 [] { ["AWSOrganizationsV20161128.DescribeCreateAccountStatus"] }
def policy-type-completer [] { ["AISERVICES_OPT_OUT_POLICY" "BACKUP_POLICY" "TAG_POLICY"] }
def x-amz-target-completer-17 [] { ["AWSOrganizationsV20161128.DescribeEffectivePolicy"] }
def x-amz-target-completer-18 [] { ["AWSOrganizationsV20161128.DescribeHandshake"] }
def x-amz-target-completer-19 [] { ["AWSOrganizationsV20161128.DescribeOrganization"] }
def x-amz-target-completer-20 [] { ["AWSOrganizationsV20161128.DescribeOrganizationalUnit"] }
def x-amz-target-completer-21 [] { ["AWSOrganizationsV20161128.DescribePolicy"] }
def x-amz-target-completer-22 [] { ["AWSOrganizationsV20161128.DescribeResourcePolicy"] }
def x-amz-target-completer-23 [] { ["AWSOrganizationsV20161128.DetachPolicy"] }
def x-amz-target-completer-24 [] { ["AWSOrganizationsV20161128.DisableAWSServiceAccess"] }
def policy-type-completer-1 [] { ["AISERVICES_OPT_OUT_POLICY" "BACKUP_POLICY" "SERVICE_CONTROL_POLICY" "TAG_POLICY"] }
def x-amz-target-completer-25 [] { ["AWSOrganizationsV20161128.DisablePolicyType"] }
def x-amz-target-completer-26 [] { ["AWSOrganizationsV20161128.EnableAWSServiceAccess"] }
def x-amz-target-completer-27 [] { ["AWSOrganizationsV20161128.EnableAllFeatures"] }
def x-amz-target-completer-28 [] { ["AWSOrganizationsV20161128.EnablePolicyType"] }
def x-amz-target-completer-29 [] { ["AWSOrganizationsV20161128.InviteAccountToOrganization"] }
def x-amz-target-completer-30 [] { ["AWSOrganizationsV20161128.LeaveOrganization"] }
def x-amz-target-completer-31 [] { ["AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization"] }
def x-amz-target-completer-32 [] { ["AWSOrganizationsV20161128.ListAccounts"] }
def x-amz-target-completer-33 [] { ["AWSOrganizationsV20161128.ListAccountsForParent"] }
def child-type-completer [] { ["ACCOUNT" "ORGANIZATIONAL_UNIT"] }
def x-amz-target-completer-34 [] { ["AWSOrganizationsV20161128.ListChildren"] }
def x-amz-target-completer-35 [] { ["AWSOrganizationsV20161128.ListCreateAccountStatus"] }
def x-amz-target-completer-36 [] { ["AWSOrganizationsV20161128.ListDelegatedAdministrators"] }
def x-amz-target-completer-37 [] { ["AWSOrganizationsV20161128.ListDelegatedServicesForAccount"] }
def x-amz-target-completer-38 [] { ["AWSOrganizationsV20161128.ListHandshakesForAccount"] }
def x-amz-target-completer-39 [] { ["AWSOrganizationsV20161128.ListHandshakesForOrganization"] }
def x-amz-target-completer-40 [] { ["AWSOrganizationsV20161128.ListOrganizationalUnitsForParent"] }
def x-amz-target-completer-41 [] { ["AWSOrganizationsV20161128.ListParents"] }
def filter-completer [] { ["AISERVICES_OPT_OUT_POLICY" "BACKUP_POLICY" "SERVICE_CONTROL_POLICY" "TAG_POLICY"] }
def x-amz-target-completer-42 [] { ["AWSOrganizationsV20161128.ListPolicies"] }
def x-amz-target-completer-43 [] { ["AWSOrganizationsV20161128.ListPoliciesForTarget"] }
def x-amz-target-completer-44 [] { ["AWSOrganizationsV20161128.ListRoots"] }
def x-amz-target-completer-45 [] { ["AWSOrganizationsV20161128.ListTagsForResource"] }
def x-amz-target-completer-46 [] { ["AWSOrganizationsV20161128.ListTargetsForPolicy"] }
def x-amz-target-completer-47 [] { ["AWSOrganizationsV20161128.MoveAccount"] }
def x-amz-target-completer-48 [] { ["AWSOrganizationsV20161128.PutResourcePolicy"] }
def x-amz-target-completer-49 [] { ["AWSOrganizationsV20161128.RegisterDelegatedAdministrator"] }
def x-amz-target-completer-50 [] { ["AWSOrganizationsV20161128.RemoveAccountFromOrganization"] }
def x-amz-target-completer-51 [] { ["AWSOrganizationsV20161128.TagResource"] }
def x-amz-target-completer-52 [] { ["AWSOrganizationsV20161128.UntagResource"] }
def x-amz-target-completer-53 [] { ["AWSOrganizationsV20161128.UpdateOrganizationalUnit"] }
def x-amz-target-completer-54 [] { ["AWSOrganizationsV20161128.UpdatePolicy"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-handshake: "record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>"
    cancel-handshake: "record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>"
    create-account: "record<CreateAccountStatus: record<Id: string, AccountName: string, State: string, RequestedTimestamp: string, CompletedTimestamp: string, AccountId: string, GovCloudAccountId: string, FailureReason: string>>"
    create-gov-cloud-account: "record<CreateAccountStatus: record<Id: string, AccountName: string, State: string, RequestedTimestamp: string, CompletedTimestamp: string, AccountId: string, GovCloudAccountId: string, FailureReason: string>>"
    create-organization: "record<Organization: record<Id: string, Arn: string, FeatureSet: string, MasterAccountArn: string, MasterAccountId: string, MasterAccountEmail: string, AvailablePolicyTypes: list<record>>>"
    create-organizational-unit: "record<OrganizationalUnit: record<Id: string, Arn: string, Name: string>>"
    create-policy: "record<Policy: record<PolicySummary: record<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, Content: string>>"
    decline-handshake: "record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>"
    describe-account: "record<Account: record<Id: string, Arn: string, Email: string, Name: string, Status: string, JoinedMethod: string, JoinedTimestamp: string>>"
    describe-create-account-status: "record<CreateAccountStatus: record<Id: string, AccountName: string, State: string, RequestedTimestamp: string, CompletedTimestamp: string, AccountId: string, GovCloudAccountId: string, FailureReason: string>>"
    describe-effective-policy: "record<EffectivePolicy: record<PolicyContent: string, LastUpdatedTimestamp: string, TargetId: string, PolicyType: string>>"
    describe-handshake: "record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>"
    describe-organization: "record<Organization: record<Id: string, Arn: string, FeatureSet: string, MasterAccountArn: string, MasterAccountId: string, MasterAccountEmail: string, AvailablePolicyTypes: list<record>>>"
    describe-organizational-unit: "record<OrganizationalUnit: record<Id: string, Arn: string, Name: string>>"
    describe-policy: "record<Policy: record<PolicySummary: record<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, Content: string>>"
    describe-resource-policy: "record<ResourcePolicy: record<ResourcePolicySummary: record<Id: string, Arn: string>, Content: string>>"
    disable-policy-type: "record<Root: record<Id: string, Arn: string, Name: string, PolicyTypes: list<record>>>"
    enable-all-features: "record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>"
    enable-policy-type: "record<Root: record<Id: string, Arn: string, Name: string, PolicyTypes: list<record>>>"
    invite-account-to-organization: "record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>"
    list-aws-service-access-for-organization: "record<EnabledServicePrincipals: table<ServicePrincipal: string, DateEnabled: string>, NextToken: string>"
    list-accounts: "record<Accounts: table<Id: string, Arn: string, Email: string, Name: string, Status: string, JoinedMethod: string, JoinedTimestamp: string>, NextToken: string>"
    list-accounts-for-parent: "record<Accounts: table<Id: string, Arn: string, Email: string, Name: string, Status: string, JoinedMethod: string, JoinedTimestamp: string>, NextToken: string>"
    list-children: "record<Children: table<Id: string, Type: string>, NextToken: string>"
    list-create-account-status: "record<CreateAccountStatuses: table<Id: string, AccountName: string, State: string, RequestedTimestamp: string, CompletedTimestamp: string, AccountId: string, GovCloudAccountId: string, FailureReason: string>, NextToken: string>"
    list-delegated-administrators: "record<DelegatedAdministrators: table<Id: string, Arn: string, Email: string, Name: string, Status: string, JoinedMethod: string, JoinedTimestamp: string, DelegationEnabledDate: string>, NextToken: string>"
    list-delegated-services-for-account: "record<DelegatedServices: table<ServicePrincipal: string, DelegationEnabledDate: string>, NextToken: string>"
    list-handshakes-for-account: "record<Handshakes: table<Id: string, Arn: string, Parties: list, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list>, NextToken: string>"
    list-handshakes-for-organization: "record<Handshakes: table<Id: string, Arn: string, Parties: list, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list>, NextToken: string>"
    list-organizational-units-for-parent: "record<OrganizationalUnits: table<Id: string, Arn: string, Name: string>, NextToken: string>"
    list-parents: "record<Parents: table<Id: string, Type: string>, NextToken: string>"
    list-policies: "record<Policies: table<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, NextToken: string>"
    list-policies-for-target: "record<Policies: table<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, NextToken: string>"
    list-roots: "record<Roots: table<Id: string, Arn: string, Name: string, PolicyTypes: list>, NextToken: string>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>, NextToken: string>"
    list-targets-for-policy: "record<Targets: table<TargetId: string, Arn: string, Name: string, Type: string>, NextToken: string>"
    put-resource-policy: "record<ResourcePolicy: record<ResourcePolicySummary: record<Id: string, Arn: string>, Content: string>>"
    update-organizational-unit: "record<OrganizationalUnit: record<Id: string, Arn: string, Name: string>>"
    update-policy: "record<Policy: record<PolicySummary: record<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, Content: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-handshake" "attach-policy" "cancel-handshake" "close-account" "create-account" "create-gov-cloud-account" "create-organization" "create-organizational-unit" "create-policy" "decline-handshake" "delete-organization" "delete-organizational-unit" "delete-policy" "delete-resource-policy" "deregister-delegated-administrator" "describe-account" "describe-create-account-status" "describe-effective-policy" "describe-handshake" "describe-organization" "describe-organizational-unit" "describe-policy" "describe-resource-policy" "detach-policy" "disable-aws-service-access" "disable-policy-type" "enable-aws-service-access" "enable-all-features" "enable-policy-type" "invite-account-to-organization" "leave-organization" "list-aws-service-access-for-organization" "list-accounts" "list-accounts-for-parent" "list-children" "list-create-account-status" "list-delegated-administrators" "list-delegated-services-for-account" "list-handshakes-for-account" "list-handshakes-for-organization" "list-organizational-units-for-parent" "list-parents" "list-policies" "list-policies-for-target" "list-roots" "list-tags-for-resource" "list-targets-for-policy" "move-account" "put-resource-policy" "register-delegated-administrator" "remove-account-from-organization" "tag-resource" "untag-resource" "update-organizational-unit" "update-policy" "commands"] | sort) } | get name | first)
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

# Sends a response to the originator of a handshake agreeing to the action proposed by the handshake request. You can only call this operation by the following principals when they also have the relevant IAM permissions: Invitation to join or Approve all features request handshakes: only a principal from the member account. The user who calls the API for an invitation to join must have the organizations:AcceptHandshake permission. If you enabled all features in the organization, the user must also have the iam:CreateServiceLinkedRole permission so that Organizations can create the required service-linked role named AWSServiceRoleForOrganizations. For more information, see Organizations and Service-Linked Roles (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integration_services.html#orgs_integration_service-linked-roles) in the Organizations User Guide. Enable all features final confirmation handshake: only a principal from the management account. For more information about invitations, see Inviting an Amazon Web Services account to join your organization (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_invites.html) in the Organizations User Guide. For more information about requests to enable all features in the organization, see Enabling all features in your organization (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html) in the Organizations User Guide. After you accept a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.
#
# POST /
# Returns: record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>
# operationId: AcceptHandshake
export def "accept-handshake" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer # required
  handshake_id: string # The unique identifier (ID) of the handshake that you want to accept. The regex pattern (http://wikipedia.org/wiki/regex) for handshake ID string requires "h-" followed by from 8 to 32 lowercase letters or digits.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.AcceptHandshake"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HandshakeId, var: handshake_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, handshake_id: $handshake_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches a policy to a root, an organizational unit (OU), or an individual account. How the policy affects accounts depends on the type of policy. Refer to the Organizations User Guide for information about each policy type: AISERVICES_OPT_OUT_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) BACKUP_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html) SERVICE_CONTROL_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html) TAG_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html) This operation can be called only from the organization's management account.
#
# POST /
# operationId: AttachPolicy
export def "attach-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1 # required
  policy_id: string # The unique identifier (ID) of the policy that you want to attach to the target. You can get the ID for the policy by calling the ListPolicies operation. The regex pattern (http://wikipedia.org/wiki/regex) for a policy ID string requires "p-" followed by from 8 to 128 lowercase or uppercase letters, digits, or the underscore character (_).
  target_id: string # The unique identifier (ID) of the root, OU, or account that you want to attach the policy to. You can get the ID by calling the ListRoots, ListOrganizationalUnitsForParent, or ListAccounts operations. The regex pattern (http://wikipedia.org/wiki/regex) for a target ID string requires one of the following: Root - A string that begins with "r-" followed by from 4 to 32 lowercase letters or digits. Account - A string that consists of exactly 12 digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that the OU is in). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.AttachPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyId, var: policy_id}, {name: TargetId, var: target_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_id: $policy_id, target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a handshake. Canceling a handshake sets the handshake state to CANCELED. This operation can be called only from the account that originated the handshake. The recipient of the handshake can't cancel it, but can use DeclineHandshake instead. After a handshake is canceled, the recipient can no longer respond to that handshake. After you cancel a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.
#
# POST /
# Returns: record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>
# operationId: CancelHandshake
export def "cancel-handshake" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2 # required
  handshake_id: string # The unique identifier (ID) of the handshake that you want to cancel. You can get the ID from the ListHandshakesForOrganization operation. The regex pattern (http://wikipedia.org/wiki/regex) for handshake ID string requires "h-" followed by from 8 to 32 lowercase letters or digits.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.CancelHandshake"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HandshakeId, var: handshake_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, handshake_id: $handshake_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Closes an Amazon Web Services member account within an organization. You can close an account when all features are enabled (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html). You can't close the management account with this API. This is an asynchronous request that Amazon Web Services performs in the background. Because CloseAccount operates asynchronously, it can return a successful completion message even though account closure might still be in progress. You need to wait a few minutes before the account is fully closed. To check the status of the request, do one of the following: Use the AccountId that you sent in the CloseAccount request to provide as a parameter to the DescribeAccount operation. While the close account request is in progress, Account status will indicate PENDING_CLOSURE. When the close account request completes, the status will change to SUSPENDED. Check the CloudTrail log for the CloseAccountResult event that gets published after the account closes successfully. For information on using CloudTrail with Organizations, see Logging and monitoring in Organizations (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_security_incident-response.html#orgs_cloudtrail-integration) in the Organizations User Guide. You can close only 10% of member accounts, between 10 and 200, within a rolling 30 day period. This quota is not bound by a calendar month, but starts when you close an account. After you reach this limit, you can close additional accounts in the Billing console. For more information, see Closing an account (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/close-account.html) in the Amazon Web Services Billing and Cost Management User Guide. To reinstate a closed account, contact Amazon Web Services Support within the 90-day grace period while the account is in SUSPENDED status. If the Amazon Web Services account you attempt to close is linked to an Amazon Web Services GovCloud (US) account, the CloseAccount request will close both accounts. To learn important pre-closure details, see Closing an Amazon Web Services GovCloud (US) account (https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/Closing-govcloud-account.html) in the Amazon Web Services GovCloud User Guide. For more information about closing accounts, see Closing an Amazon Web Services account (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html) in the Organizations User Guide.
#
# POST /
# operationId: CloseAccount
export def "close-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3 # required
  account_id: string # Retrieves the Amazon Web Services account Id for the current CloseAccount API request.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.CloseAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountId, var: account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Web Services account that is automatically a member of the organization whose credentials made the request. This is an asynchronous request that Amazon Web Services performs in the background. Because CreateAccount operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following: Use the Id value of the CreateAccountStatus response element from this operation to provide as a parameter to the DescribeCreateAccountStatus operation. Check the CloudTrail log for the CreateAccountResult event. For information on using CloudTrail with Organizations, see Logging and monitoring in Organizations (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_security_incident-response.html#orgs_cloudtrail-integration) in the Organizations User Guide. The user who calls the API to create an account must have the organizations:CreateAccount permission. If you enabled all features in the organization, Organizations creates the required service-linked role named AWSServiceRoleForOrganizations. For more information, see Organizations and Service-Linked Roles (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs) in the Organizations User Guide. If the request includes tags, then the requester must have the organizations:TagResource permission. Organizations preconfigures the new member account with a role (named OrganizationAccountAccessRole by default) that grants users in the management account administrator permissions in the new member account. Principals in the management account can assume the role. Organizations clones the company name and address information for the new account from the organization's management account. This operation can be called only from the organization's management account. For more information about creating accounts, see Creating an Amazon Web Services account in Your Organization (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html) in the Organizations User Guide. When you create an account in an organization using the Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account, such as a payment method and signing the end user license agreement (EULA) is not automatically collected. If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at To leave an organization as a member account (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info) in the Organizations User Guide. If you get an exception that indicates that you exceeded your account limits for the organization, contact Amazon Web Services Support (https://console.aws.amazon.com/support/home#/). If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact Amazon Web Services Support (https://console.aws.amazon.com/support/home#/). Using CreateAccount to create multiple temporary accounts isn't recommended. You can only close an account from the Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see Closing an Amazon Web Services account (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html) in the Organizations User Guide. When you create a member account with this operation, you can choose whether to create the account with the IAM User and Role Access to Billing Information switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see Granting Access to Your Billing Information and Tools (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html).
#
# POST /
# Returns: record<CreateAccountStatus: record<Id: string, AccountName: string, State: string, RequestedTimestamp: string, CompletedTimestamp: string, AccountId: string, GovCloudAccountId: string, FailureReason: string>>
# operationId: CreateAccount
export def "create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4 # required
  email: string # The email address of the owner to assign to the new member account. This email address must not already be associated with another Amazon Web Services account. You must use a valid email address to complete account creation. The rules for a valid email address: The address must be a minimum of 6 and a maximum of 64 characters long. All characters must be 7-bit ASCII characters. There must be one and only one @ symbol, which separates the local name from the domain name. The local name can't contain any of the following characters: whitespace, " ' ( ) < > [ ] : ; , \ | % & The local name can't begin with a dot (.) The domain name can consist of only the characters [a-z],[A-Z],[0-9], hyphen (-), or dot (.) The domain name can't begin or end with a hyphen (-) or dot (.) The domain name must contain at least one dot You can't access the root user of the account or remove an account that was created with an invalid email address. (format: password)
  account_name: string # The friendly name of the member account. (format: password)
  --role-name: string # The name of an IAM role that Organizations automatically preconfigures in the new member account. This role trusts the management account, allowing users in the management account to assume the role, as permitted by the management account administrator. The role has administrator permissions in the new member account. If you don't specify this parameter, the role name defaults to OrganizationAccountAccessRole. For more information about how to use this role to access the member account, see the following links: Accessing and Administering the Member Accounts in Your Organization (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html#orgs_manage_accounts_create-cross-account-role) in the Organizations User Guide Steps 2 and 3 in Tutorial: Delegate Access Across Amazon Web Services accounts Using IAM Roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html) in the IAM User Guide The regex pattern (http://wikipedia.org/wiki/regex) that is used to validate this parameter. The pattern can include uppercase letters, lowercase letters, digits with no spaces, and any of the following characters: =,.@-
  --iam-user-access-to-billing: string@iam-user-access-to-billing-completer # If set to ALLOW, the new account enables IAM users to access account billing information if they have the required permissions. If set to DENY, only the root user of the new account can access account billing information. For more information, see Activating Access to the Billing and Cost Management Console (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate) in the Amazon Web Services Billing and Cost Management User Guide. If you don't specify this parameter, the value defaults to ALLOW, and IAM users and roles with the required permissions can access billing information for the new account.
  --tags: list # A list of tags that you want to attach to the newly created account. For each tag in the list, you must specify both a tag key and a value. You can set the value to an empty string, but you can't set it to null. For more information about tagging, see Tagging Organizations resources (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tagging.html) in the Organizations User Guide. If any one of the tags is not valid or if you exceed the maximum allowed number of tags for an account, then the entire request fails and the account is not created. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.CreateAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Email, var: email}, {name: AccountName, var: account_name}, {name: RoleName, var: role_name}, {name: IamUserAccessToBilling, var: iam_user_access_to_billing}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, email: $email, account_name: $account_name, role_name: $role_name, iam_user_access_to_billing: $iam_user_access_to_billing, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This action is available if all of the following are true: You're authorized to create accounts in the Amazon Web Services GovCloud (US) Region. For more information on the Amazon Web Services GovCloud (US) Region, see the Amazon Web Services GovCloud User Guide. (https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/welcome.html) You already have an account in the Amazon Web Services GovCloud (US) Region that is paired with a management account of an organization in the commercial Region. You call this action from the management account of your organization in the commercial Region. You have the organizations:CreateGovCloudAccount permission. Organizations automatically creates the required service-linked role named AWSServiceRoleForOrganizations. For more information, see Organizations and Service-Linked Roles (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html#orgs_integrate_services-using_slrs) in the Organizations User Guide. Amazon Web Services automatically enables CloudTrail for Amazon Web Services GovCloud (US) accounts, but you should also do the following: Verify that CloudTrail is enabled to store logs. Create an Amazon S3 bucket for CloudTrail log storage. For more information, see Verifying CloudTrail Is Enabled (https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/verifying-cloudtrail.html) in the Amazon Web Services GovCloud User Guide. If the request includes tags, then the requester must have the organizations:TagResource permission. The tags are attached to the commercial account associated with the GovCloud account, rather than the GovCloud account itself. To add tags to the GovCloud account, call the TagResource operation in the GovCloud Region after the new GovCloud account exists. You call this action from the management account of your organization in the commercial Region to create a standalone Amazon Web Services account in the Amazon Web Services GovCloud (US) Region. After the account is created, the management account of an organization in the Amazon Web Services GovCloud (US) Region can invite it to that organization. For more information on inviting standalone accounts in the Amazon Web Services GovCloud (US) to join an organization, see Organizations (https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html) in the Amazon Web Services GovCloud User Guide. Calling CreateGovCloudAccount is an asynchronous request that Amazon Web Services performs in the background. Because CreateGovCloudAccount operates asynchronously, it can return a successful completion message even though account initialization might still be in progress. You might need to wait a few minutes before you can successfully access the account. To check the status of the request, do one of the following: Use the OperationId response element from this operation to provide as a parameter to the DescribeCreateAccountStatus operation. Check the CloudTrail log for the CreateAccountResult event. For information on using CloudTrail with Organizations, see Monitoring the Activity in Your Organization (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_monitoring.html) in the Organizations User Guide. When you call the CreateGovCloudAccount action, you create two accounts: a standalone account in the Amazon Web Services GovCloud (US) Region and an associated account in the commercial Region for billing and support purposes. The account in the commercial Region is automatically a member of the organization whose credentials made the request. Both accounts are associated with the same email address. A role is created in the new account in the commercial Region that allows the management account in the organization in the commercial Region to assume it. An Amazon Web Services GovCloud (US) account is then created and associated with the commercial account that you just created. A role is also created in the new Amazon Web Services GovCloud (US) account that can be assumed by the Amazon Web Services GovCloud (US) account that is associated with the management account of the commercial organization. For more information and to view a diagram that explains how account access works, see Organizations (https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-organizations.html) in the Amazon Web Services GovCloud User Guide. For more information about creating accounts, see Creating an Amazon Web Services account in Your Organization (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html) in the Organizations User Guide. When you create an account in an organization using the Organizations console, API, or CLI commands, the information required for the account to operate as a standalone account is not automatically collected. This includes a payment method and signing the end user license agreement (EULA). If you must remove an account from your organization later, you can do so only after you provide the missing information. Follow the steps at To leave an organization as a member account (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info) in the Organizations User Guide. If you get an exception that indicates that you exceeded your account limits for the organization, contact Amazon Web Services Support (https://console.aws.amazon.com/support/home#/). If you get an exception that indicates that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists, contact Amazon Web Services Support (https://console.aws.amazon.com/support/home#/). Using CreateGovCloudAccount to create multiple temporary accounts isn't recommended. You can only close an account from the Amazon Web Services Billing and Cost Management console, and you must be signed in as the root user. For information on the requirements and process for closing an account, see Closing an Amazon Web Services account (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_close.html) in the Organizations User Guide. When you create a member account with this operation, you can choose whether to create the account with the IAM User and Role Access to Billing Information switch enabled. If you enable it, IAM users and roles that have appropriate permissions can view billing information for the account. If you disable it, only the account root user can access billing information. For information about how to disable this switch for an account, see Granting Access to Your Billing Information and Tools (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html).
#
# POST /
# Returns: record<CreateAccountStatus: record<Id: string, AccountName: string, State: string, RequestedTimestamp: string, CompletedTimestamp: string, AccountId: string, GovCloudAccountId: string, FailureReason: string>>
# operationId: CreateGovCloudAccount
export def "create-gov-cloud-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5 # required
  email: string # Specifies the email address of the owner to assign to the new member account in the commercial Region. This email address must not already be associated with another Amazon Web Services account. You must use a valid email address to complete account creation. The rules for a valid email address: The address must be a minimum of 6 and a maximum of 64 characters long. All characters must be 7-bit ASCII characters. There must be one and only one @ symbol, which separates the local name from the domain name. The local name can't contain any of the following characters: whitespace, " ' ( ) < > [ ] : ; , \ | % & The local name can't begin with a dot (.) The domain name can consist of only the characters [a-z],[A-Z],[0-9], hyphen (-), or dot (.) The domain name can't begin or end with a hyphen (-) or dot (.) The domain name must contain at least one dot You can't access the root user of the account or remove an account that was created with an invalid email address. Like all request parameters for CreateGovCloudAccount, the request for the email address for the Amazon Web Services GovCloud (US) account originates from the commercial Region, not from the Amazon Web Services GovCloud (US) Region. (format: password)
  account_name: string # The friendly name of the member account. The account name can consist of only the characters [a-z],[A-Z],[0-9], hyphen (-), or dot (.) You can't separate characters with a dash (–). (format: password)
  --role-name: string # (Optional) The name of an IAM role that Organizations automatically preconfigures in the new member accounts in both the Amazon Web Services GovCloud (US) Region and in the commercial Region. This role trusts the management account, allowing users in the management account to assume the role, as permitted by the management account administrator. The role has administrator permissions in the new member account. If you don't specify this parameter, the role name defaults to OrganizationAccountAccessRole. For more information about how to use this role to access the member account, see Accessing and Administering the Member Accounts in Your Organization (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html#orgs_manage_accounts_create-cross-account-role) in the Organizations User Guide and steps 2 and 3 in Tutorial: Delegate Access Across Amazon Web Services accounts Using IAM Roles (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html) in the IAM User Guide. The regex pattern (http://wikipedia.org/wiki/regex) that is used to validate this parameter. The pattern can include uppercase letters, lowercase letters, digits with no spaces, and any of the following characters: =,.@-
  --iam-user-access-to-billing: string@iam-user-access-to-billing-completer # If set to ALLOW, the new linked account in the commercial Region enables IAM users to access account billing information if they have the required permissions. If set to DENY, only the root user of the new account can access account billing information. For more information, see Activating Access to the Billing and Cost Management Console (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate) in the Amazon Web Services Billing and Cost Management User Guide. If you don't specify this parameter, the value defaults to ALLOW, and IAM users and roles with the required permissions can access billing information for the new account.
  --tags: list # A list of tags that you want to attach to the newly created account. These tags are attached to the commercial account associated with the GovCloud account, and not to the GovCloud account itself. To add tags to the actual GovCloud account, call the TagResource operation in the GovCloud region after the new GovCloud account exists. For each tag in the list, you must specify both a tag key and a value. You can set the value to an empty string, but you can't set it to null. For more information about tagging, see Tagging Organizations resources (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tagging.html) in the Organizations User Guide. If any one of the tags is not valid or if you exceed the maximum allowed number of tags for an account, then the entire request fails and the account is not created. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.CreateGovCloudAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Email, var: email}, {name: AccountName, var: account_name}, {name: RoleName, var: role_name}, {name: IamUserAccessToBilling, var: iam_user_access_to_billing}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, email: $email, account_name: $account_name, role_name: $role_name, iam_user_access_to_billing: $iam_user_access_to_billing, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Web Services organization. The account whose user is calling the CreateOrganization operation automatically becomes the management account (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started_concepts.html#account) of the new organization. This operation must be called using credentials from the account that is to become the new organization's management account. The principal must also have the relevant IAM permissions. By default (or if you set the FeatureSet parameter to ALL), the new organization is created with all features enabled and service control policies automatically enabled in the root. If you instead choose to create the organization supporting only the consolidated billing features by setting the FeatureSet parameter to CONSOLIDATED_BILLING", no policy types are enabled by default, and you can't use organization policies
#
# POST /
# Returns: record<Organization: record<Id: string, Arn: string, FeatureSet: string, MasterAccountArn: string, MasterAccountId: string, MasterAccountEmail: string, AvailablePolicyTypes: list<record>>>
# operationId: CreateOrganization
export def "create-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6 # required
  --feature-set: string@feature-set-completer # Specifies the feature set supported by the new organization. Each feature set supports different levels of functionality. CONSOLIDATED_BILLING: All member accounts have their bills consolidated to and paid by the management account. For more information, see Consolidated billing (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started_concepts.html#feature-set-cb-only) in the Organizations User Guide. The consolidated billing feature subset isn't available for organizations in the Amazon Web Services GovCloud (US) Region. ALL: In addition to all the features supported by the consolidated billing feature set, the management account can also apply any policy type to any member account in the organization. For more information, see All features (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started_concepts.html#feature-set-all) in the Organizations User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.CreateOrganization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: FeatureSet, var: feature_set}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, feature_set: $feature_set
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an organizational unit (OU) within a root or parent OU. An OU is a container for accounts that enables you to organize your accounts to apply policies according to your business requirements. The number of levels deep that you can nest OUs is dependent upon the policy types enabled for that root. For service control policies, the limit is five. For more information about OUs, see Managing Organizational Units (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_ous.html) in the Organizations User Guide. If the request includes tags, then the requester must have the organizations:TagResource permission. This operation can be called only from the organization's management account.
#
# POST /
# Returns: record<OrganizationalUnit: record<Id: string, Arn: string, Name: string>>
# operationId: CreateOrganizationalUnit
export def "create-organizational-unit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7 # required
  parent_id: string # The unique identifier (ID) of the parent root or OU that you want to create the new OU in. The regex pattern (http://wikipedia.org/wiki/regex) for a parent ID string requires one of the following: Root - A string that begins with "r-" followed by from 4 to 32 lowercase letters or digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that the OU is in). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
  name: string # The friendly name to assign to the new OU.
  --tags: list # A list of tags that you want to attach to the newly created OU. For each tag in the list, you must specify both a tag key and a value. You can set the value to an empty string, but you can't set it to null. For more information about tagging, see Tagging Organizations resources (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tagging.html) in the Organizations User Guide. If any one of the tags is not valid or if you exceed the allowed number of tags for an OU, then the entire request fails and the OU is not created. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.CreateOrganizationalUnit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParentId, var: parent_id}, {name: Name, var: name}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parent_id: $parent_id, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a policy of a specified type that you can attach to a root, an organizational unit (OU), or an individual Amazon Web Services account. For more information about policies and their use, see Managing Organization Policies (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html). If the request includes tags, then the requester must have the organizations:TagResource permission. This operation can be called only from the organization's management account.
#
# POST /
# Returns: record<Policy: record<PolicySummary: record<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, Content: string>>
# operationId: CreatePolicy
export def "create-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8 # required
  content: string # The policy text content to add to the new policy. The text that you supply must adhere to the rules of the policy type you specify in the Type parameter.
  description: string # An optional description to assign to the policy.
  name: string # The friendly name to assign to the policy. The regex pattern (http://wikipedia.org/wiki/regex) that is used to validate this parameter is a string of any of the characters in the ASCII character range.
  type: string@type-completer # The type of policy to create. You can specify one of the following values: AISERVICES_OPT_OUT_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) BACKUP_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html) SERVICE_CONTROL_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html) TAG_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html)
  --tags: list # A list of tags that you want to attach to the newly created policy. For each tag in the list, you must specify both a tag key and a value. You can set the value to an empty string, but you can't set it to null. For more information about tagging, see Tagging Organizations resources (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tagging.html) in the Organizations User Guide. If any one of the tags is not valid or if you exceed the allowed number of tags for a policy, then the entire request fails and the policy is not created. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.CreatePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}, {name: Description, var: description}, {name: Name, var: name}, {name: Type, var: type}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, content: $content, description: $description, name: $name, type: $type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Declines a handshake request. This sets the handshake state to DECLINED and effectively deactivates the request. This operation can be called only from the account that received the handshake. The originator of the handshake can use CancelHandshake instead. The originator can't reactivate a declined request, but can reinitiate the process with a new handshake request. After you decline a handshake, it continues to appear in the results of relevant APIs for only 30 days. After that, it's deleted.
#
# POST /
# Returns: record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>
# operationId: DeclineHandshake
export def "decline-handshake" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9 # required
  handshake_id: string # The unique identifier (ID) of the handshake that you want to decline. You can get the ID from the ListHandshakesForAccount operation. The regex pattern (http://wikipedia.org/wiki/regex) for handshake ID string requires "h-" followed by from 8 to 32 lowercase letters or digits.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DeclineHandshake"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HandshakeId, var: handshake_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, handshake_id: $handshake_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the organization. You can delete an organization only by using credentials from the management account. The organization must be empty of member accounts.
#
# POST /
# operationId: DeleteOrganization
export def "delete-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10 # required
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DeleteOrganization"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an organizational unit (OU) from a root or another OU. You must first remove all accounts and child OUs from the OU that you want to delete. This operation can be called only from the organization's management account.
#
# POST /
# operationId: DeleteOrganizationalUnit
export def "delete-organizational-unit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11 # required
  organizational_unit_id: string # The unique identifier (ID) of the organizational unit that you want to delete. You can get the ID from the ListOrganizationalUnitsForParent operation. The regex pattern (http://wikipedia.org/wiki/regex) for an organizational unit ID string requires "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that contains the OU). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DeleteOrganizationalUnit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OrganizationalUnitId, var: organizational_unit_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, organizational_unit_id: $organizational_unit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified policy from your organization. Before you perform this operation, you must first detach the policy from all organizational units (OUs), roots, and accounts. This operation can be called only from the organization's management account.
#
# POST /
# operationId: DeletePolicy
export def "delete-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12 # required
  policy_id: string # The unique identifier (ID) of the policy that you want to delete. You can get the ID from the ListPolicies or ListPoliciesForTarget operations. The regex pattern (http://wikipedia.org/wiki/regex) for a policy ID string requires "p-" followed by from 8 to 128 lowercase or uppercase letters, digits, or the underscore character (_).
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DeletePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyId, var: policy_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_id: $policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the resource policy from your organization. You can only call this operation from the organization's management account.
#
# POST /
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13 # required
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DeleteResourcePolicy"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified member Amazon Web Services account as a delegated administrator for the specified Amazon Web Services service. Deregistering a delegated administrator can have unintended impacts on the functionality of the enabled Amazon Web Services service. See the documentation for the enabled service before you deregister a delegated administrator so that you understand any potential impacts. You can run this action only for Amazon Web Services services that support this feature. For a current list of services that support it, see the column Supports Delegated Administrator in the table at Amazon Web Services Services that you can use with Organizations (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html) in the Organizations User Guide. This operation can be called only from the organization's management account.
#
# POST /
# operationId: DeregisterDelegatedAdministrator
export def "deregister-delegated-administrator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14 # required
  account_id: string # The account ID number of the member account in the organization that you want to deregister as a delegated administrator.
  service_principal: string # The service principal name of an Amazon Web Services service for which the account is a delegated administrator. Delegated administrator privileges are revoked for only the specified Amazon Web Services service from the member account. If the specified service is the only service for which the member account is a delegated administrator, the operation also revokes Organizations read action permissions.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DeregisterDelegatedAdministrator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountId, var: account_id}, {name: ServicePrincipal, var: service_principal}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_id: $account_id, service_principal: $service_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves Organizations-related information about the specified account. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Account: record<Id: string, Arn: string, Email: string, Name: string, Status: string, JoinedMethod: string, JoinedTimestamp: string>>
# operationId: DescribeAccount
export def "describe-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15 # required
  account_id: string # The unique identifier (ID) of the Amazon Web Services account that you want information about. You can get the ID from the ListAccounts or ListAccountsForParent operations. The regex pattern (http://wikipedia.org/wiki/regex) for an account ID string requires exactly 12 digits.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DescribeAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountId, var: account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the current status of an asynchronous request to create an account. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<CreateAccountStatus: record<Id: string, AccountName: string, State: string, RequestedTimestamp: string, CompletedTimestamp: string, AccountId: string, GovCloudAccountId: string, FailureReason: string>>
# operationId: DescribeCreateAccountStatus
export def "describe-create-account-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  create_account_request_id: string # Specifies the Id value that uniquely identifies the CreateAccount request. You can get the value from the CreateAccountStatus.Id response in an earlier CreateAccount request, or from the ListCreateAccountStatus operation. The regex pattern (http://wikipedia.org/wiki/regex) for a create account request ID string requires "car-" followed by from 8 to 32 lowercase letters or digits.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DescribeCreateAccountStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreateAccountRequestId, var: create_account_request_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, create_account_request_id: $create_account_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the contents of the effective policy for specified policy type and account. The effective policy is the aggregation of any policies of the specified type that the account inherits, plus any policy of that type that is directly attached to the account. This operation applies only to policy types other than service control policies (SCPs). For more information about policy inheritance, see How Policy Inheritance Works (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies-inheritance.html) in the Organizations User Guide. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<EffectivePolicy: record<PolicyContent: string, LastUpdatedTimestamp: string, TargetId: string, PolicyType: string>>
# operationId: DescribeEffectivePolicy
export def "describe-effective-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  policy_type: string@policy-type-completer # The type of policy that you want information about. You can specify one of the following values: AISERVICES_OPT_OUT_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) BACKUP_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html) TAG_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html)
  --target-id: string # When you're signed in as the management account, specify the ID of the account that you want details about. Specifying an organization root or organizational unit (OU) as the target is not supported.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DescribeEffectivePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyType, var: policy_type}, {name: TargetId, var: target_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_type: $policy_type, target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a previously requested handshake. The handshake ID comes from the response to the original InviteAccountToOrganization operation that generated the handshake. You can access handshakes that are ACCEPTED, DECLINED, or CANCELED for only 30 days after they change to that state. They're then deleted and no longer accessible. This operation can be called from any account in the organization.
#
# POST /
# Returns: record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>
# operationId: DescribeHandshake
export def "describe-handshake" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  handshake_id: string # The unique identifier (ID) of the handshake that you want information about. You can get the ID from the original call to InviteAccountToOrganization, or from a call to ListHandshakesForAccount or ListHandshakesForOrganization. The regex pattern (http://wikipedia.org/wiki/regex) for handshake ID string requires "h-" followed by from 8 to 32 lowercase letters or digits.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DescribeHandshake"}]
    body: {content_type: "application/json", kind: json, fields: [{name: HandshakeId, var: handshake_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, handshake_id: $handshake_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the organization that the user's account belongs to. This operation can be called from any account in the organization. Even if a policy type is shown as available in the organization, you can disable it separately at the root level with DisablePolicyType. Use ListRoots to see the status of policy types for a specified root.
#
# POST /
# Returns: record<Organization: record<Id: string, Arn: string, FeatureSet: string, MasterAccountArn: string, MasterAccountId: string, MasterAccountEmail: string, AvailablePolicyTypes: list<record>>>
# operationId: DescribeOrganization
export def "describe-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DescribeOrganization"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about an organizational unit (OU). This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<OrganizationalUnit: record<Id: string, Arn: string, Name: string>>
# operationId: DescribeOrganizationalUnit
export def "describe-organizational-unit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  organizational_unit_id: string # The unique identifier (ID) of the organizational unit that you want details about. You can get the ID from the ListOrganizationalUnitsForParent operation. The regex pattern (http://wikipedia.org/wiki/regex) for an organizational unit ID string requires "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that contains the OU). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DescribeOrganizationalUnit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OrganizationalUnitId, var: organizational_unit_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, organizational_unit_id: $organizational_unit_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a policy. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Policy: record<PolicySummary: record<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, Content: string>>
# operationId: DescribePolicy
export def "describe-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  policy_id: string # The unique identifier (ID) of the policy that you want details about. You can get the ID from the ListPolicies or ListPoliciesForTarget operations. The regex pattern (http://wikipedia.org/wiki/regex) for a policy ID string requires "p-" followed by from 8 to 128 lowercase or uppercase letters, digits, or the underscore character (_).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DescribePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyId, var: policy_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_id: $policy_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about a resource policy. You can only call this operation from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<ResourcePolicy: record<ResourcePolicySummary: record<Id: string, Arn: string>, Content: string>>
# operationId: DescribeResourcePolicy
export def "describe-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DescribeResourcePolicy"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches a policy from a target root, organizational unit (OU), or account. If the policy being detached is a service control policy (SCP), the changes to permissions for Identity and Access Management (IAM) users and roles in affected accounts are immediate. Every root, OU, and account must have at least one SCP attached. If you want to replace the default FullAWSAccess policy with an SCP that limits the permissions that can be delegated, you must attach the replacement SCP before you can remove the default SCP. This is the authorization strategy of an "allow list (https://docs.aws.amazon.com/organizations/latest/userguide/SCP_strategies.html#orgs_policies_allowlist)". If you instead attach a second SCP and leave the FullAWSAccess SCP still attached, and specify "Effect": "Deny" in the second SCP to override the "Effect": "Allow" in the FullAWSAccess policy (or any other attached SCP), you're using the authorization strategy of a "deny list (https://docs.aws.amazon.com/organizations/latest/userguide/SCP_strategies.html#orgs_policies_denylist)". This operation can be called only from the organization's management account.
#
# POST /
# operationId: DetachPolicy
export def "detach-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  policy_id: string # The unique identifier (ID) of the policy you want to detach. You can get the ID from the ListPolicies or ListPoliciesForTarget operations. The regex pattern (http://wikipedia.org/wiki/regex) for a policy ID string requires "p-" followed by from 8 to 128 lowercase or uppercase letters, digits, or the underscore character (_).
  target_id: string # The unique identifier (ID) of the root, OU, or account that you want to detach the policy from. You can get the ID from the ListRoots, ListOrganizationalUnitsForParent, or ListAccounts operations. The regex pattern (http://wikipedia.org/wiki/regex) for a target ID string requires one of the following: Root - A string that begins with "r-" followed by from 4 to 32 lowercase letters or digits. Account - A string that consists of exactly 12 digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that the OU is in). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DetachPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyId, var: policy_id}, {name: TargetId, var: target_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_id: $policy_id, target_id: $target_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables the integration of an Amazon Web Services service (the service that is specified by ServicePrincipal) with Organizations. When you disable integration, the specified service no longer can create a service-linked role (https://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html) in new accounts in your organization. This means the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from Organizations. We strongly recommend that you don't use this command to disable integration between Organizations and the specified Amazon Web Services service. Instead, use the console or commands that are provided by the specified service. This lets the trusted service perform any required initialization when enabling trusted access, such as creating any required resources and any required clean up of resources when disabling trusted access. For information about how to disable trusted service access to your organization using the trusted service, see the Learn more link under the Supports Trusted Access column at Amazon Web Services services that you can use with Organizations (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html). on this page. If you disable access by using this command, it causes the following actions to occur: The service can no longer create a service-linked role in the accounts in your organization. This means that the service can't perform operations on your behalf on any new accounts in your organization. The service can still perform operations in older accounts until the service completes its clean-up from Organizations. The service can no longer perform tasks in the member accounts in the organization, unless those operations are explicitly permitted by the IAM policies that are attached to your roles. This includes any data aggregation from the member accounts to the management account, or to a delegated administrator account, where relevant. Some services detect this and clean up any remaining data or resources related to the integration, while other services stop accessing the organization but leave any historical data and configuration in place to support a possible re-enabling of the integration. Using the other service's console or commands to disable the integration ensures that the other service is aware that it can clean up any resources that are required only for the integration. How the service cleans up its resources in the organization's accounts depends on that service. For more information, see the documentation for the other Amazon Web Services service. After you perform the DisableAWSServiceAccess operation, the specified service can no longer perform operations in your organization's accounts For more information about integrating other services with Organizations, including the list of services that work with Organizations, see Integrating Organizations with Other Amazon Web Services Services (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html) in the Organizations User Guide. This operation can be called only from the organization's management account.
#
# POST /
# operationId: DisableAWSServiceAccess
export def "disable-aws-service-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  service_principal: string # The service principal name of the Amazon Web Services service for which you want to disable integration with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DisableAWSServiceAccess"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServicePrincipal, var: service_principal}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_principal: $service_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables an organizational policy type in a root. A policy of a certain type can be attached to entities in a root only if that type is enabled in the root. After you perform this operation, you no longer can attach policies of the specified type to that root or to any organizational unit (OU) or account in that root. You can undo this by using the EnablePolicyType operation. This is an asynchronous request that Amazon Web Services performs in the background. If you disable a policy type for a root, it still appears enabled for the organization if all features (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html) are enabled for the organization. Amazon Web Services recommends that you first use ListRoots to see the status of policy types for a specified root, and then use this operation. This operation can be called only from the organization's management account. To view the status of available policy types in the organization, use DescribeOrganization.
#
# POST /
# Returns: record<Root: record<Id: string, Arn: string, Name: string, PolicyTypes: list<record>>>
# operationId: DisablePolicyType
export def "disable-policy-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  root_id: string # The unique identifier (ID) of the root in which you want to disable a policy type. You can get the ID from the ListRoots operation. The regex pattern (http://wikipedia.org/wiki/regex) for a root ID string requires "r-" followed by from 4 to 32 lowercase letters or digits.
  policy_type: string@policy-type-completer-1 # The policy type that you want to disable in this root. You can specify one of the following values: AISERVICES_OPT_OUT_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) BACKUP_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html) SERVICE_CONTROL_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html) TAG_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.DisablePolicyType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RootId, var: root_id}, {name: PolicyType, var: policy_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, root_id: $root_id, policy_type: $policy_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the integration of an Amazon Web Services service (the service that is specified by ServicePrincipal) with Organizations. When you enable integration, you allow the specified service to create a service-linked role (https://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html) in all the accounts in your organization. This allows the service to perform operations on your behalf in your organization and its accounts. We recommend that you enable integration between Organizations and the specified Amazon Web Services service by using the console or commands that are provided by the specified service. Doing so ensures that the service is aware that it can create the resources that are required for the integration. How the service creates those resources in the organization's accounts depends on that service. For more information, see the documentation for the other Amazon Web Services service. For more information about enabling services to integrate with Organizations, see Integrating Organizations with Other Amazon Web Services Services (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html) in the Organizations User Guide. You can only call this operation from the organization's management account and only if the organization has enabled all features (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html).
#
# POST /
# operationId: EnableAWSServiceAccess
export def "enable-aws-service-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  service_principal: string # The service principal name of the Amazon Web Services service for which you want to enable integration with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.EnableAWSServiceAccess"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServicePrincipal, var: service_principal}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_principal: $service_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables all features in an organization. This enables the use of organization policies that can restrict the services and actions that can be called in each account. Until you enable all features, you have access only to consolidated billing, and you can't use any of the advanced account administration features that Organizations supports. For more information, see Enabling All Features in Your Organization (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_org_support-all-features.html) in the Organizations User Guide. This operation is required only for organizations that were created explicitly with only the consolidated billing features enabled. Calling this operation sends a handshake to every invited account in the organization. The feature set change can be finalized and the additional features enabled only after all administrators in the invited accounts approve the change by accepting the handshake. After you enable all features, you can separately enable or disable individual policy types in a root using EnablePolicyType and DisablePolicyType. To see the status of policy types in a root, use ListRoots. After all invited member accounts accept the handshake, you finalize the feature set change by accepting the handshake that contains "Action": "ENABLE_ALL_FEATURES". This completes the change. After you enable all features in your organization, the management account in the organization can apply policies on all member accounts. These policies can restrict what users and even administrators in those accounts can do. The management account can apply policies that prevent accounts from leaving the organization. Ensure that your account administrators are aware of this. This operation can be called only from the organization's management account.
#
# POST /
# Returns: record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>
# operationId: EnableAllFeatures
export def "enable-all-features" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.EnableAllFeatures"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables a policy type in a root. After you enable a policy type in a root, you can attach policies of that type to the root, any organizational unit (OU), or account in that root. You can undo this by using the DisablePolicyType operation. This is an asynchronous request that Amazon Web Services performs in the background. Amazon Web Services recommends that you first use ListRoots to see the status of policy types for a specified root, and then use this operation. This operation can be called only from the organization's management account. You can enable a policy type in a root only if that policy type is available in the organization. To view the status of available policy types in the organization, use DescribeOrganization.
#
# POST /
# Returns: record<Root: record<Id: string, Arn: string, Name: string, PolicyTypes: list<record>>>
# operationId: EnablePolicyType
export def "enable-policy-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  root_id: string # The unique identifier (ID) of the root in which you want to enable a policy type. You can get the ID from the ListRoots operation. The regex pattern (http://wikipedia.org/wiki/regex) for a root ID string requires "r-" followed by from 4 to 32 lowercase letters or digits.
  policy_type: string@policy-type-completer-1 # The policy type that you want to enable. You can specify one of the following values: AISERVICES_OPT_OUT_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) BACKUP_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html) SERVICE_CONTROL_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html) TAG_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.EnablePolicyType"}]
    body: {content_type: "application/json", kind: json, fields: [{name: RootId, var: root_id}, {name: PolicyType, var: policy_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, root_id: $root_id, policy_type: $policy_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sends an invitation to another account to join your organization as a member account. Organizations sends email on your behalf to the email address that is associated with the other account's owner. The invitation is implemented as a Handshake whose details are in the response. You can invite Amazon Web Services accounts only from the same seller as the management account. For example, if your organization's management account was created by Amazon Internet Services Pvt. Ltd (AISPL), an Amazon Web Services seller in India, you can invite only other AISPL accounts to your organization. You can't combine accounts from AISPL and Amazon Web Services or from any other Amazon Web Services seller. For more information, see Consolidated Billing in India (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/useconsolidatedbilliing-India.html). If you receive an exception that indicates that you exceeded your account limits for the organization or that the operation failed because your organization is still initializing, wait one hour and then try again. If the error persists after an hour, contact Amazon Web Services Support (https://console.aws.amazon.com/support/home#/). If the request includes tags, then the requester must have the organizations:TagResource permission. This operation can be called only from the organization's management account.
#
# POST /
# Returns: record<Handshake: record<Id: string, Arn: string, Parties: list<record>, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list<record>>>
# operationId: InviteAccountToOrganization
export def "invite-account-to-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  target: record # Identifies a participant in a handshake. — shape: {Id: string, Type: "ACCOUNT"|"ORGANIZATION"|"EMAIL"}
  --notes: string # Additional information that you want to include in the generated email to the recipient account owner. (format: password)
  --tags: list # A list of tags that you want to attach to the account when it becomes a member of the organization. For each tag in the list, you must specify both a tag key and a value. You can set the value to an empty string, but you can't set it to null. For more information about tagging, see Tagging Organizations resources (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tagging.html) in the Organizations User Guide. Any tags in the request are checked for compliance with any applicable tag policies when the request is made. The request is rejected if the tags in the request don't match the requirements of the policy at that time. Tag policy compliance is not checked again when the invitation is accepted and the tags are actually attached to the account. That means that if the tag policy changes between the invitation and the acceptance, then that tags could potentially be non-compliant. If any one of the tags is not valid or if you exceed the allowed number of tags for an account, then the entire request fails and invitations are not sent. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.InviteAccountToOrganization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Target, var: target}, {name: Notes, var: notes}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, target: $target, notes: $notes, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a member account from its parent organization. This version of the operation is performed by the account that wants to leave. To remove a member account as a user in the management account, use RemoveAccountFromOrganization instead. This operation can be called only from a member account in the organization. The management account in an organization with all features enabled can set service control policies (SCPs) that can restrict what administrators of member accounts can do. This includes preventing them from successfully calling LeaveOrganization and leaving the organization. You can leave an organization as a member account only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the Organizations console, API, or CLI commands, the information required of standalone accounts is not automatically collected. For each account that you want to make standalone, you must perform the following steps. If any of the steps are already completed for this account, that step doesn't appear. Choose a support plan Provide and verify the required contact information Provide a current payment method Amazon Web Services uses the payment method to charge for any billable (not free tier) Amazon Web Services activity that occurs while the account isn't attached to an organization. Follow the steps at To leave an organization when all required account information has not yet been provided (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info) in the Organizations User Guide. The account that you want to leave must not be a delegated administrator account for any Amazon Web Services service enabled for your organization. If the account is a delegated administrator, you must first change the delegated administrator account to another account that is remaining in the organization. You can leave an organization only after you enable IAM user access to billing in your account. For more information, see Activating Access to the Billing and Cost Management Console (https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/grantaccess.html#ControllingAccessWebsite-Activate) in the Amazon Web Services Billing and Cost Management User Guide. After the account leaves the organization, all tags that were attached to the account object in the organization are deleted. Amazon Web Services accounts outside of an organization do not support tags. A newly created account has a waiting period before it can be removed from its organization. If you get an error that indicates that a wait period is required, then try again in a few days.
#
# POST /
# operationId: LeaveOrganization
export def "leave-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.LeaveOrganization"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the Amazon Web Services services that you enabled to integrate with your organization. After a service on this list creates the resources that it requires for the integration, it can perform operations on your organization and its accounts. For more information about integrating other services with Organizations, including the list of services that currently work with Organizations, see Integrating Organizations with Other Amazon Web Services Services (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services.html) in the Organizations User Guide. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<EnabledServicePrincipals: table<ServicePrincipal: string, DateEnabled: string>, NextToken: string>
# operationId: ListAWSServiceAccessForOrganization
export def "list-aws-service-access-for-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListAWSServiceAccessForOrganization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the accounts in the organization. To request only the accounts in a specified root or organizational unit (OU), use the ListAccountsForParent operation instead. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Accounts: table<Id: string, Arn: string, Email: string, Name: string, Status: string, JoinedMethod: string, JoinedTimestamp: string>, NextToken: string>
# operationId: ListAccounts
export def "list-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32 # required
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListAccounts"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the accounts in an organization that are contained by the specified target root or organizational unit (OU). If you specify the root, you get a list of all the accounts that aren't in any OU. If you specify an OU, you get a list of all the accounts in only that OU and not in any child OUs. To get a list of all accounts in the organization, use the ListAccounts operation. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Accounts: table<Id: string, Arn: string, Email: string, Name: string, Status: string, JoinedMethod: string, JoinedTimestamp: string>, NextToken: string>
# operationId: ListAccountsForParent
export def "list-accounts-for-parent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  parent_id: string # The unique identifier (ID) for the parent root or organization unit (OU) whose accounts you want to list.
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListAccountsForParent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParentId, var: parent_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parent_id: $parent_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the organizational units (OUs) or accounts that are contained in the specified parent OU or root. This operation, along with ListParents enables you to traverse the tree structure that makes up this root. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Children: table<Id: string, Type: string>, NextToken: string>
# operationId: ListChildren
export def "list-children" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34 # required
  parent_id: string # The unique identifier (ID) for the parent root or OU whose children you want to list. The regex pattern (http://wikipedia.org/wiki/regex) for a parent ID string requires one of the following: Root - A string that begins with "r-" followed by from 4 to 32 lowercase letters or digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that the OU is in). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
  child_type: string@child-type-completer # Filters the output to include only the specified child type.
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListChildren"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParentId, var: parent_id}, {name: ChildType, var: child_type}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parent_id: $parent_id, child_type: $child_type, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the account creation requests that match the specified status that is currently being tracked for the organization. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<CreateAccountStatuses: table<Id: string, AccountName: string, State: string, RequestedTimestamp: string, CompletedTimestamp: string, AccountId: string, GovCloudAccountId: string, FailureReason: string>, NextToken: string>
# operationId: ListCreateAccountStatus
export def "list-create-account-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35 # required
  --states: list<string> # A list of one or more states that you want included in the response. If this parameter isn't present, all requests are included in the response.
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListCreateAccountStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: States, var: states}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, states: $states, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon Web Services accounts that are designated as delegated administrators in this organization. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<DelegatedAdministrators: table<Id: string, Arn: string, Email: string, Name: string, Status: string, JoinedMethod: string, JoinedTimestamp: string, DelegationEnabledDate: string>, NextToken: string>
# operationId: ListDelegatedAdministrators
export def "list-delegated-administrators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36 # required
  --service-principal: string # Specifies a service principal name. If specified, then the operation lists the delegated administrators only for the specified service. If you don't specify a service principal, the operation lists all delegated administrators for all services in your organization.
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListDelegatedAdministrators"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ServicePrincipal, var: service_principal}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_principal: $service_principal, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the Amazon Web Services services for which the specified account is a delegated administrator. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<DelegatedServices: table<ServicePrincipal: string, DelegationEnabledDate: string>, NextToken: string>
# operationId: ListDelegatedServicesForAccount
export def "list-delegated-services-for-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  account_id: string # The account ID number of a delegated administrator account in the organization.
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListDelegatedServicesForAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountId, var: account_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_id: $account_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the current handshakes that are associated with the account of the requesting user. Handshakes that are ACCEPTED, DECLINED, CANCELED, or EXPIRED appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called from any account in the organization.
#
# POST /
# Returns: record<Handshakes: table<Id: string, Arn: string, Parties: list, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list>, NextToken: string>
# operationId: ListHandshakesForAccount
export def "list-handshakes-for-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38 # required
  --filter: record # Specifies the criteria that are used to select the handshakes for the operation. — shape: {ActionType?: "INVITE"|"ENABLE_ALL_FEATURES"|"APPROVE_ALL_FEATURES"|"ADD_ORGANIZATIONS_SERVICE_LINKED_ROLE", ParentHandshakeId?: string}
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListHandshakesForAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the handshakes that are associated with the organization that the requesting user is part of. The ListHandshakesForOrganization operation returns a list of handshake structures. Each structure contains details and status about a handshake. Handshakes that are ACCEPTED, DECLINED, CANCELED, or EXPIRED appear in the results of this API for only 30 days after changing to that state. After that, they're deleted and no longer accessible. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Handshakes: table<Id: string, Arn: string, Parties: list, State: string, RequestedTimestamp: string, ExpirationTimestamp: string, Action: string, Resources: list>, NextToken: string>
# operationId: ListHandshakesForOrganization
export def "list-handshakes-for-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-39 # required
  --filter: record # Specifies the criteria that are used to select the handshakes for the operation. — shape: {ActionType?: "INVITE"|"ENABLE_ALL_FEATURES"|"APPROVE_ALL_FEATURES"|"ADD_ORGANIZATIONS_SERVICE_LINKED_ROLE", ParentHandshakeId?: string}
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListHandshakesForOrganization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the organizational units (OUs) in a parent organizational unit or root. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<OrganizationalUnits: table<Id: string, Arn: string, Name: string>, NextToken: string>
# operationId: ListOrganizationalUnitsForParent
export def "list-organizational-units-for-parent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  parent_id: string # The unique identifier (ID) of the root or OU whose child OUs you want to list. The regex pattern (http://wikipedia.org/wiki/regex) for a parent ID string requires one of the following: Root - A string that begins with "r-" followed by from 4 to 32 lowercase letters or digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that the OU is in). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListOrganizationalUnitsForParent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ParentId, var: parent_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, parent_id: $parent_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the root or organizational units (OUs) that serve as the immediate parent of the specified child OU or account. This operation, along with ListChildren enables you to traverse the tree structure that makes up this root. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service. In the current release, a child can have only a single parent.
#
# POST /
# Returns: record<Parents: table<Id: string, Type: string>, NextToken: string>
# operationId: ListParents
export def "list-parents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41 # required
  child_id: string # The unique identifier (ID) of the OU or account whose parent containers you want to list. Don't specify a root. The regex pattern (http://wikipedia.org/wiki/regex) for a child ID string requires one of the following: Account - A string that consists of exactly 12 digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that contains the OU). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListParents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ChildId, var: child_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, child_id: $child_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the list of all policies in an organization of a specified type. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Policies: table<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, NextToken: string>
# operationId: ListPolicies
export def "list-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  filter: string@filter-completer # Specifies the type of policy that you want to include in the response. You must specify one of the following values: AISERVICES_OPT_OUT_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) BACKUP_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html) SERVICE_CONTROL_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html) TAG_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html)
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListPolicies"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the policies that are directly attached to the specified target root, organizational unit (OU), or account. You must specify the policy type that you want included in the returned list. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Policies: table<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, NextToken: string>
# operationId: ListPoliciesForTarget
export def "list-policies-for-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  target_id: string # The unique identifier (ID) of the root, organizational unit, or account whose policies you want to list. The regex pattern (http://wikipedia.org/wiki/regex) for a target ID string requires one of the following: Root - A string that begins with "r-" followed by from 4 to 32 lowercase letters or digits. Account - A string that consists of exactly 12 digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that the OU is in). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
  filter: string@filter-completer # The type of policy that you want to include in the returned list. You must specify one of the following values: AISERVICES_OPT_OUT_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_ai-opt-out.html) BACKUP_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html) SERVICE_CONTROL_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html) TAG_POLICY (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html)
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListPoliciesForTarget"}]
    body: {content_type: "application/json", kind: json, fields: [{name: TargetId, var: target_id}, {name: Filter, var: filter}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, target_id: $target_id, filter: $filter, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the roots that are defined in the current organization. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service. Policy types can be enabled and disabled in roots. This is distinct from whether they're available in the organization. When you enable all features, you make policy types available for use in that organization. Individual policy types can then be enabled and disabled in a root. To see the availability of a policy type in an organization, use DescribeOrganization.
#
# POST /
# Returns: record<Roots: table<Id: string, Arn: string, Name: string, PolicyTypes: list>, NextToken: string>
# operationId: ListRoots
export def "list-roots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListRoots"}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists tags that are attached to the specified resource. You can attach tags to the following resources in Organizations. Amazon Web Services account Organization root Organizational unit (OU) Policy (any type) This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Tags: table<Key: string, Value: string>, NextToken: string>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  resource_id: string # The ID of the resource with the tags to list. You can specify any of the following taggable resources. Amazon Web Services account – specify the account ID number. Organizational unit – specify the OU ID that begins with ou- and looks similar to: ou-1a2b-34uvwxyz Root – specify the root ID that begins with r- and looks similar to: r-1a2b Policy – specify the policy ID that begins with p- andlooks similar to: p-12abcdefg3
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: NextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the roots, organizational units (OUs), and accounts that the specified policy is attached to. Always check the NextToken response parameter for a null value when calling a List* operation. These operations can occasionally return an empty set of results even when there are more results available. The NextToken response parameter value is null only when there are no more results to display. This operation can be called only from the organization's management account or by a member account that is a delegated administrator for an Amazon Web Services service.
#
# POST /
# Returns: record<Targets: table<TargetId: string, Arn: string, Name: string, Type: string>, NextToken: string>
# operationId: ListTargetsForPolicy
export def "list-targets-for-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  policy_id: string # The unique identifier (ID) of the policy whose attachments you want to know. The regex pattern (http://wikipedia.org/wiki/regex) for a policy ID string requires "p-" followed by from 8 to 128 lowercase or uppercase letters, digits, or the underscore character (_).
  --body-next-token: string # The parameter for receiving additional results if you receive a NextToken response in a previous request. A NextToken response indicates that more output is available. Set this parameter to the value of the previous call's NextToken response to indicate where the output should continue from. (spec name: NextToken)
  --body-max-results: int # The total number of results that you want included on each page of the response. If you do not include this parameter, it defaults to a value that is specific to the operation. If additional items exist beyond the maximum you specify, the NextToken response element is present and has a value (is not null). Include that value as the NextToken request parameter in the next call to the operation to get the next part of the results. Note that Organizations might return fewer results than the maximum even when there are more results available. You should check NextToken after every operation to ensure that you receive all of the results. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.ListTargetsForPolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyId, var: policy_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_id: $policy_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves an account from its current source parent root or organizational unit (OU) to the specified destination parent root or OU. This operation can be called only from the organization's management account.
#
# POST /
# operationId: MoveAccount
export def "move-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  account_id: string # The unique identifier (ID) of the account that you want to move. The regex pattern (http://wikipedia.org/wiki/regex) for an account ID string requires exactly 12 digits.
  source_parent_id: string # The unique identifier (ID) of the root or organizational unit that you want to move the account from. The regex pattern (http://wikipedia.org/wiki/regex) for a parent ID string requires one of the following: Root - A string that begins with "r-" followed by from 4 to 32 lowercase letters or digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that the OU is in). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
  destination_parent_id: string # The unique identifier (ID) of the root or organizational unit that you want to move the account to. The regex pattern (http://wikipedia.org/wiki/regex) for a parent ID string requires one of the following: Root - A string that begins with "r-" followed by from 4 to 32 lowercase letters or digits. Organizational unit (OU) - A string that begins with "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that the OU is in). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.MoveAccount"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountId, var: account_id}, {name: SourceParentId, var: source_parent_id}, {name: DestinationParentId, var: destination_parent_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_id: $account_id, source_parent_id: $source_parent_id, destination_parent_id: $destination_parent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a resource policy. You can only call this operation from the organization's management account.
#
# POST /
# Returns: record<ResourcePolicy: record<ResourcePolicySummary: record<Id: string, Arn: string>, Content: string>>
# operationId: PutResourcePolicy
export def "put-resource-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  content: string # If provided, the new content for the resource policy. The text must be correctly formatted JSON that complies with the syntax for the resource policy's type. For more information, see Service Control Policy Syntax (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_scp-syntax.html) in the Organizations User Guide.
  --tags: list # A list of tags that you want to attach to the newly created resource policy. For each tag in the list, you must specify both a tag key and a value. You can set the value to an empty string, but you can't set it to null. For more information about tagging, see Tagging Organizations resources (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tagging.html) in the Organizations User Guide. Calls with tags apply to the initial creation of the resource policy, otherwise an exception is thrown. If any one of the tags is not valid or if you exceed the allowed number of tags for the resource policy, then the entire request fails and the resource policy is not created. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.PutResourcePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: Content, var: content}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, content: $content, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the specified member account to administer the Organizations features of the specified Amazon Web Services service. It grants read-only access to Organizations service data. The account still requires IAM permissions to access and administer the Amazon Web Services service. You can run this action only for Amazon Web Services services that support this feature. For a current list of services that support it, see the column Supports Delegated Administrator in the table at Amazon Web Services Services that you can use with Organizations (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html) in the Organizations User Guide. This operation can be called only from the organization's management account.
#
# POST /
# operationId: RegisterDelegatedAdministrator
export def "register-delegated-administrator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49 # required
  account_id: string # The account ID number of the member account in the organization to register as a delegated administrator.
  service_principal: string # The service principal of the Amazon Web Services service for which you want to make the member account a delegated administrator.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.RegisterDelegatedAdministrator"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountId, var: account_id}, {name: ServicePrincipal, var: service_principal}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_id: $account_id, service_principal: $service_principal
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the specified account from the organization. The removed account becomes a standalone account that isn't a member of any organization. It's no longer subject to any policies and is responsible for its own bill payments. The organization's management account is no longer charged for any expenses accrued by the member account after it's removed from the organization. This operation can be called only from the organization's management account. Member accounts can remove themselves with LeaveOrganization instead. You can remove an account from your organization only if the account is configured with the information required to operate as a standalone account. When you create an account in an organization using the Organizations console, API, or CLI commands, the information required of standalone accounts is not automatically collected. For an account that you want to make standalone, you must choose a support plan, provide and verify the required contact information, and provide a current payment method. Amazon Web Services uses the payment method to charge for any billable (not free tier) Amazon Web Services activity that occurs while the account isn't attached to an organization. To remove an account that doesn't yet have this information, you must sign in as the member account and follow the steps at To leave an organization when all required account information has not yet been provided (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_remove.html#leave-without-all-info) in the Organizations User Guide. The account that you want to leave must not be a delegated administrator account for any Amazon Web Services service enabled for your organization. If the account is a delegated administrator, you must first change the delegated administrator account to another account that is remaining in the organization. After the account leaves the organization, all tags that were attached to the account object in the organization are deleted. Amazon Web Services accounts outside of an organization do not support tags.
#
# POST /
# operationId: RemoveAccountFromOrganization
export def "remove-account-from-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50 # required
  account_id: string # The unique identifier (ID) of the member account that you want to remove from the organization. The regex pattern (http://wikipedia.org/wiki/regex) for an account ID string requires exactly 12 digits.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.RemoveAccountFromOrganization"}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountId, var: account_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more tags to the specified resource. Currently, you can attach tags to the following resources in Organizations. Amazon Web Services account Organization root Organizational unit (OU) Policy (any type) This operation can be called only from the organization's management account.
#
# POST /
# operationId: TagResource
export def "tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51 # required
  resource_id: string # The ID of the resource to add a tag to. You can specify any of the following taggable resources. Amazon Web Services account – specify the account ID number. Organizational unit – specify the OU ID that begins with ou- and looks similar to: ou-1a2b-34uvwxyz Root – specify the root ID that begins with r- and looks similar to: r-1a2b Policy – specify the policy ID that begins with p- andlooks similar to: p-12abcdefg3
  tags: list # A list of tags to add to the specified resource. For each tag in the list, you must specify both a tag key and a value. The value can be an empty string, but you can't set it to null. If any one of the tags is not valid or if you exceed the maximum allowed number of tags for a resource, then the entire request fails. — item shape: {Key: string, Value: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes any tags with the specified keys from the specified resource. You can attach tags to the following resources in Organizations. Amazon Web Services account Organization root Organizational unit (OU) Policy (any type) This operation can be called only from the organization's management account.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-52 # required
  resource_id: string # The ID of the resource to remove a tag from. You can specify any of the following taggable resources. Amazon Web Services account – specify the account ID number. Organizational unit – specify the OU ID that begins with ou- and looks similar to: ou-1a2b-34uvwxyz Root – specify the root ID that begins with r- and looks similar to: r-1a2b Policy – specify the policy ID that begins with p- andlooks similar to: p-12abcdefg3
  tag_keys: list<string> # The list of keys for tags to remove from the specified resource.
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: ResourceId, var: resource_id}, {name: TagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_id: $resource_id, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renames the specified organizational unit (OU). The ID and ARN don't change. The child OUs and accounts remain in place, and any attached policies of the OU remain attached. This operation can be called only from the organization's management account.
#
# POST /
# Returns: record<OrganizationalUnit: record<Id: string, Arn: string, Name: string>>
# operationId: UpdateOrganizationalUnit
export def "update-organizational-unit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53 # required
  organizational_unit_id: string # The unique identifier (ID) of the OU that you want to rename. You can get the ID from the ListOrganizationalUnitsForParent operation. The regex pattern (http://wikipedia.org/wiki/regex) for an organizational unit ID string requires "ou-" followed by from 4 to 32 lowercase letters or digits (the ID of the root that contains the OU). This string is followed by a second "-" dash and from 8 to 32 additional lowercase letters or digits.
  --name: string # The new name that you want to assign to the OU. The regex pattern (http://wikipedia.org/wiki/regex) that is used to validate this parameter is a string of any of the characters in the ASCII character range.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.UpdateOrganizationalUnit"}]
    body: {content_type: "application/json", kind: json, fields: [{name: OrganizationalUnitId, var: organizational_unit_id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, organizational_unit_id: $organizational_unit_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing policy with a new name, description, or content. If you don't supply any parameter, that value remains unchanged. You can't change a policy's type. This operation can be called only from the organization's management account.
#
# POST /
# Returns: record<Policy: record<PolicySummary: record<Id: string, Arn: string, Name: string, Description: string, Type: string, AwsManaged: bool>, Content: string>>
# operationId: UpdatePolicy
export def "update-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54 # required
  policy_id: string # The unique identifier (ID) of the policy that you want to update. The regex pattern (http://wikipedia.org/wiki/regex) for a policy ID string requires "p-" followed by from 8 to 128 lowercase or uppercase letters, digits, or the underscore character (_).
  --name: string # If provided, the new name for the policy. The regex pattern (http://wikipedia.org/wiki/regex) that is used to validate this parameter is a string of any of the characters in the ASCII character range.
  --description: string # If provided, the new description for the policy.
  --content: string # If provided, the new content for the policy. The text must be correctly formatted JSON that complies with the syntax for the policy's type. For more information, see Service Control Policy Syntax (https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_scp-syntax.html) in the Organizations User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AWSOrganizationsV20161128.UpdatePolicy"}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyId, var: policy_id}, {name: Name, var: name}, {name: Description, var: description}, {name: Content, var: content}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, policy_id: $policy_id, name: $name, description: $description, content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
