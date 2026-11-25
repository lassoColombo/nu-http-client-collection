# Auto-generated client for NetworkManagementClient v2016-06-01
# Source: https://api.apis.guru/v2/specs/azure.com/network/2016-06-01/swagger.json
# Auth: --token flag or $env.NETWORKMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "NETWORKMANAGEMENTCLIENT_TOKEN"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def processor-architecture-completer [] { ["Amd64" "X86"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    application-gateways-list-all: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    express-route-circuits-list-all: "record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    express-route-service-providers-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    load-balancers-list-all: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    check-dns-name-availability: "record<available: bool>"
    usages-list: "record<nextLink: string, value: table<currentValue: int, limit: int, name: record, unit: string>>"
    network-interfaces-list-all: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    network-security-groups-list-all: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    public-ip-addresses-list-all: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    route-tables-list-all: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-networks-list-all: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    application-gateways-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    application-gateways-get: "record<etag: string, properties: record<authenticationCertificates: list<record>, backendAddressPools: list<record>, backendHttpSettingsCollection: list<record>, frontendIPConfigurations: list<record>, frontendPorts: list<record>, gatewayIPConfigurations: list<record>, httpListeners: list<record>, operationalState: string, probes: list<record>, provisioningState: string, requestRoutingRules: list<record>, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, sslCertificates: list<record>, sslPolicy: record<disabledSslProtocols: list>, urlPathMaps: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    application-gateways-create-or-update: "record<etag: string, properties: record<authenticationCertificates: list<record>, backendAddressPools: list<record>, backendHttpSettingsCollection: list<record>, frontendIPConfigurations: list<record>, frontendPorts: list<record>, gatewayIPConfigurations: list<record>, httpListeners: list<record>, operationalState: string, probes: list<record>, provisioningState: string, requestRoutingRules: list<record>, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, sslCertificates: list<record>, sslPolicy: record<disabledSslProtocols: list>, urlPathMaps: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateway-connections-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-network-gateway-connections-get: "record<etag: string, properties: record<authorizationKey: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, ingressBytesTransferred: int, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateway-connections-create-or-update: "record<etag: string, properties: record<authorizationKey: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, ingressBytesTransferred: int, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateway-connections-get-shared-key: "record<value: string>"
    virtual-network-gateway-connections-set-shared-key: "record<value: string>"
    virtual-network-gateway-connections-reset-shared-key: "record<keyLength: int>"
    express-route-circuits-list: "record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    express-route-circuits-get: "record<etag: string, properties: record<allowClassicOperations: bool, authorizations: list<record>, circuitProvisioningState: string, gatewayManagerEtag: string, peerings: list<record>, provisioningState: string, serviceKey: string, serviceProviderNotes: string, serviceProviderProperties: record<bandwidthInMbps: int, peeringLocation: string, serviceProviderName: string>, serviceProviderProvisioningState: string>, sku: record<family: string, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    express-route-circuits-create-or-update: "record<etag: string, properties: record<allowClassicOperations: bool, authorizations: list<record>, circuitProvisioningState: string, gatewayManagerEtag: string, peerings: list<record>, provisioningState: string, serviceKey: string, serviceProviderNotes: string, serviceProviderProperties: record<bandwidthInMbps: int, peeringLocation: string, serviceProviderName: string>, serviceProviderProvisioningState: string>, sku: record<family: string, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>"
    express-route-circuit-authorizations-list: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    express-route-circuit-authorizations-get: "record<etag: string, name: string, properties: record<authorizationKey: string, authorizationUseStatus: string, provisioningState: string>, id: string>"
    express-route-circuit-authorizations-create-or-update: "record<etag: string, name: string, properties: record<authorizationKey: string, authorizationUseStatus: string, provisioningState: string>, id: string>"
    express-route-circuit-peerings-list: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    express-route-circuit-peerings-get: "record<etag: string, name: string, properties: record<azureASN: int, gatewayManagerEtag: string, lastModifiedBy: string, microsoftPeeringConfig: record<advertisedPublicPrefixes: list, advertisedPublicPrefixesState: string, customerASN: int, routingRegistryName: string>, peerASN: int, peeringType: string, primaryAzurePort: string, primaryPeerAddressPrefix: string, provisioningState: string, secondaryAzurePort: string, secondaryPeerAddressPrefix: string, sharedKey: string, state: string, stats: record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>, vlanId: int>, id: string>"
    express-route-circuit-peerings-create-or-update: "record<etag: string, name: string, properties: record<azureASN: int, gatewayManagerEtag: string, lastModifiedBy: string, microsoftPeeringConfig: record<advertisedPublicPrefixes: list, advertisedPublicPrefixesState: string, customerASN: int, routingRegistryName: string>, peerASN: int, peeringType: string, primaryAzurePort: string, primaryPeerAddressPrefix: string, provisioningState: string, secondaryAzurePort: string, secondaryPeerAddressPrefix: string, sharedKey: string, state: string, stats: record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>, vlanId: int>, id: string>"
    express-route-circuits-list-arp-table: "record<nextLink: string, value: table<age: int, interface: string, ipAddress: string, macAddress: string>>"
    express-route-circuits-list-routes-table: "record<nextLink: string, value: table<locPrf: string, network: string, nextHop: string, path: string, weight: int>>"
    express-route-circuits-list-routes-table-summary: "record<nextLink: string, value: table<as: int, neighbor: string, statePfxRcd: string, upDown: string, v: int>>"
    express-route-circuits-get-peering-stats: "record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>"
    express-route-circuits-get-stats: "record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>"
    load-balancers-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    load-balancers-get: "record<etag: string, properties: record<backendAddressPools: list<record>, frontendIPConfigurations: list<record>, inboundNatPools: list<record>, inboundNatRules: list<record>, loadBalancingRules: list<record>, outboundNatRules: list<record>, probes: list<record>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    load-balancers-create-or-update: "record<etag: string, properties: record<backendAddressPools: list<record>, frontendIPConfigurations: list<record>, inboundNatPools: list<record>, inboundNatRules: list<record>, loadBalancingRules: list<record>, outboundNatRules: list<record>, probes: list<record>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    local-network-gateways-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    local-network-gateways-get: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    local-network-gateways-create-or-update: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    network-interfaces-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    network-interfaces-get: "record<etag: string, properties: record<dnsSettings: record<appliedDnsServers: list, dnsServers: list, internalDnsNameLabel: string, internalDomainNameSuffix: string, internalFqdn: string>, enableIPForwarding: bool, ipConfigurations: list<record>, macAddress: string, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, primary: bool, provisioningState: string, resourceGuid: string, virtualMachine: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>"
    network-interfaces-create-or-update: "record<etag: string, properties: record<dnsSettings: record<appliedDnsServers: list, dnsServers: list, internalDnsNameLabel: string, internalDomainNameSuffix: string, internalFqdn: string>, enableIPForwarding: bool, ipConfigurations: list<record>, macAddress: string, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, primary: bool, provisioningState: string, resourceGuid: string, virtualMachine: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>"
    network-interfaces-list-effective-network-security-groups: "record<nextLink: string, value: table<association: record, effectiveSecurityRules: list, networkSecurityGroup: record>>"
    network-interfaces-get-effective-route-table: "record<nextLink: string, value: table<addressPrefix: list, name: string, nextHopIpAddress: list, nextHopType: string, source: string, state: string>>"
    network-security-groups-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    network-security-groups-get: "record<etag: string, properties: record<defaultSecurityRules: list<record>, networkInterfaces: list<record>, provisioningState: string, resourceGuid: string, securityRules: list<record>, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    network-security-groups-create-or-update: "record<etag: string, properties: record<defaultSecurityRules: list<record>, networkInterfaces: list<record>, provisioningState: string, resourceGuid: string, securityRules: list<record>, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    security-rules-list: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    security-rules-get: "record<etag: string, name: string, properties: record<access: string, description: string, destinationAddressPrefix: string, destinationPortRange: string, direction: string, priority: int, protocol: string, provisioningState: string, sourceAddressPrefix: string, sourcePortRange: string>, id: string>"
    security-rules-create-or-update: "record<etag: string, name: string, properties: record<access: string, description: string, destinationAddressPrefix: string, destinationPortRange: string, direction: string, priority: int, protocol: string, provisioningState: string, sourceAddressPrefix: string, sourcePortRange: string>, id: string>"
    public-ip-addresses-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    public-ip-addresses-get: "record<etag: string, properties: record<dnsSettings: record<domainNameLabel: string, fqdn: string, reverseFqdn: string>, idleTimeoutInMinutes: int, ipAddress: string, ipConfiguration: record<etag: string, name: string, properties: record, id: string>, provisioningState: string, publicIPAddressVersion: string, publicIPAllocationMethod: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    public-ip-addresses-create-or-update: "record<etag: string, properties: record<dnsSettings: record<domainNameLabel: string, fqdn: string, reverseFqdn: string>, idleTimeoutInMinutes: int, ipAddress: string, ipConfiguration: record<etag: string, name: string, properties: record, id: string>, provisioningState: string, publicIPAddressVersion: string, publicIPAllocationMethod: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>"
    route-tables-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    route-tables-get: "record<etag: string, properties: record<provisioningState: string, routes: list<record>, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    route-tables-create-or-update: "record<etag: string, properties: record<provisioningState: string, routes: list<record>, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    routes-list: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    routes-get: "record<etag: string, name: string, properties: record<addressPrefix: string, nextHopIpAddress: string, nextHopType: string, provisioningState: string>, id: string>"
    routes-create-or-update: "record<etag: string, name: string, properties: record<addressPrefix: string, nextHopIpAddress: string, nextHopType: string, provisioningState: string>, id: string>"
    virtual-network-gateways-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-network-gateways-get: "record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<vpnClientAddressPool: record, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateways-create-or-update: "record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<vpnClientAddressPool: record, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-network-gateways-generatevpnclientpackage: "string"
    virtual-network-gateways-reset: "record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<vpnClientAddressPool: record, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-networks-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-networks-get: "record<etag: string, properties: record<VirtualNetworkPeerings: list<record>, addressSpace: record<addressPrefixes: list>, dhcpOptions: record<dnsServers: list>, provisioningState: string, resourceGuid: string, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-networks-create-or-update: "record<etag: string, properties: record<VirtualNetworkPeerings: list<record>, addressSpace: record<addressPrefixes: list>, dhcpOptions: record<dnsServers: list>, provisioningState: string, resourceGuid: string, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-networks-check-ip-address-availability: "record<available: bool, availableIPAddresses: list<string>>"
    subnets-list: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    subnets-get: "record<etag: string, name: string, properties: record<addressPrefix: string, ipConfigurations: list<record>, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, provisioningState: string, resourceNavigationLinks: list<record>, routeTable: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string>"
    subnets-create-or-update: "record<etag: string, name: string, properties: record<addressPrefix: string, ipConfigurations: list<record>, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, provisioningState: string, resourceNavigationLinks: list<record>, routeTable: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string>"
    virtual-network-peerings-list: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    virtual-network-peerings-get: "record<etag: string, name: string, properties: record<allowForwardedTraffic: bool, allowGatewayTransit: bool, allowVirtualNetworkAccess: bool, peeringState: string, provisioningState: string, remoteVirtualNetwork: record<id: string>, useRemoteGateways: bool>, id: string>"
    virtual-network-peerings-create-or-update: "record<etag: string, name: string, properties: record<allowForwardedTraffic: bool, allowGatewayTransit: bool, allowVirtualNetworkAccess: bool, peeringState: string, provisioningState: string, remoteVirtualNetwork: record<id: string>, useRemoteGateways: bool>, id: string>"
    network-interfaces-list-virtual-machine-scale-set-network-interfaces: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    network-interfaces-list-virtual-machine-scale-set-vm-network-interfaces: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    network-interfaces-get-virtual-machine-scale-set-network-interface: "record<etag: string, properties: record<dnsSettings: record<appliedDnsServers: list, dnsServers: list, internalDnsNameLabel: string, internalDomainNameSuffix: string, internalFqdn: string>, enableIPForwarding: bool, ipConfigurations: list<record>, macAddress: string, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, primary: bool, provisioningState: string, resourceGuid: string, virtualMachine: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["application-gateways-list-all" "express-route-circuits-list-all" "express-route-service-providers-list" "load-balancers-list-all" "check-dns-name-availability" "usages-list" "network-interfaces-list-all" "network-security-groups-list-all" "public-ip-addresses-list-all" "route-tables-list-all" "virtual-networks-list-all" "application-gateways-list" "application-gateways-delete" "application-gateways-get" "application-gateways-create-or-update" "application-gateways-start" "application-gateways-stop" "virtual-network-gateway-connections-list" "virtual-network-gateway-connections-delete" "virtual-network-gateway-connections-get" "virtual-network-gateway-connections-create-or-update" "virtual-network-gateway-connections-get-shared-key" "virtual-network-gateway-connections-set-shared-key" "virtual-network-gateway-connections-reset-shared-key" "express-route-circuits-list" "express-route-circuits-delete" "express-route-circuits-get" "express-route-circuits-create-or-update" "express-route-circuit-authorizations-list" "express-route-circuit-authorizations-delete" "express-route-circuit-authorizations-get" "express-route-circuit-authorizations-create-or-update" "express-route-circuit-peerings-list" "express-route-circuit-peerings-delete" "express-route-circuit-peerings-get" "express-route-circuit-peerings-create-or-update" "express-route-circuits-list-arp-table" "express-route-circuits-list-routes-table" "express-route-circuits-list-routes-table-summary" "express-route-circuits-get-peering-stats" "express-route-circuits-get-stats" "load-balancers-list" "load-balancers-delete" "load-balancers-get" "load-balancers-create-or-update" "local-network-gateways-list" "local-network-gateways-delete" "local-network-gateways-get" "local-network-gateways-create-or-update" "network-interfaces-list" "network-interfaces-delete" "network-interfaces-get" "network-interfaces-create-or-update" "network-interfaces-list-effective-network-security-groups" "network-interfaces-get-effective-route-table" "network-security-groups-list" "network-security-groups-delete" "network-security-groups-get" "network-security-groups-create-or-update" "security-rules-list" "security-rules-delete" "security-rules-get" "security-rules-create-or-update" "public-ip-addresses-list" "public-ip-addresses-delete" "public-ip-addresses-get" "public-ip-addresses-create-or-update" "route-tables-list" "route-tables-delete" "route-tables-get" "route-tables-create-or-update" "routes-list" "routes-delete" "routes-get" "routes-create-or-update" "virtual-network-gateways-list" "virtual-network-gateways-delete" "virtual-network-gateways-get" "virtual-network-gateways-create-or-update" "virtual-network-gateways-generatevpnclientpackage" "virtual-network-gateways-reset" "virtual-networks-list" "virtual-networks-delete" "virtual-networks-get" "virtual-networks-create-or-update" "virtual-networks-check-ip-address-availability" "subnets-list" "subnets-delete" "subnets-get" "subnets-create-or-update" "virtual-network-peerings-list" "virtual-network-peerings-delete" "virtual-network-peerings-get" "virtual-network-peerings-create-or-update" "network-interfaces-list-virtual-machine-scale-set-network-interfaces" "network-interfaces-list-virtual-machine-scale-set-vm-network-interfaces" "network-interfaces-get-virtual-machine-scale-set-network-interface" "commands"] | sort) } | get name | first)
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

