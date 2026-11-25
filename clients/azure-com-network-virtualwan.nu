# Auto-generated client for VirtualWANAsAServiceManagementClient v2019-07-01
# Source: https://api.apis.guru/v2/specs/azure.com/network-virtualWan/2019-07-01/swagger.json
# Auth: --token flag or $env.VIRTUALWANASASERVICEMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "VIRTUALWANASASERVICEMANAGEMENTCLIENT_TOKEN"
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
def authentication-method-completer [] { ["EAPMSCHAPv2" "EAPTLS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    p2s-vpn-gateways-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-hubs-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-wans-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    vpn-gateways-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    vpn-sites-list: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    p2s-vpn-gateways-list-by-resource-group: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    p2s-vpn-gateways-get: "record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>"
    p2s-vpn-gateways-update-tags: "record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>"
    p2s-vpn-gateways-create-or-update: "record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>"
    p2s-vpn-gateways-generate-vpn-profile: "record<profileUrl: string>"
    p2s-vpn-gateways-get-p2s-vpn-connection-health: "record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-hubs-list-by-resource-group: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-hubs-get: "record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-hubs-update-tags: "record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-hubs-create-or-update: "record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>"
    hub-virtual-network-connections-list: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    hub-virtual-network-connections-get: "record<etag: string, name: string, properties: record<allowHubToRemoteVnetTransit: bool, allowRemoteVnetToUseHubVnetGateways: bool, enableInternetSecurity: bool, provisioningState: string, remoteVirtualNetwork: record<id: string>>, id: string>"
    virtual-wans-list-by-resource-group: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    virtual-wans-get: "record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-wans-update-tags: "record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    virtual-wans-create-or-update: "record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    supported-security-providers: "record<supportedProviders: table<name: string, type: string, url: string>>"
    p2s-vpn-server-configurations-list-by-virtual-wan: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    p2s-vpn-server-configurations-get: "record<etag: string, name: string, properties: record<etag: string, name: string, p2SVpnGateways: list<record>, p2SVpnServerConfigRadiusClientRootCertificates: list<record>, p2SVpnServerConfigRadiusServerRootCertificates: list<record>, p2SVpnServerConfigVpnClientRevokedCertificates: list<record>, p2SVpnServerConfigVpnClientRootCertificates: list<record>, provisioningState: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientIpsecPolicies: list<record>, vpnProtocols: list<string>>, id: string>"
    p2s-vpn-server-configurations-create-or-update: "record<etag: string, name: string, properties: record<etag: string, name: string, p2SVpnGateways: list<record>, p2SVpnServerConfigRadiusClientRootCertificates: list<record>, p2SVpnServerConfigRadiusServerRootCertificates: list<record>, p2SVpnServerConfigVpnClientRevokedCertificates: list<record>, p2SVpnServerConfigVpnClientRootCertificates: list<record>, provisioningState: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientIpsecPolicies: list<record>, vpnProtocols: list<string>>, id: string>"
    vpn-gateways-list-by-resource-group: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    vpn-gateways-get: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>"
    vpn-gateways-update-tags: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>"
    vpn-gateways-create-or-update: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>"
    vpn-gateways-reset: "record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>"
    vpn-connections-list-by-vpn-gateway: "record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>"
    vpn-connections-get: "record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableInternetSecurity: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, remoteVpnSite: record<id: string>, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnLinkConnections: list<record>>, id: string>"
    vpn-connections-create-or-update: "record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableInternetSecurity: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, remoteVpnSite: record<id: string>, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnLinkConnections: list<record>>, id: string>"
    vpn-link-connections-list-by-vpn-connection: "record<nextLink: string, value: table<etag: string, name: string, properties: record, type: string, id: string>>"
    vpn-site-link-connections-get: "record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnSiteLink: record<id: string>>, type: string, id: string>"
    vpn-sites-list-by-resource-group: "record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    vpn-sites-get: "record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    vpn-sites-update-tags: "record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    vpn-sites-create-or-update: "record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string>"
    vpn-site-links-list-by-vpn-site: "record<nextLink: string, value: table<etag: string, name: string, properties: record, type: string, id: string>>"
    vpn-site-links-get: "record<etag: string, name: string, properties: record<bgpProperties: record<asn: int, bgpPeeringAddress: string>, ipAddress: string, linkProperties: record<linkProviderName: string, linkSpeedInMbps: int>, provisioningState: string>, type: string, id: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["p2s-vpn-gateways-list" "virtual-hubs-list" "virtual-wans-list" "vpn-gateways-list" "vpn-sites-list" "p2s-vpn-gateways-list-by-resource-group" "p2s-vpn-gateways-delete" "p2s-vpn-gateways-get" "p2s-vpn-gateways-update-tags" "p2s-vpn-gateways-create-or-update" "p2s-vpn-gateways-generate-vpn-profile" "p2s-vpn-gateways-get-p2s-vpn-connection-health" "virtual-hubs-list-by-resource-group" "virtual-hubs-delete" "virtual-hubs-get" "virtual-hubs-update-tags" "virtual-hubs-create-or-update" "hub-virtual-network-connections-list" "hub-virtual-network-connections-get" "virtual-wans-list-by-resource-group" "virtual-wans-delete" "virtual-wans-get" "virtual-wans-update-tags" "virtual-wans-create-or-update" "supported-security-providers" "vpn-sites-configuration-download" "p2s-vpn-server-configurations-list-by-virtual-wan" "p2s-vpn-server-configurations-delete" "p2s-vpn-server-configurations-get" "p2s-vpn-server-configurations-create-or-update" "vpn-gateways-list-by-resource-group" "vpn-gateways-delete" "vpn-gateways-get" "vpn-gateways-update-tags" "vpn-gateways-create-or-update" "vpn-gateways-reset" "vpn-connections-list-by-vpn-gateway" "vpn-connections-delete" "vpn-connections-get" "vpn-connections-create-or-update" "vpn-link-connections-list-by-vpn-connection" "vpn-site-link-connections-get" "vpn-sites-list-by-resource-group" "vpn-sites-delete" "vpn-sites-get" "vpn-sites-update-tags" "vpn-sites-create-or-update" "vpn-site-links-list-by-vpn-site" "vpn-site-links-get" "commands"] | sort) } | get name | first)
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

# Lists all the P2SVpnGateways in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/p2svpnGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: P2sVpnGateways_List
export def "p2s-vpn-gateways-list" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/p2svpnGateways"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the VirtualHubs in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/virtualHubs
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualHubs_List
export def "virtual-hubs-list" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/virtualHubs"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the VirtualWANs in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/virtualWans
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualWans_List
export def "virtual-wans-list" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/virtualWans"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the VpnGateways in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/vpnGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VpnGateways_List
export def "vpn-gateways-list" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/vpnGateways"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the VpnSites in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/vpnSites
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VpnSites_List
export def "vpn-sites-list" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Network/vpnSites"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the P2SVpnGateways in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: P2sVpnGateways_ListByResourceGroup
export def "p2s-vpn-gateways-list-by-resource-group" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a virtual wan p2s vpn gateway.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}
# operationId: P2sVpnGateways_Delete
export def "p2s-vpn-gateways-delete" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a virtual wan p2s vpn gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}
# Returns: record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: P2sVpnGateways_Get
export def "p2s-vpn-gateways-get" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates virtual wan p2s vpn gateway tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}
# Returns: record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: P2sVpnGateways_UpdateTags
export def "p2s-vpn-gateways-update-tags" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a virtual wan p2s vpn gateway if it doesn't exist else updates the existing gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}
# Returns: record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: P2sVpnGateways_CreateOrUpdate
export def "p2s-vpn-gateways-create-or-update" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --properties: any # Parameters for P2SVpnGateway. — shape: {customRoutes?: any, p2SVpnServerConfiguration?: any, virtualHub?: any, vpnClientAddressPool?: any, vpnClientConnectionHealth?: any, vpnGatewayScaleUnit?: int}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates VPN profile for P2S client of the P2SVpnGateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}/generatevpnprofile
# Returns: record<profileUrl: string>
# operationId: P2sVpnGateways_GenerateVpnProfile
export def "p2s-vpn-gateways-generate-vpn-profile" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --authentication-method: string@authentication-method-completer # VPN client authentication method.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}/generatevpnprofile"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: authenticationMethod, var: authentication_method}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version, authentication_method: $authentication_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the connection health of P2S clients of the virtual wan P2SVpnGateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}/getP2sVpnConnectionHealth
# Returns: record<etag: string, properties: record<customRoutes: record<addressPrefixes: list>, p2SVpnServerConfiguration: record<id: string>, provisioningState: string, virtualHub: record<id: string>, vpnClientAddressPool: record<addressPrefixes: list>, vpnClientConnectionHealth: record<allocatedIpAddresses: list, totalEgressBytesTransferred: int, totalIngressBytesTransferred: int, vpnClientConnectionsCount: int>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: P2sVpnGateways_GetP2sVpnConnectionHealth
export def "p2s-vpn-gateways-get-p2s-vpn-connection-health" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/p2svpnGateways/{gatewayName}/getP2sVpnConnectionHealth"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the VirtualHubs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualHubs_ListByResourceGroup
export def "virtual-hubs-list-by-resource-group" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a VirtualHub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}
# operationId: VirtualHubs_Delete
export def "virtual-hubs-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualHubName, var: virtual_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_hub_name: $virtual_hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a VirtualHub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}
# Returns: record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualHubs_Get
export def "virtual-hubs-get" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualHubName, var: virtual_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_hub_name: $virtual_hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates VirtualHub tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}
# Returns: record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualHubs_UpdateTags
export def "virtual-hubs-update-tags" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualHubName, var: virtual_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_hub_name: $virtual_hub_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a VirtualHub resource if it doesn't exist else updates the existing VirtualHub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}
# Returns: record<etag: string, properties: record<addressPrefix: string, expressRouteGateway: record<id: string>, p2SVpnGateway: record<id: string>, provisioningState: string, routeTable: record<routes: list>, virtualNetworkConnections: list<record>, virtualWan: record<id: string>, vpnGateway: record<id: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualHubs_CreateOrUpdate
export def "virtual-hubs-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --properties: any # Parameters for VirtualHub. — shape: {addressPrefix?: string, expressRouteGateway?: any, p2SVpnGateway?: any, routeTable?: any, virtualNetworkConnections?: list, virtualWan?: any, vpnGateway?: any}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualHubName, var: virtual_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_hub_name: $virtual_hub_name, api_version: $api_version, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of all HubVirtualNetworkConnections.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}/hubVirtualNetworkConnections
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: HubVirtualNetworkConnections_List
export def "hub-virtual-network-connections-list" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}/hubVirtualNetworkConnections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualHubName, var: virtual_hub_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_hub_name: $virtual_hub_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a HubVirtualNetworkConnection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}/hubVirtualNetworkConnections/{connectionName}
# Returns: record<etag: string, name: string, properties: record<allowHubToRemoteVnetTransit: bool, allowRemoteVnetToUseHubVnetGateways: bool, enableInternetSecurity: bool, provisioningState: string, remoteVirtualNetwork: record<id: string>>, id: string>
# operationId: HubVirtualNetworkConnections_Get
export def "hub-virtual-network-connections-get" [
  subscription_id: string
  resource_group_name: string
  virtual_hub_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualHubs/{virtualHubName}/hubVirtualNetworkConnections/{connectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualHubName, var: virtual_hub_name}, {name: connectionName, var: connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_hub_name: $virtual_hub_name, connection_name: $connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the VirtualWANs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VirtualWans_ListByResourceGroup
export def "virtual-wans-list-by-resource-group" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a VirtualWAN.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}
# operationId: VirtualWans_Delete
export def "virtual-wans-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: VirtualWANName, var: virtual_wan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a VirtualWAN.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}
# Returns: record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualWans_Get
export def "virtual-wans-get" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: VirtualWANName, var: virtual_wan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a VirtualWAN tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}
# Returns: record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualWans_UpdateTags
export def "virtual-wans-update-tags" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: VirtualWANName, var: virtual_wan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a VirtualWAN resource if it doesn't exist else updates the existing VirtualWAN.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}
# Returns: record<etag: string, properties: record<allowBranchToBranchTraffic: bool, allowVnetToVnetTraffic: bool, disableVpnEncryption: bool, office365LocalBreakoutCategory: string, p2SVpnServerConfigurations: list<record>, provisioningState: string, securityProviderName: string, virtualHubs: list<record>, vpnSites: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VirtualWans_CreateOrUpdate
export def "virtual-wans-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --properties: any # Parameters for VirtualWAN. — shape: {allowBranchToBranchTraffic?: bool, allowVnetToVnetTraffic?: bool, disableVpnEncryption?: bool, p2SVpnServerConfigurations?: list, securityProviderName?: string}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{VirtualWANName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: VirtualWANName, var: virtual_wan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, api_version: $api_version, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gives the supported security providers for the virtual wan.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWANName}/supportedSecurityProviders
# Returns: record<supportedProviders: table<name: string, type: string, url: string>>
# operationId: SupportedSecurityProviders
export def "supported-security-providers" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWANName}/supportedSecurityProviders"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualWANName, var: virtual_wan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gives the sas-url to download the configurations for vpn-sites in a resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWANName}/vpnConfiguration
# operationId: VpnSitesConfiguration_Download
export def "vpn-sites-configuration-download" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  output_blob_sas_url: string # The sas-url to download the configurations for vpn-sites.
  --vpn-sites: list<string> # List of resource-ids of the vpn-sites for which config is to be downloaded.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWANName}/vpnConfiguration"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualWANName, var: virtual_wan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: outputBlobSasUrl, var: output_blob_sas_url}, {name: vpnSites, var: vpn_sites}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, api_version: $api_version, output_blob_sas_url: $output_blob_sas_url, vpn_sites: $vpn_sites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all P2SVpnServerConfigurations for a particular VirtualWan.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: P2sVpnServerConfigurations_ListByVirtualWan
