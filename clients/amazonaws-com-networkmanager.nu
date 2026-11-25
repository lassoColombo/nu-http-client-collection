# Auto-generated client for AWS Network Manager v2019-07-05
# Source: https://api.apis.guru/v2/specs/amazonaws.com/networkmanager/2019-07-05/openapi.json
# Auth: --token flag or $env.AWS_NETWORK_MANAGER_TOKEN

const CLIENT = {
  base_url: "http://networkmanager.us-east-1.amazonaws.com"
  token_env_var: "AWS_NETWORK_MANAGER_TOKEN"
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

def base-url-completer [] { ["http://networkmanager.us-east-1.amazonaws.com" "http://networkmanager.us-east-2.amazonaws.com" "http://networkmanager.us-west-1.amazonaws.com" "http://networkmanager.us-west-2.amazonaws.com" "http://networkmanager.us-gov-west-1.amazonaws.com" "http://networkmanager.us-gov-east-1.amazonaws.com" "http://networkmanager.ca-central-1.amazonaws.com" "http://networkmanager.eu-north-1.amazonaws.com" "http://networkmanager.eu-west-1.amazonaws.com" "http://networkmanager.eu-west-2.amazonaws.com" "http://networkmanager.eu-west-3.amazonaws.com" "http://networkmanager.eu-central-1.amazonaws.com" "http://networkmanager.eu-south-1.amazonaws.com" "http://networkmanager.af-south-1.amazonaws.com" "http://networkmanager.ap-northeast-1.amazonaws.com" "http://networkmanager.ap-northeast-2.amazonaws.com" "http://networkmanager.ap-northeast-3.amazonaws.com" "http://networkmanager.ap-southeast-1.amazonaws.com" "http://networkmanager.ap-southeast-2.amazonaws.com" "http://networkmanager.ap-east-1.amazonaws.com" "http://networkmanager.ap-south-1.amazonaws.com" "http://networkmanager.sa-east-1.amazonaws.com" "http://networkmanager.me-south-1.amazonaws.com" "https://networkmanager.us-east-1.amazonaws.com" "https://networkmanager.us-east-2.amazonaws.com" "https://networkmanager.us-west-1.amazonaws.com" "https://networkmanager.us-west-2.amazonaws.com" "https://networkmanager.us-gov-west-1.amazonaws.com" "https://networkmanager.us-gov-east-1.amazonaws.com" "https://networkmanager.ca-central-1.amazonaws.com" "https://networkmanager.eu-north-1.amazonaws.com" "https://networkmanager.eu-west-1.amazonaws.com" "https://networkmanager.eu-west-2.amazonaws.com" "https://networkmanager.eu-west-3.amazonaws.com" "https://networkmanager.eu-central-1.amazonaws.com" "https://networkmanager.eu-south-1.amazonaws.com" "https://networkmanager.af-south-1.amazonaws.com" "https://networkmanager.ap-northeast-1.amazonaws.com" "https://networkmanager.ap-northeast-2.amazonaws.com" "https://networkmanager.ap-northeast-3.amazonaws.com" "https://networkmanager.ap-southeast-1.amazonaws.com" "https://networkmanager.ap-southeast-2.amazonaws.com" "https://networkmanager.ap-east-1.amazonaws.com" "https://networkmanager.ap-south-1.amazonaws.com" "https://networkmanager.sa-east-1.amazonaws.com" "https://networkmanager.me-south-1.amazonaws.com" "http://networkmanager.cn-north-1.amazonaws.com.cn" "http://networkmanager.cn-northwest-1.amazonaws.com.cn" "https://networkmanager.cn-north-1.amazonaws.com.cn" "https://networkmanager.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alias-completer [] { ["LATEST" "LIVE"] }
def attachment-type-completer [] { ["CONNECT" "SITE_TO_SITE_VPN" "TRANSIT_GATEWAY_ROUTE_TABLE" "VPC"] }
def state-completer [] { ["AVAILABLE" "CREATING" "DELETING" "FAILED" "PENDING_ATTACHMENT_ACCEPTANCE" "PENDING_NETWORK_UPDATE" "PENDING_TAG_ACCEPTANCE" "REJECTED" "UPDATING"] }
def peering-type-completer [] { ["TRANSIT_GATEWAY"] }
def state-completer-1 [] { ["AVAILABLE" "CREATING" "DELETING" "FAILED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-attachment: "record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list<record>, ProposedSegmentChange: record<Tags: list, AttachmentPolicyRuleNumber: int, SegmentName: string>, CreatedAt: string, UpdatedAt: string>>"
    associate-connect-peer: "record<ConnectPeerAssociation: record<ConnectPeerId: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>"
    get-connect-peer-associations: "record<ConnectPeerAssociations: table<ConnectPeerId: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>, NextToken: string>"
    associate-customer-gateway: "record<CustomerGatewayAssociation: record<CustomerGatewayArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>"
    get-customer-gateway-associations: "record<CustomerGatewayAssociations: table<CustomerGatewayArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>, NextToken: string>"
    associate-link: "record<LinkAssociation: record<GlobalNetworkId: string, DeviceId: string, LinkId: string, LinkAssociationState: string>>"
    get-link-associations: "record<LinkAssociations: table<GlobalNetworkId: string, DeviceId: string, LinkId: string, LinkAssociationState: string>, NextToken: string>"
    associate-transit-gateway-connect-peer: "record<TransitGatewayConnectPeerAssociation: record<TransitGatewayConnectPeerArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>"
    get-transit-gateway-connect-peer-associations: "record<TransitGatewayConnectPeerAssociations: table<TransitGatewayConnectPeerArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>, NextToken: string>"
    create-connect-attachment: "record<ConnectAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, TransportAttachmentId: string, Options: record<Protocol: string>>>"
    create-connect-peer: "record<ConnectPeer: record<CoreNetworkId: string, ConnectAttachmentId: string, ConnectPeerId: string, EdgeLocation: string, State: string, CreatedAt: string, Configuration: record<CoreNetworkAddress: string, PeerAddress: string, InsideCidrBlocks: list, Protocol: string, BgpConfigurations: list>, Tags: list<record>>>"
    list-connect-peers: "record<ConnectPeers: table<CoreNetworkId: string, ConnectAttachmentId: string, ConnectPeerId: string, EdgeLocation: string, ConnectPeerState: string, CreatedAt: string, Tags: list>, NextToken: string>"
    create-connection: "record<Connection: record<ConnectionId: string, ConnectionArn: string, GlobalNetworkId: string, DeviceId: string, ConnectedDeviceId: string, LinkId: string, ConnectedLinkId: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>"
    get-connections: "record<Connections: table<ConnectionId: string, ConnectionArn: string, GlobalNetworkId: string, DeviceId: string, ConnectedDeviceId: string, LinkId: string, ConnectedLinkId: string, Description: string, CreatedAt: string, State: string, Tags: list>, NextToken: string>"
    create-core-network: "record<CoreNetwork: record<GlobalNetworkId: string, CoreNetworkId: string, CoreNetworkArn: string, Description: string, CreatedAt: string, State: string, Segments: list<record>, Edges: list<record>, Tags: list<record>>>"
    list-core-networks: "record<CoreNetworks: table<CoreNetworkId: string, CoreNetworkArn: string, GlobalNetworkId: string, OwnerAccountId: string, State: string, Description: string, Tags: list>, NextToken: string>"
    create-device: "record<Device: record<DeviceId: string, DeviceArn: string, GlobalNetworkId: string, AWSLocation: record<Zone: string, SubnetArn: string>, Description: string, Type: string, Vendor: string, Model: string, SerialNumber: string, Location: record<Address: string, Latitude: string, Longitude: string>, SiteId: string, CreatedAt: string, State: string, Tags: list<record>>>"
    get-devices: "record<Devices: table<DeviceId: string, DeviceArn: string, GlobalNetworkId: string, AWSLocation: record, Description: string, Type: string, Vendor: string, Model: string, SerialNumber: string, Location: record, SiteId: string, CreatedAt: string, State: string, Tags: list>, NextToken: string>"
    create-global-network: "record<GlobalNetwork: record<GlobalNetworkId: string, GlobalNetworkArn: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>"
    describe-global-networks: "record<GlobalNetworks: table<GlobalNetworkId: string, GlobalNetworkArn: string, Description: string, CreatedAt: string, State: string, Tags: list>, NextToken: string>"
    create-link: "record<Link: record<LinkId: string, LinkArn: string, GlobalNetworkId: string, SiteId: string, Description: string, Type: string, Bandwidth: record<UploadSpeed: int, DownloadSpeed: int>, Provider: string, CreatedAt: string, State: string, Tags: list<record>>>"
    get-links: "record<Links: table<LinkId: string, LinkArn: string, GlobalNetworkId: string, SiteId: string, Description: string, Type: string, Bandwidth: record, Provider: string, CreatedAt: string, State: string, Tags: list>, NextToken: string>"
    create-site: "record<Site: record<SiteId: string, SiteArn: string, GlobalNetworkId: string, Description: string, Location: record<Address: string, Latitude: string, Longitude: string>, CreatedAt: string, State: string, Tags: list<record>>>"
    get-sites: "record<Sites: table<SiteId: string, SiteArn: string, GlobalNetworkId: string, Description: string, Location: record, CreatedAt: string, State: string, Tags: list>, NextToken: string>"
    create-site-to-site-vpn-attachment: "record<SiteToSiteVpnAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, VpnConnectionArn: string>>"
    create-transit-gateway-peering: "record<TransitGatewayPeering: record<Peering: record<CoreNetworkId: string, CoreNetworkArn: string, PeeringId: string, OwnerAccountId: string, PeeringType: string, State: string, EdgeLocation: string, ResourceArn: string, Tags: list, CreatedAt: string>, TransitGatewayArn: string, TransitGatewayPeeringAttachmentId: string>>"
    create-transit-gateway-route-table-attachment: "record<TransitGatewayRouteTableAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, PeeringId: string, TransitGatewayRouteTableArn: string>>"
    create-vpc-attachment: "record<VpcAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, SubnetArns: list<string>, Options: record<Ipv6Support: bool, ApplianceModeSupport: bool>>>"
    delete-attachment: "record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list<record>, ProposedSegmentChange: record<Tags: list, AttachmentPolicyRuleNumber: int, SegmentName: string>, CreatedAt: string, UpdatedAt: string>>"
    delete-connect-peer: "record<ConnectPeer: record<CoreNetworkId: string, ConnectAttachmentId: string, ConnectPeerId: string, EdgeLocation: string, State: string, CreatedAt: string, Configuration: record<CoreNetworkAddress: string, PeerAddress: string, InsideCidrBlocks: list, Protocol: string, BgpConfigurations: list>, Tags: list<record>>>"
    get-connect-peer: "record<ConnectPeer: record<CoreNetworkId: string, ConnectAttachmentId: string, ConnectPeerId: string, EdgeLocation: string, State: string, CreatedAt: string, Configuration: record<CoreNetworkAddress: string, PeerAddress: string, InsideCidrBlocks: list, Protocol: string, BgpConfigurations: list>, Tags: list<record>>>"
    delete-connection: "record<Connection: record<ConnectionId: string, ConnectionArn: string, GlobalNetworkId: string, DeviceId: string, ConnectedDeviceId: string, LinkId: string, ConnectedLinkId: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>"
    update-connection: "record<Connection: record<ConnectionId: string, ConnectionArn: string, GlobalNetworkId: string, DeviceId: string, ConnectedDeviceId: string, LinkId: string, ConnectedLinkId: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>"
    delete-core-network: "record<CoreNetwork: record<GlobalNetworkId: string, CoreNetworkId: string, CoreNetworkArn: string, Description: string, CreatedAt: string, State: string, Segments: list<record>, Edges: list<record>, Tags: list<record>>>"
    get-core-network: "record<CoreNetwork: record<GlobalNetworkId: string, CoreNetworkId: string, CoreNetworkArn: string, Description: string, CreatedAt: string, State: string, Segments: list<record>, Edges: list<record>, Tags: list<record>>>"
    update-core-network: "record<CoreNetwork: record<GlobalNetworkId: string, CoreNetworkId: string, CoreNetworkArn: string, Description: string, CreatedAt: string, State: string, Segments: list<record>, Edges: list<record>, Tags: list<record>>>"
    delete-core-network-policy-version: "record<CoreNetworkPolicy: record<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string, PolicyErrors: list<record>, PolicyDocument: string>>"
    delete-device: "record<Device: record<DeviceId: string, DeviceArn: string, GlobalNetworkId: string, AWSLocation: record<Zone: string, SubnetArn: string>, Description: string, Type: string, Vendor: string, Model: string, SerialNumber: string, Location: record<Address: string, Latitude: string, Longitude: string>, SiteId: string, CreatedAt: string, State: string, Tags: list<record>>>"
    update-device: "record<Device: record<DeviceId: string, DeviceArn: string, GlobalNetworkId: string, AWSLocation: record<Zone: string, SubnetArn: string>, Description: string, Type: string, Vendor: string, Model: string, SerialNumber: string, Location: record<Address: string, Latitude: string, Longitude: string>, SiteId: string, CreatedAt: string, State: string, Tags: list<record>>>"
    delete-global-network: "record<GlobalNetwork: record<GlobalNetworkId: string, GlobalNetworkArn: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>"
    update-global-network: "record<GlobalNetwork: record<GlobalNetworkId: string, GlobalNetworkArn: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>"
    delete-link: "record<Link: record<LinkId: string, LinkArn: string, GlobalNetworkId: string, SiteId: string, Description: string, Type: string, Bandwidth: record<UploadSpeed: int, DownloadSpeed: int>, Provider: string, CreatedAt: string, State: string, Tags: list<record>>>"
    update-link: "record<Link: record<LinkId: string, LinkArn: string, GlobalNetworkId: string, SiteId: string, Description: string, Type: string, Bandwidth: record<UploadSpeed: int, DownloadSpeed: int>, Provider: string, CreatedAt: string, State: string, Tags: list<record>>>"
    delete-peering: "record<Peering: record<CoreNetworkId: string, CoreNetworkArn: string, PeeringId: string, OwnerAccountId: string, PeeringType: string, State: string, EdgeLocation: string, ResourceArn: string, Tags: list<record>, CreatedAt: string>>"
    delete-resource-policy: "record"
    get-resource-policy: "record<PolicyDocument: string>"
    put-resource-policy: "record"
    delete-site: "record<Site: record<SiteId: string, SiteArn: string, GlobalNetworkId: string, Description: string, Location: record<Address: string, Latitude: string, Longitude: string>, CreatedAt: string, State: string, Tags: list<record>>>"
    update-site: "record<Site: record<SiteId: string, SiteArn: string, GlobalNetworkId: string, Description: string, Location: record<Address: string, Latitude: string, Longitude: string>, CreatedAt: string, State: string, Tags: list<record>>>"
    deregister-transit-gateway: "record<TransitGatewayRegistration: record<GlobalNetworkId: string, TransitGatewayArn: string, State: record<Code: string, Message: string>>>"
    disassociate-connect-peer: "record<ConnectPeerAssociation: record<ConnectPeerId: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>"
    disassociate-customer-gateway: "record<CustomerGatewayAssociation: record<CustomerGatewayArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>"
    disassociate-link: "record<LinkAssociation: record<GlobalNetworkId: string, DeviceId: string, LinkId: string, LinkAssociationState: string>>"
    disassociate-transit-gateway-connect-peer: "record<TransitGatewayConnectPeerAssociation: record<TransitGatewayConnectPeerArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>"
    execute-core-network-change-set: "record"
    get-connect-attachment: "record<ConnectAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, TransportAttachmentId: string, Options: record<Protocol: string>>>"
    get-core-network-change-events: "record<CoreNetworkChangeEvents: table<Type: string, Action: string, IdentifierPath: string, EventTime: string, Status: string, Values: record>, NextToken: string>"
    get-core-network-change-set: "record<CoreNetworkChanges: table<Type: string, Action: string, Identifier: string, PreviousValues: record, NewValues: record, IdentifierPath: string>, NextToken: string>"
    get-core-network-policy: "record<CoreNetworkPolicy: record<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string, PolicyErrors: list<record>, PolicyDocument: string>>"
    put-core-network-policy: "record<CoreNetworkPolicy: record<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string, PolicyErrors: list<record>, PolicyDocument: string>>"
    get-network-resource-counts: "record<NetworkResourceCounts: table<ResourceType: string, Count: int>, NextToken: string>"
    get-network-resource-relationships: "record<Relationships: table<From: string, To: string>, NextToken: string>"
    get-network-resources: "record<NetworkResources: table<RegisteredGatewayArn: string, CoreNetworkId: string, AwsRegion: string, AccountId: string, ResourceType: string, ResourceId: string, ResourceArn: string, Definition: string, DefinitionTimestamp: string, Tags: list, Metadata: record>, NextToken: string>"
    get-network-routes: "record<RouteTableArn: string, CoreNetworkSegmentEdge: record<CoreNetworkId: string, SegmentName: string, EdgeLocation: string>, RouteTableType: string, RouteTableTimestamp: string, NetworkRoutes: table<DestinationCidrBlock: string, Destinations: list, PrefixListId: string, State: string, Type: string>>"
    get-network-telemetry: "record<NetworkTelemetry: table<RegisteredGatewayArn: string, CoreNetworkId: string, AwsRegion: string, AccountId: string, ResourceType: string, ResourceId: string, ResourceArn: string, Address: string, Health: record>, NextToken: string>"
    get-route-analysis: "record<RouteAnalysis: record<GlobalNetworkId: string, OwnerAccountId: string, RouteAnalysisId: string, StartTimestamp: string, Status: string, Source: record<TransitGatewayAttachmentArn: string, TransitGatewayArn: string, IpAddress: string>, Destination: record<TransitGatewayAttachmentArn: string, TransitGatewayArn: string, IpAddress: string>, IncludeReturnPath: bool, UseMiddleboxes: bool, ForwardPath: record<CompletionStatus: record, Path: list>, ReturnPath: record<CompletionStatus: record, Path: list>>>"
    get-site-to-site-vpn-attachment: "record<SiteToSiteVpnAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, VpnConnectionArn: string>>"
    get-transit-gateway-peering: "record<TransitGatewayPeering: record<Peering: record<CoreNetworkId: string, CoreNetworkArn: string, PeeringId: string, OwnerAccountId: string, PeeringType: string, State: string, EdgeLocation: string, ResourceArn: string, Tags: list, CreatedAt: string>, TransitGatewayArn: string, TransitGatewayPeeringAttachmentId: string>>"
    get-transit-gateway-registrations: "record<TransitGatewayRegistrations: table<GlobalNetworkId: string, TransitGatewayArn: string, State: record>, NextToken: string>"
    register-transit-gateway: "record<TransitGatewayRegistration: record<GlobalNetworkId: string, TransitGatewayArn: string, State: record<Code: string, Message: string>>>"
    get-transit-gateway-route-table-attachment: "record<TransitGatewayRouteTableAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, PeeringId: string, TransitGatewayRouteTableArn: string>>"
    get-vpc-attachment: "record<VpcAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, SubnetArns: list<string>, Options: record<Ipv6Support: bool, ApplianceModeSupport: bool>>>"
    update-vpc-attachment: "record<VpcAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, SubnetArns: list<string>, Options: record<Ipv6Support: bool, ApplianceModeSupport: bool>>>"
    list-attachments: "record<Attachments: table<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, NextToken: string>"
    list-core-network-policy-versions: "record<CoreNetworkPolicyVersions: table<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string>, NextToken: string>"
    list-organization-service-access-status: "record<OrganizationStatus: record<OrganizationId: string, OrganizationAwsServiceAccessStatus: string, SLRDeploymentStatus: string, AccountStatusList: list<record>>, NextToken: string>"
    start-organization-service-access-update: "record<OrganizationStatus: record<OrganizationId: string, OrganizationAwsServiceAccessStatus: string, SLRDeploymentStatus: string, AccountStatusList: list<record>>>"
    list-peerings: "record<Peerings: table<CoreNetworkId: string, CoreNetworkArn: string, PeeringId: string, OwnerAccountId: string, PeeringType: string, State: string, EdgeLocation: string, ResourceArn: string, Tags: list, CreatedAt: string>, NextToken: string>"
    list-tags-for-resource: "record<TagList: table<Key: string, Value: string>>"
    tag-resource: "record"
    reject-attachment: "record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list<record>, ProposedSegmentChange: record<Tags: list, AttachmentPolicyRuleNumber: int, SegmentName: string>, CreatedAt: string, UpdatedAt: string>>"
    restore-core-network-policy-version: "record<CoreNetworkPolicy: record<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string, PolicyErrors: list<record>, PolicyDocument: string>>"
    start-route-analysis: "record<RouteAnalysis: record<GlobalNetworkId: string, OwnerAccountId: string, RouteAnalysisId: string, StartTimestamp: string, Status: string, Source: record<TransitGatewayAttachmentArn: string, TransitGatewayArn: string, IpAddress: string>, Destination: record<TransitGatewayAttachmentArn: string, TransitGatewayArn: string, IpAddress: string>, IncludeReturnPath: bool, UseMiddleboxes: bool, ForwardPath: record<CompletionStatus: record, Path: list>, ReturnPath: record<CompletionStatus: record, Path: list>>>"
    untag-resource: "record"
    update-network-resource-metadata: "record<ResourceArn: string, Metadata: record>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-attachment" "associate-connect-peer" "get-connect-peer-associations" "associate-customer-gateway" "get-customer-gateway-associations" "associate-link" "get-link-associations" "associate-transit-gateway-connect-peer" "get-transit-gateway-connect-peer-associations" "create-connect-attachment" "create-connect-peer" "list-connect-peers" "create-connection" "get-connections" "create-core-network" "list-core-networks" "create-device" "get-devices" "create-global-network" "describe-global-networks" "create-link" "get-links" "create-site" "get-sites" "create-site-to-site-vpn-attachment" "create-transit-gateway-peering" "create-transit-gateway-route-table-attachment" "create-vpc-attachment" "delete-attachment" "delete-connect-peer" "get-connect-peer" "delete-connection" "update-connection" "delete-core-network" "get-core-network" "update-core-network" "delete-core-network-policy-version" "delete-device" "update-device" "delete-global-network" "update-global-network" "delete-link" "update-link" "delete-peering" "delete-resource-policy" "get-resource-policy" "put-resource-policy" "delete-site" "update-site" "deregister-transit-gateway" "disassociate-connect-peer" "disassociate-customer-gateway" "disassociate-link" "disassociate-transit-gateway-connect-peer" "execute-core-network-change-set" "get-connect-attachment" "get-core-network-change-events" "get-core-network-change-set" "get-core-network-policy" "put-core-network-policy" "get-network-resource-counts" "get-network-resource-relationships" "get-network-resources" "get-network-routes" "get-network-telemetry" "get-route-analysis" "get-site-to-site-vpn-attachment" "get-transit-gateway-peering" "get-transit-gateway-registrations" "register-transit-gateway" "get-transit-gateway-route-table-attachment" "get-vpc-attachment" "update-vpc-attachment" "list-attachments" "list-core-network-policy-versions" "list-organization-service-access-status" "start-organization-service-access-update" "list-peerings" "list-tags-for-resource" "tag-resource" "reject-attachment" "restore-core-network-policy-version" "start-route-analysis" "untag-resource" "update-network-resource-metadata" "commands"] | sort) } | get name | first)
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

# Accepts a core network attachment request. Once the attachment request is accepted by a core network owner, the attachment is created and connected to a core network.
#
# POST /attachments/{attachmentId}/accept
# Returns: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list<record>, ProposedSegmentChange: record<Tags: list, AttachmentPolicyRuleNumber: int, SegmentName: string>, CreatedAt: string, UpdatedAt: string>>
# operationId: AcceptAttachment
export def "accept-attachment" [
  attachment_id: string
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
    method: post
    path: "/attachments/{attachmentId}/accept"
    path_params: [{name: attachmentId, var: attachment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_id: $attachment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a core network Connect peer with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. You can only associate core network Connect peers that have been created on a core network Connect attachment on a core network.
#
# POST /global-networks/{globalNetworkId}/connect-peer-associations
# Returns: record<ConnectPeerAssociation: record<ConnectPeerId: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>
# operationId: AssociateConnectPeer
export def "associate-connect-peer" [
  global_network_id: string
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
  connect_peer_id: string # The ID of the Connect peer.
  device_id: string # The ID of the device.
  --link-id: string # The ID of the link.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/connect-peer-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConnectPeerId, var: connect_peer_id}, {name: DeviceId, var: device_id}, {name: LinkId, var: link_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connect_peer_id: $connect_peer_id, device_id: $device_id, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a core network Connect peer associations.
#
# GET /global-networks/{globalNetworkId}/connect-peer-associations
# Returns: record<ConnectPeerAssociations: table<ConnectPeerId: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>, NextToken: string>
# operationId: GetConnectPeerAssociations
export def "get-connect-peer-associations" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connect-peer-ids: list<string> # The IDs of the Connect peers.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/connect-peer-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: connectPeerIds, var: connect_peer_ids, style: multi}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, connect_peer_ids: $connect_peer_ids, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a customer gateway with a device and optionally, with a link. If you specify a link, it must be associated with the specified device. You can only associate customer gateways that are connected to a VPN attachment on a transit gateway or core network registered in your global network. When you register a transit gateway or core network, customer gateways that are connected to the transit gateway are automatically included in the global network. To list customer gateways that are connected to a transit gateway, use the DescribeVpnConnections (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpnConnections.html) EC2 API and filter by transit-gateway-id. You cannot associate a customer gateway with more than one device and link.
#
# POST /global-networks/{globalNetworkId}/customer-gateway-associations
# Returns: record<CustomerGatewayAssociation: record<CustomerGatewayArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>
# operationId: AssociateCustomerGateway
export def "associate-customer-gateway" [
  global_network_id: string
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
  customer_gateway_arn: string # The Amazon Resource Name (ARN) of the customer gateway.
  device_id: string # The ID of the device.
  --link-id: string # The ID of the link.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/customer-gateway-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CustomerGatewayArn, var: customer_gateway_arn}, {name: DeviceId, var: device_id}, {name: LinkId, var: link_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, customer_gateway_arn: $customer_gateway_arn, device_id: $device_id, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the association information for customer gateways that are associated with devices and links in your global network.
#
# GET /global-networks/{globalNetworkId}/customer-gateway-associations
# Returns: record<CustomerGatewayAssociations: table<CustomerGatewayArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>, NextToken: string>
# operationId: GetCustomerGatewayAssociations
export def "get-customer-gateway-associations" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-gateway-arns: list<string> # One or more customer gateway Amazon Resource Names (ARNs). The maximum is 10.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/customer-gateway-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: customerGatewayArns, var: customer_gateway_arns, style: multi}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, customer_gateway_arns: $customer_gateway_arns, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a link to a device. A device can be associated to multiple links and a link can be associated to multiple devices. The device and link must be in the same global network and the same site.
#
# POST /global-networks/{globalNetworkId}/link-associations
# Returns: record<LinkAssociation: record<GlobalNetworkId: string, DeviceId: string, LinkId: string, LinkAssociationState: string>>
# operationId: AssociateLink
export def "associate-link" [
  global_network_id: string
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
  device_id: string # The ID of the device.
  link_id: string # The ID of the link.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/link-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DeviceId, var: device_id}, {name: LinkId, var: link_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, device_id: $device_id, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the link associations for a device or a link. Either the device ID or the link ID must be specified.
#
# GET /global-networks/{globalNetworkId}/link-associations
# Returns: record<LinkAssociations: table<GlobalNetworkId: string, DeviceId: string, LinkId: string, LinkAssociationState: string>, NextToken: string>
# operationId: GetLinkAssociations
export def "get-link-associations" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The ID of the device.
  --link-id: string # The ID of the link.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/link-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: deviceId, var: device_id}, {name: linkId, var: link_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, device_id: $device_id, link_id: $link_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associates a transit gateway Connect peer with a device, and optionally, with a link. If you specify a link, it must be associated with the specified device. You can only associate transit gateway Connect peers that have been created on a transit gateway that's registered in your global network. You cannot associate a transit gateway Connect peer with more than one device and link.
#
# POST /global-networks/{globalNetworkId}/transit-gateway-connect-peer-associations
# Returns: record<TransitGatewayConnectPeerAssociation: record<TransitGatewayConnectPeerArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>
# operationId: AssociateTransitGatewayConnectPeer
export def "associate-transit-gateway-connect-peer" [
  global_network_id: string
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
  transit_gateway_connect_peer_arn: string # The Amazon Resource Name (ARN) of the Connect peer.
  device_id: string # The ID of the device.
  --link-id: string # The ID of the link.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/transit-gateway-connect-peer-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransitGatewayConnectPeerArn, var: transit_gateway_connect_peer_arn}, {name: DeviceId, var: device_id}, {name: LinkId, var: link_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, transit_gateway_connect_peer_arn: $transit_gateway_connect_peer_arn, device_id: $device_id, link_id: $link_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more of your transit gateway Connect peer associations in a global network.
#
# GET /global-networks/{globalNetworkId}/transit-gateway-connect-peer-associations
# Returns: record<TransitGatewayConnectPeerAssociations: table<TransitGatewayConnectPeerArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>, NextToken: string>
# operationId: GetTransitGatewayConnectPeerAssociations
export def "get-transit-gateway-connect-peer-associations" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transit-gateway-connect-peer-arns: list<string> # One or more transit gateway Connect peer Amazon Resource Names (ARNs).
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/transit-gateway-connect-peer-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: transitGatewayConnectPeerArns, var: transit_gateway_connect_peer_arns, style: multi}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, transit_gateway_connect_peer_arns: $transit_gateway_connect_peer_arns, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a core network Connect attachment from a specified core network attachment. A core network Connect attachment is a GRE-based tunnel attachment that you can use to establish a connection between a core network and an appliance. A core network Connect attachment uses an existing VPC attachment as the underlying transport mechanism.
#
# POST /connect-attachments
# Returns: record<ConnectAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, TransportAttachmentId: string, Options: record<Protocol: string>>>
# operationId: CreateConnectAttachment
export def "create-connect-attachment" [
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
  core_network_id: string # The ID of a core network where you want to create the attachment.
  edge_location: string # The Region where the edge is located.
  transport_attachment_id: string # The ID of the attachment between the two connections.
  options: record # Describes a core network Connect attachment options. — shape: {Protocol?: "GRE"}
  --tags: list # The list of key-value tags associated with the request. — item shape: {Key?: string, Value?: string}
  --client-token: string # The client token associated with the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/connect-attachments"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CoreNetworkId, var: core_network_id}, {name: EdgeLocation, var: edge_location}, {name: TransportAttachmentId, var: transport_attachment_id}, {name: Options, var: options}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, core_network_id: $core_network_id, edge_location: $edge_location, transport_attachment_id: $transport_attachment_id, options: $options, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a core network Connect peer for a specified core network connect attachment between a core network and an appliance. The peer address and transit gateway address must be the same IP address family (IPv4 or IPv6).
#
# POST /connect-peers
# Returns: record<ConnectPeer: record<CoreNetworkId: string, ConnectAttachmentId: string, ConnectPeerId: string, EdgeLocation: string, State: string, CreatedAt: string, Configuration: record<CoreNetworkAddress: string, PeerAddress: string, InsideCidrBlocks: list, Protocol: string, BgpConfigurations: list>, Tags: list<record>>>
# operationId: CreateConnectPeer
export def "create-connect-peer" [
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
  connect_attachment_id: string # The ID of the connection attachment.
  --core-network-address: string # A Connect peer core network address.
  peer_address: string # The Connect peer address.
  --bgp-options: record # Describes the BGP options. — shape: {PeerAsn?: int}
  inside_cidr_blocks: list<string> # The inside IP addresses used for BGP peering.
  --tags: list # The tags associated with the peer request. — item shape: {Key?: string, Value?: string}
  --client-token: string # The client token associated with the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/connect-peers"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ConnectAttachmentId, var: connect_attachment_id}, {name: CoreNetworkAddress, var: core_network_address}, {name: PeerAddress, var: peer_address}, {name: BgpOptions, var: bgp_options}, {name: InsideCidrBlocks, var: inside_cidr_blocks}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, connect_attachment_id: $connect_attachment_id, core_network_address: $core_network_address, peer_address: $peer_address, bgp_options: $bgp_options, inside_cidr_blocks: $inside_cidr_blocks, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of core network Connect peers.
#
# GET /connect-peers
# Returns: record<ConnectPeers: table<CoreNetworkId: string, ConnectAttachmentId: string, ConnectPeerId: string, EdgeLocation: string, ConnectPeerState: string, CreatedAt: string, Tags: list>, NextToken: string>
# operationId: ListConnectPeers
export def "list-connect-peers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --core-network-id: string # The ID of a core network.
  --connect-attachment-id: string # The ID of the attachment.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/connect-peers"
    query: [{name: coreNetworkId, var: core_network_id}, {name: connectAttachmentId, var: connect_attachment_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, connect_attachment_id: $connect_attachment_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a connection between two devices. The devices can be a physical or virtual appliance that connects to a third-party appliance in a VPC, or a physical appliance that connects to another physical appliance in an on-premises network.
#
# POST /global-networks/{globalNetworkId}/connections
# Returns: record<Connection: record<ConnectionId: string, ConnectionArn: string, GlobalNetworkId: string, DeviceId: string, ConnectedDeviceId: string, LinkId: string, ConnectedLinkId: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: CreateConnection
export def "create-connection" [
  global_network_id: string
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
  device_id: string # The ID of the first device in the connection.
  connected_device_id: string # The ID of the second device in the connection.
  --link-id: string # The ID of the link for the first device.
  --connected-link-id: string # The ID of the link for the second device.
  --description: string # A description of the connection. Length Constraints: Maximum length of 256 characters.
  --tags: list # The tags to apply to the resource during creation. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/connections"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DeviceId, var: device_id}, {name: ConnectedDeviceId, var: connected_device_id}, {name: LinkId, var: link_id}, {name: ConnectedLinkId, var: connected_link_id}, {name: Description, var: description}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, device_id: $device_id, connected_device_id: $connected_device_id, link_id: $link_id, connected_link_id: $connected_link_id, description: $description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more of your connections in a global network.
#
# GET /global-networks/{globalNetworkId}/connections
# Returns: record<Connections: table<ConnectionId: string, ConnectionArn: string, GlobalNetworkId: string, DeviceId: string, ConnectedDeviceId: string, LinkId: string, ConnectedLinkId: string, Description: string, CreatedAt: string, State: string, Tags: list>, NextToken: string>
# operationId: GetConnections
export def "get-connections" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-ids: list<string> # One or more connection IDs.
  --device-id: string # The ID of the device.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/connections"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: connectionIds, var: connection_ids, style: multi}, {name: deviceId, var: device_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, connection_ids: $connection_ids, device_id: $device_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a core network as part of your global network, and optionally, with a core network policy.
#
# POST /core-networks
# Returns: record<CoreNetwork: record<GlobalNetworkId: string, CoreNetworkId: string, CoreNetworkArn: string, Description: string, CreatedAt: string, State: string, Segments: list<record>, Edges: list<record>, Tags: list<record>>>
# operationId: CreateCoreNetwork
export def "create-core-network" [
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
  global_network_id: string # The ID of the global network that a core network will be a part of.
  --description: string # The description of a core network.
  --tags: list # Key-value tags associated with a core network request. — item shape: {Key?: string, Value?: string}
  --policy-document: string # The policy document for creating a core network.
  --client-token: string # The client token associated with a core network request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/core-networks"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GlobalNetworkId, var: global_network_id}, {name: Description, var: description}, {name: Tags, var: tags}, {name: PolicyDocument, var: policy_document}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, global_network_id: $global_network_id, description: $description, tags: $tags, policy_document: $policy_document, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of owned and shared core networks.
#
# GET /core-networks
# Returns: record<CoreNetworks: table<CoreNetworkId: string, CoreNetworkArn: string, GlobalNetworkId: string, OwnerAccountId: string, State: string, Description: string, Tags: list>, NextToken: string>
# operationId: ListCoreNetworks
export def "list-core-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/core-networks"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new device in a global network. If you specify both a site ID and a location, the location of the site is used for visualization in the Network Manager console.
#
# POST /global-networks/{globalNetworkId}/devices
# Returns: record<Device: record<DeviceId: string, DeviceArn: string, GlobalNetworkId: string, AWSLocation: record<Zone: string, SubnetArn: string>, Description: string, Type: string, Vendor: string, Model: string, SerialNumber: string, Location: record<Address: string, Latitude: string, Longitude: string>, SiteId: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: CreateDevice
export def "create-device" [
  global_network_id: string
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
  --aws-location: record # Specifies a location in Amazon Web Services. — shape: {Zone?: string, SubnetArn?: string}
  --description: string # A description of the device. Constraints: Maximum length of 256 characters.
  --type: string # The type of the device.
  --vendor: string # The vendor of the device. Constraints: Maximum length of 128 characters.
  --model: string # The model of the device. Constraints: Maximum length of 128 characters.
  --serial-number: string # The serial number of the device. Constraints: Maximum length of 128 characters.
  --location: record # Describes a location. — shape: {Address?: string, Latitude?: string, Longitude?: string}
  --site-id: string # The ID of the site.
  --tags: list # The tags to apply to the resource during creation. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/devices"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AWSLocation, var: aws_location}, {name: Description, var: description}, {name: Type, var: type}, {name: Vendor, var: vendor}, {name: Model, var: model}, {name: SerialNumber, var: serial_number}, {name: Location, var: location}, {name: SiteId, var: site_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, aws_location: $aws_location, description: $description, type: $type, vendor: $vendor, model: $model, serial_number: $serial_number, location: $location, site_id: $site_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more of your devices in a global network.
#
# GET /global-networks/{globalNetworkId}/devices
# Returns: record<Devices: table<DeviceId: string, DeviceArn: string, GlobalNetworkId: string, AWSLocation: record, Description: string, Type: string, Vendor: string, Model: string, SerialNumber: string, Location: record, SiteId: string, CreatedAt: string, State: string, Tags: list>, NextToken: string>
# operationId: GetDevices
export def "get-devices" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-ids: list<string> # One or more device IDs. The maximum is 10.
  --site-id: string # The ID of the site.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/devices"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: deviceIds, var: device_ids, style: multi}, {name: siteId, var: site_id}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, device_ids: $device_ids, site_id: $site_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new, empty global network.
#
# POST /global-networks
# Returns: record<GlobalNetwork: record<GlobalNetworkId: string, GlobalNetworkArn: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: CreateGlobalNetwork
export def "create-global-network" [
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
  --description: string # A description of the global network. Constraints: Maximum length of 256 characters.
  --tags: list # The tags to apply to the resource during creation. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes one or more global networks. By default, all global networks are described. To describe the objects in your global network, you must use the appropriate Get* action. For example, to list the transit gateways in your global network, use GetTransitGatewayRegistrations.
#
# GET /global-networks
# Returns: record<GlobalNetworks: table<GlobalNetworkId: string, GlobalNetworkArn: string, Description: string, CreatedAt: string, State: string, Tags: list>, NextToken: string>
# operationId: DescribeGlobalNetworks
export def "describe-global-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-network-ids: list<string> # The IDs of one or more global networks. The maximum is 10.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks"
    query: [{name: globalNetworkIds, var: global_network_ids, style: multi}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_ids: $global_network_ids, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new link for a specified site.
#
# POST /global-networks/{globalNetworkId}/links
# Returns: record<Link: record<LinkId: string, LinkArn: string, GlobalNetworkId: string, SiteId: string, Description: string, Type: string, Bandwidth: record<UploadSpeed: int, DownloadSpeed: int>, Provider: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: CreateLink
export def "create-link" [
  global_network_id: string
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
  --description: string # A description of the link. Constraints: Maximum length of 256 characters.
  --type: string # The type of the link. Constraints: Maximum length of 128 characters. Cannot include the following characters: | \ ^
  bandwidth: record # Describes bandwidth information. — shape: {UploadSpeed?: int, DownloadSpeed?: int}
  --provider: string # The provider of the link. Constraints: Maximum length of 128 characters. Cannot include the following characters: | \ ^
  site_id: string # The ID of the site.
  --tags: list # The tags to apply to the resource during creation. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/links"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Type, var: type}, {name: Bandwidth, var: bandwidth}, {name: Provider, var: provider}, {name: SiteId, var: site_id}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, type: $type, bandwidth: $bandwidth, provider: $provider, site_id: $site_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more links in a specified global network. If you specify the site ID, you cannot specify the type or provider in the same request. You can specify the type and provider in the same request.
#
# GET /global-networks/{globalNetworkId}/links
# Returns: record<Links: table<LinkId: string, LinkArn: string, GlobalNetworkId: string, SiteId: string, Description: string, Type: string, Bandwidth: record, Provider: string, CreatedAt: string, State: string, Tags: list>, NextToken: string>
# operationId: GetLinks
export def "get-links" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --link-ids: list<string> # One or more link IDs. The maximum is 10.
  --site-id: string # The ID of the site.
  --type: string # The link type.
  --provider: string # The link provider.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/links"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: linkIds, var: link_ids, style: multi}, {name: siteId, var: site_id}, {name: type, var: type}, {name: provider, var: provider}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, link_ids: $link_ids, site_id: $site_id, type: $type, provider: $provider, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new site in a global network.
#
# POST /global-networks/{globalNetworkId}/sites
# Returns: record<Site: record<SiteId: string, SiteArn: string, GlobalNetworkId: string, Description: string, Location: record<Address: string, Latitude: string, Longitude: string>, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: CreateSite
export def "create-site" [
  global_network_id: string
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
  --description: string # A description of your site. Constraints: Maximum length of 256 characters.
  --location: record # Describes a location. — shape: {Address?: string, Latitude?: string, Longitude?: string}
  --tags: list # The tags to apply to the resource during creation. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/sites"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Location, var: location}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about one or more of your sites in a global network.
#
# GET /global-networks/{globalNetworkId}/sites
# Returns: record<Sites: table<SiteId: string, SiteArn: string, GlobalNetworkId: string, Description: string, Location: record, CreatedAt: string, State: string, Tags: list>, NextToken: string>
# operationId: GetSites
export def "get-sites" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-ids: list<string> # One or more site IDs. The maximum is 10.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/sites"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: siteIds, var: site_ids, style: multi}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, site_ids: $site_ids, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon Web Services site-to-site VPN attachment on an edge location of a core network.
#
# POST /site-to-site-vpn-attachments
# Returns: record<SiteToSiteVpnAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, VpnConnectionArn: string>>
# operationId: CreateSiteToSiteVpnAttachment
export def "create-site-to-site-vpn-attachment" [
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
  core_network_id: string # The ID of a core network where you're creating a site-to-site VPN attachment.
  vpn_connection_arn: string # The ARN identifying the VPN attachment.
  --tags: list # The tags associated with the request. — item shape: {Key?: string, Value?: string}
  --client-token: string # The client token associated with the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/site-to-site-vpn-attachments"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CoreNetworkId, var: core_network_id}, {name: VpnConnectionArn, var: vpn_connection_arn}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, core_network_id: $core_network_id, vpn_connection_arn: $vpn_connection_arn, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a transit gateway peering connection.
#
# POST /transit-gateway-peerings
# Returns: record<TransitGatewayPeering: record<Peering: record<CoreNetworkId: string, CoreNetworkArn: string, PeeringId: string, OwnerAccountId: string, PeeringType: string, State: string, EdgeLocation: string, ResourceArn: string, Tags: list, CreatedAt: string>, TransitGatewayArn: string, TransitGatewayPeeringAttachmentId: string>>
# operationId: CreateTransitGatewayPeering
export def "create-transit-gateway-peering" [
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
  core_network_id: string # The ID of a core network.
  transit_gateway_arn: string # The ARN of the transit gateway for the peering request.
  --tags: list # The list of key-value tags associated with the request. — item shape: {Key?: string, Value?: string}
  --client-token: string # The client token associated with the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transit-gateway-peerings"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CoreNetworkId, var: core_network_id}, {name: TransitGatewayArn, var: transit_gateway_arn}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, core_network_id: $core_network_id, transit_gateway_arn: $transit_gateway_arn, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a transit gateway route table attachment.
#
# POST /transit-gateway-route-table-attachments
# Returns: record<TransitGatewayRouteTableAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, PeeringId: string, TransitGatewayRouteTableArn: string>>
# operationId: CreateTransitGatewayRouteTableAttachment
export def "create-transit-gateway-route-table-attachment" [
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
  peering_id: string # The ID of the peer for the
  transit_gateway_route_table_arn: string # The ARN of the transit gateway route table for the attachment request. For example, "TransitGatewayRouteTableArn": "arn:aws:ec2:us-west-2:123456789012:transit-gateway-route-table/tgw-rtb-9876543210123456".
  --tags: list # The list of key-value tags associated with the request. — item shape: {Key?: string, Value?: string}
  --client-token: string # The client token associated with the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transit-gateway-route-table-attachments"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PeeringId, var: peering_id}, {name: TransitGatewayRouteTableArn, var: transit_gateway_route_table_arn}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, peering_id: $peering_id, transit_gateway_route_table_arn: $transit_gateway_route_table_arn, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a VPC attachment on an edge location of a core network.
#
# POST /vpc-attachments
# Returns: record<VpcAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, SubnetArns: list<string>, Options: record<Ipv6Support: bool, ApplianceModeSupport: bool>>>
# operationId: CreateVpcAttachment
export def "create-vpc-attachment" [
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
  core_network_id: string # The ID of a core network for the VPC attachment.
  vpc_arn: string # The ARN of the VPC.
  subnet_arns: list<string> # The subnet ARN of the VPC attachment.
  --options: record # Describes the VPC options. — shape: {Ipv6Support?: bool, ApplianceModeSupport?: bool}
  --tags: list # The key-value tags associated with the request. — item shape: {Key?: string, Value?: string}
  --client-token: string # The client token associated with the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/vpc-attachments"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: CoreNetworkId, var: core_network_id}, {name: VpcArn, var: vpc_arn}, {name: SubnetArns, var: subnet_arns}, {name: Options, var: options}, {name: Tags, var: tags}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, core_network_id: $core_network_id, vpc_arn: $vpc_arn, subnet_arns: $subnet_arns, options: $options, tags: $tags, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an attachment. Supports all attachment types.
#
# DELETE /attachments/{attachmentId}
# Returns: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list<record>, ProposedSegmentChange: record<Tags: list, AttachmentPolicyRuleNumber: int, SegmentName: string>, CreatedAt: string, UpdatedAt: string>>
# operationId: DeleteAttachment
export def "delete-attachment" [
  attachment_id: string
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
    method: delete
    path: "/attachments/{attachmentId}"
    path_params: [{name: attachmentId, var: attachment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_id: $attachment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Connect peer.
#
# DELETE /connect-peers/{connectPeerId}
# Returns: record<ConnectPeer: record<CoreNetworkId: string, ConnectAttachmentId: string, ConnectPeerId: string, EdgeLocation: string, State: string, CreatedAt: string, Configuration: record<CoreNetworkAddress: string, PeerAddress: string, InsideCidrBlocks: list, Protocol: string, BgpConfigurations: list>, Tags: list<record>>>
# operationId: DeleteConnectPeer
export def "delete-connect-peer" [
  connect_peer_id: string
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
    method: delete
    path: "/connect-peers/{connectPeerId}"
    path_params: [{name: connectPeerId, var: connect_peer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connect_peer_id: $connect_peer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a core network Connect peer.
#
# GET /connect-peers/{connectPeerId}
# Returns: record<ConnectPeer: record<CoreNetworkId: string, ConnectAttachmentId: string, ConnectPeerId: string, EdgeLocation: string, State: string, CreatedAt: string, Configuration: record<CoreNetworkAddress: string, PeerAddress: string, InsideCidrBlocks: list, Protocol: string, BgpConfigurations: list>, Tags: list<record>>>
# operationId: GetConnectPeer
export def "get-connect-peer" [
  connect_peer_id: string
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
    path: "/connect-peers/{connectPeerId}"
    path_params: [{name: connectPeerId, var: connect_peer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    connect_peer_id: $connect_peer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified connection in your global network.
#
# DELETE /global-networks/{globalNetworkId}/connections/{connectionId}
# Returns: record<Connection: record<ConnectionId: string, ConnectionArn: string, GlobalNetworkId: string, DeviceId: string, ConnectedDeviceId: string, LinkId: string, ConnectedLinkId: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: DeleteConnection
export def "delete-connection" [
  global_network_id: string
  connection_id: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}/connections/{connectionId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: connectionId, var: connection_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, connection_id: $connection_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the information for an existing connection. To remove information for any of the parameters, specify an empty string.
#
# PATCH /global-networks/{globalNetworkId}/connections/{connectionId}
# Returns: record<Connection: record<ConnectionId: string, ConnectionArn: string, GlobalNetworkId: string, DeviceId: string, ConnectedDeviceId: string, LinkId: string, ConnectedLinkId: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: UpdateConnection
export def "update-connection" [
  global_network_id: string
  connection_id: string
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
  --link-id: string # The ID of the link for the first device in the connection.
  --connected-link-id: string # The ID of the link for the second device in the connection.
  --description: string # A description of the connection. Length Constraints: Maximum length of 256 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/global-networks/{globalNetworkId}/connections/{connectionId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: connectionId, var: connection_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: LinkId, var: link_id}, {name: ConnectedLinkId, var: connected_link_id}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, connection_id: $connection_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, link_id: $link_id, connected_link_id: $connected_link_id, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a core network along with all core network policies. This can only be done if there are no attachments on a core network.
#
# DELETE /core-networks/{coreNetworkId}
# Returns: record<CoreNetwork: record<GlobalNetworkId: string, CoreNetworkId: string, CoreNetworkArn: string, Description: string, CreatedAt: string, State: string, Segments: list<record>, Edges: list<record>, Tags: list<record>>>
# operationId: DeleteCoreNetwork
export def "delete-core-network" [
  core_network_id: string
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
    method: delete
    path: "/core-networks/{coreNetworkId}"
    path_params: [{name: coreNetworkId, var: core_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the LIVE policy for a core network.
#
# GET /core-networks/{coreNetworkId}
# Returns: record<CoreNetwork: record<GlobalNetworkId: string, CoreNetworkId: string, CoreNetworkArn: string, Description: string, CreatedAt: string, State: string, Segments: list<record>, Edges: list<record>, Tags: list<record>>>
# operationId: GetCoreNetwork
export def "get-core-network" [
  core_network_id: string
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
    path: "/core-networks/{coreNetworkId}"
    path_params: [{name: coreNetworkId, var: core_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the description of a core network.
#
# PATCH /core-networks/{coreNetworkId}
# Returns: record<CoreNetwork: record<GlobalNetworkId: string, CoreNetworkId: string, CoreNetworkArn: string, Description: string, CreatedAt: string, State: string, Segments: list<record>, Edges: list<record>, Tags: list<record>>>
# operationId: UpdateCoreNetwork
export def "update-core-network" [
  core_network_id: string
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
  --description: string # The description of the update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/core-networks/{coreNetworkId}"
    path_params: [{name: coreNetworkId, var: core_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a policy version from a core network. You can't delete the current LIVE policy.
#
# DELETE /core-networks/{coreNetworkId}/core-network-policy-versions/{policyVersionId}
# Returns: record<CoreNetworkPolicy: record<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string, PolicyErrors: list<record>, PolicyDocument: string>>
# operationId: DeleteCoreNetworkPolicyVersion
export def "delete-core-network-policy-version" [
  core_network_id: string
  policy_version_id: int
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
    method: delete
    path: "/core-networks/{coreNetworkId}/core-network-policy-versions/{policyVersionId}"
    path_params: [{name: coreNetworkId, var: core_network_id}, {name: policyVersionId, var: policy_version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, policy_version_id: $policy_version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing device. You must first disassociate the device from any links and customer gateways.
#
# DELETE /global-networks/{globalNetworkId}/devices/{deviceId}
# Returns: record<Device: record<DeviceId: string, DeviceArn: string, GlobalNetworkId: string, AWSLocation: record<Zone: string, SubnetArn: string>, Description: string, Type: string, Vendor: string, Model: string, SerialNumber: string, Location: record<Address: string, Latitude: string, Longitude: string>, SiteId: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: DeleteDevice
export def "delete-device" [
  global_network_id: string
  device_id: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}/devices/{deviceId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: deviceId, var: device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, device_id: $device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the details for an existing device. To remove information for any of the parameters, specify an empty string.
#
# PATCH /global-networks/{globalNetworkId}/devices/{deviceId}
# Returns: record<Device: record<DeviceId: string, DeviceArn: string, GlobalNetworkId: string, AWSLocation: record<Zone: string, SubnetArn: string>, Description: string, Type: string, Vendor: string, Model: string, SerialNumber: string, Location: record<Address: string, Latitude: string, Longitude: string>, SiteId: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: UpdateDevice
export def "update-device" [
  global_network_id: string
  device_id: string
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
  --aws-location: record # Specifies a location in Amazon Web Services. — shape: {Zone?: string, SubnetArn?: string}
  --description: string # A description of the device. Constraints: Maximum length of 256 characters.
  --type: string # The type of the device.
  --vendor: string # The vendor of the device. Constraints: Maximum length of 128 characters.
  --model: string # The model of the device. Constraints: Maximum length of 128 characters.
  --serial-number: string # The serial number of the device. Constraints: Maximum length of 128 characters.
  --location: record # Describes a location. — shape: {Address?: string, Latitude?: string, Longitude?: string}
  --site-id: string # The ID of the site.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/global-networks/{globalNetworkId}/devices/{deviceId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: deviceId, var: device_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AWSLocation, var: aws_location}, {name: Description, var: description}, {name: Type, var: type}, {name: Vendor, var: vendor}, {name: Model, var: model}, {name: SerialNumber, var: serial_number}, {name: Location, var: location}, {name: SiteId, var: site_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, device_id: $device_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, aws_location: $aws_location, description: $description, type: $type, vendor: $vendor, model: $model, serial_number: $serial_number, location: $location, site_id: $site_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing global network. You must first delete all global network objects (devices, links, and sites), deregister all transit gateways, and delete any core networks.
#
# DELETE /global-networks/{globalNetworkId}
# Returns: record<GlobalNetwork: record<GlobalNetworkId: string, GlobalNetworkArn: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: DeleteGlobalNetwork
export def "delete-global-network" [
  global_network_id: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing global network. To remove information for any of the parameters, specify an empty string.
#
# PATCH /global-networks/{globalNetworkId}
# Returns: record<GlobalNetwork: record<GlobalNetworkId: string, GlobalNetworkArn: string, Description: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: UpdateGlobalNetwork
export def "update-global-network" [
  global_network_id: string
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
  --description: string # A description of the global network. Constraints: Maximum length of 256 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/global-networks/{globalNetworkId}"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing link. You must first disassociate the link from any devices and customer gateways.
#
# DELETE /global-networks/{globalNetworkId}/links/{linkId}
# Returns: record<Link: record<LinkId: string, LinkArn: string, GlobalNetworkId: string, SiteId: string, Description: string, Type: string, Bandwidth: record<UploadSpeed: int, DownloadSpeed: int>, Provider: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: DeleteLink
export def "delete-link" [
  global_network_id: string
  link_id: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}/links/{linkId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: linkId, var: link_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, link_id: $link_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the details for an existing link. To remove information for any of the parameters, specify an empty string.
#
# PATCH /global-networks/{globalNetworkId}/links/{linkId}
# Returns: record<Link: record<LinkId: string, LinkArn: string, GlobalNetworkId: string, SiteId: string, Description: string, Type: string, Bandwidth: record<UploadSpeed: int, DownloadSpeed: int>, Provider: string, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: UpdateLink
export def "update-link" [
  global_network_id: string
  link_id: string
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
  --description: string # A description of the link. Constraints: Maximum length of 256 characters.
  --type: string # The type of the link. Constraints: Maximum length of 128 characters.
  --bandwidth: record # Describes bandwidth information. — shape: {UploadSpeed?: int, DownloadSpeed?: int}
  --provider: string # The provider of the link. Constraints: Maximum length of 128 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/global-networks/{globalNetworkId}/links/{linkId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: linkId, var: link_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Type, var: type}, {name: Bandwidth, var: bandwidth}, {name: Provider, var: provider}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, link_id: $link_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, type: $type, bandwidth: $bandwidth, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing peering connection.
#
# DELETE /peerings/{peeringId}
# Returns: record<Peering: record<CoreNetworkId: string, CoreNetworkArn: string, PeeringId: string, OwnerAccountId: string, PeeringType: string, State: string, EdgeLocation: string, ResourceArn: string, Tags: list<record>, CreatedAt: string>>
# operationId: DeletePeering
export def "delete-peering" [
  peering_id: string
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
    method: delete
    path: "/peerings/{peeringId}"
    path_params: [{name: peeringId, var: peering_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    peering_id: $peering_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a resource policy for the specified resource. This revokes the access of the principals specified in the resource policy.
#
# DELETE /resource-policy/{resourceArn}
# Returns: record
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
  resource_arn: string
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
    method: delete
    path: "/resource-policy/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a resource policy.
#
# GET /resource-policy/{resourceArn}
# Returns: record<PolicyDocument: string>
# operationId: GetResourcePolicy
export def "get-resource-policy" [
  resource_arn: string
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
    path: "/resource-policy/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a resource policy.
#
# POST /resource-policy/{resourceArn}
# Returns: record
# operationId: PutResourcePolicy
export def "put-resource-policy" [
  resource_arn: string
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
  policy_document: string # The JSON resource policy document.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/resource-policy/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyDocument, var: policy_document}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, policy_document: $policy_document
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing site. The site cannot be associated with any device or link.
#
# DELETE /global-networks/{globalNetworkId}/sites/{siteId}
# Returns: record<Site: record<SiteId: string, SiteArn: string, GlobalNetworkId: string, Description: string, Location: record<Address: string, Latitude: string, Longitude: string>, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: DeleteSite
export def "delete-site" [
  global_network_id: string
  site_id: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}/sites/{siteId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: siteId, var: site_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, site_id: $site_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the information for an existing site. To remove information for any of the parameters, specify an empty string.
#
# PATCH /global-networks/{globalNetworkId}/sites/{siteId}
# Returns: record<Site: record<SiteId: string, SiteArn: string, GlobalNetworkId: string, Description: string, Location: record<Address: string, Latitude: string, Longitude: string>, CreatedAt: string, State: string, Tags: list<record>>>
# operationId: UpdateSite
export def "update-site" [
  global_network_id: string
  site_id: string
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
  --description: string # A description of your site. Constraints: Maximum length of 256 characters.
  --location: record # Describes a location. — shape: {Address?: string, Latitude?: string, Longitude?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/global-networks/{globalNetworkId}/sites/{siteId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: siteId, var: site_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Location, var: location}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, site_id: $site_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deregisters a transit gateway from your global network. This action does not delete your transit gateway, or modify any of its attachments. This action removes any customer gateway associations.
#
# DELETE /global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}
# Returns: record<TransitGatewayRegistration: record<GlobalNetworkId: string, TransitGatewayArn: string, State: record<Code: string, Message: string>>>
# operationId: DeregisterTransitGateway
export def "deregister-transit-gateway" [
  global_network_id: string
  transit_gateway_arn: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}/transit-gateway-registrations/{transitGatewayArn}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: transitGatewayArn, var: transit_gateway_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, transit_gateway_arn: $transit_gateway_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a core network Connect peer from a device and a link.
#
# DELETE /global-networks/{globalNetworkId}/connect-peer-associations/{connectPeerId}
# Returns: record<ConnectPeerAssociation: record<ConnectPeerId: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>
# operationId: DisassociateConnectPeer
export def "disassociate-connect-peer" [
  global_network_id: string
  connect_peer_id: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}/connect-peer-associations/{connectPeerId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: connectPeerId, var: connect_peer_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, connect_peer_id: $connect_peer_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a customer gateway from a device and a link.
#
# DELETE /global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}
# Returns: record<CustomerGatewayAssociation: record<CustomerGatewayArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>
# operationId: DisassociateCustomerGateway
export def "disassociate-customer-gateway" [
  global_network_id: string
  customer_gateway_arn: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}/customer-gateway-associations/{customerGatewayArn}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: customerGatewayArn, var: customer_gateway_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, customer_gateway_arn: $customer_gateway_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates an existing device from a link. You must first disassociate any customer gateways that are associated with the link.
#
# DELETE /global-networks/{globalNetworkId}/link-associations
# Returns: record<LinkAssociation: record<GlobalNetworkId: string, DeviceId: string, LinkId: string, LinkAssociationState: string>>
# operationId: DisassociateLink
export def "disassociate-link" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The ID of the device. (required)
  --link-id: string # The ID of the link. (required)
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
    path: "/global-networks/{globalNetworkId}/link-associations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: deviceId, var: device_id, required: true}, {name: linkId, var: link_id, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, device_id: $device_id, link_id: $link_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociates a transit gateway Connect peer from a device and link.
#
# DELETE /global-networks/{globalNetworkId}/transit-gateway-connect-peer-associations/{transitGatewayConnectPeerArn}
# Returns: record<TransitGatewayConnectPeerAssociation: record<TransitGatewayConnectPeerArn: string, GlobalNetworkId: string, DeviceId: string, LinkId: string, State: string>>
# operationId: DisassociateTransitGatewayConnectPeer
export def "disassociate-transit-gateway-connect-peer" [
  global_network_id: string
  transit_gateway_connect_peer_arn: string
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
    method: delete
    path: "/global-networks/{globalNetworkId}/transit-gateway-connect-peer-associations/{transitGatewayConnectPeerArn}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: transitGatewayConnectPeerArn, var: transit_gateway_connect_peer_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, transit_gateway_connect_peer_arn: $transit_gateway_connect_peer_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes a change set on your core network. Deploys changes globally based on the policy submitted..
#
# POST /core-networks/{coreNetworkId}/core-network-change-sets/{policyVersionId}/execute
# Returns: record
# operationId: ExecuteCoreNetworkChangeSet
export def "execute-core-network-change-set" [
  core_network_id: string
  policy_version_id: int
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
    method: post
    path: "/core-networks/{coreNetworkId}/core-network-change-sets/{policyVersionId}/execute"
    path_params: [{name: coreNetworkId, var: core_network_id}, {name: policyVersionId, var: policy_version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, policy_version_id: $policy_version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a core network Connect attachment.
#
# GET /connect-attachments/{attachmentId}
# Returns: record<ConnectAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, TransportAttachmentId: string, Options: record<Protocol: string>>>
# operationId: GetConnectAttachment
export def "get-connect-attachment" [
  attachment_id: string
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
    path: "/connect-attachments/{attachmentId}"
    path_params: [{name: attachmentId, var: attachment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_id: $attachment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a core network change event.
#
# GET /core-networks/{coreNetworkId}/core-network-change-events/{policyVersionId}
# Returns: record<CoreNetworkChangeEvents: table<Type: string, Action: string, IdentifierPath: string, EventTime: string, Status: string, Values: record>, NextToken: string>
# operationId: GetCoreNetworkChangeEvents
export def "get-core-network-change-events" [
  core_network_id: string
  policy_version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/core-networks/{coreNetworkId}/core-network-change-events/{policyVersionId}"
    path_params: [{name: coreNetworkId, var: core_network_id}, {name: policyVersionId, var: policy_version_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, policy_version_id: $policy_version_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a change set between the LIVE core network policy and a submitted policy.
#
# GET /core-networks/{coreNetworkId}/core-network-change-sets/{policyVersionId}
# Returns: record<CoreNetworkChanges: table<Type: string, Action: string, Identifier: string, PreviousValues: record, NewValues: record, IdentifierPath: string>, NextToken: string>
# operationId: GetCoreNetworkChangeSet
export def "get-core-network-change-set" [
  core_network_id: string
  policy_version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/core-networks/{coreNetworkId}/core-network-change-sets/{policyVersionId}"
    path_params: [{name: coreNetworkId, var: core_network_id}, {name: policyVersionId, var: policy_version_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, policy_version_id: $policy_version_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns details about a core network policy. You can get details about your current live policy or any previous policy version.
#
# GET /core-networks/{coreNetworkId}/core-network-policy
# Returns: record<CoreNetworkPolicy: record<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string, PolicyErrors: list<record>, PolicyDocument: string>>
# operationId: GetCoreNetworkPolicy
export def "get-core-network-policy" [
  core_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-version-id: int # The ID of a core network policy version.
  --alias: string@alias-completer # The alias of a core network policy
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
    path: "/core-networks/{coreNetworkId}/core-network-policy"
    path_params: [{name: coreNetworkId, var: core_network_id}]
    query: [{name: policyVersionId, var: policy_version_id}, {name: alias, var: alias}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, policy_version_id: $policy_version_id, alias: $alias, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new, immutable version of a core network policy. A subsequent change set is created showing the differences between the LIVE policy and the submitted policy.
#
# POST /core-networks/{coreNetworkId}/core-network-policy
# Returns: record<CoreNetworkPolicy: record<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string, PolicyErrors: list<record>, PolicyDocument: string>>
# operationId: PutCoreNetworkPolicy
export def "put-core-network-policy" [
  core_network_id: string
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
  policy_document: string # The policy document.
  --description: string # a core network policy description.
  --latest-version-id: int # The ID of a core network policy.
  --client-token: string # The client token associated with the request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/core-networks/{coreNetworkId}/core-network-policy"
    path_params: [{name: coreNetworkId, var: core_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PolicyDocument, var: policy_document}, {name: Description, var: description}, {name: LatestVersionId, var: latest_version_id}, {name: ClientToken, var: client_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, policy_document: $policy_document, description: $description, latest_version_id: $latest_version_id, client_token: $client_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the count of network resources, by resource type, for the specified global network.
#
# GET /global-networks/{globalNetworkId}/network-resource-count
# Returns: record<NetworkResourceCounts: table<ResourceType: string, Count: int>, NextToken: string>
# operationId: GetNetworkResourceCounts
export def "get-network-resource-counts" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string # The resource type. The following are the supported resource types for Direct Connect: dxcon dx-gateway dx-vif The following are the supported resource types for Network Manager: connection device link site The following are the supported resource types for Amazon VPC: customer-gateway transit-gateway transit-gateway-attachment transit-gateway-connect-peer transit-gateway-route-table vpn-connection
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/network-resource-count"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: resourceType, var: resource_type}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, resource_type: $resource_type, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the network resource relationships for the specified global network.
#
# GET /global-networks/{globalNetworkId}/network-resource-relationships
# Returns: record<Relationships: table<From: string, To: string>, NextToken: string>
# operationId: GetNetworkResourceRelationships
export def "get-network-resource-relationships" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --core-network-id: string # The ID of a core network.
  --registered-gateway-arn: string # The ARN of the registered gateway.
  --aws-region: string # The Amazon Web Services Region.
  --account-id: string # The Amazon Web Services account ID.
  --resource-type: string # The resource type. The following are the supported resource types for Direct Connect: dxcon dx-gateway dx-vif The following are the supported resource types for Network Manager: connection device link site The following are the supported resource types for Amazon VPC: customer-gateway transit-gateway transit-gateway-attachment transit-gateway-connect-peer transit-gateway-route-table vpn-connection
  --resource-arn: string # The ARN of the gateway.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/network-resource-relationships"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: coreNetworkId, var: core_network_id}, {name: registeredGatewayArn, var: registered_gateway_arn}, {name: awsRegion, var: aws_region}, {name: accountId, var: account_id}, {name: resourceType, var: resource_type}, {name: resourceArn, var: resource_arn}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, core_network_id: $core_network_id, registered_gateway_arn: $registered_gateway_arn, aws_region: $aws_region, account_id: $account_id, resource_type: $resource_type, resource_arn: $resource_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the network resources for the specified global network. The results include information from the corresponding Describe call for the resource, minus any sensitive information such as pre-shared keys.
#
# GET /global-networks/{globalNetworkId}/network-resources
# Returns: record<NetworkResources: table<RegisteredGatewayArn: string, CoreNetworkId: string, AwsRegion: string, AccountId: string, ResourceType: string, ResourceId: string, ResourceArn: string, Definition: string, DefinitionTimestamp: string, Tags: list, Metadata: record>, NextToken: string>
# operationId: GetNetworkResources
export def "get-network-resources" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --core-network-id: string # The ID of a core network.
  --registered-gateway-arn: string # The ARN of the gateway.
  --aws-region: string # The Amazon Web Services Region.
  --account-id: string # The Amazon Web Services account ID.
  --resource-type: string # The resource type. The following are the supported resource types for Direct Connect: dxcon - The definition model is Connection (https://docs.aws.amazon.com/directconnect/latest/APIReference/API_Connection.html). dx-gateway - The definition model is DirectConnectGateway (https://docs.aws.amazon.com/directconnect/latest/APIReference/API_DirectConnectGateway.html). dx-vif - The definition model is VirtualInterface (https://docs.aws.amazon.com/directconnect/latest/APIReference/API_VirtualInterface.html). The following are the supported resource types for Network Manager: connection - The definition model is Connection (https://docs.aws.amazon.com/networkmanager/latest/APIReference/API_Connection.html). device - The definition model is Device (https://docs.aws.amazon.com/networkmanager/latest/APIReference/API_Device.html). link - The definition model is Link (https://docs.aws.amazon.com/networkmanager/latest/APIReference/API_Link.html). site - The definition model is Site (https://docs.aws.amazon.com/networkmanager/latest/APIReference/API_Site.html). The following are the supported resource types for Amazon VPC: customer-gateway - The definition model is CustomerGateway (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CustomerGateway.html). transit-gateway - The definition model is TransitGateway (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_TransitGateway.html). transit-gateway-attachment - The definition model is TransitGatewayAttachment (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_TransitGatewayAttachment.html). transit-gateway-connect-peer - The definition model is TransitGatewayConnectPeer (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_TransitGatewayConnectPeer.html). transit-gateway-route-table - The definition model is TransitGatewayRouteTable (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_TransitGatewayRouteTable.html). vpn-connection - The definition model is VpnConnection (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_VpnConnection.html).
  --resource-arn: string # The ARN of the resource.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/network-resources"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: coreNetworkId, var: core_network_id}, {name: registeredGatewayArn, var: registered_gateway_arn}, {name: awsRegion, var: aws_region}, {name: accountId, var: account_id}, {name: resourceType, var: resource_type}, {name: resourceArn, var: resource_arn}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, core_network_id: $core_network_id, registered_gateway_arn: $registered_gateway_arn, aws_region: $aws_region, account_id: $account_id, resource_type: $resource_type, resource_arn: $resource_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the network routes of the specified global network.
#
# POST /global-networks/{globalNetworkId}/network-routes
# Returns: record<RouteTableArn: string, CoreNetworkSegmentEdge: record<CoreNetworkId: string, SegmentName: string, EdgeLocation: string>, RouteTableType: string, RouteTableTimestamp: string, NetworkRoutes: table<DestinationCidrBlock: string, Destinations: list, PrefixListId: string, State: string, Type: string>>
# operationId: GetNetworkRoutes
export def "get-network-routes" [
  global_network_id: string
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
  route_table_identifier: record # Describes a route table. — shape: {TransitGatewayRouteTableArn?: string, CoreNetworkSegmentEdge?: record}
  --exact-cidr-matches: list<string> # An exact CIDR block.
  --longest-prefix-matches: list<string> # The most specific route that matches the traffic (longest prefix match).
  --subnet-of-matches: list<string> # The routes with a subnet that match the specified CIDR filter.
  --supernet-of-matches: list<string> # The routes with a CIDR that encompasses the CIDR filter. Example: If you specify 10.0.1.0/30, then the result returns 10.0.1.0/29.
  --prefix-list-ids: list<string> # The IDs of the prefix lists.
  --states: list<string> # The route states.
  --types: list<string> # The route types.
  --destination-filters: record # Filter by route table destination. Possible Values: TRANSIT_GATEWAY_ATTACHMENT_ID, RESOURCE_ID, or RESOURCE_TYPE.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/network-routes"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: RouteTableIdentifier, var: route_table_identifier}, {name: ExactCidrMatches, var: exact_cidr_matches}, {name: LongestPrefixMatches, var: longest_prefix_matches}, {name: SubnetOfMatches, var: subnet_of_matches}, {name: SupernetOfMatches, var: supernet_of_matches}, {name: PrefixListIds, var: prefix_list_ids}, {name: States, var: states}, {name: Types, var: types}, {name: DestinationFilters, var: destination_filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, route_table_identifier: $route_table_identifier, exact_cidr_matches: $exact_cidr_matches, longest_prefix_matches: $longest_prefix_matches, subnet_of_matches: $subnet_of_matches, supernet_of_matches: $supernet_of_matches, prefix_list_ids: $prefix_list_ids, states: $states, types: $types, destination_filters: $destination_filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the network telemetry of the specified global network.
#
# GET /global-networks/{globalNetworkId}/network-telemetry
# Returns: record<NetworkTelemetry: table<RegisteredGatewayArn: string, CoreNetworkId: string, AwsRegion: string, AccountId: string, ResourceType: string, ResourceId: string, ResourceArn: string, Address: string, Health: record>, NextToken: string>
# operationId: GetNetworkTelemetry
export def "get-network-telemetry" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --core-network-id: string # The ID of a core network.
  --registered-gateway-arn: string # The ARN of the gateway.
  --aws-region: string # The Amazon Web Services Region.
  --account-id: string # The Amazon Web Services account ID.
  --resource-type: string # The resource type. The following are the supported resource types for Direct Connect: dxcon dx-gateway dx-vif The following are the supported resource types for Network Manager: connection device link site The following are the supported resource types for Amazon VPC: customer-gateway transit-gateway transit-gateway-attachment transit-gateway-connect-peer transit-gateway-route-table vpn-connection
  --resource-arn: string # The ARN of the resource.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/network-telemetry"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: coreNetworkId, var: core_network_id}, {name: registeredGatewayArn, var: registered_gateway_arn}, {name: awsRegion, var: aws_region}, {name: accountId, var: account_id}, {name: resourceType, var: resource_type}, {name: resourceArn, var: resource_arn}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, core_network_id: $core_network_id, registered_gateway_arn: $registered_gateway_arn, aws_region: $aws_region, account_id: $account_id, resource_type: $resource_type, resource_arn: $resource_arn, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the specified route analysis.
#
# GET /global-networks/{globalNetworkId}/route-analyses/{routeAnalysisId}
# Returns: record<RouteAnalysis: record<GlobalNetworkId: string, OwnerAccountId: string, RouteAnalysisId: string, StartTimestamp: string, Status: string, Source: record<TransitGatewayAttachmentArn: string, TransitGatewayArn: string, IpAddress: string>, Destination: record<TransitGatewayAttachmentArn: string, TransitGatewayArn: string, IpAddress: string>, IncludeReturnPath: bool, UseMiddleboxes: bool, ForwardPath: record<CompletionStatus: record, Path: list>, ReturnPath: record<CompletionStatus: record, Path: list>>>
# operationId: GetRouteAnalysis
export def "get-route-analysis" [
  global_network_id: string
  route_analysis_id: string
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
    path: "/global-networks/{globalNetworkId}/route-analyses/{routeAnalysisId}"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: routeAnalysisId, var: route_analysis_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, route_analysis_id: $route_analysis_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a site-to-site VPN attachment.
#
# GET /site-to-site-vpn-attachments/{attachmentId}
# Returns: record<SiteToSiteVpnAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, VpnConnectionArn: string>>
# operationId: GetSiteToSiteVpnAttachment
export def "get-site-to-site-vpn-attachment" [
  attachment_id: string
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
    path: "/site-to-site-vpn-attachments/{attachmentId}"
    path_params: [{name: attachmentId, var: attachment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_id: $attachment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a transit gateway peer.
#
# GET /transit-gateway-peerings/{peeringId}
# Returns: record<TransitGatewayPeering: record<Peering: record<CoreNetworkId: string, CoreNetworkArn: string, PeeringId: string, OwnerAccountId: string, PeeringType: string, State: string, EdgeLocation: string, ResourceArn: string, Tags: list, CreatedAt: string>, TransitGatewayArn: string, TransitGatewayPeeringAttachmentId: string>>
# operationId: GetTransitGatewayPeering
export def "get-transit-gateway-peering" [
  peering_id: string
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
    path: "/transit-gateway-peerings/{peeringId}"
    path_params: [{name: peeringId, var: peering_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    peering_id: $peering_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the transit gateway registrations in a specified global network.
#
# GET /global-networks/{globalNetworkId}/transit-gateway-registrations
# Returns: record<TransitGatewayRegistrations: table<GlobalNetworkId: string, TransitGatewayArn: string, State: record>, NextToken: string>
# operationId: GetTransitGatewayRegistrations
export def "get-transit-gateway-registrations" [
  global_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transit-gateway-arns: list<string> # The Amazon Resource Names (ARNs) of one or more transit gateways. The maximum is 10.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/global-networks/{globalNetworkId}/transit-gateway-registrations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    query: [{name: transitGatewayArns, var: transit_gateway_arns, style: multi}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, transit_gateway_arns: $transit_gateway_arns, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Registers a transit gateway in your global network. Not all Regions support transit gateways for global networks. For a list of the supported Regions, see Region Availability (https://docs.aws.amazon.com/network-manager/latest/tgwnm/what-are-global-networks.html#nm-available-regions) in the Amazon Web Services Transit Gateways for Global Networks User Guide. The transit gateway can be in any of the supported Amazon Web Services Regions, but it must be owned by the same Amazon Web Services account that owns the global network. You cannot register a transit gateway in more than one global network.
#
# POST /global-networks/{globalNetworkId}/transit-gateway-registrations
# Returns: record<TransitGatewayRegistration: record<GlobalNetworkId: string, TransitGatewayArn: string, State: record<Code: string, Message: string>>>
# operationId: RegisterTransitGateway
export def "register-transit-gateway" [
  global_network_id: string
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
  transit_gateway_arn: string # The Amazon Resource Name (ARN) of the transit gateway.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/transit-gateway-registrations"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransitGatewayArn, var: transit_gateway_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, transit_gateway_arn: $transit_gateway_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a transit gateway route table attachment.
#
# GET /transit-gateway-route-table-attachments/{attachmentId}
# Returns: record<TransitGatewayRouteTableAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, PeeringId: string, TransitGatewayRouteTableArn: string>>
# operationId: GetTransitGatewayRouteTableAttachment
export def "get-transit-gateway-route-table-attachment" [
  attachment_id: string
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
    path: "/transit-gateway-route-table-attachments/{attachmentId}"
    path_params: [{name: attachmentId, var: attachment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_id: $attachment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a VPC attachment.
#
# GET /vpc-attachments/{attachmentId}
# Returns: record<VpcAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, SubnetArns: list<string>, Options: record<Ipv6Support: bool, ApplianceModeSupport: bool>>>
# operationId: GetVpcAttachment
export def "get-vpc-attachment" [
  attachment_id: string
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
    path: "/vpc-attachments/{attachmentId}"
    path_params: [{name: attachmentId, var: attachment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_id: $attachment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a VPC attachment.
#
# PATCH /vpc-attachments/{attachmentId}
# Returns: record<VpcAttachment: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, SubnetArns: list<string>, Options: record<Ipv6Support: bool, ApplianceModeSupport: bool>>>
# operationId: UpdateVpcAttachment
export def "update-vpc-attachment" [
  attachment_id: string
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
  --add-subnet-arns: list<string> # Adds a subnet ARN to the VPC attachment.
  --remove-subnet-arns: list<string> # Removes a subnet ARN from the attachment.
  --options: record # Describes the VPC options. — shape: {Ipv6Support?: bool, ApplianceModeSupport?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/vpc-attachments/{attachmentId}"
    path_params: [{name: attachmentId, var: attachment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AddSubnetArns, var: add_subnet_arns}, {name: RemoveSubnetArns, var: remove_subnet_arns}, {name: Options, var: options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_id: $attachment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, add_subnet_arns: $add_subnet_arns, remove_subnet_arns: $remove_subnet_arns, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of core network attachments.
#
# GET /attachments
# Returns: record<Attachments: table<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list, ProposedSegmentChange: record, CreatedAt: string, UpdatedAt: string>, NextToken: string>
# operationId: ListAttachments
export def "list-attachments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --core-network-id: string # The ID of a core network.
  --attachment-type: string@attachment-type-completer # The type of attachment.
  --edge-location: string # The Region where the edge is located.
  --state: string@state-completer # The state of the attachment.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/attachments"
    query: [{name: coreNetworkId, var: core_network_id}, {name: attachmentType, var: attachment_type}, {name: edgeLocation, var: edge_location}, {name: state, var: state}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, attachment_type: $attachment_type, edge_location: $edge_location, state: $state, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of core network policy versions.
#
# GET /core-networks/{coreNetworkId}/core-network-policy-versions
# Returns: record<CoreNetworkPolicyVersions: table<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string>, NextToken: string>
# operationId: ListCoreNetworkPolicyVersions
export def "list-core-network-policy-versions" [
  core_network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/core-networks/{coreNetworkId}/core-network-policy-versions"
    path_params: [{name: coreNetworkId, var: core_network_id}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the status of the Service Linked Role (SLR) deployment for the accounts in a given Amazon Web Services Organization.
#
# GET /organizations/service-access
# Returns: record<OrganizationStatus: record<OrganizationId: string, OrganizationAwsServiceAccessStatus: string, SLRDeploymentStatus: string, AccountStatusList: list<record>>, NextToken: string>
# operationId: ListOrganizationServiceAccessStatus
export def "list-organization-service-access-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
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
    path: "/organizations/service-access"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables the Network Manager service for an Amazon Web Services Organization. This can only be called by a management account within the organization.
#
# POST /organizations/service-access
# Returns: record<OrganizationStatus: record<OrganizationId: string, OrganizationAwsServiceAccessStatus: string, SLRDeploymentStatus: string, AccountStatusList: list<record>>>
# operationId: StartOrganizationServiceAccessUpdate
export def "start-organization-service-access-update" [
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
  action: string # The action to take for the update request. This can be either ENABLE or DISABLE.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organizations/service-access"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Action, var: action}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the peerings for a core network.
#
# GET /peerings
# Returns: record<Peerings: table<CoreNetworkId: string, CoreNetworkArn: string, PeeringId: string, OwnerAccountId: string, PeeringType: string, State: string, EdgeLocation: string, ResourceArn: string, Tags: list, CreatedAt: string>, NextToken: string>
# operationId: ListPeerings
export def "list-peerings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --core-network-id: string # The ID of a core network.
  --peering-type: string@peering-type-completer # Returns a list of a peering requests.
  --edge-location: string # Returns a list edge locations for the
  --state: string@state-completer-1 # Returns a list of the peering request states.
  --max-results: int # The maximum number of results to return.
  --next-token: string # The token for the next page of results.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
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
    path: "/peerings"
    query: [{name: coreNetworkId, var: core_network_id}, {name: peeringType, var: peering_type}, {name: edgeLocation, var: edge_location}, {name: state, var: state}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, peering_type: $peering_type, edge_location: $edge_location, state: $state, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags for a specified resource.
#
# GET /tags/{resourceArn}
# Returns: record<TagList: table<Key: string, Value: string>>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tags a specified resource.
#
# POST /tags/{resourceArn}
# Returns: record
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
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
  tags: list # The tags to apply to the specified resource. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rejects a core network attachment request.
#
# POST /attachments/{attachmentId}/reject
# Returns: record<Attachment: record<CoreNetworkId: string, CoreNetworkArn: string, AttachmentId: string, OwnerAccountId: string, AttachmentType: string, State: string, EdgeLocation: string, ResourceArn: string, AttachmentPolicyRuleNumber: int, SegmentName: string, Tags: list<record>, ProposedSegmentChange: record<Tags: list, AttachmentPolicyRuleNumber: int, SegmentName: string>, CreatedAt: string, UpdatedAt: string>>
# operationId: RejectAttachment
export def "reject-attachment" [
  attachment_id: string
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
    method: post
    path: "/attachments/{attachmentId}/reject"
    path_params: [{name: attachmentId, var: attachment_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_id: $attachment_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a previous policy version as a new, immutable version of a core network policy. A subsequent change set is created showing the differences between the LIVE policy and restored policy.
#
# POST /core-networks/{coreNetworkId}/core-network-policy-versions/{policyVersionId}/restore
# Returns: record<CoreNetworkPolicy: record<CoreNetworkId: string, PolicyVersionId: int, Alias: string, Description: string, CreatedAt: string, ChangeSetState: string, PolicyErrors: list<record>, PolicyDocument: string>>
# operationId: RestoreCoreNetworkPolicyVersion
export def "restore-core-network-policy-version" [
  core_network_id: string
  policy_version_id: int
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
    method: post
    path: "/core-networks/{coreNetworkId}/core-network-policy-versions/{policyVersionId}/restore"
    path_params: [{name: coreNetworkId, var: core_network_id}, {name: policyVersionId, var: policy_version_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    core_network_id: $core_network_id, policy_version_id: $policy_version_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts analyzing the routing path between the specified source and destination. For more information, see Route Analyzer (https://docs.aws.amazon.com/vpc/latest/tgw/route-analyzer.html).
#
# POST /global-networks/{globalNetworkId}/route-analyses
# Returns: record<RouteAnalysis: record<GlobalNetworkId: string, OwnerAccountId: string, RouteAnalysisId: string, StartTimestamp: string, Status: string, Source: record<TransitGatewayAttachmentArn: string, TransitGatewayArn: string, IpAddress: string>, Destination: record<TransitGatewayAttachmentArn: string, TransitGatewayArn: string, IpAddress: string>, IncludeReturnPath: bool, UseMiddleboxes: bool, ForwardPath: record<CompletionStatus: record, Path: list>, ReturnPath: record<CompletionStatus: record, Path: list>>>
# operationId: StartRouteAnalysis
export def "start-route-analysis" [
  global_network_id: string
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
  source: record # Describes a source or a destination. — shape: {TransitGatewayAttachmentArn?: string, IpAddress?: string}
  destination: record # Describes a source or a destination. — shape: {TransitGatewayAttachmentArn?: string, IpAddress?: string}
  --include-return-path: oneof<nothing, bool> # Indicates whether to analyze the return path. The default is false.
  --use-middleboxes: oneof<nothing, bool> # Indicates whether to include the location of middlebox appliances in the route analysis. The default is false.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/global-networks/{globalNetworkId}/route-analyses"
    path_params: [{name: globalNetworkId, var: global_network_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Source, var: source}, {name: Destination, var: destination}, {name: IncludeReturnPath, var: include_return_path}, {name: UseMiddleboxes, var: use_middleboxes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source: $source, destination: $destination, include_return_path: $include_return_path, use_middleboxes: $use_middleboxes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes tags from a specified resource.
#
# DELETE /tags/{resourceArn}
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # The tag keys to remove from the specified resource. (required)
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
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the resource metadata for the specified global network.
#
# PATCH /global-networks/{globalNetworkId}/network-resources/{resourceArn}/metadata
# Returns: record<ResourceArn: string, Metadata: record>
# operationId: UpdateNetworkResourceMetadata
export def "update-network-resource-metadata" [
  global_network_id: string
  resource_arn: string
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
  metadata: record # The resource metadata.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/global-networks/{globalNetworkId}/network-resources/{resourceArn}/metadata"
    path_params: [{name: globalNetworkId, var: global_network_id}, {name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Metadata, var: metadata}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    global_network_id: $global_network_id, resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, metadata: $metadata
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