# The List ApplicationGateway operation retrieves all the application gateways in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ApplicationGateways_ListAll
export def "application-gateways-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/applicationGateways"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List ExpressRouteCircuit operation retrieves all the ExpressRouteCircuits in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/expressRouteCircuits
# Returns: record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ExpressRouteCircuits_ListAll
export def "express-route-circuits-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/expressRouteCircuits"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List ExpressRouteServiceProvider operation retrieves all the available ExpressRouteServiceProviders.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/expressRouteServiceProviders
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ExpressRouteServiceProviders_List
export def "express-route-service-providers-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/expressRouteServiceProviders"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List loadBalancer operation retrieves all the load balancers in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/loadBalancers
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: LoadBalancers_ListAll
export def "load-balancers-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/loadBalancers"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Checks whether a domain name in the cloudapp.net zone is available for use.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/locations/{location}/CheckDnsNameAvailability
# Returns: record<available: bool>
# operationId: CheckDnsNameAvailability
export def "check-dns-name-availability" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --domain-name-label: string # The domain name to be verified. It must conform to the following regular expression: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/locations/{location}/CheckDnsNameAvailability"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}]
    query: [{name: domainNameLabel, var: domain_name_label}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, domain_name_label: $domain_name_label, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists compute usages for a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/locations/{location}/usages
# Returns: record<nextLink: string, value: table<currentValue: int, limit: int, name: record, unit: string>>
# operationId: Usages_List
export def "usages-list" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/locations/{location}/usages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: location, var: location}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, location: $location, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List networkInterfaces operation retrieves all the networkInterfaces in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/networkInterfaces
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: NetworkInterfaces_ListAll
export def "network-interfaces-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/networkInterfaces"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list NetworkSecurityGroups returns all network security groups in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/networkSecurityGroups
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: NetworkSecurityGroups_ListAll
export def "network-security-groups-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/networkSecurityGroups"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List publicIpAddress operation retrieves all the publicIpAddresses in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/publicIPAddresses
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: PublicIPAddresses_ListAll
export def "public-ip-addresses-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/publicIPAddresses"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list RouteTables returns all route tables in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/routeTables
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: RouteTables_ListAll
export def "route-tables-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/routeTables"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list VirtualNetwork returns all Virtual Networks in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/virtualNetworks
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualNetworks_ListAll
export def "virtual-networks-list-all" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/virtualNetworks"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List ApplicationGateway operation retrieves all the application gateways in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ApplicationGateways_List
export def "application-gateways-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete ApplicationGateway operation deletes the specified application gateway.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}
# operationId: ApplicationGateways_Delete
export def "application-gateways-delete" [
  subscription_id: string
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: applicationGatewayName, var: application_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_gateway_name: $application_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get ApplicationGateway operation retrieves information about the specified application gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}
# Returns: record<etag: string, properties: record<authenticationCertificates: list<record>, backendAddressPools: list<record>, backendHttpSettingsCollection: list<record>, frontendIPConfigurations: list<record>, frontendPorts: list<record>, gatewayIPConfigurations: list<record>, httpListeners: list<record>, operationalState: string, probes: list<record>, provisioningState: string, requestRoutingRules: list<record>, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, sslCertificates: list<record>, sslPolicy: record<disabledSslProtocols: list>, urlPathMaps: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ApplicationGateways_Get
export def "application-gateways-get" [
  subscription_id: string
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: applicationGatewayName, var: application_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_gateway_name: $application_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put ApplicationGateway operation creates/updates a ApplicationGateway
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}
# Returns: record<etag: string, properties: record<authenticationCertificates: list<record>, backendAddressPools: list<record>, backendHttpSettingsCollection: list<record>, frontendIPConfigurations: list<record>, frontendPorts: list<record>, gatewayIPConfigurations: list<record>, httpListeners: list<record>, operationalState: string, probes: list<record>, provisioningState: string, requestRoutingRules: list<record>, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, sslCertificates: list<record>, sslPolicy: record<disabledSslProtocols: list>, urlPathMaps: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ApplicationGateways_CreateOrUpdate
export def "application-gateways-create-or-update" [
  subscription_id: string
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated
  --properties: any # Properties of Application Gateway — shape: {authenticationCertificates?: list, backendAddressPools?: list, backendHttpSettingsCollection?: list, frontendIPConfigurations?: list, frontendPorts?: list, gatewayIPConfigurations?: list, httpListeners?: list, probes?: list, provisioningState?: string, requestRoutingRules?: list, resourceGuid?: string, sku?: any, sslCertificates?: list, sslPolicy?: any, urlPathMaps?: list}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: applicationGatewayName, var: application_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_gateway_name: $application_gateway_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Start ApplicationGateway operation starts application gateway in the specified resource group through Network resource provider.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}/start
# operationId: ApplicationGateways_Start
export def "application-gateways-start" [
  subscription_id: string
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: applicationGatewayName, var: application_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_gateway_name: $application_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The STOP ApplicationGateway operation stops application gateway in the specified resource group through Network resource provider.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}/stop
# operationId: ApplicationGateways_Stop
export def "application-gateways-stop" [
  subscription_id: string
  resource_group_name: string
  application_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/applicationGateways/{applicationGatewayName}/stop"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: applicationGatewayName, var: application_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, application_gateway_name: $application_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List VirtualNetworkGatewayConnections operation retrieves all the virtual network gateways connections created.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualNetworkGatewayConnections_List
export def "virtual-network-gateway-connections-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Delete VirtualNetworkGatewayConnection operation deletes the specified virtual network Gateway connection through Network resource provider.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}
# operationId: VirtualNetworkGatewayConnections_Delete
export def "virtual-network-gateway-connections-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get VirtualNetworkGatewayConnection operation retrieves information about the specified virtual network gateway connection through Network resource provider.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}
# Returns: record<etag: string, properties: record<authorizationKey: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, ingressBytesTransferred: int, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGatewayConnections_Get
export def "virtual-network-gateway-connections-get" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put VirtualNetworkGatewayConnection operation creates/updates a virtual network gateway connection in the specified resource group through Network resource provider.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}
# Returns: record<etag: string, properties: record<authorizationKey: string, connectionStatus: string, connectionType: string, egressBytesTransferred: int, enableBgp: bool, ingressBytesTransferred: int, localNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, peer: record<id: string>, provisioningState: string, resourceGuid: string, routingWeight: int, sharedKey: string, virtualNetworkGateway1: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, virtualNetworkGateway2: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGatewayConnections_CreateOrUpdate
export def "virtual-network-gateway-connections-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # VirtualNetworkGatewayConnection properties — shape: {authorizationKey?: string, connectionStatus?: "Unknown"|"Connecting"|"Connected"|"NotConnected", connectionType?: "IPsec"|"Vnet2Vnet"|"ExpressRoute"|"VPNClient", egressBytesTransferred?: int, enableBgp?: bool, ingressBytesTransferred?: int, localNetworkGateway2?: any, peer?: any, provisioningState?: string, resourceGuid?: string, routingWeight?: int, sharedKey?: string, virtualNetworkGateway1?: any, virtualNetworkGateway2?: any}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get VirtualNetworkGatewayConnectionSharedKey operation retrieves information about the specified virtual network gateway connection shared key through Network resource provider.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey
# Returns: record<value: string>
# operationId: VirtualNetworkGatewayConnections_GetSharedKey
export def "virtual-network-gateway-connections-get-shared-key" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put VirtualNetworkGatewayConnectionSharedKey operation sets the virtual network gateway connection shared key for passed virtual network gateway connection in the specified resource group through Network resource provider.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey
# Returns: record<value: string>
# operationId: VirtualNetworkGatewayConnections_SetSharedKey
export def "virtual-network-gateway-connections-set-shared-key" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --value: string # The virtual network connection shared key value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The VirtualNetworkGatewayConnectionResetSharedKey operation resets the virtual network gateway connection shared key for passed virtual network gateway connection in the specified resource group through Network resource provider.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey/reset
# Returns: record<keyLength: int>
# operationId: VirtualNetworkGatewayConnections_ResetSharedKey
export def "virtual-network-gateway-connections-reset-shared-key" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --key-length: int # The virtual network connection reset shared key length (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/connections/{virtualNetworkGatewayConnectionName}/sharedkey/reset"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayConnectionName, var: virtual_network_gateway_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyLength, var: key_length}]}
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_connection_name: $virtual_network_gateway_connection_name, api_version: $api_version, key_length: $key_length
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List ExpressRouteCircuit operation retrieves all the ExpressRouteCircuits in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits
# Returns: record<nextLink: string, value: table<etag: string, properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: ExpressRouteCircuits_List
export def "express-route-circuits-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete ExpressRouteCircuit operation deletes the specified ExpressRouteCircuit.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}
# operationId: ExpressRouteCircuits_Delete
export def "express-route-circuits-delete" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get ExpressRouteCircuit operation retrieves information about the specified ExpressRouteCircuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}
# Returns: record<etag: string, properties: record<allowClassicOperations: bool, authorizations: list<record>, circuitProvisioningState: string, gatewayManagerEtag: string, peerings: list<record>, provisioningState: string, serviceKey: string, serviceProviderNotes: string, serviceProviderProperties: record<bandwidthInMbps: int, peeringLocation: string, serviceProviderName: string>, serviceProviderProvisioningState: string>, sku: record<family: string, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ExpressRouteCircuits_Get
export def "express-route-circuits-get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put ExpressRouteCircuit operation creates/updates a ExpressRouteCircuit
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}
# Returns: record<etag: string, properties: record<allowClassicOperations: bool, authorizations: list<record>, circuitProvisioningState: string, gatewayManagerEtag: string, peerings: list<record>, provisioningState: string, serviceKey: string, serviceProviderNotes: string, serviceProviderProperties: record<bandwidthInMbps: int, peeringLocation: string, serviceProviderName: string>, serviceProviderProvisioningState: string>, sku: record<family: string, name: string, tier: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: ExpressRouteCircuits_CreateOrUpdate
export def "express-route-circuits-create-or-update" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # Properties of ExpressRouteCircuit — shape: {allowClassicOperations?: bool, authorizations?: list, circuitProvisioningState?: string, gatewayManagerEtag?: string, peerings?: list, provisioningState?: string, serviceKey?: string, serviceProviderNotes?: string, serviceProviderProperties?: any, serviceProviderProvisioningState?: "NotProvisioned"|"Provisioning"|"Provisioned"|"Deprovisioning"}
  --sku: any # Contains sku in an ExpressRouteCircuit — shape: {family?: "UnlimitedData"|"MeteredData", name?: string, tier?: "Standard"|"Premium"}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: sku, var: sku}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, api_version: $api_version, etag: $etag, properties: $properties, sku: $sku, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List authorization operation retrieves all the authorizations in an ExpressRouteCircuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: ExpressRouteCircuitAuthorizations_List
