# Auto-generated client for LogicManagementClient v2019-05-01
# Source: https://api.apis.guru/v2/specs/azure.com/logic/2019-05-01/swagger.json
# Auth: --token flag or $env.LOGICMANAGEMENTCLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "LOGICMANAGEMENTCLIENT_TOKEN"
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
def key-type-completer [] { ["NotSpecified" "Primary" "Secondary"] }
def track-events-options-completer [] { ["DisableSourceInfoEnrich" "None"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    operations-list: "record<nextLink: string, value: table<display: record, name: string>>"
    integration-accounts-list-by-subscription: "record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-service-environments-list-by-subscription: "record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    workflows-list-by-subscription: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-accounts-list-by-resource-group: "record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-accounts-get: "record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-accounts-update: "record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-accounts-create-or-update: "record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-agreements-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-account-agreements-get: "record<properties: record<agreementType: string, changedTime: string, content: record<aS2: record, edifact: record, x12: record>, createdTime: string, guestIdentity: record<qualifier: string, value: string>, guestPartner: string, hostIdentity: record<qualifier: string, value: string>, hostPartner: string, metadata: record>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-agreements-create-or-update: "record<properties: record<agreementType: string, changedTime: string, content: record<aS2: record, edifact: record, x12: record>, createdTime: string, guestIdentity: record<qualifier: string, value: string>, guestPartner: string, hostIdentity: record<qualifier: string, value: string>, hostPartner: string, metadata: record>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-agreements-list-content-callback-url: "record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>"
    integration-account-assemblies-list: "record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-account-assemblies-get: "record<properties: record<assemblyCulture: string, assemblyName: string, assemblyPublicKeyToken: string, assemblyVersion: string, content: any, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, changedTime: string, createdTime: string, metadata: any>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-assemblies-create-or-update: "record<properties: record<assemblyCulture: string, assemblyName: string, assemblyPublicKeyToken: string, assemblyVersion: string, content: any, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, changedTime: string, createdTime: string, metadata: any>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-assemblies-list-content-callback-url: "record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>"
    integration-account-batch-configurations-list: "record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-account-batch-configurations-get: "record<properties: record<batchGroupName: string, changedTime: string, createdTime: string, releaseCriteria: record<batchSize: int, messageCount: int, recurrence: record>, metadata: any>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-batch-configurations-create-or-update: "record<properties: record<batchGroupName: string, changedTime: string, createdTime: string, releaseCriteria: record<batchSize: int, messageCount: int, recurrence: record>, metadata: any>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-certificates-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-account-certificates-get: "record<properties: record<changedTime: string, createdTime: string, key: record<keyName: string, keyVault: record, keyVersion: string>, metadata: record, publicCertificate: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-certificates-create-or-update: "record<properties: record<changedTime: string, createdTime: string, key: record<keyName: string, keyVault: record, keyVersion: string>, metadata: record, publicCertificate: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-accounts-list-callback-url: "record<value: string>"
    integration-accounts-list-key-vault-keys: "record<skipToken: string, value: table<attributes: record, kid: string>>"
    integration-account-maps-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-account-maps-get: "record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, mapType: string, metadata: record, parametersSchema: record<ref: string>>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-maps-create-or-update: "record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, mapType: string, metadata: record, parametersSchema: record<ref: string>>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-maps-list-content-callback-url: "record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>"
    integration-account-partners-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-account-partners-get: "record<properties: record<changedTime: string, content: record<b2b: record>, createdTime: string, metadata: record, partnerType: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-partners-create-or-update: "record<properties: record<changedTime: string, content: record<b2b: record>, createdTime: string, metadata: record, partnerType: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-partners-list-content-callback-url: "record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>"
    integration-accounts-regenerate-access-key: "record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-schemas-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-account-schemas-get: "record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, documentName: string, fileName: string, metadata: record, schemaType: string, targetNamespace: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-schemas-create-or-update: "record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, documentName: string, fileName: string, metadata: record, schemaType: string, targetNamespace: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-schemas-list-content-callback-url: "record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>"
    integration-account-sessions-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-account-sessions-get: "record<properties: record<changedTime: string, content: record, createdTime: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-account-sessions-create-or-update: "record<properties: record<changedTime: string, content: record, createdTime: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflows-list-by-resource-group: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    workflows-get: "record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflows-update: "record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflows-create-or-update: "record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflows-generate-upgraded-definition: "record"
    workflows-list-callback-url: "record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>"
    workflows-list-swagger: "record"
    workflow-runs-list: "record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>"
    workflow-runs-get: "record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, correlationId: string, endTime: string, error: record, outputs: record, response: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, startTime: string, status: string, trigger: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, waitEndTime: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>"
    workflow-run-actions-list: "record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>"
    workflow-run-actions-get: "record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, endTime: string, error: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, startTime: string, status: string, trackedProperties: record, trackingId: string>, type: string, id: string>"
    workflow-run-actions-list-expression-traces: "record<inputs: table<path: string, error: record, subexpressions: list, text: string, value: any>>"
    workflow-run-action-repetitions-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    workflow-run-action-repetitions-get: "record<properties: record<repetitionIndexes: list<record>, inputs: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, iterationCount: int, outputs: record, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, trackedProperties: record, trackingId: string, code: string, correlation: record<actionTrackingId: string, clientKeywords: list, clientTrackingId: string>, endTime: string, error: any, startTime: string, status: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflow-run-action-repetitions-list-expression-traces: "record<inputs: table<path: string, error: record, subexpressions: list, text: string, value: any>>"
    workflow-run-action-repetitions-request-histories-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    workflow-run-action-repetitions-request-histories-get: "record<properties: record<endTime: string, request: record<headers: record, method: string, uri: string>, response: record<bodyLink: record, headers: record, statusCode: int>, startTime: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflow-run-action-request-histories-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    workflow-run-action-request-histories-get: "record<properties: record<endTime: string, request: record<headers: record, method: string, uri: string>, response: record<bodyLink: record, headers: record, statusCode: int>, startTime: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflow-run-action-scope-repetitions-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    workflow-run-action-scope-repetitions-get: "record<properties: record<repetitionIndexes: list<record>, inputs: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, iterationCount: int, outputs: record, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, trackedProperties: record, trackingId: string, code: string, correlation: record<actionTrackingId: string, clientKeywords: list, clientTrackingId: string>, endTime: string, error: any, startTime: string, status: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflow-run-operations-get: "record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, correlationId: string, endTime: string, error: record, outputs: record, response: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, startTime: string, status: string, trigger: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, waitEndTime: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>"
    workflow-triggers-list: "record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>"
    workflow-triggers-get: "record<name: string, properties: record<changedTime: string, createdTime: string, lastExecutionTime: string, nextExecutionTime: string, provisioningState: string, recurrence: record<endTime: string, frequency: string, interval: int, schedule: record, startTime: string, timeZone: string>, state: string, status: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>"
    workflow-trigger-histories-list: "record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>"
    workflow-trigger-histories-get: "record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, endTime: string, error: record, fired: bool, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, run: record<id: string, name: string, type: string>, startTime: string, status: string, trackingId: string>, type: string, id: string>"
    workflow-triggers-list-callback-url: "record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>"
    workflow-triggers-run: "record"
    workflow-triggers-get-schema-json: "record<content: string, title: string>"
    workflow-versions-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    workflow-versions-get: "record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, integrationAccount: record<id: string, name: string, type: string>, parameters: record, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>"
    workflow-version-triggers-list-callback-url: "record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>"
    integration-service-environments-list-by-resource-group: "record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-service-environments-get: "record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-service-environments-update: "record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-service-environments-create-or-update: "record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>"
    integration-service-environment-network-health-get: "record"
    integration-service-environment-managed-apis-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-service-environment-managed-apis-get: "record<properties: record<apiDefinitionUrl: string, apiDefinitions: record<modifiedSwaggerUrl: string, originalSwaggerUrl: string>, backendService: record<serviceUrl: string>, capabilities: list<string>, category: string, connectionParameters: record, generalInformation: record<description: string, displayName: string, iconUrl: string, releaseTag: string, termsOfUseUrl: string, tier: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, metadata: record<ApiType: string, brandColor: string, connectionType: string, deploymentParameters: record, hideKey: string, provisioningState: string, source: string, tags: record, wsdlImportMethod: string, wsdlService: record>, name: string, policies: record<content: string, contentLink: string>, provisioningState: string, runtimeUrls: list<string>>, id: string, location: string, name: string, tags: record, type: string>"
    integration-service-environment-managed-apis-put: "record<properties: record<apiDefinitionUrl: string, apiDefinitions: record<modifiedSwaggerUrl: string, originalSwaggerUrl: string>, backendService: record<serviceUrl: string>, capabilities: list<string>, category: string, connectionParameters: record, generalInformation: record<description: string, displayName: string, iconUrl: string, releaseTag: string, termsOfUseUrl: string, tier: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, metadata: record<ApiType: string, brandColor: string, connectionType: string, deploymentParameters: record, hideKey: string, provisioningState: string, source: string, tags: record, wsdlImportMethod: string, wsdlService: record>, name: string, policies: record<content: string, contentLink: string>, provisioningState: string, runtimeUrls: list<string>>, id: string, location: string, name: string, tags: record, type: string>"
    integration-service-environment-managed-api-operations-list: "record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>"
    integration-service-environment-skus-list: "record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["operations-list" "integration-accounts-list-by-subscription" "integration-service-environments-list-by-subscription" "workflows-list-by-subscription" "integration-accounts-list-by-resource-group" "integration-accounts-delete" "integration-accounts-get" "integration-accounts-update" "integration-accounts-create-or-update" "integration-account-agreements-list" "integration-account-agreements-delete" "integration-account-agreements-get" "integration-account-agreements-create-or-update" "integration-account-agreements-list-content-callback-url" "integration-account-assemblies-list" "integration-account-assemblies-delete" "integration-account-assemblies-get" "integration-account-assemblies-create-or-update" "integration-account-assemblies-list-content-callback-url" "integration-account-batch-configurations-list" "integration-account-batch-configurations-delete" "integration-account-batch-configurations-get" "integration-account-batch-configurations-create-or-update" "integration-account-certificates-list" "integration-account-certificates-delete" "integration-account-certificates-get" "integration-account-certificates-create-or-update" "integration-accounts-list-callback-url" "integration-accounts-list-key-vault-keys" "integration-accounts-log-tracking-events" "integration-account-maps-list" "integration-account-maps-delete" "integration-account-maps-get" "integration-account-maps-create-or-update" "integration-account-maps-list-content-callback-url" "integration-account-partners-list" "integration-account-partners-delete" "integration-account-partners-get" "integration-account-partners-create-or-update" "integration-account-partners-list-content-callback-url" "integration-accounts-regenerate-access-key" "integration-account-schemas-list" "integration-account-schemas-delete" "integration-account-schemas-get" "integration-account-schemas-create-or-update" "integration-account-schemas-list-content-callback-url" "integration-account-sessions-list" "integration-account-sessions-delete" "integration-account-sessions-get" "integration-account-sessions-create-or-update" "workflows-validate-by-location" "workflows-list-by-resource-group" "workflows-delete" "workflows-get" "workflows-update" "workflows-create-or-update" "workflows-disable" "workflows-enable" "workflows-generate-upgraded-definition" "workflows-list-callback-url" "workflows-list-swagger" "workflows-move" "workflows-regenerate-access-key" "workflow-runs-list" "workflow-runs-get" "workflow-run-actions-list" "workflow-run-actions-get" "workflow-run-actions-list-expression-traces" "workflow-run-action-repetitions-list" "workflow-run-action-repetitions-get" "workflow-run-action-repetitions-list-expression-traces" "workflow-run-action-repetitions-request-histories-list" "workflow-run-action-repetitions-request-histories-get" "workflow-run-action-request-histories-list" "workflow-run-action-request-histories-get" "workflow-run-action-scope-repetitions-list" "workflow-run-action-scope-repetitions-get" "workflow-runs-cancel" "workflow-run-operations-get" "workflow-triggers-list" "workflow-triggers-get" "workflow-trigger-histories-list" "workflow-trigger-histories-get" "workflow-trigger-histories-resubmit" "workflow-triggers-list-callback-url" "workflow-triggers-reset" "workflow-triggers-run" "workflow-triggers-get-schema-json" "workflow-triggers-set-state" "workflows-validate-by-resource-group" "workflow-versions-list" "workflow-versions-get" "workflow-version-triggers-list-callback-url" "integration-service-environments-list-by-resource-group" "integration-service-environments-delete" "integration-service-environments-get" "integration-service-environments-update" "integration-service-environments-create-or-update" "integration-service-environment-network-health-get" "integration-service-environment-managed-apis-list" "integration-service-environment-managed-apis-delete" "integration-service-environment-managed-apis-get" "integration-service-environment-managed-apis-put" "integration-service-environment-managed-api-operations-list" "integration-service-environments-restart" "integration-service-environment-skus-list" "commands"] | sort) } | get name | first)
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

# Lists all of the available Logic REST API operations.
#
# GET /providers/Microsoft.Logic/operations
# Returns: record<nextLink: string, value: table<display: record, name: string>>
# operationId: Operations_List
export def "operations-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Logic/operations"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration accounts by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/integrationAccounts
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccounts_ListBySubscription
export def "integration-accounts-list-by-subscription" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Logic/integrationAccounts"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration service environments by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/integrationServiceEnvironments
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationServiceEnvironments_ListBySubscription
export def "integration-service-environments-list-by-subscription" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Logic/integrationServiceEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of workflows by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/workflows
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Workflows_ListBySubscription
export def "workflows-list-by-subscription" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: State, Trigger, and ReferencedResourceId.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Logic/workflows"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration accounts by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccounts_ListByResourceGroup
export def "integration-accounts-list-by-resource-group" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_Delete
export def "integration-accounts-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# Returns: record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccounts_Get
export def "integration-accounts-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an integration account.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# Returns: record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccounts_Update
export def "integration-accounts-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The integration account properties. — shape: {integrationServiceEnvironment?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration account sku. — shape: {name: "NotSpecified"|"Free"|"Basic"|"Standard"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# Returns: record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccounts_CreateOrUpdate
export def "integration-accounts-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The integration account properties. — shape: {integrationServiceEnvironment?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration account sku. — shape: {name: "NotSpecified"|"Free"|"Basic"|"Standard"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration account agreements.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccountAgreements_List
export def "integration-account-agreements-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: AgreementType.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an integration account agreement.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# operationId: IntegrationAccountAgreements_Delete
export def "integration-account-agreements-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: agreementName, var: agreement_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, agreement_name: $agreement_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an integration account agreement.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# Returns: record<properties: record<agreementType: string, changedTime: string, content: record<aS2: record, edifact: record, x12: record>, createdTime: string, guestIdentity: record<qualifier: string, value: string>, guestPartner: string, hostIdentity: record<qualifier: string, value: string>, hostPartner: string, metadata: record>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountAgreements_Get
export def "integration-account-agreements-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: agreementName, var: agreement_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, agreement_name: $agreement_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an integration account agreement.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# Returns: record<properties: record<agreementType: string, changedTime: string, content: record<aS2: record, edifact: record, x12: record>, createdTime: string, guestIdentity: record<qualifier: string, value: string>, guestPartner: string, hostIdentity: record<qualifier: string, value: string>, hostPartner: string, metadata: record>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountAgreements_CreateOrUpdate
export def "integration-account-agreements-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account agreement properties. — shape: {agreementType: "NotSpecified"|"AS2"|"X12"|"Edifact", content: record, guestIdentity: record, guestPartner: string, hostIdentity: record, hostPartner: string, metadata?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: agreementName, var: agreement_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, agreement_name: $agreement_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}/listContentCallbackUrl
# Returns: record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>
# operationId: IntegrationAccountAgreements_ListContentCallbackUrl
export def "integration-account-agreements-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}/listContentCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: agreementName, var: agreement_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}, {name: notAfter, var: not_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, agreement_name: $agreement_name, api_version: $api_version, key_type: $key_type, not_after: $not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the assemblies for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies
# Returns: record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccountAssemblies_List
export def "integration-account-assemblies-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an assembly for an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# operationId: IntegrationAccountAssemblies_Delete
export def "integration-account-assemblies-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: assemblyArtifactName, var: assembly_artifact_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, assembly_artifact_name: $assembly_artifact_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an assembly for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# Returns: record<properties: record<assemblyCulture: string, assemblyName: string, assemblyPublicKeyToken: string, assemblyVersion: string, content: any, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, changedTime: string, createdTime: string, metadata: any>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountAssemblies_Get
export def "integration-account-assemblies-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: assemblyArtifactName, var: assembly_artifact_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, assembly_artifact_name: $assembly_artifact_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update an assembly for an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# Returns: record<properties: record<assemblyCulture: string, assemblyName: string, assemblyPublicKeyToken: string, assemblyVersion: string, content: any, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, changedTime: string, createdTime: string, metadata: any>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountAssemblies_CreateOrUpdate
export def "integration-account-assemblies-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The assembly properties definition. — shape: {assemblyCulture?: string, assemblyName: string, assemblyPublicKeyToken?: string, assemblyVersion?: string, contentLink?: record, contentType?: string, changedTime?: string, createdTime?: string}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: assemblyArtifactName, var: assembly_artifact_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, assembly_artifact_name: $assembly_artifact_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content callback url for an integration account assembly.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}/listContentCallbackUrl
# Returns: record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>
# operationId: IntegrationAccountAssemblies_ListContentCallbackUrl
export def "integration-account-assemblies-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}/listContentCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: assemblyArtifactName, var: assembly_artifact_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, assembly_artifact_name: $assembly_artifact_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the batch configurations for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations
# Returns: record<value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccountBatchConfigurations_List
export def "integration-account-batch-configurations-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a batch configuration for an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# operationId: IntegrationAccountBatchConfigurations_Delete
export def "integration-account-batch-configurations-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: batchConfigurationName, var: batch_configuration_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, batch_configuration_name: $batch_configuration_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a batch configuration for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# Returns: record<properties: record<batchGroupName: string, changedTime: string, createdTime: string, releaseCriteria: record<batchSize: int, messageCount: int, recurrence: record>, metadata: any>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountBatchConfigurations_Get
export def "integration-account-batch-configurations-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: batchConfigurationName, var: batch_configuration_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, batch_configuration_name: $batch_configuration_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a batch configuration for an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# Returns: record<properties: record<batchGroupName: string, changedTime: string, createdTime: string, releaseCriteria: record<batchSize: int, messageCount: int, recurrence: record>, metadata: any>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountBatchConfigurations_CreateOrUpdate
export def "integration-account-batch-configurations-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The batch configuration properties definition. — shape: {batchGroupName: string, changedTime?: string, createdTime?: string, releaseCriteria: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: batchConfigurationName, var: batch_configuration_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, batch_configuration_name: $batch_configuration_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration account certificates.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccountCertificates_List
export def "integration-account-certificates-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an integration account certificate.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# operationId: IntegrationAccountCertificates_Delete
export def "integration-account-certificates-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an integration account certificate.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# Returns: record<properties: record<changedTime: string, createdTime: string, key: record<keyName: string, keyVault: record, keyVersion: string>, metadata: record, publicCertificate: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountCertificates_Get
export def "integration-account-certificates-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an integration account certificate.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# Returns: record<properties: record<changedTime: string, createdTime: string, key: record<keyName: string, keyVault: record, keyVersion: string>, metadata: record, publicCertificate: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountCertificates_CreateOrUpdate
export def "integration-account-certificates-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account certificate properties. — shape: {key?: record, metadata?: record, publicCertificate?: string}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: certificateName, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, certificate_name: $certificate_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the integration account callback URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/listCallbackUrl
# Returns: record<value: string>
# operationId: IntegrationAccounts_ListCallbackUrl
export def "integration-accounts-list-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/listCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}, {name: notAfter, var: not_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, key_type: $key_type, not_after: $not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the integration account's Key Vault keys.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/listKeyVaultKeys
# Returns: record<skipToken: string, value: table<attributes: record, kid: string>>
# operationId: IntegrationAccounts_ListKeyVaultKeys
export def "integration-accounts-list-key-vault-keys" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  key_vault: record # The key vault reference. — shape: {id?: string}
  --skip-token: string # The skip token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/listKeyVaultKeys"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyVault, var: key_vault}, {name: skipToken, var: skip_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, key_vault: $key_vault, skip_token: $skip_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logs the integration account's tracking events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/logTrackingEvents
# operationId: IntegrationAccounts_LogTrackingEvents
export def "integration-accounts-log-tracking-events" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  events: list # The events. — item shape: {error?: record, eventLevel: "LogAlways"|"Critical"|"Error"|"Warning"|"Informational"|"Verbose", eventTime: string, ... (1 more fields)}
  source_type: string # The source type.
  --track-events-options: string@track-events-options-completer # The track events operation options.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/logTrackingEvents"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: events, var: events}, {name: sourceType, var: source_type}, {name: trackEventsOptions, var: track_events_options}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, events: $events, source_type: $source_type, track_events_options: $track_events_options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration account maps.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccountMaps_List
export def "integration-account-maps-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: MapType.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an integration account map.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# operationId: IntegrationAccountMaps_Delete
export def "integration-account-maps-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: mapName, var: map_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, map_name: $map_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an integration account map.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# Returns: record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, mapType: string, metadata: record, parametersSchema: record<ref: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountMaps_Get
export def "integration-account-maps-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: mapName, var: map_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, map_name: $map_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an integration account map.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# Returns: record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, mapType: string, metadata: record, parametersSchema: record<ref: string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountMaps_CreateOrUpdate
export def "integration-account-maps-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account map. — shape: {content?: string, contentLink?: record, contentType?: string, mapType: "NotSpecified"|"Xslt"|"Xslt20"|"Xslt30"|"Liquid", metadata?: record, parametersSchema?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: mapName, var: map_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, map_name: $map_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}/listContentCallbackUrl
# Returns: record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>
# operationId: IntegrationAccountMaps_ListContentCallbackUrl
export def "integration-account-maps-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}/listContentCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: mapName, var: map_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}, {name: notAfter, var: not_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, map_name: $map_name, api_version: $api_version, key_type: $key_type, not_after: $not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration account partners.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccountPartners_List
export def "integration-account-partners-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: PartnerType.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an integration account partner.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# operationId: IntegrationAccountPartners_Delete
export def "integration-account-partners-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: partnerName, var: partner_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, partner_name: $partner_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an integration account partner.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# Returns: record<properties: record<changedTime: string, content: record<b2b: record>, createdTime: string, metadata: record, partnerType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountPartners_Get
export def "integration-account-partners-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: partnerName, var: partner_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, partner_name: $partner_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an integration account partner.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# Returns: record<properties: record<changedTime: string, content: record<b2b: record>, createdTime: string, metadata: record, partnerType: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountPartners_CreateOrUpdate
export def "integration-account-partners-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account partner properties. — shape: {content: record, metadata?: record, partnerType: "NotSpecified"|"B2B"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: partnerName, var: partner_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, partner_name: $partner_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}/listContentCallbackUrl
# Returns: record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>
# operationId: IntegrationAccountPartners_ListContentCallbackUrl
export def "integration-account-partners-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}/listContentCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: partnerName, var: partner_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}, {name: notAfter, var: not_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, partner_name: $partner_name, api_version: $api_version, key_type: $key_type, not_after: $not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerates the integration account access key.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/regenerateAccessKey
# Returns: record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>, state: string>, sku: record<name: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccounts_RegenerateAccessKey
export def "integration-accounts-regenerate-access-key" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/regenerateAccessKey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, key_type: $key_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration account schemas.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccountSchemas_List
export def "integration-account-schemas-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: SchemaType.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an integration account schema.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# operationId: IntegrationAccountSchemas_Delete
export def "integration-account-schemas-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: schemaName, var: schema_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, schema_name: $schema_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an integration account schema.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# Returns: record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, documentName: string, fileName: string, metadata: record, schemaType: string, targetNamespace: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountSchemas_Get
export def "integration-account-schemas-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: schemaName, var: schema_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, schema_name: $schema_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an integration account schema.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# Returns: record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, documentName: string, fileName: string, metadata: record, schemaType: string, targetNamespace: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountSchemas_CreateOrUpdate
export def "integration-account-schemas-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account schema properties. — shape: {content?: string, contentLink?: record, contentType?: string, documentName?: string, fileName?: string, metadata?: record, schemaType: "NotSpecified"|"Xml", targetNamespace?: string}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: schemaName, var: schema_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, schema_name: $schema_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}/listContentCallbackUrl
# Returns: record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>
# operationId: IntegrationAccountSchemas_ListContentCallbackUrl
export def "integration-account-schemas-list-content-callback-url" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}/listContentCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: schemaName, var: schema_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}, {name: notAfter, var: not_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, schema_name: $schema_name, api_version: $api_version, key_type: $key_type, not_after: $not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration account sessions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationAccountSessions_List
export def "integration-account-sessions-list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: ChangedTime.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an integration account session.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# operationId: IntegrationAccountSessions_Delete
export def "integration-account-sessions-delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: sessionName, var: session_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, session_name: $session_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an integration account session.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# Returns: record<properties: record<changedTime: string, content: record, createdTime: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountSessions_Get
export def "integration-account-sessions-get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: sessionName, var: session_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, session_name: $session_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an integration account session.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# Returns: record<properties: record<changedTime: string, content: record, createdTime: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationAccountSessions_CreateOrUpdate
export def "integration-account-sessions-create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  properties: record # The integration account session properties. — shape: {content?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: integrationAccountName, var: integration_account_name}, {name: sessionName, var: session_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, integration_account_name: $integration_account_name, session_name: $session_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates the workflow definition.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/locations/{location}/workflows/{workflowName}/validate
# operationId: Workflows_ValidateByLocation
export def "workflows-validate-by-location" [
  subscription_id: string
  resource_group_name: string
  location: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/locations/{location}/workflows/{workflowName}/validate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: location, var: location}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, location: $location, workflow_name: $workflow_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of workflows by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: Workflows_ListByResourceGroup
export def "workflows-list-by-resource-group" [
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
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: State, Trigger, and ReferencedResourceId.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a workflow.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_Delete
export def "workflows-delete" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a workflow.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# Returns: record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Workflows_Get
export def "workflows-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a workflow.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# Returns: record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Workflows_Update
export def "workflows-update" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a workflow.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# Returns: record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: Workflows_CreateOrUpdate
export def "workflows-create-or-update" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/disable
# operationId: Workflows_Disable
export def "workflows-disable" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/disable"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/enable
# operationId: Workflows_Enable
export def "workflows-enable" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/enable"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates the upgraded definition for a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/generateUpgradedDefinition
# Returns: record
# operationId: Workflows_GenerateUpgradedDefinition
export def "workflows-generate-upgraded-definition" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --target-schema-version: string # The target schema version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/generateUpgradedDefinition"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: targetSchemaVersion, var: target_schema_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, target_schema_version: $target_schema_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the workflow callback Url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/listCallbackUrl
# Returns: record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>
# operationId: Workflows_ListCallbackUrl
export def "workflows-list-callback-url" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/listCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}, {name: notAfter, var: not_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, key_type: $key_type, not_after: $not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an OpenAPI definition for the workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/listSwagger
# Returns: record
# operationId: Workflows_ListSwagger
export def "workflows-list-swagger" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/listSwagger"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves an existing workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/move
# operationId: Workflows_Move
export def "workflows-move" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/move"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerates the callback URL access key for request triggers.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/regenerateAccessKey
# operationId: Workflows_RegenerateAccessKey
export def "workflows-regenerate-access-key" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/regenerateAccessKey"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, key_type: $key_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of workflow runs.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs
# Returns: record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>
# operationId: WorkflowRuns_List
export def "workflow-runs-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status, StartTime, and ClientTrackingId.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a workflow run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}
# Returns: record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, correlationId: string, endTime: string, error: record, outputs: record, response: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, startTime: string, status: string, trigger: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, waitEndTime: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>
# operationId: WorkflowRuns_Get
export def "workflow-runs-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of workflow run actions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions
# Returns: record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>
# operationId: WorkflowRunActions_List
export def "workflow-run-actions-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a workflow run action.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}
# Returns: record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, endTime: string, error: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, startTime: string, status: string, trackedProperties: record, trackingId: string>, type: string, id: string>
# operationId: WorkflowRunActions_Get
export def "workflow-run-actions-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists a workflow run expression trace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/listExpressionTraces
# Returns: record<inputs: table<path: string, error: record, subexpressions: list, text: string, value: any>>
# operationId: WorkflowRunActions_ListExpressionTraces
export def "workflow-run-actions-list-expression-traces" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/listExpressionTraces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all of a workflow run action repetitions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: WorkflowRunActionRepetitions_List
export def "workflow-run-action-repetitions-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a workflow run action repetition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}
# Returns: record<properties: record<repetitionIndexes: list<record>, inputs: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, iterationCount: int, outputs: record, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, trackedProperties: record, trackingId: string, code: string, correlation: record<actionTrackingId: string, clientKeywords: list, clientTrackingId: string>, endTime: string, error: any, startTime: string, status: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: WorkflowRunActionRepetitions_Get
export def "workflow-run-action-repetitions-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}, {name: repetitionName, var: repetition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, repetition_name: $repetition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists a workflow run expression trace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/listExpressionTraces
# Returns: record<inputs: table<path: string, error: record, subexpressions: list, text: string, value: any>>
# operationId: WorkflowRunActionRepetitions_ListExpressionTraces
export def "workflow-run-action-repetitions-list-expression-traces" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/listExpressionTraces"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}, {name: repetitionName, var: repetition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, repetition_name: $repetition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a workflow run repetition request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/requestHistories
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: WorkflowRunActionRepetitionsRequestHistories_List
export def "workflow-run-action-repetitions-request-histories-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/requestHistories"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}, {name: repetitionName, var: repetition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, repetition_name: $repetition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a workflow run repetition request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/requestHistories/{requestHistoryName}
# Returns: record<properties: record<endTime: string, request: record<headers: record, method: string, uri: string>, response: record<bodyLink: record, headers: record, statusCode: int>, startTime: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: WorkflowRunActionRepetitionsRequestHistories_Get
export def "workflow-run-action-repetitions-request-histories-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  request_history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/requestHistories/{requestHistoryName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}, {name: repetitionName, var: repetition_name}, {name: requestHistoryName, var: request_history_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, repetition_name: $repetition_name, request_history_name: $request_history_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List a workflow run request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/requestHistories
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: WorkflowRunActionRequestHistories_List
export def "workflow-run-action-request-histories-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/requestHistories"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a workflow run request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/requestHistories/{requestHistoryName}
# Returns: record<properties: record<endTime: string, request: record<headers: record, method: string, uri: string>, response: record<bodyLink: record, headers: record, statusCode: int>, startTime: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: WorkflowRunActionRequestHistories_Get
export def "workflow-run-action-request-histories-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  request_history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/requestHistories/{requestHistoryName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}, {name: requestHistoryName, var: request_history_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, request_history_name: $request_history_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the workflow run action scoped repetitions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/scopeRepetitions
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: WorkflowRunActionScopeRepetitions_List
export def "workflow-run-action-scope-repetitions-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/scopeRepetitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a workflow run action scoped repetition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/scopeRepetitions/{repetitionName}
# Returns: record<properties: record<repetitionIndexes: list<record>, inputs: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, iterationCount: int, outputs: record, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, trackedProperties: record, trackingId: string, code: string, correlation: record<actionTrackingId: string, clientKeywords: list, clientTrackingId: string>, endTime: string, error: any, startTime: string, status: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: WorkflowRunActionScopeRepetitions_Get
export def "workflow-run-action-scope-repetitions-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/scopeRepetitions/{repetitionName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: actionName, var: action_name}, {name: repetitionName, var: repetition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, action_name: $action_name, repetition_name: $repetition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels a workflow run.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/cancel
# operationId: WorkflowRuns_Cancel
export def "workflow-runs-cancel" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/cancel"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an operation for a run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/operations/{operationId}
# Returns: record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, correlationId: string, endTime: string, error: record, outputs: record, response: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, startTime: string, status: string, trigger: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, waitEndTime: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>
# operationId: WorkflowRunOperations_Get
export def "workflow-run-operations-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: runName, var: run_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, run_name: $run_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of workflow triggers.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers
# Returns: record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>
# operationId: WorkflowTriggers_List
export def "workflow-triggers-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a workflow trigger.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}
# Returns: record<name: string, properties: record<changedTime: string, createdTime: string, lastExecutionTime: string, nextExecutionTime: string, provisioningState: string, recurrence: record<endTime: string, frequency: string, interval: int, schedule: record, startTime: string, timeZone: string>, state: string, status: string, workflow: record<id: string, name: string, type: string>>, type: string, id: string>
# operationId: WorkflowTriggers_Get
export def "workflow-triggers-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of workflow trigger histories.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories
# Returns: record<nextLink: string, value: table<name: string, properties: record, type: string, id: string>>
# operationId: WorkflowTriggerHistories_List
export def "workflow-trigger-histories-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status, StartTime, and ClientTrackingId.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}, {name: "$filter", var: filter}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, api_version: $api_version, top: $top, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a workflow trigger history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories/{historyName}
# Returns: record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, endTime: string, error: record, fired: bool, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, run: record<id: string, name: string, type: string>, startTime: string, status: string, trackingId: string>, type: string, id: string>
# operationId: WorkflowTriggerHistories_Get
export def "workflow-trigger-histories-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories/{historyName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}, {name: historyName, var: history_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, history_name: $history_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resubmits a workflow run based on the trigger history.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories/{historyName}/resubmit
# operationId: WorkflowTriggerHistories_Resubmit
export def "workflow-trigger-histories-resubmit" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories/{historyName}/resubmit"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}, {name: historyName, var: history_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, history_name: $history_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the callback URL for a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/listCallbackUrl
# Returns: record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>
# operationId: WorkflowTriggers_ListCallbackUrl
export def "workflow-triggers-list-callback-url" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/listCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/reset
# operationId: WorkflowTriggers_Reset
export def "workflow-triggers-reset" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/reset"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/run
# Returns: record
# operationId: WorkflowTriggers_Run
export def "workflow-triggers-run" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/run"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: []
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the trigger schema as JSON.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/schemas/json
# Returns: record<content: string, title: string>
# operationId: WorkflowTriggers_GetSchemaJson
export def "workflow-triggers-get-schema-json" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/schemas/json"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the state of a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/setState
# operationId: WorkflowTriggers_SetState
export def "workflow-triggers-set-state" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  source: record # The workflow trigger. — shape: {properties?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/setState"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: triggerName, var: trigger_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, trigger_name: $trigger_name, api_version: $api_version, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validates the workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/validate
# operationId: Workflows_ValidateByResourceGroup
export def "workflows-validate-by-resource-group" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/validate"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, properties: $properties, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of workflow versions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: WorkflowVersions_List
export def "workflow-versions-list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, api_version: $api_version, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a workflow version.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions/{versionId}
# Returns: record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, integrationAccount: record<id: string, name: string, type: string>, parameters: record, sku: record<name: string, plan: record>, state: string, version: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: WorkflowVersions_Get
export def "workflow-versions-get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
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
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions/{versionId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: versionId, var: version_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, version_id: $version_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the callback url for a trigger of a workflow version.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions/{versionId}/triggers/{triggerName}/listCallbackUrl
# Returns: record<basePath: string, method: string, queries: record<api-version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string>
# operationId: WorkflowVersionTriggers_ListCallbackUrl
export def "workflow-version-triggers-list-callback-url" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  version_id: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions/{versionId}/triggers/{triggerName}/listCallbackUrl"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workflowName, var: workflow_name}, {name: versionId, var: version_id}, {name: triggerName, var: trigger_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyType, var: key_type}, {name: notAfter, var: not_after}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workflow_name: $workflow_name, version_id: $version_id, trigger_name: $trigger_name, api_version: $api_version, key_type: $key_type, not_after: $not_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration service environments by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationServiceEnvironments_ListByResourceGroup
export def "integration-service-environments-list-by-resource-group" [
  subscription_id: string
  resource_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}]
    query: [{name: api-version, var: api_version, required: true}, {name: "$top", var: top}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, api_version: $api_version, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an integration service environment.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_Delete
export def "integration-service-environments-delete" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an integration service environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# Returns: record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationServiceEnvironments_Get
export def "integration-service-environments-get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an integration service environment.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# Returns: record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationServiceEnvironments_Update
export def "integration-service-environments-update" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The integration service environment properties. — shape: {endpointsConfiguration?: record, integrationServiceEnvironmentId?: string, networkConfiguration?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration service environment sku. — shape: {capacity?: int, name?: "NotSpecified"|"Premium"|"Developer"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_version: $api_version, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates an integration service environment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# Returns: record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationServiceEnvironments_CreateOrUpdate
export def "integration-service-environments-create-or-update" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
  --properties: record # The integration service environment properties. — shape: {endpointsConfiguration?: record, integrationServiceEnvironmentId?: string, networkConfiguration?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration service environment sku. — shape: {capacity?: int, name?: "NotSpecified"|"Premium"|"Developer"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: location, var: location}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_version: $api_version, properties: $properties, sku: $sku, location: $location, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the integration service environment network health.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/health/network
# Returns: record
# operationId: IntegrationServiceEnvironmentNetworkHealth_Get
export def "integration-service-environment-network-health-get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/health/network"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the integration service environment managed Apis.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationServiceEnvironmentManagedApis_List
export def "integration-service-environment-managed-apis-list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the integration service environment managed Api.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# operationId: IntegrationServiceEnvironmentManagedApis_Delete
export def "integration-service-environment-managed-apis-delete" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}, {name: apiName, var: api_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [202, 204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_name: $api_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the integration service environment managed Api.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# Returns: record<properties: record<apiDefinitionUrl: string, apiDefinitions: record<modifiedSwaggerUrl: string, originalSwaggerUrl: string>, backendService: record<serviceUrl: string>, capabilities: list<string>, category: string, connectionParameters: record, generalInformation: record<description: string, displayName: string, iconUrl: string, releaseTag: string, termsOfUseUrl: string, tier: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, metadata: record<ApiType: string, brandColor: string, connectionType: string, deploymentParameters: record, hideKey: string, provisioningState: string, source: string, tags: record, wsdlImportMethod: string, wsdlService: record>, name: string, policies: record<content: string, contentLink: string>, provisioningState: string, runtimeUrls: list<string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationServiceEnvironmentManagedApis_Get
export def "integration-service-environment-managed-apis-get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}, {name: apiName, var: api_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_name: $api_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts the integration service environment managed Api.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# Returns: record<properties: record<apiDefinitionUrl: string, apiDefinitions: record<modifiedSwaggerUrl: string, originalSwaggerUrl: string>, backendService: record<serviceUrl: string>, capabilities: list<string>, category: string, connectionParameters: record, generalInformation: record<description: string, displayName: string, iconUrl: string, releaseTag: string, termsOfUseUrl: string, tier: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, metadata: record<ApiType: string, brandColor: string, connectionType: string, deploymentParameters: record, hideKey: string, provisioningState: string, source: string, tags: record, wsdlImportMethod: string, wsdlService: record>, name: string, policies: record<content: string, contentLink: string>, provisioningState: string, runtimeUrls: list<string>>, id: string, location: string, name: string, tags: record, type: string>
# operationId: IntegrationServiceEnvironmentManagedApis_Put
export def "integration-service-environment-managed-apis-put" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}, {name: apiName, var: api_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_name: $api_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the managed Api operations.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}/apiOperations
# Returns: record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>>
# operationId: IntegrationServiceEnvironmentManagedApiOperations_List
export def "integration-service-environment-managed-api-operations-list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}/apiOperations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}, {name: apiName, var: api_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_name: $api_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restarts an integration service environment.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/restart
# operationId: IntegrationServiceEnvironments_Restart
export def "integration-service-environments-restart" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/restart"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of integration service environment Skus.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/skus
# Returns: record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>
# operationId: IntegrationServiceEnvironmentSkus_List
export def "integration-service-environment-skus-list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/skus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroup, var: resource_group}, {name: integrationServiceEnvironmentName, var: integration_service_environment_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group: $resource_group, integration_service_environment_name: $integration_service_environment_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
