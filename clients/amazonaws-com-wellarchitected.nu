# Auto-generated client for AWS Well-Architected Tool v2020-03-31
# Source: https://api.apis.guru/v2/specs/amazonaws.com/wellarchitected/2020-03-31/openapi.json
# Auth: --token flag or $env.AWS_WELL_ARCHITECTED_TOOL_TOKEN

const CLIENT = {
  base_url: "http://wellarchitected.us-east-1.amazonaws.com"
  token_env_var: "AWS_WELL_ARCHITECTED_TOOL_TOKEN"
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

def base-url-completer [] { ["http://wellarchitected.us-east-1.amazonaws.com" "http://wellarchitected.us-east-2.amazonaws.com" "http://wellarchitected.us-west-1.amazonaws.com" "http://wellarchitected.us-west-2.amazonaws.com" "http://wellarchitected.us-gov-west-1.amazonaws.com" "http://wellarchitected.us-gov-east-1.amazonaws.com" "http://wellarchitected.ca-central-1.amazonaws.com" "http://wellarchitected.eu-north-1.amazonaws.com" "http://wellarchitected.eu-west-1.amazonaws.com" "http://wellarchitected.eu-west-2.amazonaws.com" "http://wellarchitected.eu-west-3.amazonaws.com" "http://wellarchitected.eu-central-1.amazonaws.com" "http://wellarchitected.eu-south-1.amazonaws.com" "http://wellarchitected.af-south-1.amazonaws.com" "http://wellarchitected.ap-northeast-1.amazonaws.com" "http://wellarchitected.ap-northeast-2.amazonaws.com" "http://wellarchitected.ap-northeast-3.amazonaws.com" "http://wellarchitected.ap-southeast-1.amazonaws.com" "http://wellarchitected.ap-southeast-2.amazonaws.com" "http://wellarchitected.ap-east-1.amazonaws.com" "http://wellarchitected.ap-south-1.amazonaws.com" "http://wellarchitected.sa-east-1.amazonaws.com" "http://wellarchitected.me-south-1.amazonaws.com" "https://wellarchitected.us-east-1.amazonaws.com" "https://wellarchitected.us-east-2.amazonaws.com" "https://wellarchitected.us-west-1.amazonaws.com" "https://wellarchitected.us-west-2.amazonaws.com" "https://wellarchitected.us-gov-west-1.amazonaws.com" "https://wellarchitected.us-gov-east-1.amazonaws.com" "https://wellarchitected.ca-central-1.amazonaws.com" "https://wellarchitected.eu-north-1.amazonaws.com" "https://wellarchitected.eu-west-1.amazonaws.com" "https://wellarchitected.eu-west-2.amazonaws.com" "https://wellarchitected.eu-west-3.amazonaws.com" "https://wellarchitected.eu-central-1.amazonaws.com" "https://wellarchitected.eu-south-1.amazonaws.com" "https://wellarchitected.af-south-1.amazonaws.com" "https://wellarchitected.ap-northeast-1.amazonaws.com" "https://wellarchitected.ap-northeast-2.amazonaws.com" "https://wellarchitected.ap-northeast-3.amazonaws.com" "https://wellarchitected.ap-southeast-1.amazonaws.com" "https://wellarchitected.ap-southeast-2.amazonaws.com" "https://wellarchitected.ap-east-1.amazonaws.com" "https://wellarchitected.ap-south-1.amazonaws.com" "https://wellarchitected.sa-east-1.amazonaws.com" "https://wellarchitected.me-south-1.amazonaws.com" "http://wellarchitected.cn-north-1.amazonaws.com.cn" "http://wellarchitected.cn-northwest-1.amazonaws.com.cn" "https://wellarchitected.cn-north-1.amazonaws.com.cn" "https://wellarchitected.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["ACCEPTED" "ASSOCIATED" "ASSOCIATING" "EXPIRED" "FAILED" "PENDING" "REJECTED" "REVOKED"] }
def environment-completer [] { ["PREPRODUCTION" "PRODUCTION"] }
def permission-type-completer [] { ["CONTRIBUTOR" "READONLY"] }
def lens-status-completer [] { ["ALL" "DRAFT" "PUBLISHED"] }
def reason-completer [] { ["ARCHITECTURE_CONSTRAINTS" "BUSINESS_PRIORITIES" "NONE" "OTHER" "OUT_OF_SCOPE"] }
def format-completer [] { ["JSON" "PDF"] }
def improvement-status-completer [] { ["COMPLETE" "IN_PROGRESS" "NOT_APPLICABLE" "NOT_STARTED" "RISK_ACKNOWLEDGED"] }
def lens-type-completer [] { ["AWS_OFFICIAL" "CUSTOM_SELF" "CUSTOM_SHARED"] }
def share-resource-type-completer [] { ["LENS" "WORKLOAD"] }
def organization-sharing-status-completer [] { ["DISABLED" "ENABLED"] }
def share-invitation-action-completer [] { ["ACCEPT" "REJECT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-lens-share: "record<ShareId: string>"
    list-lens-shares: "record<LensShareSummaries: table<ShareId: string, SharedWith: string, Status: string, StatusMessage: string>, NextToken: string>"
    create-lens-version: "record<LensArn: string, LensVersion: string>"
    create-milestone: "record<WorkloadId: string, MilestoneNumber: int>"
    create-workload: "record<WorkloadId: string, WorkloadArn: string>"
    create-workload-share: "record<WorkloadId: string, ShareId: string>"
    list-workload-shares: "record<WorkloadId: string, WorkloadShareSummaries: table<ShareId: string, SharedWith: string, PermissionType: string, Status: string, StatusMessage: string>, NextToken: string>"
    export-lens: "record<LensJSON: string>"
    get-answer: "record<WorkloadId: string, MilestoneNumber: int, LensAlias: string, LensArn: string, Answer: record<QuestionId: string, PillarId: string, QuestionTitle: string, QuestionDescription: string, ImprovementPlanUrl: string, HelpfulResourceUrl: string, HelpfulResourceDisplayText: string, Choices: list<record>, SelectedChoices: list<string>, ChoiceAnswers: list<record>, IsApplicable: bool, Risk: string, Notes: string, Reason: string>>"
    update-answer: "record<WorkloadId: string, LensAlias: string, LensArn: string, Answer: record<QuestionId: string, PillarId: string, QuestionTitle: string, QuestionDescription: string, ImprovementPlanUrl: string, HelpfulResourceUrl: string, HelpfulResourceDisplayText: string, Choices: list<record>, SelectedChoices: list<string>, ChoiceAnswers: list<record>, IsApplicable: bool, Risk: string, Notes: string, Reason: string>>"
    get-consolidated-report: "record<Metrics: table<MetricType: string, RiskCounts: record, WorkloadId: string, WorkloadName: string, WorkloadArn: string, UpdatedAt: string, Lenses: list, LensesAppliedCount: int>, NextToken: string, Base64String: string>"
    get-lens: "record<Lens: record<LensArn: string, LensVersion: string, Name: string, Description: string, Owner: string, ShareInvitationId: string, Tags: record>>"
    get-lens-review: "record<WorkloadId: string, MilestoneNumber: int, LensReview: record<LensAlias: string, LensArn: string, LensVersion: string, LensName: string, LensStatus: string, PillarReviewSummaries: list<record>, UpdatedAt: string, Notes: string, RiskCounts: record, NextToken: string>>"
    update-lens-review: "record<WorkloadId: string, LensReview: record<LensAlias: string, LensArn: string, LensVersion: string, LensName: string, LensStatus: string, PillarReviewSummaries: list<record>, UpdatedAt: string, Notes: string, RiskCounts: record, NextToken: string>>"
    get-lens-review-report: "record<WorkloadId: string, MilestoneNumber: int, LensReviewReport: record<LensAlias: string, LensArn: string, Base64String: string>>"
    get-lens-version-difference: "record<LensAlias: string, LensArn: string, BaseLensVersion: string, TargetLensVersion: string, LatestLensVersion: string, VersionDifferences: record<PillarDifferences: list<record>>>"
    get-milestone: "record<WorkloadId: string, Milestone: record<MilestoneNumber: int, MilestoneName: string, RecordedAt: string, Workload: record<WorkloadId: string, WorkloadArn: string, WorkloadName: string, Description: string, Environment: string, UpdatedAt: string, AccountIds: list, AwsRegions: list, NonAwsRegions: list, ArchitecturalDesign: string, ReviewOwner: string, ReviewRestrictionDate: string, IsReviewOwnerUpdateAcknowledged: bool, IndustryType: string, Industry: string, Notes: string, ImprovementStatus: string, RiskCounts: record, PillarPriorities: list, Lenses: list, Owner: string, ShareInvitationId: string, Tags: record, DiscoveryConfig: record, Applications: list>>>"
    get-workload: "record<Workload: record<WorkloadId: string, WorkloadArn: string, WorkloadName: string, Description: string, Environment: string, UpdatedAt: string, AccountIds: list<string>, AwsRegions: list<string>, NonAwsRegions: list<string>, ArchitecturalDesign: string, ReviewOwner: string, ReviewRestrictionDate: string, IsReviewOwnerUpdateAcknowledged: bool, IndustryType: string, Industry: string, Notes: string, ImprovementStatus: string, RiskCounts: record, PillarPriorities: list<string>, Lenses: list<string>, Owner: string, ShareInvitationId: string, Tags: record, DiscoveryConfig: record<TrustedAdvisorIntegrationStatus: string>, Applications: list<string>>>"
    update-workload: "record<Workload: record<WorkloadId: string, WorkloadArn: string, WorkloadName: string, Description: string, Environment: string, UpdatedAt: string, AccountIds: list<string>, AwsRegions: list<string>, NonAwsRegions: list<string>, ArchitecturalDesign: string, ReviewOwner: string, ReviewRestrictionDate: string, IsReviewOwnerUpdateAcknowledged: bool, IndustryType: string, Industry: string, Notes: string, ImprovementStatus: string, RiskCounts: record, PillarPriorities: list<string>, Lenses: list<string>, Owner: string, ShareInvitationId: string, Tags: record, DiscoveryConfig: record<TrustedAdvisorIntegrationStatus: string>, Applications: list<string>>>"
    import-lens: "record<LensArn: string, Status: string>"
    list-answers: "record<WorkloadId: string, MilestoneNumber: int, LensAlias: string, LensArn: string, AnswerSummaries: table<QuestionId: string, PillarId: string, QuestionTitle: string, Choices: list, SelectedChoices: list, ChoiceAnswerSummaries: list, IsApplicable: bool, Risk: string, Reason: string>, NextToken: string>"
    list-check-details: "record<CheckDetails: table<Id: string, Name: string, Description: string, Provider: string, LensArn: string, PillarId: string, QuestionId: string, ChoiceId: string, Status: string, AccountId: string, FlaggedResources: int, Reason: string, UpdatedAt: string>, NextToken: string>"
    list-check-summaries: "record<CheckSummaries: table<Id: string, Name: string, Provider: string, Description: string, UpdatedAt: string, LensArn: string, PillarId: string, QuestionId: string, ChoiceId: string, Status: string, AccountSummary: record>, NextToken: string>"
    list-lens-review-improvements: "record<WorkloadId: string, MilestoneNumber: int, LensAlias: string, LensArn: string, ImprovementSummaries: table<QuestionId: string, PillarId: string, QuestionTitle: string, Risk: string, ImprovementPlanUrl: string, ImprovementPlans: list>, NextToken: string>"
    list-lens-reviews: "record<WorkloadId: string, MilestoneNumber: int, LensReviewSummaries: table<LensAlias: string, LensArn: string, LensVersion: string, LensName: string, LensStatus: string, UpdatedAt: string, RiskCounts: record>, NextToken: string>"
    list-lenses: "record<LensSummaries: table<LensArn: string, LensAlias: string, LensName: string, LensType: string, Description: string, CreatedAt: string, UpdatedAt: string, LensVersion: string, Owner: string, LensStatus: string>, NextToken: string>"
    list-milestones: "record<WorkloadId: string, MilestoneSummaries: table<MilestoneNumber: int, MilestoneName: string, RecordedAt: string, WorkloadSummary: record>, NextToken: string>"
    list-notifications: "record<NotificationSummaries: table<Type: string, LensUpgradeSummary: record>, NextToken: string>"
    list-share-invitations: "record<ShareInvitationSummaries: table<ShareInvitationId: string, SharedBy: string, SharedWith: string, PermissionType: string, ShareResourceType: string, WorkloadName: string, WorkloadId: string, LensName: string, LensArn: string>, NextToken: string>"
    list-tags-for-resource: "record<Tags: record>"
    tag-resource: "record"
    list-workloads: "record<WorkloadSummaries: table<WorkloadId: string, WorkloadArn: string, WorkloadName: string, Owner: string, UpdatedAt: string, Lenses: list, RiskCounts: record, ImprovementStatus: string>, NextToken: string>"
    untag-resource: "record"
    update-share-invitation: "record<ShareInvitation: record<ShareInvitationId: string, ShareResourceType: string, WorkloadId: string, LensAlias: string, LensArn: string>>"
    update-workload-share: "record<WorkloadId: string, WorkloadShare: record<ShareId: string, SharedBy: string, SharedWith: string, PermissionType: string, Status: string, WorkloadName: string, WorkloadId: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["associate-lenses" "create-lens-share" "list-lens-shares" "create-lens-version" "create-milestone" "create-workload" "create-workload-share" "list-workload-shares" "delete-lens" "delete-lens-share" "delete-workload" "delete-workload-share" "disassociate-lenses" "export-lens" "get-answer" "update-answer" "get-consolidated-report" "get-lens" "get-lens-review" "update-lens-review" "get-lens-review-report" "get-lens-version-difference" "get-milestone" "get-workload" "update-workload" "import-lens" "list-answers" "list-check-details" "list-check-summaries" "list-lens-review-improvements" "list-lens-reviews" "list-lenses" "list-milestones" "list-notifications" "list-share-invitations" "list-tags-for-resource" "tag-resource" "list-workloads" "untag-resource" "update-global-settings" "update-share-invitation" "update-workload-share" "upgrade-lens-review" "commands"] | sort) } | get name | first)
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

# Associate a lens to a workload. Up to 10 lenses can be associated with a workload in a single API operation. A maximum of 20 lenses can be associated with a workload. Disclaimer By accessing and/or applying custom lenses created by another Amazon Web Services user or account, you acknowledge that custom lenses created by other users and shared with you are Third Party Content as defined in the Amazon Web Services Customer Agreement.
#
# PATCH /workloads/{WorkloadId}/associateLenses
# operationId: AssociateLenses
export def "associate-lenses" [
  workload_id: string
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
  lens_aliases: list<string> # List of lens aliases to associate or disassociate with a workload. Up to 10 lenses can be specified. Identify a lens using its LensSummary$LensAlias.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/workloads/{WorkloadId}/associateLenses"
    path_params: [{name: WorkloadId, var: workload_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LensAliases, var: lens_aliases}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, lens_aliases: $lens_aliases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a lens share. The owner of a lens can share it with other Amazon Web Services accounts, users, an organization, and organizational units (OUs) in the same Amazon Web Services Region. Lenses provided by Amazon Web Services (Amazon Web Services Official Content) cannot be shared. Shared access to a lens is not removed until the lens invitation is deleted. If you share a lens with an organization or OU, all accounts in the organization or OU are granted access to the lens. For more information, see Sharing a custom lens (https://docs.aws.amazon.com/wellarchitected/latest/userguide/lenses-sharing.html) in the Well-Architected Tool User Guide. Disclaimer By sharing your custom lenses with other Amazon Web Services accounts, you acknowledge that Amazon Web Services will make your custom lenses available to those other accounts. Those other accounts may continue to access and use your shared custom lenses even if you delete the custom lenses from your own Amazon Web Services account or terminate your Amazon Web Services account.
#
# POST /lenses/{LensAlias}/shares
# Returns: record<ShareId: string>
# operationId: CreateLensShare
export def "create-lens-share" [
  lens_alias: string
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
  shared_with: string # The Amazon Web Services account ID, IAM role, organization ID, or organizational unit (OU) ID with which the workload is shared.
  client_request_token: string # A unique case-sensitive string used to ensure that this request is idempotent (executes only once). You should not reuse the same token for other requests. If you retry a request with the same client request token and the same parameters after the original request has completed successfully, the result of the original request is returned. This token is listed as required, however, if you do not specify it, the Amazon Web Services SDKs automatically generate one for you. If you are not using the Amazon Web Services SDK or the CLI, you must provide this token or the request will fail.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lenses/{LensAlias}/shares"
    path_params: [{name: LensAlias, var: lens_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SharedWith, var: shared_with}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lens_alias: $lens_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, shared_with: $shared_with, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the lens shares associated with the lens.
#
# GET /lenses/{LensAlias}/shares
# Returns: record<LensShareSummaries: table<ShareId: string, SharedWith: string, Status: string, StatusMessage: string>, NextToken: string>
# operationId: ListLensShares
export def "list-lens-shares" [
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shared-with-prefix: string # The Amazon Web Services account ID, IAM role, organization ID, or organizational unit (OU) ID with which the lens is shared.
  --next-token: string
  --max-results: int # The maximum number of results to return for this request.
  --status: string@status-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lenses/{LensAlias}/shares"
    path_params: [{name: LensAlias, var: lens_alias}]
    query: [{name: SharedWithPrefix, var: shared_with_prefix}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: Status, var: status}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lens_alias: $lens_alias, shared_with_prefix: $shared_with_prefix, next_token: $next_token, max_results: $max_results, status: $status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new lens version. A lens can have up to 100 versions. Use this operation to publish a new lens version after you have imported a lens. The LensAlias is used to identify the lens to be published. The owner of a lens can share the lens with other Amazon Web Services accounts and users in the same Amazon Web Services Region. Only the owner of a lens can delete it.
#
# POST /lenses/{LensAlias}/versions
# Returns: record<LensArn: string, LensVersion: string>
# operationId: CreateLensVersion
export def "create-lens-version" [
  lens_alias: string
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
  lens_version: string # The version of the lens being created.
  --is-major-version: oneof<nothing, bool> # Set to true if this new major lens version.
  client_request_token: string # A unique case-sensitive string used to ensure that this request is idempotent (executes only once). You should not reuse the same token for other requests. If you retry a request with the same client request token and the same parameters after the original request has completed successfully, the result of the original request is returned. This token is listed as required, however, if you do not specify it, the Amazon Web Services SDKs automatically generate one for you. If you are not using the Amazon Web Services SDK or the CLI, you must provide this token or the request will fail.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lenses/{LensAlias}/versions"
    path_params: [{name: LensAlias, var: lens_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LensVersion, var: lens_version}, {name: IsMajorVersion, var: is_major_version}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lens_alias: $lens_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, lens_version: $lens_version, is_major_version: $is_major_version, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a milestone for an existing workload.
#
# POST /workloads/{WorkloadId}/milestones
# Returns: record<WorkloadId: string, MilestoneNumber: int>
# operationId: CreateMilestone
export def "create-milestone" [
  workload_id: string
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
  milestone_name: string # The name of the milestone in a workload. Milestone names must be unique within a workload.
  client_request_token: string # A unique case-sensitive string used to ensure that this request is idempotent (executes only once). You should not reuse the same token for other requests. If you retry a request with the same client request token and the same parameters after the original request has completed successfully, the result of the original request is returned. This token is listed as required, however, if you do not specify it, the Amazon Web Services SDKs automatically generate one for you. If you are not using the Amazon Web Services SDK or the CLI, you must provide this token or the request will fail.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workloads/{WorkloadId}/milestones"
    path_params: [{name: WorkloadId, var: workload_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MilestoneName, var: milestone_name}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, milestone_name: $milestone_name, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new workload. The owner of a workload can share the workload with other Amazon Web Services accounts, users, an organization, and organizational units (OUs) in the same Amazon Web Services Region. Only the owner of a workload can delete it. For more information, see Defining a Workload (https://docs.aws.amazon.com/wellarchitected/latest/userguide/define-workload.html) in the Well-Architected Tool User Guide. Either AwsRegions, NonAwsRegions, or both must be specified when creating a workload. You also must specify ReviewOwner, even though the parameter is listed as not being required in the following section.
#
# POST /workloads
# Returns: record<WorkloadId: string, WorkloadArn: string>
# operationId: CreateWorkload
export def "create-workload" [
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
  workload_name: string # The name of the workload. The name must be unique within an account within an Amazon Web Services Region. Spaces and capitalization are ignored when checking for uniqueness.
  description: string # The description for the workload.
  environment: string@environment-completer # The environment for the workload.
  --account-ids: list<string> # The list of Amazon Web Services account IDs associated with the workload.
  --aws-regions: list<string> # The list of Amazon Web Services Regions associated with the workload, for example, us-east-2, or ca-central-1.
  --non-aws-regions: list<string> # The list of non-Amazon Web Services Regions associated with the workload.
  --pillar-priorities: list<string> # The priorities of the pillars, which are used to order items in the improvement plan. Each pillar is represented by its PillarReviewSummary$PillarId.
  --architectural-design: string # The URL of the architectural design for the workload.
  --review-owner: string # The review owner of the workload. The name, email address, or identifier for the primary group or individual that owns the workload review process.
  --industry-type: string # The industry type for the workload. If specified, must be one of the following: Agriculture Automobile Defense Design and Engineering Digital Advertising Education Environmental Protection Financial Services Gaming General Public Services Healthcare Hospitality InfoTech Justice and Public Safety Life Sciences Manufacturing Media & Entertainment Mining & Resources Oil & Gas Power & Utilities Professional Services Real Estate & Construction Retail & Wholesale Social Protection Telecommunications Travel, Transportation & Logistics Other
  --industry: string # The industry for the workload.
  lenses: list<string> # The list of lenses associated with the workload. Each lens is identified by its LensSummary$LensAlias.
  --notes: string # The notes associated with the workload.
  client_request_token: string # A unique case-sensitive string used to ensure that this request is idempotent (executes only once). You should not reuse the same token for other requests. If you retry a request with the same client request token and the same parameters after the original request has completed successfully, the result of the original request is returned. This token is listed as required, however, if you do not specify it, the Amazon Web Services SDKs automatically generate one for you. If you are not using the Amazon Web Services SDK or the CLI, you must provide this token or the request will fail.
  --tags: record # The tags to be associated with the workload.
  --discovery-config: record # Discovery configuration associated to the workload. — shape: {TrustedAdvisorIntegrationStatus?: "ENABLED"|"DISABLED"}
  --applications: list<string> # List of AppRegistry application ARNs associated to the workload.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workloads"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkloadName, var: workload_name}, {name: Description, var: description}, {name: Environment, var: environment}, {name: AccountIds, var: account_ids}, {name: AwsRegions, var: aws_regions}, {name: NonAwsRegions, var: non_aws_regions}, {name: PillarPriorities, var: pillar_priorities}, {name: ArchitecturalDesign, var: architectural_design}, {name: ReviewOwner, var: review_owner}, {name: IndustryType, var: industry_type}, {name: Industry, var: industry}, {name: Lenses, var: lenses}, {name: Notes, var: notes}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}, {name: DiscoveryConfig, var: discovery_config}, {name: Applications, var: applications}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, workload_name: $workload_name, description: $description, environment: $environment, account_ids: $account_ids, aws_regions: $aws_regions, non_aws_regions: $non_aws_regions, pillar_priorities: $pillar_priorities, architectural_design: $architectural_design, review_owner: $review_owner, industry_type: $industry_type, industry: $industry, lenses: $lenses, notes: $notes, client_request_token: $client_request_token, tags: $tags, discovery_config: $discovery_config, applications: $applications
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a workload share. The owner of a workload can share it with other Amazon Web Services accounts and users in the same Amazon Web Services Region. Shared access to a workload is not removed until the workload invitation is deleted. If you share a workload with an organization or OU, all accounts in the organization or OU are granted access to the workload. For more information, see Sharing a workload (https://docs.aws.amazon.com/wellarchitected/latest/userguide/workloads-sharing.html) in the Well-Architected Tool User Guide.
#
# POST /workloads/{WorkloadId}/shares
# Returns: record<WorkloadId: string, ShareId: string>
# operationId: CreateWorkloadShare
export def "create-workload-share" [
  workload_id: string
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
  shared_with: string # The Amazon Web Services account ID, IAM role, organization ID, or organizational unit (OU) ID with which the workload is shared.
  permission_type: string@permission-type-completer # Permission granted on a workload share.
  client_request_token: string # A unique case-sensitive string used to ensure that this request is idempotent (executes only once). You should not reuse the same token for other requests. If you retry a request with the same client request token and the same parameters after the original request has completed successfully, the result of the original request is returned. This token is listed as required, however, if you do not specify it, the Amazon Web Services SDKs automatically generate one for you. If you are not using the Amazon Web Services SDK or the CLI, you must provide this token or the request will fail.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workloads/{WorkloadId}/shares"
    path_params: [{name: WorkloadId, var: workload_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SharedWith, var: shared_with}, {name: PermissionType, var: permission_type}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, shared_with: $shared_with, permission_type: $permission_type, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the workload shares associated with the workload.
#
# GET /workloads/{WorkloadId}/shares
# Returns: record<WorkloadId: string, WorkloadShareSummaries: table<ShareId: string, SharedWith: string, PermissionType: string, Status: string, StatusMessage: string>, NextToken: string>
# operationId: ListWorkloadShares
export def "list-workload-shares" [
  workload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shared-with-prefix: string # The Amazon Web Services account ID, IAM role, organization ID, or organizational unit (OU) ID with which the workload is shared.
  --next-token: string
  --max-results: int # The maximum number of results to return for this request.
  --status: string@status-completer
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}/shares"
    path_params: [{name: WorkloadId, var: workload_id}]
    query: [{name: SharedWithPrefix, var: shared_with_prefix}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: Status, var: status}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, shared_with_prefix: $shared_with_prefix, next_token: $next_token, max_results: $max_results, status: $status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing lens. Only the owner of a lens can delete it. After the lens is deleted, Amazon Web Services accounts and users that you shared the lens with can continue to use it, but they will no longer be able to apply it to new workloads. Disclaimer By sharing your custom lenses with other Amazon Web Services accounts, you acknowledge that Amazon Web Services will make your custom lenses available to those other accounts. Those other accounts may continue to access and use your shared custom lenses even if you delete the custom lenses from your own Amazon Web Services account or terminate your Amazon Web Services account.
#
# DELETE /lenses/{LensAlias}
# operationId: DeleteLens
export def "delete-lens" [
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-request-token: string # required
  --lens-status: string@lens-status-completer # The status of the lens to be deleted. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/lenses/{LensAlias}"
    path_params: [{name: LensAlias, var: lens_alias}]
    query: [{name: ClientRequestToken, var: client_request_token, required: true}, {name: LensStatus, var: lens_status, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lens_alias: $lens_alias, client_request_token: $client_request_token, lens_status: $lens_status, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a lens share. After the lens share is deleted, Amazon Web Services accounts, users, organizations, and organizational units (OUs) that you shared the lens with can continue to use it, but they will no longer be able to apply it to new workloads. Disclaimer By sharing your custom lenses with other Amazon Web Services accounts, you acknowledge that Amazon Web Services will make your custom lenses available to those other accounts. Those other accounts may continue to access and use your shared custom lenses even if you delete the custom lenses from your own Amazon Web Services account or terminate your Amazon Web Services account.
#
# DELETE /lenses/{LensAlias}/shares/{ShareId}
# operationId: DeleteLensShare
export def "delete-lens-share" [
  lens_alias: string
  share_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-request-token: string # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/lenses/{LensAlias}/shares/{ShareId}"
    path_params: [{name: LensAlias, var: lens_alias}, {name: ShareId, var: share_id}]
    query: [{name: ClientRequestToken, var: client_request_token, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lens_alias: $lens_alias, share_id: $share_id, client_request_token: $client_request_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing workload.
#
# DELETE /workloads/{WorkloadId}
# operationId: DeleteWorkload
export def "delete-workload" [
  workload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-request-token: string # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/workloads/{WorkloadId}"
    path_params: [{name: WorkloadId, var: workload_id}]
    query: [{name: ClientRequestToken, var: client_request_token, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, client_request_token: $client_request_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a workload share.
#
# DELETE /workloads/{WorkloadId}/shares/{ShareId}
# operationId: DeleteWorkloadShare
export def "delete-workload-share" [
  workload_id: string
  share_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-request-token: string # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/workloads/{WorkloadId}/shares/{ShareId}"
    path_params: [{name: WorkloadId, var: workload_id}, {name: ShareId, var: share_id}]
    query: [{name: ClientRequestToken, var: client_request_token, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, share_id: $share_id, client_request_token: $client_request_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociate a lens from a workload. Up to 10 lenses can be disassociated from a workload in a single API operation. The Amazon Web Services Well-Architected Framework lens (wellarchitected) cannot be removed from a workload.
#
# PATCH /workloads/{WorkloadId}/disassociateLenses
# operationId: DisassociateLenses
export def "disassociate-lenses" [
  workload_id: string
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
  lens_aliases: list<string> # List of lens aliases to associate or disassociate with a workload. Up to 10 lenses can be specified. Identify a lens using its LensSummary$LensAlias.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/workloads/{WorkloadId}/disassociateLenses"
    path_params: [{name: WorkloadId, var: workload_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LensAliases, var: lens_aliases}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, lens_aliases: $lens_aliases
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Export an existing lens. Only the owner of a lens can export it. Lenses provided by Amazon Web Services (Amazon Web Services Official Content) cannot be exported. Lenses are defined in JSON. For more information, see JSON format specification (https://docs.aws.amazon.com/wellarchitected/latest/userguide/lenses-format-specification.html) in the Well-Architected Tool User Guide. Disclaimer Do not include or gather personal identifiable information (PII) of end users or other identifiable individuals in or via your custom lenses. If your custom lens or those shared with you and used in your account do include or collect PII you are responsible for: ensuring that the included PII is processed in accordance with applicable law, providing adequate privacy notices, and obtaining necessary consents for processing such data.
#
# GET /lenses/{LensAlias}/export
# Returns: record<LensJSON: string>
# operationId: ExportLens
export def "export-lens" [
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lens-version: string # The lens version to be exported.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lenses/{LensAlias}/export"
    path_params: [{name: LensAlias, var: lens_alias}]
    query: [{name: LensVersion, var: lens_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lens_alias: $lens_alias, lens_version: $lens_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the answer to a specific question in a workload review.
#
# GET /workloads/{WorkloadId}/lensReviews/{LensAlias}/answers/{QuestionId}
# Returns: record<WorkloadId: string, MilestoneNumber: int, LensAlias: string, LensArn: string, Answer: record<QuestionId: string, PillarId: string, QuestionTitle: string, QuestionDescription: string, ImprovementPlanUrl: string, HelpfulResourceUrl: string, HelpfulResourceDisplayText: string, Choices: list<record>, SelectedChoices: list<string>, ChoiceAnswers: list<record>, IsApplicable: bool, Risk: string, Notes: string, Reason: string>>
# operationId: GetAnswer
export def "get-answer" [
  workload_id: string
  lens_alias: string
  question_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --milestone-number: int
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}/lensReviews/{LensAlias}/answers/{QuestionId}"
    path_params: [{name: WorkloadId, var: workload_id}, {name: LensAlias, var: lens_alias}, {name: QuestionId, var: question_id}]
    query: [{name: MilestoneNumber, var: milestone_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, lens_alias: $lens_alias, question_id: $question_id, milestone_number: $milestone_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the answer to a specific question in a workload review.
#
# PATCH /workloads/{WorkloadId}/lensReviews/{LensAlias}/answers/{QuestionId}
# Returns: record<WorkloadId: string, LensAlias: string, LensArn: string, Answer: record<QuestionId: string, PillarId: string, QuestionTitle: string, QuestionDescription: string, ImprovementPlanUrl: string, HelpfulResourceUrl: string, HelpfulResourceDisplayText: string, Choices: list<record>, SelectedChoices: list<string>, ChoiceAnswers: list<record>, IsApplicable: bool, Risk: string, Notes: string, Reason: string>>
# operationId: UpdateAnswer
export def "update-answer" [
  workload_id: string
  lens_alias: string
  question_id: string
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
  --selected-choices: list<string> # List of selected choice IDs in a question answer. The values entered replace the previously selected choices.
  --choice-updates: record # A list of choices to update on a question in your workload. The String key corresponds to the choice ID to be updated.
  --notes: string # The notes associated with the workload.
  --is-applicable: oneof<nothing, bool> # Defines whether this question is applicable to a lens review.
  --reason: string@reason-completer # The reason why a question is not applicable to your workload.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/workloads/{WorkloadId}/lensReviews/{LensAlias}/answers/{QuestionId}"
    path_params: [{name: WorkloadId, var: workload_id}, {name: LensAlias, var: lens_alias}, {name: QuestionId, var: question_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SelectedChoices, var: selected_choices}, {name: ChoiceUpdates, var: choice_updates}, {name: Notes, var: notes}, {name: IsApplicable, var: is_applicable}, {name: Reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, lens_alias: $lens_alias, question_id: $question_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, selected_choices: $selected_choices, choice_updates: $choice_updates, notes: $notes, is_applicable: $is_applicable, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a consolidated report of your workloads. You can optionally choose to include workloads that have been shared with you.
#
# GET /consolidatedReport
# Returns: record<Metrics: table<MetricType: string, RiskCounts: record, WorkloadId: string, WorkloadName: string, WorkloadArn: string, UpdatedAt: string, Lenses: list, LensesAppliedCount: int>, NextToken: string, Base64String: string>
# operationId: GetConsolidatedReport
export def "get-consolidated-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The format of the consolidated report. For PDF, Base64String is returned. For JSON, Metrics is returned. (required)
  --include-shared-resources: oneof<nothing, bool> # Set to true to have shared resources included in the report.
  --next-token: string
  --max-results: int # The maximum number of results to return for this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/consolidatedReport"
    query: [{name: Format, var: format, required: true}, {name: IncludeSharedResources, var: include_shared_resources}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format, include_shared_resources: $include_shared_resources, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an existing lens.
#
# GET /lenses/{LensAlias}
# Returns: record<Lens: record<LensArn: string, LensVersion: string, Name: string, Description: string, Owner: string, ShareInvitationId: string, Tags: record>>
# operationId: GetLens
export def "get-lens" [
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lens-version: string # The lens version to be retrieved.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lenses/{LensAlias}"
    path_params: [{name: LensAlias, var: lens_alias}]
    query: [{name: LensVersion, var: lens_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lens_alias: $lens_alias, lens_version: $lens_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lens review.
#
# GET /workloads/{WorkloadId}/lensReviews/{LensAlias}
# Returns: record<WorkloadId: string, MilestoneNumber: int, LensReview: record<LensAlias: string, LensArn: string, LensVersion: string, LensName: string, LensStatus: string, PillarReviewSummaries: list<record>, UpdatedAt: string, Notes: string, RiskCounts: record, NextToken: string>>
# operationId: GetLensReview
export def "get-lens-review" [
  workload_id: string
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --milestone-number: int
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}/lensReviews/{LensAlias}"
    path_params: [{name: WorkloadId, var: workload_id}, {name: LensAlias, var: lens_alias}]
    query: [{name: MilestoneNumber, var: milestone_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, lens_alias: $lens_alias, milestone_number: $milestone_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update lens review for a particular workload.
#
# PATCH /workloads/{WorkloadId}/lensReviews/{LensAlias}
# Returns: record<WorkloadId: string, LensReview: record<LensAlias: string, LensArn: string, LensVersion: string, LensName: string, LensStatus: string, PillarReviewSummaries: list<record>, UpdatedAt: string, Notes: string, RiskCounts: record, NextToken: string>>
# operationId: UpdateLensReview
export def "update-lens-review" [
  workload_id: string
  lens_alias: string
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
  --lens-notes: string # The notes associated with the workload.
  --pillar-notes: record # List of pillar notes of a lens review in a workload.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/workloads/{WorkloadId}/lensReviews/{LensAlias}"
    path_params: [{name: WorkloadId, var: workload_id}, {name: LensAlias, var: lens_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LensNotes, var: lens_notes}, {name: PillarNotes, var: pillar_notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, lens_alias: $lens_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, lens_notes: $lens_notes, pillar_notes: $pillar_notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lens review report.
#
# GET /workloads/{WorkloadId}/lensReviews/{LensAlias}/report
# Returns: record<WorkloadId: string, MilestoneNumber: int, LensReviewReport: record<LensAlias: string, LensArn: string, Base64String: string>>
# operationId: GetLensReviewReport
export def "get-lens-review-report" [
  workload_id: string
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --milestone-number: int
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}/lensReviews/{LensAlias}/report"
    path_params: [{name: WorkloadId, var: workload_id}, {name: LensAlias, var: lens_alias}]
    query: [{name: MilestoneNumber, var: milestone_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, lens_alias: $lens_alias, milestone_number: $milestone_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lens version differences.
#
# GET /lenses/{LensAlias}/versionDifference
# Returns: record<LensAlias: string, LensArn: string, BaseLensVersion: string, TargetLensVersion: string, LatestLensVersion: string, VersionDifferences: record<PillarDifferences: list<record>>>
# operationId: GetLensVersionDifference
export def "get-lens-version-difference" [
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --base-lens-version: string # The base version of the lens.
  --target-lens-version: string # The lens version to target a difference for.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lenses/{LensAlias}/versionDifference"
    path_params: [{name: LensAlias, var: lens_alias}]
    query: [{name: BaseLensVersion, var: base_lens_version}, {name: TargetLensVersion, var: target_lens_version}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    lens_alias: $lens_alias, base_lens_version: $base_lens_version, target_lens_version: $target_lens_version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a milestone for an existing workload.
#
# GET /workloads/{WorkloadId}/milestones/{MilestoneNumber}
# Returns: record<WorkloadId: string, Milestone: record<MilestoneNumber: int, MilestoneName: string, RecordedAt: string, Workload: record<WorkloadId: string, WorkloadArn: string, WorkloadName: string, Description: string, Environment: string, UpdatedAt: string, AccountIds: list, AwsRegions: list, NonAwsRegions: list, ArchitecturalDesign: string, ReviewOwner: string, ReviewRestrictionDate: string, IsReviewOwnerUpdateAcknowledged: bool, IndustryType: string, Industry: string, Notes: string, ImprovementStatus: string, RiskCounts: record, PillarPriorities: list, Lenses: list, Owner: string, ShareInvitationId: string, Tags: record, DiscoveryConfig: record, Applications: list>>>
# operationId: GetMilestone
export def "get-milestone" [
  workload_id: string
  milestone_number: int
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}/milestones/{MilestoneNumber}"
    path_params: [{name: WorkloadId, var: workload_id}, {name: MilestoneNumber, var: milestone_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, milestone_number: $milestone_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an existing workload.
#
# GET /workloads/{WorkloadId}
# Returns: record<Workload: record<WorkloadId: string, WorkloadArn: string, WorkloadName: string, Description: string, Environment: string, UpdatedAt: string, AccountIds: list<string>, AwsRegions: list<string>, NonAwsRegions: list<string>, ArchitecturalDesign: string, ReviewOwner: string, ReviewRestrictionDate: string, IsReviewOwnerUpdateAcknowledged: bool, IndustryType: string, Industry: string, Notes: string, ImprovementStatus: string, RiskCounts: record, PillarPriorities: list<string>, Lenses: list<string>, Owner: string, ShareInvitationId: string, Tags: record, DiscoveryConfig: record<TrustedAdvisorIntegrationStatus: string>, Applications: list<string>>>
# operationId: GetWorkload
export def "get-workload" [
  workload_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}"
    path_params: [{name: WorkloadId, var: workload_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing workload.
#
# PATCH /workloads/{WorkloadId}
# Returns: record<Workload: record<WorkloadId: string, WorkloadArn: string, WorkloadName: string, Description: string, Environment: string, UpdatedAt: string, AccountIds: list<string>, AwsRegions: list<string>, NonAwsRegions: list<string>, ArchitecturalDesign: string, ReviewOwner: string, ReviewRestrictionDate: string, IsReviewOwnerUpdateAcknowledged: bool, IndustryType: string, Industry: string, Notes: string, ImprovementStatus: string, RiskCounts: record, PillarPriorities: list<string>, Lenses: list<string>, Owner: string, ShareInvitationId: string, Tags: record, DiscoveryConfig: record<TrustedAdvisorIntegrationStatus: string>, Applications: list<string>>>
# operationId: UpdateWorkload
export def "update-workload" [
  workload_id: string
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
  --workload-name: string # The name of the workload. The name must be unique within an account within an Amazon Web Services Region. Spaces and capitalization are ignored when checking for uniqueness.
  --description: string # The description for the workload.
  --environment: string@environment-completer # The environment for the workload.
  --account-ids: list<string> # The list of Amazon Web Services account IDs associated with the workload.
  --aws-regions: list<string> # The list of Amazon Web Services Regions associated with the workload, for example, us-east-2, or ca-central-1.
  --non-aws-regions: list<string> # The list of non-Amazon Web Services Regions associated with the workload.
  --pillar-priorities: list<string> # The priorities of the pillars, which are used to order items in the improvement plan. Each pillar is represented by its PillarReviewSummary$PillarId.
  --architectural-design: string # The URL of the architectural design for the workload.
  --review-owner: string # The review owner of the workload. The name, email address, or identifier for the primary group or individual that owns the workload review process.
  --is-review-owner-update-acknowledged: oneof<nothing, bool> # Flag indicating whether the workload owner has acknowledged that the Review owner field is required. If a Review owner is not added to the workload within 60 days of acknowledgement, access to the workload is restricted until an owner is added.
  --industry-type: string # The industry type for the workload. If specified, must be one of the following: Agriculture Automobile Defense Design and Engineering Digital Advertising Education Environmental Protection Financial Services Gaming General Public Services Healthcare Hospitality InfoTech Justice and Public Safety Life Sciences Manufacturing Media & Entertainment Mining & Resources Oil & Gas Power & Utilities Professional Services Real Estate & Construction Retail & Wholesale Social Protection Telecommunications Travel, Transportation & Logistics Other
  --industry: string # The industry for the workload.
  --notes: string # The notes associated with the workload.
  --improvement-status: string@improvement-status-completer # The improvement status for a workload.
  --discovery-config: record # Discovery configuration associated to the workload. — shape: {TrustedAdvisorIntegrationStatus?: "ENABLED"|"DISABLED"}
  --applications: list<string> # List of AppRegistry application ARNs to associate to the workload.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/workloads/{WorkloadId}"
    path_params: [{name: WorkloadId, var: workload_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkloadName, var: workload_name}, {name: Description, var: description}, {name: Environment, var: environment}, {name: AccountIds, var: account_ids}, {name: AwsRegions, var: aws_regions}, {name: NonAwsRegions, var: non_aws_regions}, {name: PillarPriorities, var: pillar_priorities}, {name: ArchitecturalDesign, var: architectural_design}, {name: ReviewOwner, var: review_owner}, {name: IsReviewOwnerUpdateAcknowledged, var: is_review_owner_update_acknowledged}, {name: IndustryType, var: industry_type}, {name: Industry, var: industry}, {name: Notes, var: notes}, {name: ImprovementStatus, var: improvement_status}, {name: DiscoveryConfig, var: discovery_config}, {name: Applications, var: applications}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, workload_name: $workload_name, description: $description, environment: $environment, account_ids: $account_ids, aws_regions: $aws_regions, non_aws_regions: $non_aws_regions, pillar_priorities: $pillar_priorities, architectural_design: $architectural_design, review_owner: $review_owner, is_review_owner_update_acknowledged: $is_review_owner_update_acknowledged, industry_type: $industry_type, industry: $industry, notes: $notes, improvement_status: $improvement_status, discovery_config: $discovery_config, applications: $applications
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Import a new custom lens or update an existing custom lens. To update an existing custom lens, specify its ARN as the LensAlias. If no ARN is specified, a new custom lens is created. The new or updated lens will have a status of DRAFT. The lens cannot be applied to workloads or shared with other Amazon Web Services accounts until it's published with CreateLensVersion. Lenses are defined in JSON. For more information, see JSON format specification (https://docs.aws.amazon.com/wellarchitected/latest/userguide/lenses-format-specification.html) in the Well-Architected Tool User Guide. A custom lens cannot exceed 500 KB in size. Disclaimer Do not include or gather personal identifiable information (PII) of end users or other identifiable individuals in or via your custom lenses. If your custom lens or those shared with you and used in your account do include or collect PII you are responsible for: ensuring that the included PII is processed in accordance with applicable law, providing adequate privacy notices, and obtaining necessary consents for processing such data.
#
# PUT /importLens
# Returns: record<LensArn: string, Status: string>
# operationId: ImportLens
export def "import-lens" [
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
  --lens-alias: string # The alias of the lens. For Amazon Web Services official lenses, this is either the lens alias, such as serverless, or the lens ARN, such as arn:aws:wellarchitected:us-east-1::lens/serverless. Note that some operations (such as ExportLens and CreateLensShare) are not permitted on Amazon Web Services official lenses. For custom lenses, this is the lens ARN, such as arn:aws:wellarchitected:us-west-2:123456789012:lens/0123456789abcdef01234567890abcdef. Each lens is identified by its LensSummary$LensAlias.
  json_string: string # The JSON representation of a lens.
  client_request_token: string # A unique case-sensitive string used to ensure that this request is idempotent (executes only once). You should not reuse the same token for other requests. If you retry a request with the same client request token and the same parameters after the original request has completed successfully, the result of the original request is returned. This token is listed as required, however, if you do not specify it, the Amazon Web Services SDKs automatically generate one for you. If you are not using the Amazon Web Services SDK or the CLI, you must provide this token or the request will fail.
  --tags: record # Tags to associate to a lens.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/importLens"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LensAlias, var: lens_alias}, {name: JSONString, var: json_string}, {name: ClientRequestToken, var: client_request_token}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, lens_alias: $lens_alias, json_string: $json_string, client_request_token: $client_request_token, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of answers for a particular workload and lens.
#
# GET /workloads/{WorkloadId}/lensReviews/{LensAlias}/answers
# Returns: record<WorkloadId: string, MilestoneNumber: int, LensAlias: string, LensArn: string, AnswerSummaries: table<QuestionId: string, PillarId: string, QuestionTitle: string, Choices: list, SelectedChoices: list, ChoiceAnswerSummaries: list, IsApplicable: bool, Risk: string, Reason: string>, NextToken: string>
# operationId: ListAnswers
export def "list-answers" [
  workload_id: string
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pillar-id: string
  --milestone-number: int
  --next-token: string
  --max-results: int # The maximum number of results to return for this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}/lensReviews/{LensAlias}/answers"
    path_params: [{name: WorkloadId, var: workload_id}, {name: LensAlias, var: lens_alias}]
    query: [{name: PillarId, var: pillar_id}, {name: MilestoneNumber, var: milestone_number}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, lens_alias: $lens_alias, pillar_id: $pillar_id, milestone_number: $milestone_number, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Trusted Advisor check details by account related to the workload.
#
# POST /workloads/{WorkloadId}/checks
# Returns: record<CheckDetails: table<Id: string, Name: string, Description: string, Provider: string, LensArn: string, PillarId: string, QuestionId: string, ChoiceId: string, Status: string, AccountId: string, FlaggedResources: int, Reason: string, UpdatedAt: string>, NextToken: string>
# operationId: ListCheckDetails
export def "list-check-details" [
  workload_id: string
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
  --body-next-token: string # The token to use to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return for this request. (spec name: MaxResults)
  lens_arn: string # Well-Architected Lens ARN.
  pillar_id: string # The ID used to identify a pillar, for example, security. A pillar is identified by its PillarReviewSummary$PillarId.
  question_id: string # The ID of the question.
  choice_id: string # The ID of a choice.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workloads/{WorkloadId}/checks"
    path_params: [{name: WorkloadId, var: workload_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: LensArn, var: lens_arn}, {name: PillarId, var: pillar_id}, {name: QuestionId, var: question_id}, {name: ChoiceId, var: choice_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_next_token: $body_next_token, body_max_results: $body_max_results, lens_arn: $lens_arn, pillar_id: $pillar_id, question_id: $question_id, choice_id: $choice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Trusted Advisor checks summarized for all accounts related to the workload.
#
# POST /workloads/{WorkloadId}/checkSummaries
# Returns: record<CheckSummaries: table<Id: string, Name: string, Provider: string, Description: string, UpdatedAt: string, LensArn: string, PillarId: string, QuestionId: string, ChoiceId: string, Status: string, AccountSummary: record>, NextToken: string>
# operationId: ListCheckSummaries
export def "list-check-summaries" [
  workload_id: string
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
  --body-next-token: string # The token to use to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return for this request. (spec name: MaxResults)
  lens_arn: string # Well-Architected Lens ARN.
  pillar_id: string # The ID used to identify a pillar, for example, security. A pillar is identified by its PillarReviewSummary$PillarId.
  question_id: string # The ID of the question.
  choice_id: string # The ID of a choice.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workloads/{WorkloadId}/checkSummaries"
    path_params: [{name: WorkloadId, var: workload_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}, {name: LensArn, var: lens_arn}, {name: PillarId, var: pillar_id}, {name: QuestionId, var: question_id}, {name: ChoiceId, var: choice_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_next_token: $body_next_token, body_max_results: $body_max_results, lens_arn: $lens_arn, pillar_id: $pillar_id, question_id: $question_id, choice_id: $choice_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List lens review improvements.
#
# GET /workloads/{WorkloadId}/lensReviews/{LensAlias}/improvements
# Returns: record<WorkloadId: string, MilestoneNumber: int, LensAlias: string, LensArn: string, ImprovementSummaries: table<QuestionId: string, PillarId: string, QuestionTitle: string, Risk: string, ImprovementPlanUrl: string, ImprovementPlans: list>, NextToken: string>
# operationId: ListLensReviewImprovements
export def "list-lens-review-improvements" [
  workload_id: string
  lens_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pillar-id: string
  --milestone-number: int
  --next-token: string
  --max-results: int # The maximum number of results to return for this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}/lensReviews/{LensAlias}/improvements"
    path_params: [{name: WorkloadId, var: workload_id}, {name: LensAlias, var: lens_alias}]
    query: [{name: PillarId, var: pillar_id}, {name: MilestoneNumber, var: milestone_number}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, lens_alias: $lens_alias, pillar_id: $pillar_id, milestone_number: $milestone_number, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List lens reviews for a particular workload.
#
# GET /workloads/{WorkloadId}/lensReviews
# Returns: record<WorkloadId: string, MilestoneNumber: int, LensReviewSummaries: table<LensAlias: string, LensArn: string, LensVersion: string, LensName: string, LensStatus: string, UpdatedAt: string, RiskCounts: record>, NextToken: string>
# operationId: ListLensReviews
export def "list-lens-reviews" [
  workload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --milestone-number: int
  --next-token: string
  --max-results: int
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workloads/{WorkloadId}/lensReviews"
    path_params: [{name: WorkloadId, var: workload_id}]
    query: [{name: MilestoneNumber, var: milestone_number}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, milestone_number: $milestone_number, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the available lenses.
#
# GET /lenses
# Returns: record<LensSummaries: table<LensArn: string, LensAlias: string, LensName: string, LensType: string, Description: string, CreatedAt: string, UpdatedAt: string, LensVersion: string, Owner: string, LensStatus: string>, NextToken: string>
# operationId: ListLenses
export def "list-lenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: int
  --lens-type: string@lens-type-completer # The type of lenses to be returned.
  --lens-status: string@lens-status-completer # The status of lenses to be returned.
  --lens-name: string
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/lenses"
    query: [{name: NextToken, var: next_token}, {name: MaxResults, var: max_results}, {name: LensType, var: lens_type}, {name: LensStatus, var: lens_status}, {name: LensName, var: lens_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, max_results: $max_results, lens_type: $lens_type, lens_status: $lens_status, lens_name: $lens_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all milestones for an existing workload.
#
# POST /workloads/{WorkloadId}/milestonesSummaries
# Returns: record<WorkloadId: string, MilestoneSummaries: table<MilestoneNumber: int, MilestoneName: string, RecordedAt: string, WorkloadSummary: record>, NextToken: string>
# operationId: ListMilestones
export def "list-milestones" [
  workload_id: string
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
  --body-next-token: string # The token to use to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return for this request. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workloads/{WorkloadId}/milestonesSummaries"
    path_params: [{name: WorkloadId, var: workload_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List lens notifications.
#
# POST /notifications
# Returns: record<NotificationSummaries: table<Type: string, LensUpgradeSummary: record>, NextToken: string>
# operationId: ListNotifications
export def "list-notifications" [
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
  --workload-id: string # The ID assigned to the workload. This ID is unique within an Amazon Web Services Region.
  --body-next-token: string # The token to use to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return for this request. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/notifications"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkloadId, var: workload_id}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, workload_id: $workload_id, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the workload invitations.
#
# GET /shareInvitations
# Returns: record<ShareInvitationSummaries: table<ShareInvitationId: string, SharedBy: string, SharedWith: string, PermissionType: string, ShareResourceType: string, WorkloadName: string, WorkloadId: string, LensName: string, LensArn: string>, NextToken: string>
# operationId: ListShareInvitations
export def "list-share-invitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workload-name-prefix: string
  --lens-name-prefix: string # An optional string added to the beginning of each lens name returned in the results.
  --share-resource-type: string@share-resource-type-completer # The type of share invitations to be returned.
  --next-token: string
  --max-results: int # The maximum number of results to return for this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shareInvitations"
    query: [{name: WorkloadNamePrefix, var: workload_name_prefix}, {name: LensNamePrefix, var: lens_name_prefix}, {name: ShareResourceType, var: share_resource_type}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_name_prefix: $workload_name_prefix, lens_name_prefix: $lens_name_prefix, share_resource_type: $share_resource_type, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the tags for a resource. The WorkloadArn parameter can be either a workload ARN or a custom lens ARN.
#
# GET /tags/{WorkloadArn}
# Returns: record<Tags: record>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  workload_arn: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{WorkloadArn}"
    path_params: [{name: WorkloadArn, var: workload_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_arn: $workload_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds one or more tags to the specified resource. The WorkloadArn parameter can be either a workload ARN or a custom lens ARN.
#
# POST /tags/{WorkloadArn}
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  workload_arn: string
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
  tags: record # The tags for the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{WorkloadArn}"
    path_params: [{name: WorkloadArn, var: workload_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_arn: $workload_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Paginated list of workloads.
#
# POST /workloadsSummaries
# Returns: record<WorkloadSummaries: table<WorkloadId: string, WorkloadArn: string, WorkloadName: string, Owner: string, UpdatedAt: string, Lenses: list, RiskCounts: record, ImprovementStatus: string>, NextToken: string>
# operationId: ListWorkloads
export def "list-workloads" [
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
  --workload-name-prefix: string # An optional string added to the beginning of each workload name returned in the results.
  --body-next-token: string # The token to use to retrieve the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return for this request. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workloadsSummaries"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: WorkloadNamePrefix, var: workload_name_prefix}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, workload_name_prefix: $workload_name_prefix, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes specified tags from a resource. The WorkloadArn parameter can be either a workload ARN or a custom lens ARN. To specify multiple tags, use separate tagKeys parameters, for example: DELETE /tags/WorkloadArn?tagKeys=key1&tagKeys=key2
#
# DELETE /tags/{WorkloadArn}
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  workload_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # A list of tag keys. Existing tags of the resource whose keys are members of this list are removed from the resource. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tags/{WorkloadArn}"
    path_params: [{name: WorkloadArn, var: workload_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_arn: $workload_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates whether the Amazon Web Services account is opted into organization sharing features.
#
# PATCH /global-settings
# operationId: UpdateGlobalSettings
export def "update-global-settings" [
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
  --organization-sharing-status: string@organization-sharing-status-completer # The status of organization sharing settings.
]: any -> any {
  $in | http-request {
    method: patch
    path: "/global-settings"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: OrganizationSharingStatus, var: organization_sharing_status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, organization_sharing_status: $organization_sharing_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a workload or custom lens share invitation. This API operation can be called independently of any resource. Previous documentation implied that a workload ARN must be specified.
#
# PATCH /shareInvitations/{ShareInvitationId}
# Returns: record<ShareInvitation: record<ShareInvitationId: string, ShareResourceType: string, WorkloadId: string, LensAlias: string, LensArn: string>>
# operationId: UpdateShareInvitation
export def "update-share-invitation" [
  share_invitation_id: string
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
  share_invitation_action: string@share-invitation-action-completer # Share invitation action taken by contributor.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/shareInvitations/{ShareInvitationId}"
    path_params: [{name: ShareInvitationId, var: share_invitation_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ShareInvitationAction, var: share_invitation_action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    share_invitation_id: $share_invitation_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, share_invitation_action: $share_invitation_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a workload share.
#
# PATCH /workloads/{WorkloadId}/shares/{ShareId}
# Returns: record<WorkloadId: string, WorkloadShare: record<ShareId: string, SharedBy: string, SharedWith: string, PermissionType: string, Status: string, WorkloadName: string, WorkloadId: string>>
# operationId: UpdateWorkloadShare
export def "update-workload-share" [
  workload_id: string
  share_id: string
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
  permission_type: string@permission-type-completer # Permission granted on a workload share.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/workloads/{WorkloadId}/shares/{ShareId}"
    path_params: [{name: WorkloadId, var: workload_id}, {name: ShareId, var: share_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PermissionType, var: permission_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, share_id: $share_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, permission_type: $permission_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upgrade lens review for a particular workload.
#
# PUT /workloads/{WorkloadId}/lensReviews/{LensAlias}/upgrade
# operationId: UpgradeLensReview
export def "upgrade-lens-review" [
  workload_id: string
  lens_alias: string
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
  milestone_name: string # The name of the milestone in a workload. Milestone names must be unique within a workload.
  --client-request-token: string # A unique case-sensitive string used to ensure that this request is idempotent (executes only once). You should not reuse the same token for other requests. If you retry a request with the same client request token and the same parameters after the original request has completed successfully, the result of the original request is returned. This token is listed as required, however, if you do not specify it, the Amazon Web Services SDKs automatically generate one for you. If you are not using the Amazon Web Services SDK or the CLI, you must provide this token or the request will fail.
]: any -> any {
  $in | http-request {
    method: put
    path: "/workloads/{WorkloadId}/lensReviews/{LensAlias}/upgrade"
    path_params: [{name: WorkloadId, var: workload_id}, {name: LensAlias, var: lens_alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MilestoneName, var: milestone_name}, {name: ClientRequestToken, var: client_request_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workload_id: $workload_id, lens_alias: $lens_alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, milestone_name: $milestone_name, client_request_token: $client_request_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