export def "express-route-circuit-authorizations-list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete authorization operation deletes the specified authorization from the specified ExpressRouteCircuit.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}
# operationId: ExpressRouteCircuitAuthorizations_Delete
export def "express-route-circuit-authorizations-delete" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  authorization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: authorizationName, var: authorization_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, authorization_name: $authorization_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The GET authorization operation retrieves the specified authorization from the specified ExpressRouteCircuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}
# Returns: record<etag: string, name: string, properties: record<authorizationKey: string, authorizationUseStatus: string, provisioningState: string>, id: string>
# operationId: ExpressRouteCircuitAuthorizations_Get
export def "express-route-circuit-authorizations-get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  authorization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: authorizationName, var: authorization_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, authorization_name: $authorization_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put Authorization operation creates/updates an authorization in the specified ExpressRouteCircuits
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}
# Returns: record<etag: string, name: string, properties: record<authorizationKey: string, authorizationUseStatus: string, provisioningState: string>, id: string>
# operationId: ExpressRouteCircuitAuthorizations_CreateOrUpdate
export def "express-route-circuit-authorizations-create-or-update" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  authorization_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated
  --name: string # Gets name of the resource that is unique within a resource group. This name can be used to access the resource
  --properties: any # shape: {authorizationKey?: string, authorizationUseStatus?: "Available"|"InUse", provisioningState?: string}
  --id: string # Resource Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/authorizations/{authorizationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: authorizationName, var: authorization_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: name, var: name}, {name: properties, var: properties}, {name: id, var: id}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, authorization_name: $authorization_name, api_version: $api_version, etag: $etag, name: $name, properties: $properties, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List peering operation retrieves all the peerings in an ExpressRouteCircuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: ExpressRouteCircuitPeerings_List
