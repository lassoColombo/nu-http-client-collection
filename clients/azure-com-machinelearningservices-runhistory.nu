# Auto-generated client for Run History APIs v2019-09-30
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearningservices-runHistory/2019-09-30/swagger.json
# Auth: --token flag or $env.RUN_HISTORY_APIS_TOKEN

const CLIENT = {
  base_url: "https://azure.local"
  token_env_var: "RUN_HISTORY_APIS_TOKEN"
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def merge-strategy-type-completer [] { ["Default" "MergeToVector" "None"] }
def merge-strategy-options-completer [] { ["None" "ReportUnmergedMetricsValues"] }
def merge-strategy-settings-select-metrics-completer [] { ["SelectAll" "SelectByFirstValueSchema" "SelectByFirstValueSchemaMergeNumericValues"] }
def sortorder-completer [] { ["Asc" "Desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    experiments-get-by-id: "record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>"
    experiments-update: "record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>"
    experiments-delete-tags: "record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>"
    experiments-get: "record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>"
    experiments-create: "record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>"
    events-batch-post: "record<errors: table<key: record, value: record>>"
    runs-batch-add-or-modify: "record<errors: record, runs: record>"
    run-metrics-get: "record<cells: list<record>, createdUtc: string, dataContainerId: string, dataLocation: string, description: string, label: string, metricId: string, metricType: string, name: string, numCells: int, runId: string, schema: record<numProperties: int, properties: list<record>>>"
    run-metrics-get-by-query: "record<continuationToken: string, nextLink: string, value: table<cells: list, createdUtc: string, dataContainerId: string, dataLocation: string, description: string, label: string, metricId: string, metricType: string, name: string, numCells: int, runId: string, schema: record>>"
    runs-get: "record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>>"
    runs-patch: "record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>>"
    run-artifacts-list-in-container: "record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>>"
    run-artifacts-get-sas-uri: "string"
    run-artifacts-batch-create-empty-artifacts: "record<artifactContentInformation: record, artifacts: record, errors: record>"
    run-artifacts-get-content-information: "record<container: string, contentUri: string, origin: string, path: string>"
    run-artifacts-get-by-id: "record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string>"
    run-artifacts-list-in-path: "record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>>"
    run-artifacts-list-sas-by-prefix: "record<continuationToken: string, nextLink: string, value: table<container: string, contentUri: string, origin: string, path: string>>"
    runs-get-child: "record<continuationToken: string, nextLink: string, value: table<cancelUri: string, createdBy: record, createdFrom: record, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: list>>"
    runs-get-details: "record<endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, logFiles: record, parentRunId: string, properties: record, revision: int, runDefinition: record, runId: string, startTimeUtc: string, status: string, tags: record, target: string, warnings: table<message: string, source: string>>"
    runs-delete-tags: "record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>>"
    runs-get-by-query: "record<continuationToken: string, nextLink: string, value: table<cancelUri: string, createdBy: record, createdFrom: record, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: list>>"
    experiments-get-by-query: "record<continuationToken: string, nextLink: string, value: table<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["experiments-get-by-id" "experiments-update" "experiments-delete-tags" "experiments-get" "experiments-create" "events-batch-post" "runs-batch-add-or-modify" "run-metrics-get" "run-metrics-get-by-query" "runs-get" "runs-patch" "run-artifacts-list-in-container" "run-artifacts-get-sas-uri" "run-artifacts-batch-create-empty-artifacts" "run-artifacts-get-content-information" "run-artifacts-get-by-id" "run-artifacts-list-in-path" "run-artifacts-list-sas-by-prefix" "run-metrics-batch-post" "runs-get-child" "runs-get-details" "events-post" "run-metrics-post" "runs-delete-tags" "runs-get-by-query" "experiments-get-by-query" "commands"] | sort) } | get name | first)
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

# Get details of an Experiment.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}
# Returns: record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>
# operationId: Experiments_GetById
export def "experiments-get-by-id" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_id: string
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
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentId, var: experiment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_id: $experiment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update details of an Experiment.
#
# PATCH /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}
# Returns: record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>
# operationId: Experiments_Update
export def "experiments-update" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archive: oneof<nothing, bool>
  --description: string
  --tags: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentId, var: experiment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: archive, var: archive}, {name: description, var: description}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_id: $experiment_id, archive: $archive, description: $description, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete list of Tags in an Experiment.
#
# DELETE /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}/tags
# Returns: record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>
# operationId: Experiments_DeleteTags
export def "experiments-delete-tags" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experimentids/{experimentId}/tags"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentId, var: experiment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_id: $experiment_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of an Experiment.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}
# Returns: record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>
# operationId: Experiments_Get
export def "experiments-get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
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
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Experiment.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}
# Returns: record<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>
# operationId: Experiments_Create
export def "experiments-create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
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
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Batch post event data.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/batch/events
# Returns: record<errors: table<key: record, value: record>>
# operationId: Events_BatchPost
export def "events-batch-post" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: list # item shape: {data?: record, name?: string, timestamp?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/batch/events"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: events, var: events}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, events: $events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or Modify a batch of Runs.
#
# PATCH /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/batch/runs
# Returns: record<errors: record, runs: record>
# operationId: Runs_BatchAddOrModify
export def "runs-batch-add-or-modify" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --runs: list # item shape: {cancelUri?: string, createdFrom?: record, dataContainerId?: string, description?: string, diagnosticsUri?: string, endTimeUtc?: string, heartbeatEnabled?: bool, hidden?: bool, name?: string, options?: record, parentRunId?: string, properties?: record, runDefinition?: record, runId?: string, runType?: string, scriptName?: string, startTimeUtc?: string, status?: string, tags?: record, target?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/batch/runs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: runs, var: runs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, runs: $runs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Metric details.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/metrics/{metricId}
# Returns: record<cells: list<record>, createdUtc: string, dataContainerId: string, dataLocation: string, description: string, label: string, metricId: string, metricType: string, name: string, numCells: int, runId: string, schema: record<numProperties: int, properties: list<record>>>
# operationId: RunMetrics_Get
export def "run-metrics-get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  metric_id: string
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
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/metrics/{metricId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: metricId, var: metric_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, metric_id: $metric_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Run Metrics for the specific Experiment.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/metrics:query
# Returns: record<continuationToken: string, nextLink: string, value: table<cells: list, createdUtc: string, dataContainerId: string, dataLocation: string, description: string, label: string, metricId: string, metricType: string, name: string, numCells: int, runId: string, schema: record>>
# operationId: RunMetrics_GetByQuery
export def "run-metrics-get-by-query" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --merge-strategy-type: string@merge-strategy-type-completer # The type of merge strategy. Currently supported strategies are: None - all logged values are returned as individual metrics. MergeToVector - merges multiple values into a vector of values. Default - the system determines the behavior.
  --merge-strategy-options: string@merge-strategy-options-completer # Controls behavior of the merge strategy in certain cases; e.g. when a metric is not merged.
  --merge-strategy-settings-version: string # The strategy settings version.
  --merge-strategy-settings-select-metrics: string@merge-strategy-settings-select-metrics-completer # Defines how to select metrics when merging them together.
  --continuation-token: string # The continuation token to use for getting the next set of resources.
  --filter: string # Allows for filtering the collection of resources. The expression specified is evaluated for each resource in the collection, and only items where the expression evaluates to true are included in the response. See https://docs.microsoft.com/en-us/azure/search/query-odata-filter-orderby-syntax for details on the expression syntax.
  --order-by: string # The comma separated list of resource properties to use for sorting the requested resources. Optionally, can be followed by either 'asc' or 'desc' (e.g. Color, Size desc)
  --top: int # The maximum number of items in the resource collection to be included in the result. If not specified, all items are returned. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/metrics:query"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}]
    query: [{name: MergeStrategyType, var: merge_strategy_type}, {name: MergeStrategyOptions, var: merge_strategy_options}, {name: "MergeStrategySettings.Version", var: merge_strategy_settings_version}, {name: "MergeStrategySettings.SelectMetrics", var: merge_strategy_settings_select_metrics}]
    body: {content_type: "application/json", kind: json, fields: [{name: continuationToken, var: continuation_token}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: top, var: top}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, merge_strategy_type: $merge_strategy_type, merge_strategy_options: $merge_strategy_options, merge_strategy_settings_version: $merge_strategy_settings_version, merge_strategy_settings_select_metrics: $merge_strategy_settings_select_metrics, continuation_token: $continuation_token, filter: $filter, order_by: $order_by, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Run details.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}
# Returns: record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>>
# operationId: Runs_Get
export def "runs-get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
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
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or Modify a Run.
#
# PATCH /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}
# Returns: record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>>
# operationId: Runs_Patch
export def "runs-patch" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cancel-uri: string
  --created-from: record # shape: {location?: string, locationType?: "ArtifactId", type?: "Notebook"}
  --data-container-id: string
  --description: string
  --diagnostics-uri: string
  --end-time-utc: string # The end time of the run in UTC. (format: date-time)
  --heartbeat-enabled: oneof<nothing, bool>
  --hidden: oneof<nothing, bool>
  --name: string
  --options: record # shape: {generateDataContainerIdIfNotSpecified?: bool}
  --parent-run-id: string # The parent of the run if the run is hierarchical; otherwise, Null.
  --properties: record
  --run-definition: record
  --body-run-id: string # The identifier for the run. Run IDs must be less than 256 characters and contain only alphanumeric characters with dashes and underscores. (spec name: runId)
  --run-type: string
  --script-name: string
  --start-time-utc: string # The start time of the run in UTC. (format: date-time)
  --status: string # The status of the run. The Status string value maps to the RunStatus Enum.
  --tags: record
  --target: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cancelUri, var: cancel_uri}, {name: createdFrom, var: created_from}, {name: dataContainerId, var: data_container_id}, {name: description, var: description}, {name: diagnosticsUri, var: diagnostics_uri}, {name: endTimeUtc, var: end_time_utc}, {name: heartbeatEnabled, var: heartbeat_enabled}, {name: hidden, var: hidden}, {name: name, var: name}, {name: options, var: options}, {name: parentRunId, var: parent_run_id}, {name: properties, var: properties}, {name: runDefinition, var: run_definition}, {name: runId, var: body_run_id}, {name: runType, var: run_type}, {name: scriptName, var: script_name}, {name: startTimeUtc, var: start_time_utc}, {name: status, var: status}, {name: tags, var: tags}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, cancel_uri: $cancel_uri, created_from: $created_from, data_container_id: $data_container_id, description: $description, diagnostics_uri: $diagnostics_uri, end_time_utc: $end_time_utc, heartbeat_enabled: $heartbeat_enabled, hidden: $hidden, name: $name, options: $options, parent_run_id: $parent_run_id, properties: $properties, run_definition: $run_definition, body_run_id: $body_run_id, run_type: $run_type, script_name: $script_name, start_time_utc: $start_time_utc, status: $status, tags: $tags, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Artifacts in a container.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts
# Returns: record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>>
# operationId: RunArtifacts_ListInContainer
export def "run-artifacts-list-in-container" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --continuation-token: string # The Continuation Token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    query: [{name: continuationToken, var: continuation_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, continuation_token: $continuation_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get URI of an Artifact.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/artifacturi
# Returns: string
# operationId: RunArtifacts_GetSasUri
export def "run-artifacts-get-sas-uri" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> any {
  http-request {
    method: get
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/artifacturi"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    query: [{name: path, var: path}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a batch of empty Artifacts.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/batch/metadata
# Returns: record<artifactContentInformation: record, artifacts: record, errors: record>
# operationId: RunArtifacts_BatchCreateEmptyArtifacts
export def "run-artifacts-batch-create-empty-artifacts" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  paths: list # List of Artifact Paths. — item shape: {path: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/batch/metadata"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: paths, var: paths}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, paths: $paths
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Artifact content information.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/contentinfo
# Returns: record<container: string, contentUri: string, origin: string, path: string>
# operationId: RunArtifacts_GetContentInformation
export def "run-artifacts-get-content-information" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/contentinfo"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    query: [{name: path, var: path}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Artifact by Id.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/metadata
# Returns: record<artifactId: string, container: string, createdTime: string, dataPath: record<dataStoreName: string, relativePath: string, sqlDataPath: record<sqlQuery: string, sqlStoredProcedureName: string, sqlStoredProcedureParams: list, sqlTableName: string>>, etag: string, origin: string, path: string>
# operationId: RunArtifacts_GetById
export def "run-artifacts-get-by-id" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/metadata"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    query: [{name: path, var: path}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Artifacts in the provided path.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/path
# Returns: record<continuationToken: string, nextLink: string, value: table<artifactId: string, container: string, createdTime: string, dataPath: record, etag: string, origin: string, path: string>>
# operationId: RunArtifacts_ListInPath
export def "run-artifacts-list-in-path" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuation-token: string # The Continuation Token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/path"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    query: [{name: path, var: path}, {name: continuationToken, var: continuation_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, path: $path, continuation_token: $continuation_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get SAS of an Artifact.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/prefix/contentinfo
# Returns: record<continuationToken: string, nextLink: string, value: table<container: string, contentUri: string, origin: string, path: string>>
# operationId: RunArtifacts_ListSasByPrefix
export def "run-artifacts-list-sas-by-prefix" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The Artifact Path.
  --continuation-token: string # The Continuation Token.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/artifacts/prefix/contentinfo"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    query: [{name: path, var: path}, {name: continuationToken, var: continuation_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, path: $path, continuation_token: $continuation_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post Metrics to a Run.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/batch/metrics
# operationId: RunMetrics_BatchPost
export def "run-metrics-batch-post" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --values: list # item shape: {cells?: list, createdUtc?: string, dataContainerId?: string, dataLocation?: string, description?: string, label?: string, metricId?: string, metricType?: string, name?: string, numCells?: int, schema?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/batch/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of all child runs.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/children
# Returns: record<continuationToken: string, nextLink: string, value: table<cancelUri: string, createdBy: record, createdFrom: record, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: list>>
# operationId: Runs_GetChild
export def "runs-get-child" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Allows for filtering the collection of resources. The expression specified is evaluated for each resource in the collection, and only items where the expression evaluates to true are included in the response.
  --continuationtoken: string # The continuation token to use for getting the next set of resources.
  --orderby: list<string> # The list of resource properties to use for sorting the requested resources.
  --sortorder: string@sortorder-completer # The sort order of the returned resources. Not used, specify asc or desc after each property name in the OrderBy parameter.
  --top: int # The maximum number of items in the resource collection to be included in the result. If not specified, all items are returned. (format: int32)
  --count: oneof<nothing, bool> # Whether to include a count of the matching resources along with the resources returned in the response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/children"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    query: [{name: "$filter", var: filter}, {name: "$continuationtoken", var: continuationtoken}, {name: "$orderby", var: orderby, style: multi}, {name: "$sortorder", var: sortorder}, {name: "$top", var: top}, {name: "$count", var: count}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, filter: $filter, continuationtoken: $continuationtoken, orderby: $orderby, sortorder: $sortorder, top: $top, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Run Details.
#
# GET /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/details
# Returns: record<endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, logFiles: record, parentRunId: string, properties: record, revision: int, runDefinition: record, runId: string, startTimeUtc: string, status: string, tags: record, target: string, warnings: table<message: string, source: string>>
# operationId: Runs_GetDetails
export def "runs-get-details" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
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
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/details"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post event data.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/events
# operationId: Events_Post
export def "events-post" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --name: string
  --timestamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: post
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/events"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: name, var: name}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, data: $data, name: $name, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post Metric to a Run.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/metrics
# operationId: RunMetrics_Post
export def "run-metrics-post" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cells: list
  --created-utc: string # format: date-time
  --data-container-id: string
  --data-location: string
  --description: string
  --label: string
  --metric-id: string # format: uuid
  --metric-type: string
  --name: string
  --num-cells: int # format: int32
  --schema: record # shape: {numProperties?: int, properties?: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: cells, var: cells}, {name: createdUtc, var: created_utc}, {name: dataContainerId, var: data_container_id}, {name: dataLocation, var: data_location}, {name: description, var: description}, {name: label, var: label}, {name: metricId, var: metric_id}, {name: metricType, var: metric_type}, {name: name, var: name}, {name: numCells, var: num_cells}, {name: schema, var: schema}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, cells: $cells, created_utc: $created_utc, data_container_id: $data_container_id, data_location: $data_location, description: $description, label: $label, metric_id: $metric_id, metric_type: $metric_type, name: $name, num_cells: $num_cells, schema: $schema
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete list of Tags in a Run.
#
# DELETE /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/tags
# Returns: record<cancelUri: string, createdBy: record<userName: string, userObjectId: string, userTenantId: string>, createdFrom: record<location: string, locationType: string, type: string>, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record<correlation: record, environment: string, error: record<code: string, details: list, innerError: record, message: string, target: string>, location: string, time: string>, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record<generateDataContainerIdIfNotSpecified: bool>, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: table<message: string, source: string>>
# operationId: Runs_DeleteTags
export def "runs-delete-tags" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  run_id: string
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
    method: delete
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs/{runId}/tags"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}, {name: runId, var: run_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, run_id: $run_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Runs for a specific Experiment.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs:query
# Returns: record<continuationToken: string, nextLink: string, value: table<cancelUri: string, createdBy: record, createdFrom: record, createdUtc: string, dataContainerId: string, description: string, diagnosticsUri: string, endTimeUtc: string, error: record, experimentId: string, heartbeatEnabled: bool, hidden: bool, name: string, options: record, parentRunId: string, properties: record, revision: int, rootRunId: string, runDefinition: record, runId: string, runNumber: int, runType: string, scriptName: string, startTimeUtc: string, status: string, tags: record, target: string, token: string, tokenExpiryTimeUtc: string, userId: string, warnings: list>>
# operationId: Runs_GetByQuery
export def "runs-get-by-query" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --continuation-token: string # The continuation token to use for getting the next set of resources.
  --filter: string # Allows for filtering the collection of resources. The expression specified is evaluated for each resource in the collection, and only items where the expression evaluates to true are included in the response. See https://docs.microsoft.com/en-us/azure/search/query-odata-filter-orderby-syntax for details on the expression syntax.
  --order-by: string # The comma separated list of resource properties to use for sorting the requested resources. Optionally, can be followed by either 'asc' or 'desc' (e.g. Color, Size desc)
  --top: int # The maximum number of items in the resource collection to be included in the result. If not specified, all items are returned. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments/{experimentName}/runs:query"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}, {name: experimentName, var: experiment_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: continuationToken, var: continuation_token}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: top, var: top}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, experiment_name: $experiment_name, continuation_token: $continuation_token, filter: $filter, order_by: $order_by, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Experiments in a specific workspace.
#
# POST /history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments:query
# Returns: record<continuationToken: string, nextLink: string, value: table<archivedTime: string, createdUtc: string, description: string, experimentId: string, latestCreatedRunCreatedUtc: string, latestCreatedRunId: string, name: string, tags: record>>
# operationId: Experiments_GetByQuery
export def "experiments-get-by-query" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --continuation-token: string # The continuation token to use for getting the next set of resources.
  --filter: string # Allows for filtering the collection of resources. The expression specified is evaluated for each resource in the collection, and only items where the expression evaluates to true are included in the response. See https://docs.microsoft.com/en-us/azure/search/query-odata-filter-orderby-syntax for details on the expression syntax.
  --order-by: string # The comma separated list of resource properties to use for sorting the requested resources. Optionally, can be followed by either 'asc' or 'desc' (e.g. Color, Size desc)
  --top: int # The maximum number of items in the resource collection to be included in the result. If not specified, all items are returned. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/history/v1.0/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearningServices/workspaces/{workspaceName}/experiments:query"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: workspaceName, var: workspace_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: continuationToken, var: continuation_token}, {name: filter, var: filter}, {name: orderBy, var: order_by}, {name: top, var: top}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, workspace_name: $workspace_name, continuation_token: $continuation_token, filter: $filter, order_by: $order_by, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