export def "p2s-vpn-server-configurations-list-by-virtual-wan" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualWanName, var: virtual_wan_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a P2SVpnServerConfiguration.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}
# operationId: P2sVpnServerConfigurations_Delete
export def "p2s-vpn-server-configurations-delete" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  p2_s_vpn_server_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualWanName, var: virtual_wan_name}, {name: p2SVpnServerConfigurationName, var: p2_s_vpn_server_configuration_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, p2_s_vpn_server_configuration_name: $p2_s_vpn_server_configuration_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a P2SVpnServerConfiguration.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}
# Returns: record<etag: string, name: string, properties: record<etag: string, name: string, p2SVpnGateways: list<record>, p2SVpnServerConfigRadiusClientRootCertificates: list<record>, p2SVpnServerConfigRadiusServerRootCertificates: list<record>, p2SVpnServerConfigVpnClientRevokedCertificates: list<record>, p2SVpnServerConfigVpnClientRootCertificates: list<record>, provisioningState: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientIpsecPolicies: list<record>, vpnProtocols: list<string>>, id: string>
# operationId: P2sVpnServerConfigurations_Get
export def "p2s-vpn-server-configurations-get" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  p2_s_vpn_server_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualWanName, var: virtual_wan_name}, {name: p2SVpnServerConfigurationName, var: p2_s_vpn_server_configuration_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, p2_s_vpn_server_configuration_name: $p2_s_vpn_server_configuration_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a P2SVpnServerConfiguration to associate with a VirtualWan if it doesn't exist else updates the existing P2SVpnServerConfiguration.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}
# Returns: record<etag: string, name: string, properties: record<etag: string, name: string, p2SVpnGateways: list<record>, p2SVpnServerConfigRadiusClientRootCertificates: list<record>, p2SVpnServerConfigRadiusServerRootCertificates: list<record>, p2SVpnServerConfigVpnClientRevokedCertificates: list<record>, p2SVpnServerConfigVpnClientRootCertificates: list<record>, provisioningState: string, radiusServerAddress: string, radiusServerSecret: string, vpnClientIpsecPolicies: list<record>, vpnProtocols: list<string>>, id: string>
# operationId: P2sVpnServerConfigurations_CreateOrUpdate
export def "p2s-vpn-server-configurations-create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_wan_name: string
  p2_s_vpn_server_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --name: string # The name of the resource that is unique within a resource group. This name can be used to access the resource.
  --properties: any # Parameters for P2SVpnServerConfiguration. — shape: {etag?: string, name?: string, p2SVpnServerConfigRadiusClientRootCertificates?: list, p2SVpnServerConfigRadiusServerRootCertificates?: list, p2SVpnServerConfigVpnClientRevokedCertificates?: list, p2SVpnServerConfigVpnClientRootCertificates?: list, radiusServerAddress?: string, radiusServerSecret?: string, vpnClientIpsecPolicies?: list, vpnProtocols?: list<string>}
  --id: string # Resource ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualWans/{virtualWanName}/p2sVpnServerConfigurations/{p2SVpnServerConfigurationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: virtualWanName, var: virtual_wan_name}, {name: p2SVpnServerConfigurationName, var: p2_s_vpn_server_configuration_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, virtual_wan_name: $virtual_wan_name, p2_s_vpn_server_configuration_name: $p2_s_vpn_server_configuration_name, api_version: $api_version, name: $name, properties: $properties, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the VpnGateways in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VpnGateways_ListByResourceGroup
export def "vpn-gateways-list-by-resource-group" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a virtual wan vpn gateway.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}
# operationId: VpnGateways_Delete
export def "vpn-gateways-delete" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a virtual wan vpn gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VpnGateways_Get
export def "vpn-gateways-get" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates virtual wan vpn gateway tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VpnGateways_UpdateTags
export def "vpn-gateways-update-tags" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a virtual wan vpn gateway if it doesn't exist else updates the existing gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VpnGateways_CreateOrUpdate
export def "vpn-gateways-create-or-update" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --properties: any # Parameters for VpnGateway. — shape: {bgpSettings?: any, connections?: list, virtualHub?: any, vpnGatewayScaleUnit?: int}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the primary of the vpn gateway in the specified resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/reset
# Returns: record<etag: string, properties: record<bgpSettings: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, connections: list<record>, provisioningState: string, virtualHub: record<id: string>, vpnGatewayScaleUnit: int>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VpnGateways_Reset
export def "vpn-gateways-reset" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/reset"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all vpn connections for a particular virtual wan vpn gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, id: string>>
# operationId: VpnConnections_ListByVpnGateway
export def "vpn-connections-list-by-vpn-gateway" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a vpn connection.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}
# operationId: VpnConnections_Delete
export def "vpn-connections-delete" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}, {name: connectionName, var: connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, connection_name: $connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a vpn connection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}
# Returns: record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableInternetSecurity: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, remoteVpnSite: record<id: string>, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnLinkConnections: list<record>>, id: string>
# operationId: VpnConnections_Get
export def "vpn-connections-get" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}, {name: connectionName, var: connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, connection_name: $connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a vpn connection to a scalable vpn gateway if it doesn't exist else updates the existing connection.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}
# Returns: record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableInternetSecurity: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, remoteVpnSite: record<id: string>, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnLinkConnections: list<record>>, id: string>
# operationId: VpnConnections_CreateOrUpdate
export def "vpn-connections-create-or-update" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --name: string # The name of the resource that is unique within a resource group. This name can be used to access the resource.
  --properties: any # Parameters for VpnConnection. — shape: {connectionBandwidth?: int, enableBgp?: bool, enableInternetSecurity?: bool, enableRateLimiting?: bool, ipsecPolicies?: list, remoteVpnSite?: any, routingWeight?: int, sharedKey?: string, useLocalAzureIpAddress?: bool, usePolicyBasedTrafficSelectors?: bool, vpnConnectionProtocolType?: "IKEv2"|"IKEv1", vpnLinkConnections?: list}
  --id: string # Resource ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}, {name: connectionName, var: connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: properties, var: properties}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, connection_name: $connection_name, api_version: $api_version, name: $name, properties: $properties, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all vpn site link connections for a particular virtual wan vpn gateway vpn connection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}/vpnLinkConnections
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, type: string, id: string>>
# operationId: VpnLinkConnections_ListByVpnConnection
export def "vpn-link-connections-list-by-vpn-connection" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}/vpnLinkConnections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}, {name: connectionName, var: connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, connection_name: $connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a vpn site link connection.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}/vpnLinkConnections/{linkConnectionName}
# Returns: record<etag: string, name: string, properties: record<connectionBandwidth: int, connectionStatus: string, egressBytesTransferred: int, enableBgp: bool, enableRateLimiting: bool, ingressBytesTransferred: int, ipsecPolicies: list<record>, provisioningState: string, routingWeight: int, sharedKey: string, useLocalAzureIpAddress: bool, usePolicyBasedTrafficSelectors: bool, vpnConnectionProtocolType: string, vpnSiteLink: record<id: string>>, type: string, id: string>
# operationId: VpnSiteLinkConnections_Get
export def "vpn-site-link-connections-get" [
  subscription_id: string
  resource_group_name: string
  gateway_name: string
  connection_name: string
  link_connection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnGateways/{gatewayName}/vpnConnections/{connectionName}/vpnLinkConnections/{linkConnectionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: gatewayName, var: gateway_name}, {name: connectionName, var: connection_name}, {name: linkConnectionName, var: link_connection_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, gateway_name: $gateway_name, connection_name: $connection_name, link_connection_name: $link_connection_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the vpnSites in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites
# Returns: record<nextLink: string, value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: VpnSites_ListByResourceGroup
export def "vpn-sites-list-by-resource-group" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a VpnSite.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}
# operationId: VpnSites_Delete
export def "vpn-sites-delete" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vpnSiteName, var: vpn_site_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vpn_site_name: $vpn_site_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a VPN site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}
# Returns: record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VpnSites_Get
export def "vpn-sites-get" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vpnSiteName, var: vpn_site_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vpn_site_name: $vpn_site_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates VpnSite tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}
# Returns: record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VpnSites_UpdateTags
export def "vpn-sites-update-tags" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vpnSiteName, var: vpn_site_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vpn_site_name: $vpn_site_name, api_version: $api_version, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a VpnSite resource if it doesn't exist else updates the existing VpnSite.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}
# Returns: record<etag: string, properties: record<addressSpace: record<addressPrefixes: list>, bgpProperties: record<asn: int, bgpPeeringAddress: string, peerWeight: int>, deviceProperties: record<deviceModel: string, deviceVendor: string, linkSpeedInMbps: int>, ipAddress: string, isSecuritySite: bool, provisioningState: string, siteKey: string, virtualWan: record<id: string>, vpnSiteLinks: list<record>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: VpnSites_CreateOrUpdate
export def "vpn-sites-create-or-update" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
  --properties: any # Parameters for VpnSite. — shape: {addressSpace?: any, bgpProperties?: any, deviceProperties?: any, ipAddress?: string, isSecuritySite?: bool, siteKey?: string, virtualWan?: any, vpnSiteLinks?: list}
  --id: string # Resource ID.
  location: string # Resource location.
  --tags: record # Resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vpnSiteName, var: vpn_site_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vpn_site_name: $vpn_site_name, api_version: $api_version, properties: $properties, id: $id, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the vpnSiteLinks in a resource group for a vpn site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}/vpnSiteLinks
# Returns: record<nextLink: string, value: table<etag: string, name: string, properties: record, type: string, id: string>>
# operationId: VpnSiteLinks_ListByVpnSite
export def "vpn-site-links-list-by-vpn-site" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}/vpnSiteLinks"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vpnSiteName, var: vpn_site_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vpn_site_name: $vpn_site_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the details of a VPN site link.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}/vpnSiteLinks/{vpnSiteLinkName}
# Returns: record<etag: string, name: string, properties: record<bgpProperties: record<asn: int, bgpPeeringAddress: string>, ipAddress: string, linkProperties: record<linkProviderName: string, linkSpeedInMbps: int>, provisioningState: string>, type: string, id: string>
# operationId: VpnSiteLinks_Get
export def "vpn-site-links-get" [
  subscription_id: string
  resource_group_name: string
  vpn_site_name: string
  vpn_site_link_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/vpnSites/{vpnSiteName}/vpnSiteLinks/{vpnSiteLinkName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: vpnSiteName, var: vpn_site_name}, {name: vpnSiteLinkName, var: vpn_site_link_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, vpn_site_name: $vpn_site_name, vpn_site_link_name: $vpn_site_link_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