export def "express-route-circuit-peerings-list" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete peering operation deletes the specified peering from the ExpressRouteCircuit.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}
# operationId: ExpressRouteCircuitPeerings_Delete
export def "express-route-circuit-peerings-delete" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: peeringName, var: peering_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, peering_name: $peering_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The GET peering operation retrieves the specified authorization from the ExpressRouteCircuit.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}
# Returns: record<etag: string, name: string, properties: record<azureASN: int, gatewayManagerEtag: string, lastModifiedBy: string, microsoftPeeringConfig: record<advertisedPublicPrefixes: list, advertisedPublicPrefixesState: string, customerASN: int, routingRegistryName: string>, peerASN: int, peeringType: string, primaryAzurePort: string, primaryPeerAddressPrefix: string, provisioningState: string, secondaryAzurePort: string, secondaryPeerAddressPrefix: string, sharedKey: string, state: string, stats: record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>, vlanId: int>, id: string>
# operationId: ExpressRouteCircuitPeerings_Get
export def "express-route-circuit-peerings-get" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: peeringName, var: peering_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, peering_name: $peering_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put Peering operation creates/updates an peering in the specified ExpressRouteCircuits
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}
# Returns: record<etag: string, name: string, properties: record<azureASN: int, gatewayManagerEtag: string, lastModifiedBy: string, microsoftPeeringConfig: record<advertisedPublicPrefixes: list, advertisedPublicPrefixesState: string, customerASN: int, routingRegistryName: string>, peerASN: int, peeringType: string, primaryAzurePort: string, primaryPeerAddressPrefix: string, provisioningState: string, secondaryAzurePort: string, secondaryPeerAddressPrefix: string, sharedKey: string, state: string, stats: record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>, vlanId: int>, id: string>
# operationId: ExpressRouteCircuitPeerings_CreateOrUpdate
export def "express-route-circuit-peerings-create-or-update" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated
  --name: string # Gets name of the resource that is unique within a resource group. This name can be used to access the resource
  --properties: any # shape: {azureASN?: int, gatewayManagerEtag?: string, lastModifiedBy?: string, microsoftPeeringConfig?: any, peerASN?: int, peeringType?: "AzurePublicPeering"|"AzurePrivatePeering"|"MicrosoftPeering", primaryAzurePort?: string, primaryPeerAddressPrefix?: string, provisioningState?: string, secondaryAzurePort?: string, secondaryPeerAddressPrefix?: string, sharedKey?: string, state?: "Disabled"|"Enabled", stats?: any, vlanId?: int}
  --id: string # Resource Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: peeringName, var: peering_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: name, var: name}, {name: properties, var: properties}, {name: id, var: id}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, peering_name: $peering_name, api_version: $api_version, etag: $etag, name: $name, properties: $properties, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The ListArpTable from ExpressRouteCircuit operation retrieves the currently advertised arp table associated with the ExpressRouteCircuits in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/arpTables/{devicePath}
# Returns: record<nextLink: string, value: table<age: int, interface: string, ipAddress: string, macAddress: string>>
# operationId: ExpressRouteCircuits_ListArpTable
export def "express-route-circuits-list-arp-table" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  device_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/arpTables/{devicePath}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: peeringName, var: peering_name}, {name: devicePath, var: device_path}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, peering_name: $peering_name, device_path: $device_path, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The ListRoutesTable from ExpressRouteCircuit operation retrieves the currently advertised routes table associated with the ExpressRouteCircuits in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/routeTables/{devicePath}
# Returns: record<nextLink: string, value: table<locPrf: string, network: string, nextHop: string, path: string, weight: int>>
# operationId: ExpressRouteCircuits_ListRoutesTable
export def "express-route-circuits-list-routes-table" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  device_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/routeTables/{devicePath}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: peeringName, var: peering_name}, {name: devicePath, var: device_path}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, peering_name: $peering_name, device_path: $device_path, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The ListRoutesTable from ExpressRouteCircuit operation retrieves the currently advertised routes table associated with the ExpressRouteCircuits in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/routeTablesSummary/{devicePath}
# Returns: record<nextLink: string, value: table<as: int, neighbor: string, statePfxRcd: string, upDown: string, v: int>>
# operationId: ExpressRouteCircuits_ListRoutesTableSummary
export def "express-route-circuits-list-routes-table-summary" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  device_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/routeTablesSummary/{devicePath}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: peeringName, var: peering_name}, {name: devicePath, var: device_path}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, peering_name: $peering_name, device_path: $device_path, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List stats ExpressRouteCircuit operation retrieves all the stats from a ExpressRouteCircuits in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/stats
# Returns: record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>
# operationId: ExpressRouteCircuits_GetPeeringStats
export def "express-route-circuits-get-peering-stats" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/peerings/{peeringName}/stats"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}, {name: peeringName, var: peering_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, peering_name: $peering_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List stats ExpressRouteCircuit operation retrieves all the stats from a ExpressRouteCircuits in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/stats
# Returns: record<primarybytesIn: int, primarybytesOut: int, secondarybytesIn: int, secondarybytesOut: int>
# operationId: ExpressRouteCircuits_GetStats
export def "express-route-circuits-get-stats" [
  subscription_id: string
  resource_group_name: string
  circuit_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/expressRouteCircuits/{circuitName}/stats"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: circuitName, var: circuit_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, circuit_name: $circuit_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List loadBalancer operation retrieves all the load balancers in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/loadBalancers
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: LoadBalancers_List
export def "load-balancers-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/loadBalancers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete LoadBalancer operation deletes the specified load balancer.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/loadBalancers/{loadBalancerName}
# operationId: LoadBalancers_Delete
export def "load-balancers-delete" [
  subscription_id: string
  resource_group_name: string
  load_balancer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/loadBalancers/{loadBalancerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: loadBalancerName, var: load_balancer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, load_balancer_name: $load_balancer_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get LoadBalancer operation retrieves information about the specified LoadBalancer.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/loadBalancers/{loadBalancerName}
# Returns: record<etag: string, properties: record<backendAddressPools: list<record>, frontendIPConfigurations: list<record>, inboundNatPools: list<record>, inboundNatRules: list<record>, loadBalancingRules: list<record>, outboundNatRules: list<record>, probes: list<record>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LoadBalancers_Get
export def "load-balancers-get" [
  subscription_id: string
  resource_group_name: string
  load_balancer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --expand: string # expand references resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/loadBalancers/{loadBalancerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: loadBalancerName, var: load_balancer_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, load_balancer_name: $load_balancer_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put LoadBalancer operation creates/updates a LoadBalancer
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/loadBalancers/{loadBalancerName}
# Returns: record<etag: string, properties: record<backendAddressPools: list<record>, frontendIPConfigurations: list<record>, inboundNatPools: list<record>, inboundNatRules: list<record>, loadBalancingRules: list<record>, outboundNatRules: list<record>, probes: list<record>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LoadBalancers_CreateOrUpdate
export def "load-balancers-create-or-update" [
  subscription_id: string
  resource_group_name: string
  load_balancer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # Properties of Load Balancer — shape: {backendAddressPools?: list, frontendIPConfigurations?: list, inboundNatPools?: list, inboundNatRules?: list, loadBalancingRules?: list, outboundNatRules?: list, probes?: list, provisioningState?: string, resourceGuid?: string}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/loadBalancers/{loadBalancerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: loadBalancerName, var: load_balancer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, load_balancer_name: $load_balancer_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List LocalNetworkGateways operation retrieves all the local network gateways stored.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: LocalNetworkGateways_List
export def "local-network-gateways-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Delete LocalNetworkGateway operation deletes the specified local network Gateway through Network resource provider.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}
# operationId: LocalNetworkGateways_Delete
export def "local-network-gateways-delete" [
  subscription_id: string
  resource_group_name: string
  local_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: localNetworkGatewayName, var: local_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, local_network_gateway_name: $local_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get LocalNetworkGateway operation retrieves information about the specified local network gateway through Network resource provider.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LocalNetworkGateways_Get
export def "local-network-gateways-get" [
  subscription_id: string
  resource_group_name: string
  local_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: localNetworkGatewayName, var: local_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, local_network_gateway_name: $local_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put LocalNetworkGateway operation creates/updates a local network gateway in the specified resource group through Network resource provider.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, gatewayIpAddress: string, localNetworkAddressSpace: record<addressPrefixes: list>, provisioningState: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: LocalNetworkGateways_CreateOrUpdate
export def "local-network-gateways-create-or-update" [
  subscription_id: string
  resource_group_name: string
  local_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # LocalNetworkGateway properties — shape: {bgpSettings?: any, gatewayIpAddress?: string, localNetworkAddressSpace?: any, provisioningState?: string, resourceGuid?: string}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/localNetworkGateways/{localNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: localNetworkGatewayName, var: local_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, local_network_gateway_name: $local_network_gateway_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List networkInterfaces operation retrieves all the networkInterfaces in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: NetworkInterfaces_List
export def "network-interfaces-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete networkInterface operation deletes the specified networkInterface.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}
# operationId: NetworkInterfaces_Delete
export def "network-interfaces-delete" [
  subscription_id: string
  resource_group_name: string
  network_interface_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkInterfaceName, var: network_interface_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_interface_name: $network_interface_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get network interface operation retrieves information about the specified network interface.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}
# Returns: record<etag: string, properties: record<dnsSettings: record<appliedDnsServers: list, dnsServers: list, internalDnsNameLabel: string, internalDomainNameSuffix: string, internalFqdn: string>, enableIPForwarding: bool, ipConfigurations: list<record>, macAddress: string, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, primary: bool, provisioningState: string, resourceGuid: string, virtualMachine: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: NetworkInterfaces_Get
export def "network-interfaces-get" [
  subscription_id: string
  resource_group_name: string
  network_interface_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --expand: string # expand references resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkInterfaceName, var: network_interface_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_interface_name: $network_interface_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put NetworkInterface operation creates/updates a networkInterface
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}
# Returns: record<etag: string, properties: record<dnsSettings: record<appliedDnsServers: list, dnsServers: list, internalDnsNameLabel: string, internalDomainNameSuffix: string, internalFqdn: string>, enableIPForwarding: bool, ipConfigurations: list<record>, macAddress: string, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, primary: bool, provisioningState: string, resourceGuid: string, virtualMachine: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: NetworkInterfaces_CreateOrUpdate
export def "network-interfaces-create-or-update" [
  subscription_id: string
  resource_group_name: string
  network_interface_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # NetworkInterface properties. — shape: {dnsSettings?: any, enableIPForwarding?: bool, ipConfigurations?: list, macAddress?: string, networkSecurityGroup?: any, primary?: bool, provisioningState?: string, resourceGuid?: string, virtualMachine?: any}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkInterfaceName, var: network_interface_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_interface_name: $network_interface_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list effective network security group operation retrieves all the network security groups applied on a networkInterface.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}/effectiveNetworkSecurityGroups
# Returns: record<nextLink: string, value: table<association: record, effectiveSecurityRules: list, networkSecurityGroup: record>>
# operationId: NetworkInterfaces_ListEffectiveNetworkSecurityGroups
export def "network-interfaces-list-effective-network-security-groups" [
  subscription_id: string
  resource_group_name: string
  network_interface_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}/effectiveNetworkSecurityGroups"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkInterfaceName, var: network_interface_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_interface_name: $network_interface_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves all the route tables applied on a networkInterface.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}/effectiveRouteTable
# Returns: record<nextLink: string, value: table<addressPrefix: list, name: string, nextHopIpAddress: list, nextHopType: string, source: string, state: string>>
# operationId: NetworkInterfaces_GetEffectiveRouteTable
export def "network-interfaces-get-effective-route-table" [
  subscription_id: string
  resource_group_name: string
  network_interface_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkInterfaces/{networkInterfaceName}/effectiveRouteTable"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkInterfaceName, var: network_interface_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_interface_name: $network_interface_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list NetworkSecurityGroups returns all network security groups in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: NetworkSecurityGroups_List
export def "network-security-groups-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Delete NetworkSecurityGroup operation deletes the specified network security group
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}
# operationId: NetworkSecurityGroups_Delete
export def "network-security-groups-delete" [
  subscription_id: string
  resource_group_name: string
  network_security_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkSecurityGroupName, var: network_security_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_security_group_name: $network_security_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get NetworkSecurityGroups operation retrieves information about the specified network security group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}
# Returns: record<etag: string, properties: record<defaultSecurityRules: list<record>, networkInterfaces: list<record>, provisioningState: string, resourceGuid: string, securityRules: list<record>, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: NetworkSecurityGroups_Get
export def "network-security-groups-get" [
  subscription_id: string
  resource_group_name: string
  network_security_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --expand: string # expand references resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkSecurityGroupName, var: network_security_group_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_security_group_name: $network_security_group_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put NetworkSecurityGroup operation creates/updates a network security group in the specified resource group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}
# Returns: record<etag: string, properties: record<defaultSecurityRules: list<record>, networkInterfaces: list<record>, provisioningState: string, resourceGuid: string, securityRules: list<record>, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: NetworkSecurityGroups_CreateOrUpdate
export def "network-security-groups-create-or-update" [
  subscription_id: string
  resource_group_name: string
  network_security_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # Network Security Group resource — shape: {defaultSecurityRules?: list, provisioningState?: string, resourceGuid?: string, securityRules?: list}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkSecurityGroupName, var: network_security_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_security_group_name: $network_security_group_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List network security rule operation retrieves all the security rules in a network security group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}/securityRules
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: SecurityRules_List
export def "security-rules-list" [
  subscription_id: string
  resource_group_name: string
  network_security_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}/securityRules"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkSecurityGroupName, var: network_security_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_security_group_name: $network_security_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete network security rule operation deletes the specified network security rule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}/securityRules/{securityRuleName}
# operationId: SecurityRules_Delete
export def "security-rules-delete" [
  subscription_id: string
  resource_group_name: string
  network_security_group_name: string
  security_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}/securityRules/{securityRuleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkSecurityGroupName, var: network_security_group_name}, {name: securityRuleName, var: security_rule_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_security_group_name: $network_security_group_name, security_rule_name: $security_rule_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get NetworkSecurityRule operation retrieves information about the specified network security rule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}/securityRules/{securityRuleName}
# Returns: record<etag: string, name: string, properties: record<access: string, description: string, destinationAddressPrefix: string, destinationPortRange: string, direction: string, priority: int, protocol: string, provisioningState: string, sourceAddressPrefix: string, sourcePortRange: string>, id: string>
# operationId: SecurityRules_Get
export def "security-rules-get" [
  subscription_id: string
  resource_group_name: string
  network_security_group_name: string
  security_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}/securityRules/{securityRuleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkSecurityGroupName, var: network_security_group_name}, {name: securityRuleName, var: security_rule_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_security_group_name: $network_security_group_name, security_rule_name: $security_rule_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put network security rule operation creates/updates a security rule in the specified network security group
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}/securityRules/{securityRuleName}
# Returns: record<etag: string, name: string, properties: record<access: string, description: string, destinationAddressPrefix: string, destinationPortRange: string, direction: string, priority: int, protocol: string, provisioningState: string, sourceAddressPrefix: string, sourcePortRange: string>, id: string>
# operationId: SecurityRules_CreateOrUpdate
export def "security-rules-create-or-update" [
  subscription_id: string
  resource_group_name: string
  network_security_group_name: string
  security_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated
  --name: string # Gets name of the resource that is unique within a resource group. This name can be used to access the resource
  --properties: any # shape: {access: "Allow"|"Deny", description?: string, destinationAddressPrefix: string, destinationPortRange?: string, direction: "Inbound"|"Outbound", priority?: int, protocol: "Tcp"|"Udp"|"*", provisioningState?: string, sourceAddressPrefix: string, sourcePortRange?: string}
  --id: string # Resource Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkSecurityGroups/{networkSecurityGroupName}/securityRules/{securityRuleName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: networkSecurityGroupName, var: network_security_group_name}, {name: securityRuleName, var: security_rule_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: name, var: name}, {name: properties, var: properties}, {name: id, var: id}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, network_security_group_name: $network_security_group_name, security_rule_name: $security_rule_name, api_version: $api_version, etag: $etag, name: $name, properties: $properties, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List publicIpAddress operation retrieves all the publicIpAddresses in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/publicIPAddresses
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: PublicIPAddresses_List
export def "public-ip-addresses-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/publicIPAddresses"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete publicIpAddress operation deletes the specified publicIpAddress.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/{publicIpAddressName}
# operationId: PublicIPAddresses_Delete
export def "public-ip-addresses-delete" [
  subscription_id: string
  resource_group_name: string
  public_ip_address_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/{publicIpAddressName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: publicIpAddressName, var: public_ip_address_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, public_ip_address_name: $public_ip_address_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get publicIpAddress operation retrieves information about the specified pubicIpAddress
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/{publicIpAddressName}
# Returns: record<etag: string, properties: record<dnsSettings: record<domainNameLabel: string, fqdn: string, reverseFqdn: string>, idleTimeoutInMinutes: int, ipAddress: string, ipConfiguration: record<etag: string, name: string, properties: record, id: string>, provisioningState: string, publicIPAddressVersion: string, publicIPAllocationMethod: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: PublicIPAddresses_Get
export def "public-ip-addresses-get" [
  subscription_id: string
  resource_group_name: string
  public_ip_address_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --expand: string # expand references resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/{publicIpAddressName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: publicIpAddressName, var: public_ip_address_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, public_ip_address_name: $public_ip_address_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put PublicIPAddress operation creates/updates a stable/dynamic PublicIP address
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/{publicIpAddressName}
# Returns: record<etag: string, properties: record<dnsSettings: record<domainNameLabel: string, fqdn: string, reverseFqdn: string>, idleTimeoutInMinutes: int, ipAddress: string, ipConfiguration: record<etag: string, name: string, properties: record, id: string>, provisioningState: string, publicIPAddressVersion: string, publicIPAllocationMethod: string, resourceGuid: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: PublicIPAddresses_CreateOrUpdate
export def "public-ip-addresses-create-or-update" [
  subscription_id: string
  resource_group_name: string
  public_ip_address_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # PublicIpAddress properties — shape: {dnsSettings?: any, idleTimeoutInMinutes?: int, ipAddress?: string, ipConfiguration?: any, provisioningState?: string, publicIPAddressVersion?: "IPv4"|"IPv6", publicIPAllocationMethod?: "Static"|"Dynamic", resourceGuid?: string}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/publicIPAddresses/{publicIpAddressName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: publicIpAddressName, var: public_ip_address_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, public_ip_address_name: $public_ip_address_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list RouteTables returns all route tables in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: RouteTables_List
export def "route-tables-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Delete RouteTable operation deletes the specified Route Table
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}
# operationId: RouteTables_Delete
export def "route-tables-delete" [
  subscription_id: string
  resource_group_name: string
  route_table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: routeTableName, var: route_table_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, route_table_name: $route_table_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get RouteTables operation retrieves information about the specified route table.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}
# Returns: record<etag: string, properties: record<provisioningState: string, routes: list<record>, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: RouteTables_Get
export def "route-tables-get" [
  subscription_id: string
  resource_group_name: string
  route_table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --expand: string # expand references resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: routeTableName, var: route_table_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, route_table_name: $route_table_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put RouteTable operation creates/updates a route table in the specified resource group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}
# Returns: record<etag: string, properties: record<provisioningState: string, routes: list<record>, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: RouteTables_CreateOrUpdate
export def "route-tables-create-or-update" [
  subscription_id: string
  resource_group_name: string
  route_table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # Route Table resource — shape: {provisioningState?: string, routes?: list}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: routeTableName, var: route_table_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, route_table_name: $route_table_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List network security rule operation retrieves all the routes in a route table.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}/routes
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: Routes_List
export def "routes-list" [
  subscription_id: string
  resource_group_name: string
  route_table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}/routes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: routeTableName, var: route_table_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, route_table_name: $route_table_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete route operation deletes the specified route from a route table.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}/routes/{routeName}
# operationId: Routes_Delete
export def "routes-delete" [
  subscription_id: string
  resource_group_name: string
  route_table_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}/routes/{routeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: routeTableName, var: route_table_name}, {name: routeName, var: route_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, route_table_name: $route_table_name, route_name: $route_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get route operation retrieves information about the specified route from the route table.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}/routes/{routeName}
# Returns: record<etag: string, name: string, properties: record<addressPrefix: string, nextHopIpAddress: string, nextHopType: string, provisioningState: string>, id: string>
# operationId: Routes_Get
export def "routes-get" [
  subscription_id: string
  resource_group_name: string
  route_table_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}/routes/{routeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: routeTableName, var: route_table_name}, {name: routeName, var: route_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, route_table_name: $route_table_name, route_name: $route_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put route operation creates/updates a route in the specified route table
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}/routes/{routeName}
# Returns: record<etag: string, name: string, properties: record<addressPrefix: string, nextHopIpAddress: string, nextHopType: string, provisioningState: string>, id: string>
# operationId: Routes_CreateOrUpdate
export def "routes-create-or-update" [
  subscription_id: string
  resource_group_name: string
  route_table_name: string
  route_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated
  --name: string # Gets name of the resource that is unique within a resource group. This name can be used to access the resource
  --properties: any # Route resource — shape: {addressPrefix?: string, nextHopIpAddress?: string, nextHopType: "VirtualNetworkGateway"|"VnetLocal"|"Internet"|"VirtualAppliance"|"None", provisioningState?: string}
  --id: string # Resource Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/routeTables/{routeTableName}/routes/{routeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: routeTableName, var: route_table_name}, {name: routeName, var: route_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: name, var: name}, {name: properties, var: properties}, {name: id, var: id}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, route_table_name: $route_table_name, route_name: $route_name, api_version: $api_version, etag: $etag, name: $name, properties: $properties, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List VirtualNetworkGateways operation retrieves all the virtual network gateways stored.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualNetworkGateways_List
export def "virtual-network-gateways-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Delete VirtualNetworkGateway operation deletes the specified virtual network Gateway through Network resource provider.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}
# operationId: VirtualNetworkGateways_Delete
export def "virtual-network-gateways-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get VirtualNetworkGateway operation retrieves information about the specified virtual network gateway through Network resource provider.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}
# Returns: record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<vpnClientAddressPool: record, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGateways_Get
export def "virtual-network-gateways-get" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put VirtualNetworkGateway operation creates/updates a virtual network gateway in the specified resource group through Network resource provider.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}
# Returns: record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<vpnClientAddressPool: record, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGateways_CreateOrUpdate
export def "virtual-network-gateways-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # VirtualNetworkGateway properties — shape: {activeActive?: bool, bgpSettings?: any, enableBgp?: bool, gatewayDefaultSite?: any, gatewayType?: "Vpn"|"ExpressRoute", ipConfigurations?: list, provisioningState?: string, resourceGuid?: string, sku?: any, vpnClientConfiguration?: any, vpnType?: "PolicyBased"|"RouteBased"}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Generatevpnclientpackage operation generates Vpn client package for P2S client of the virtual network gateway in the specified resource group through Network resource provider.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/generatevpnclientpackage
# Returns: string
# operationId: VirtualNetworkGateways_Generatevpnclientpackage
export def "virtual-network-gateways-generatevpnclientpackage" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --processor-architecture: string@processor-architecture-completer # VPN client Processor Architecture -Amd64/X86
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/generatevpnclientpackage"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ProcessorArchitecture, var: processor_architecture}]}
    accept: ["application/json", "text/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, processor_architecture: $processor_architecture
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Reset VirtualNetworkGateway operation resets the primary of the virtual network gateway in the specified resource group through Network resource provider.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/reset
# Returns: record<etag: string, properties: record<activeActive: bool, bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, enableBgp: bool, gatewayDefaultSite: record<id: string>, gatewayType: string, ipConfigurations: list<record>, provisioningState: string, resourceGuid: string, sku: record<capacity: int, name: string, tier: string>, vpnClientConfiguration: record<vpnClientAddressPool: record, vpnClientRevokedCertificates: list, vpnClientRootCertificates: list>, vpnType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworkGateways_Reset
export def "virtual-network-gateways-reset" [
  subscription_id: string
  resource_group_name: string
  virtual_network_gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # VirtualNetworkGateway properties — shape: {activeActive?: bool, bgpSettings?: any, enableBgp?: bool, gatewayDefaultSite?: any, gatewayType?: "Vpn"|"ExpressRoute", ipConfigurations?: list, provisioningState?: string, resourceGuid?: string, sku?: any, vpnClientConfiguration?: any, vpnType?: "PolicyBased"|"RouteBased"}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworkGateways/{virtualNetworkGatewayName}/reset"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkGatewayName, var: virtual_network_gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_gateway_name: $virtual_network_gateway_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list VirtualNetwork returns all Virtual Networks in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualNetworks_List
export def "virtual-networks-list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Delete VirtualNetwork operation deletes the specified virtual network
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}
# operationId: VirtualNetworks_Delete
export def "virtual-networks-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get VirtualNetwork operation retrieves information about the specified virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}
# Returns: record<etag: string, properties: record<VirtualNetworkPeerings: list<record>, addressSpace: record<addressPrefixes: list>, dhcpOptions: record<dnsServers: list>, provisioningState: string, resourceGuid: string, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworks_Get
export def "virtual-networks-get" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --expand: string # expand references resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put VirtualNetwork operation creates/updates a virtual network in the specified resource group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}
# Returns: record<etag: string, properties: record<VirtualNetworkPeerings: list<record>, addressSpace: record<addressPrefixes: list>, dhcpOptions: record<dnsServers: list>, provisioningState: string, resourceGuid: string, subnets: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualNetworks_CreateOrUpdate
export def "virtual-networks-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # Gets a unique read-only string that changes whenever the resource is updated
  --properties: any # shape: {VirtualNetworkPeerings?: list, addressSpace?: any, dhcpOptions?: any, provisioningState?: string, resourceGuid?: string, subnets?: list}
  --id: string # Resource Id
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, api_version: $api_version, etag: $etag, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Checks whether a private Ip address is available for use.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/CheckIPAddressAvailability
# Returns: record<available: bool, availableIPAddresses: list<string>>
# operationId: VirtualNetworks_CheckIPAddressAvailability
export def "virtual-networks-check-ip-address-availability" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ip-address: string # The private IP address to be verified.
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/CheckIPAddressAvailability"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}]
    query: [{name: ipAddress, var: ip_address}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, ip_address: $ip_address, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List subnets operation retrieves all the subnets in a virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: Subnets_List
export def "subnets-list" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete subnet operation deletes the specified subnet.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetName}
# operationId: Subnets_Delete
export def "subnets-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  subnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}, {name: subnetName, var: subnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, subnet_name: $subnet_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get subnet operation retrieves information about the specified subnet.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetName}
# Returns: record<etag: string, name: string, properties: record<addressPrefix: string, ipConfigurations: list<record>, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, provisioningState: string, resourceNavigationLinks: list<record>, routeTable: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string>
# operationId: Subnets_Get
export def "subnets-get" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  subnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --expand: string # expand references resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}, {name: subnetName, var: subnet_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, subnet_name: $subnet_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put Subnet operation creates/updates a subnet in the specified virtual network
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetName}
# Returns: record<etag: string, name: string, properties: record<addressPrefix: string, ipConfigurations: list<record>, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, provisioningState: string, resourceNavigationLinks: list<record>, routeTable: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>, id: string>
# operationId: Subnets_CreateOrUpdate
export def "subnets-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  subnet_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated
  --name: string # Gets or sets the name of the resource that is unique within a resource group. This name can be used to access the resource
  --properties: any # shape: {addressPrefix?: string, networkSecurityGroup?: any, provisioningState?: string, resourceNavigationLinks?: list, routeTable?: any}
  --id: string # Resource Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}, {name: subnetName, var: subnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: name, var: name}, {name: properties, var: properties}, {name: id, var: id}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, subnet_name: $subnet_name, api_version: $api_version, etag: $etag, name: $name, properties: $properties, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The List virtual network peerings operation retrieves all the peerings in a virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: VirtualNetworkPeerings_List
export def "virtual-network-peerings-list" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The delete virtual network peering operation deletes the specified peering.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings/{virtualNetworkPeeringName}
# operationId: VirtualNetworkPeerings_Delete
export def "virtual-network-peerings-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  virtual_network_peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings/{virtualNetworkPeeringName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}, {name: virtualNetworkPeeringName, var: virtual_network_peering_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, virtual_network_peering_name: $virtual_network_peering_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get virtual network peering operation retrieves information about the specified virtual network peering.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings/{virtualNetworkPeeringName}
# Returns: record<etag: string, name: string, properties: record<allowForwardedTraffic: bool, allowGatewayTransit: bool, allowVirtualNetworkAccess: bool, peeringState: string, provisioningState: string, remoteVirtualNetwork: record<id: string>, useRemoteGateways: bool>, id: string>
# operationId: VirtualNetworkPeerings_Get
export def "virtual-network-peerings-get" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  virtual_network_peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings/{virtualNetworkPeeringName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}, {name: virtualNetworkPeeringName, var: virtual_network_peering_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, virtual_network_peering_name: $virtual_network_peering_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Put virtual network peering operation creates/updates a peering in the specified virtual network
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings/{virtualNetworkPeeringName}
# Returns: record<etag: string, name: string, properties: record<allowForwardedTraffic: bool, allowGatewayTransit: bool, allowVirtualNetworkAccess: bool, peeringState: string, provisioningState: string, remoteVirtualNetwork: record<id: string>, useRemoteGateways: bool>, id: string>
# operationId: VirtualNetworkPeerings_CreateOrUpdate
export def "virtual-network-peerings-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_network_name: string
  virtual_network_peering_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --etag: string # A unique read-only string that changes whenever the resource is updated
  --name: string # Gets or sets the name of the resource that is unique within a resource group. This name can be used to access the resource
  --properties: any # shape: {allowForwardedTraffic?: bool, allowGatewayTransit?: bool, allowVirtualNetworkAccess?: bool, peeringState?: "Initiated"|"Connected"|"Disconnected", provisioningState?: string, remoteVirtualNetwork?: any, useRemoteGateways?: bool}
  --id: string # Resource Id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/virtualNetworkPeerings/{virtualNetworkPeeringName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualNetworkName, var: virtual_network_name}, {name: virtualNetworkPeeringName, var: virtual_network_peering_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: etag, var: etag}, {name: name, var: name}, {name: properties, var: properties}, {name: id, var: id}]}
    accept: ["application/json", "text/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_network_name: $virtual_network_name, virtual_network_peering_name: $virtual_network_peering_name, api_version: $api_version, etag: $etag, name: $name, properties: $properties, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list network interface operation retrieves information about all network interfaces in a virtual machine scale set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.Compute/virtualMachineScaleSets/{virtualMachineScaleSetName}/networkInterfaces
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: NetworkInterfaces_ListVirtualMachineScaleSetNetworkInterfaces
export def "network-interfaces-list-virtual-machine-scale-set-network-interfaces" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_scale_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.Compute/virtualMachineScaleSets/{virtualMachineScaleSetName}/networkInterfaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualMachineScaleSetName, var: virtual_machine_scale_set_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_machine_scale_set_name: $virtual_machine_scale_set_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The list network interface operation retrieves information about all network interfaces in a virtual machine from a virtual machine scale set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.Compute/virtualMachineScaleSets/{virtualMachineScaleSetName}/virtualMachines/{virtualmachineIndex}/networkInterfaces
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: NetworkInterfaces_ListVirtualMachineScaleSetVMNetworkInterfaces
export def "network-interfaces-list-virtual-machine-scale-set-vm-network-interfaces" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_scale_set_name: string
  virtualmachine_index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.Compute/virtualMachineScaleSets/{virtualMachineScaleSetName}/virtualMachines/{virtualmachineIndex}/networkInterfaces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualMachineScaleSetName, var: virtual_machine_scale_set_name}, {name: virtualmachineIndex, var: virtualmachine_index}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_machine_scale_set_name: $virtual_machine_scale_set_name, virtualmachine_index: $virtualmachine_index, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The Get network interface operation retrieves information about the specified network interface in a virtual machine scale set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.Compute/virtualMachineScaleSets/{virtualMachineScaleSetName}/virtualMachines/{virtualmachineIndex}/networkInterfaces/{networkInterfaceName}
# Returns: record<etag: string, properties: record<dnsSettings: record<appliedDnsServers: list, dnsServers: list, internalDnsNameLabel: string, internalDomainNameSuffix: string, internalFqdn: string>, enableIPForwarding: bool, ipConfigurations: list<record>, macAddress: string, networkSecurityGroup: record<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>, primary: bool, provisioningState: string, resourceGuid: string, virtualMachine: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: NetworkInterfaces_GetVirtualMachineScaleSetNetworkInterface
export def "network-interfaces-get-virtual-machine-scale-set-network-interface" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_scale_set_name: string
  virtualmachine_index: string
  network_interface_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client Api Version. (required)
  --expand: string # expand references resources.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.Compute/virtualMachineScaleSets/{virtualMachineScaleSetName}/virtualMachines/{virtualmachineIndex}/networkInterfaces/{networkInterfaceName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualMachineScaleSetName, var: virtual_machine_scale_set_name}, {name: virtualmachineIndex, var: virtualmachine_index}, {name: networkInterfaceName, var: network_interface_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$expand", var: expand}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_machine_scale_set_name: $virtual_machine_scale_set_name, virtualmachine_index: $virtualmachine_index, network_interface_name: $network_interface_name, api_version: $api_version, expand: $expand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
