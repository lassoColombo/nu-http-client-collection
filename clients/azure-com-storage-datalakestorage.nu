# Auto-generated client for Azure Data Lake Storage v2019-10-31
# Source: https://api.apis.guru/v2/specs/azure.com/storage-DataLakeStorage/2019-10-31/swagger.json
# Auth: --token flag or $env.AZURE_DATA_LAKE_STORAGE_TOKEN

const CLIENT = {
  base_url: "https://{accountName}.dfs.core.windows.net"
  token_env_var: "AZURE_DATA_LAKE_STORAGE_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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

def base-url-completer [] { ["https://{accountName}.dfs.core.windows.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-completer [] { ["account"] }
def resource-completer-1 [] { ["filesystem"] }
def accept-completer [] { ["application/json" "application/octet-stream" "text/plain"] }
def action-completer [] { ["checkAccess" "getAccessControl" "getStatus"] }
def action-completer-1 [] { ["append" "flush" "setAccessControl" "setProperties"] }
def x-ms-lease-action-completer [] { ["acquire" "break" "change" "release" "renew"] }
def resource-completer-2 [] { ["directory" "file"] }
def mode-completer [] { ["legacy" "posix"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    filesystem-list: "record<filesystems: table<eTag: string, lastModified: string, name: string>>"
    path-list: "record<paths: table<contentLength: int, eTag: string, group: string, isDirectory: bool, lastModified: string, name: string, owner: string, permissions: string>>"
    filesystem-get-properties: "record"
    path-read: "binary"
    path-get-properties: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["filesystem-list" "filesystem-delete" "path-list" "filesystem-get-properties" "filesystem-set-properties" "filesystem-create" "path-delete" "path-read" "path-get-properties" "path-update" "path-lease" "path-create" "commands"] | sort) } | get name | first)
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

# List Filesystems
#
# GET /
# Returns: record<filesystems: table<eTag: string, lastModified: string, name: string>>
# operationId: Filesystem_List
export def "filesystem-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer # The value must be "account" for all account operations. (required)
  --prefix: string # Filters results to filesystems within the specified prefix.
  --continuation: string # The number of filesystems returned with each invocation is limited. If the number of filesystems to be returned exceeds this limit, a continuation token is returned in the response header x-ms-continuation. When a continuation token is returned in the response, it must be specified in a subsequent invocation of the list operation to continue listing the filesystems.
  --max-results: int # An optional value that specifies the maximum number of items to return. If omitted or greater than 5,000, the response will include up to 5,000 items. (format: int32)
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/"
    query: [{name: resource, var: resource, required: true, default: account}, {name: prefix, var: prefix}, {name: continuation, var: continuation}, {name: maxResults, var: max_results}, {name: timeout, var: timeout}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, prefix: $prefix, continuation: $continuation, max_results: $max_results, timeout: $timeout, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Filesystem
#
# DELETE /{filesystem}
# operationId: Filesystem_Delete
export def "filesystem-delete" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations. (required)
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  http-request {
    method: delete
    path: "/{filesystem}"
    path_params: [{name: filesystem, var: filesystem}]
    query: [{name: resource, var: resource, required: true, default: filesystem}, {name: timeout, var: timeout}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    filesystem: $filesystem, resource: $resource, timeout: $timeout, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Paths
#
# GET /{filesystem}
# Returns: record<paths: table<contentLength: int, eTag: string, group: string, isDirectory: bool, lastModified: string, name: string, owner: string, permissions: string>>
# operationId: Path_List
export def "path-list" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations. (required)
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --directory: string # Filters results to paths within the specified directory. An error occurs if the directory does not exist.
  --recursive: oneof<nothing, bool> # If "true", all paths are listed; otherwise, only paths at the root of the filesystem are listed. If "directory" is specified, the list will only include paths that share the same root. (required)
  --continuation: string # The number of paths returned with each invocation is limited. If the number of paths to be returned exceeds this limit, a continuation token is returned in the response header x-ms-continuation. When a continuation token is returned in the response, it must be specified in a subsequent invocation of the list operation to continue listing the paths.
  --max-results: int # An optional value that specifies the maximum number of items to return. If omitted or greater than 5,000, the response will include up to 5,000 items. (format: int32)
  --upn: oneof<nothing, bool> # Optional. Valid only when Hierarchical Namespace is enabled for the account. If "true", the user identity values returned in the owner and group fields of each list entry will be transformed from Azure Active Directory Object IDs to User Principal Names. If "false", the values will be returned as Azure Active Directory Object IDs. The default value is false. Note that group and application Object IDs are not translated because they do not have unique friendly names.
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/{filesystem}"
    path_params: [{name: filesystem, var: filesystem}]
    query: [{name: resource, var: resource, required: true, default: filesystem}, {name: timeout, var: timeout}, {name: directory, var: directory}, {name: recursive, var: recursive, required: true}, {name: continuation, var: continuation}, {name: maxResults, var: max_results}, {name: upn, var: upn}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filesystem: $filesystem, resource: $resource, timeout: $timeout, directory: $directory, recursive: $recursive, continuation: $continuation, max_results: $max_results, upn: $upn, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Filesystem Properties.
#
# HEAD /{filesystem}
# Returns: record
# operationId: Filesystem_GetProperties
export def "filesystem-get-properties" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations. (required)
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/{filesystem}"
    path_params: [{name: filesystem, var: filesystem}]
    query: [{name: resource, var: resource, required: true, default: filesystem}, {name: timeout, var: timeout}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filesystem: $filesystem, resource: $resource, timeout: $timeout, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Filesystem Properties
#
# PATCH /{filesystem}
# operationId: Filesystem_SetProperties
export def "filesystem-set-properties" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations. (required)
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-properties: string # Optional. User-defined properties to be stored with the filesystem, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set. If the filesystem exists, any properties not included in the list will be removed. All properties are removed if the header is omitted. To merge new and existing properties, first get all existing properties and the current E-Tag, then make a conditional request with the E-Tag and include values for all properties.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  http-request {
    method: patch
    path: "/{filesystem}"
    path_params: [{name: filesystem, var: filesystem}]
    query: [{name: resource, var: resource, required: true, default: filesystem}, {name: timeout, var: timeout}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: x-ms-properties, var: x_ms_properties}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filesystem: $filesystem, resource: $resource, timeout: $timeout, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, x_ms_properties: $x_ms_properties, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Filesystem
#
# PUT /{filesystem}
# operationId: Filesystem_Create
export def "filesystem-create" [
  filesystem: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string@resource-completer-1 # The value must be "filesystem" for all filesystem operations. (required)
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-properties: string # User-defined properties to be stored with the filesystem, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set.
]: nothing -> any {
  http-request {
    method: put
    path: "/{filesystem}"
    path_params: [{name: filesystem, var: filesystem}]
    query: [{name: resource, var: resource, required: true, default: filesystem}, {name: timeout, var: timeout}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: x-ms-properties, var: x_ms_properties}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    filesystem: $filesystem, resource: $resource, timeout: $timeout, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, x_ms_properties: $x_ms_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete File | Delete Directory
#
# DELETE /{filesystem}/{path}
# operationId: Path_Delete
export def "path-delete" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --recursive: oneof<nothing, bool> # Required and valid only when the resource is a directory. If "true", all paths beneath the directory will be deleted. If "false" and the directory is non-empty, an error occurs.
  --continuation: string # Optional. When deleting a directory, the number of paths that are deleted with each invocation is limited. If the number of paths to be deleted exceeds this limit, a continuation token is returned in this response header. When a continuation token is returned in the response, it must be specified in a subsequent invocation of the delete operation to continue deleting the directory.
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-lease-id: string # The lease ID must be specified if there is an active lease.
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  http-request {
    method: delete
    path: "/{filesystem}/{path}"
    path_params: [{name: filesystem, var: filesystem}, {name: path, var: path}]
    query: [{name: timeout, var: timeout}, {name: recursive, var: recursive}, {name: continuation, var: continuation}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: x-ms-lease-id, var: x_ms_lease_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filesystem: $filesystem, path: $path, timeout: $timeout, recursive: $recursive, continuation: $continuation, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, x_ms_lease_id: $x_ms_lease_id, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read File
#
# GET /{filesystem}/{path}
# Returns: binary
# operationId: Path_Read
export def "path-read" [
  filesystem: string
  path: string
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
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --range: string # The HTTP Range request header specifies one or more byte ranges of the resource to be retrieved.
  --x-ms-lease-id: string # Optional. If this header is specified, the operation will be performed only if both of the following conditions are met: i) the path's lease is currently active and ii) the lease ID specified in the request matches that of the path.
  --x-ms-range-get-content-md5: oneof<nothing, bool> # Optional. When this header is set to "true" and specified together with the Range header, the service returns the MD5 hash for the range, as long as the range is less than or equal to 4MB in size. If this header is specified without the Range header, the service returns status code 400 (Bad Request). If this header is set to true when the range exceeds 4 MB in size, the service returns status code 400 (Bad Request).
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  http-request {
    method: get
    path: "/{filesystem}/{path}"
    path_params: [{name: filesystem, var: filesystem}, {name: path, var: path}]
    query: [{name: timeout, var: timeout}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: Range, var: range}, {name: x-ms-lease-id, var: x_ms_lease_id}, {name: x-ms-range-get-content-md5, var: x_ms_range_get_content_md5}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json", "application/octet-stream", "text/plain"]
    ok: [200, 206]
    auth: bearer
  } {
    filesystem: $filesystem, path: $path, timeout: $timeout, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, range: $range, x_ms_lease_id: $x_ms_lease_id, x_ms_range_get_content_md5: $x_ms_range_get_content_md5, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Properties | Get Status | Get Access Control List | Check Access
#
# HEAD /{filesystem}/{path}
# Returns: record
# operationId: Path_GetProperties
export def "path-get-properties" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --action: string@action-completer # Optional. If the value is "getStatus" only the system defined properties for the path are returned. If the value is "getAccessControl" the access control list is returned in the response headers (Hierarchical Namespace must be enabled for the account), otherwise the properties are returned.
  --upn: oneof<nothing, bool> # Optional. Valid only when Hierarchical Namespace is enabled for the account. If "true", the user identity values returned in the x-ms-owner, x-ms-group, and x-ms-acl response headers will be transformed from Azure Active Directory Object IDs to User Principal Names. If "false", the values will be returned as Azure Active Directory Object IDs. The default value is false. Note that group and application Object IDs are not translated because they do not have unique friendly names.
  --fs-action: string # Required only for check access action. Valid only when Hierarchical Namespace is enabled for the account. File system operation read/write/execute in string form, matching regex pattern '[rwx-]{3}'
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-lease-id: string # Optional. If this header is specified, the operation will be performed only if both of the following conditions are met: i) the path's lease is currently active and ii) the lease ID specified in the request matches that of the path.
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/{filesystem}/{path}"
    path_params: [{name: filesystem, var: filesystem}, {name: path, var: path}]
    query: [{name: timeout, var: timeout}, {name: action, var: action}, {name: upn, var: upn}, {name: fsAction, var: fs_action}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: x-ms-lease-id, var: x_ms_lease_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filesystem: $filesystem, path: $path, timeout: $timeout, action: $action, upn: $upn, fs_action: $fs_action, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, x_ms_lease_id: $x_ms_lease_id, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Append Data | Flush Data | Set Properties | Set Access Control
#
# PATCH /{filesystem}/{path}
# operationId: Path_Update
export def "path-update" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --action: string@action-completer-1 # The action must be "append" to upload data to be appended to a file, "flush" to flush previously uploaded data to a file, "setProperties" to set the properties of a file or directory, or "setAccessControl" to set the owner, group, permissions, or access control list for a file or directory. Note that Hierarchical Namespace must be enabled for the account in order to use access control. Also note that the Access Control List (ACL) includes permissions for the owner, owning group, and others, so the x-ms-permissions and x-ms-acl request headers are mutually exclusive. (required)
  --position: int # This parameter allows the caller to upload data in parallel and control the order in which it is appended to the file. It is required when uploading data to be appended to the file and when flushing previously uploaded data to the file. The value must be the position where the data is to be appended. Uploaded data is not immediately flushed, or written, to the file. To flush, the previously uploaded data must be contiguous, the position parameter must be specified and equal to the length of the file after all data has been written, and there must not be a request entity body included with the request. (format: int64)
  --retain-uncommitted-data: oneof<nothing, bool> # Valid only for flush operations. If "true", uncommitted data is retained after the flush operation completes; otherwise, the uncommitted data is deleted after the flush operation. The default is false. Data at offsets less than the specified position are written to the file when flush succeeds, but this optional parameter allows data after the flush position to be retained for a future flush operation.
  --close: oneof<nothing, bool> # Azure Storage Events allow applications to receive notifications when files change. When Azure Storage Events are enabled, a file changed event is raised. This event has a property indicating whether this is the final change to distinguish the difference between an intermediate flush to a file stream and the final close of a file stream. The close query parameter is valid only when the action is "flush" and change notifications are enabled. If the value of close is "true" and the flush operation completes successfully, the service raises a file change notification with a property indicating that this is the final update (the file stream has been closed). If "false" a change notification is raised indicating the file has changed. The default is false. This query parameter is set to true by the Hadoop ABFS driver to indicate that the file stream has been closed."
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --content-length: int # Required for "Append Data" and "Flush Data". Must be 0 for "Flush Data". Must be the length of the request content in bytes for "Append Data". (format: int64)
  --content-md5: string # Optional. An MD5 hash of the request content. This header is valid on "Append" and "Flush" operations. This hash is used to verify the integrity of the request content during transport. When this header is specified, the storage service compares the hash of the content that has arrived with this header value. If the two hashes do not match, the operation will fail with error code 400 (Bad Request). Note that this MD5 hash is not stored with the file. This header is associated with the request content, and not with the stored content of the file itself.
  --x-ms-lease-id: string # The lease ID must be specified if there is an active lease.
  --x-ms-cache-control: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations.
  --x-ms-content-type: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Content-Type" response header for "Read File" operations.
  --x-ms-content-disposition: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations.
  --x-ms-content-encoding: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Content-Encoding" response header for "Read File" operations.
  --x-ms-content-language: string # Optional and only valid for flush and set properties operations. The service stores this value and includes it in the "Content-Language" response header for "Read File" operations.
  --x-ms-content-md5: string # Optional and only valid for "Flush & Set Properties" operations. The service stores this value and includes it in the "Content-Md5" response header for "Read & Get Properties" operations. If this property is not specified on the request, then the property will be cleared for the file. Subsequent calls to "Read & Get Properties" will not return this property unless it is explicitly set on that file again.
  --x-ms-properties: string # Optional. User-defined properties to be stored with the file or directory, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set. Valid only for the setProperties operation. If the file or directory exists, any properties not included in the list will be removed. All properties are removed if the header is omitted. To merge new and existing properties, first get all existing properties and the current E-Tag, then make a conditional request with the E-Tag and include values for all properties.
  --x-ms-owner: string # Optional and valid only for the setAccessControl operation. Sets the owner of the file or directory.
  --x-ms-group: string # Optional and valid only for the setAccessControl operation. Sets the owning group of the file or directory.
  --x-ms-permissions: string # Optional and only valid if Hierarchical Namespace is enabled for the account. Sets POSIX access permissions for the file owner, the file owning group, and others. Each class may be granted read, write, or execute permission. The sticky bit is also supported. Both symbolic (rwxrw-rw-) and 4-digit octal notation (e.g. 0766) are supported. Invalid in conjunction with x-ms-acl.
  --x-ms-acl: string # Optional and valid only for the setAccessControl operation. Sets POSIX access control rights on files and directories. The value is a comma-separated list of access control entries that fully replaces the existing access control list (ACL). Each access control entry (ACE) consists of a scope, a type, a user or group identifier, and permissions in the format "[scope:][type]:[id]:[permissions]". The scope must be "default" to indicate the ACE belongs to the default ACL for a directory; otherwise scope is implicit and the ACE belongs to the access ACL. There are four ACE types: "user" grants rights to the owner or a named user, "group" grants rights to the owning group or a named group, "mask" restricts rights granted to named users and the members of groups, and "other" grants rights to all users not found in any of the other entries. The user or group identifier is omitted for entries of type "mask" and "other". The user or group identifier is also omitted for the owner and owning group. The permission field is a 3-character sequence where the first character is 'r' to grant read access, the second character is 'w' to grant write access, and the third character is 'x' to grant execute permission. If access is not granted, the '-' character is used to denote that the permission is denied. For example, the following ACL grants read, write, and execute rights to the file owner and john.doe@contoso, the read right to the owning group, and nothing to everyone else: "user::rwx,user:john.doe@contoso:rwx,group::r--,other::---,mask=rwx". Invalid in conjunction with x-ms-permissions.
  --if-match: string # Optional for Flush Data and Set Properties, but invalid for Append Data. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional for Flush Data and Set Properties, but invalid for Append Data. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional for Flush Data and Set Properties, but invalid for Append Data. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional for Flush Data and Set Properties, but invalid for Append Data. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
  --body: any
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{filesystem}/{path}"
    path_params: [{name: filesystem, var: filesystem}, {name: path, var: path}]
    query: [{name: timeout, var: timeout}, {name: action, var: action, required: true}, {name: position, var: position}, {name: retainUncommittedData, var: retain_uncommitted_data}, {name: close, var: close}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: Content-Length, var: content_length}, {name: Content-MD5, var: content_md5}, {name: x-ms-lease-id, var: x_ms_lease_id}, {name: x-ms-cache-control, var: x_ms_cache_control}, {name: x-ms-content-type, var: x_ms_content_type}, {name: x-ms-content-disposition, var: x_ms_content_disposition}, {name: x-ms-content-encoding, var: x_ms_content_encoding}, {name: x-ms-content-language, var: x_ms_content_language}, {name: x-ms-content-md5, var: x_ms_content_md5}, {name: x-ms-properties, var: x_ms_properties}, {name: x-ms-owner, var: x_ms_owner}, {name: x-ms-group, var: x_ms_group}, {name: x-ms-permissions, var: x_ms_permissions}, {name: x-ms-acl, var: x_ms_acl}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    filesystem: $filesystem, path: $path, timeout: $timeout, action: $action, position: $position, retain_uncommitted_data: $retain_uncommitted_data, close: $close, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, content_length: $content_length, content_md5: $content_md5, x_ms_lease_id: $x_ms_lease_id, x_ms_cache_control: $x_ms_cache_control, x_ms_content_type: $x_ms_content_type, x_ms_content_disposition: $x_ms_content_disposition, x_ms_content_encoding: $x_ms_content_encoding, x_ms_content_language: $x_ms_content_language, x_ms_content_md5: $x_ms_content_md5, x_ms_properties: $x_ms_properties, x_ms_owner: $x_ms_owner, x_ms_group: $x_ms_group, x_ms_permissions: $x_ms_permissions, x_ms_acl: $x_ms_acl, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lease Path
#
# POST /{filesystem}/{path}
# operationId: Path_Lease
export def "path-lease" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --x-ms-lease-action: string@x-ms-lease-action-completer # There are five lease actions: "acquire", "break", "change", "renew", and "release". Use "acquire" and specify the "x-ms-proposed-lease-id" and "x-ms-lease-duration" to acquire a new lease. Use "break" to break an existing lease. When a lease is broken, the lease break period is allowed to elapse, during which time no lease operation except break and release can be performed on the file. When a lease is successfully broken, the response indicates the interval in seconds until a new lease can be acquired. Use "change" and specify the current lease ID in "x-ms-lease-id" and the new lease ID in "x-ms-proposed-lease-id" to change the lease ID of an active lease. Use "renew" and specify the "x-ms-lease-id" to renew an existing lease. Use "release" and specify the "x-ms-lease-id" to release a lease. (required)
  --x-ms-lease-duration: int # The lease duration is required to acquire a lease, and specifies the duration of the lease in seconds. The lease duration must be between 15 and 60 seconds or -1 for infinite lease. (format: int32)
  --x-ms-lease-break-period: int # The lease break period duration is optional to break a lease, and specifies the break period of the lease in seconds. The lease break duration must be between 0 and 60 seconds. (format: int32)
  --x-ms-lease-id: string # Required when "x-ms-lease-action" is "renew", "change" or "release". For the renew and release actions, this must match the current lease ID.
  --x-ms-proposed-lease-id: string # Required when "x-ms-lease-action" is "acquire" or "change". A lease will be acquired with this lease ID if the operation is successful.
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
]: nothing -> any {
  http-request {
    method: post
    path: "/{filesystem}/{path}"
    path_params: [{name: filesystem, var: filesystem}, {name: path, var: path}]
    query: [{name: timeout, var: timeout}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: x-ms-lease-action, var: x_ms_lease_action, required: true}, {name: x-ms-lease-duration, var: x_ms_lease_duration}, {name: x-ms-lease-break-period, var: x_ms_lease_break_period}, {name: x-ms-lease-id, var: x_ms_lease_id}, {name: x-ms-proposed-lease-id, var: x_ms_proposed_lease_id}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}]
    accept: ["application/json"]
    ok: [200, 201, 202]
    auth: bearer
  } {
    filesystem: $filesystem, path: $path, timeout: $timeout, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, x_ms_lease_action: $x_ms_lease_action, x_ms_lease_duration: $x_ms_lease_duration, x_ms_lease_break_period: $x_ms_lease_break_period, x_ms_lease_id: $x_ms_lease_id, x_ms_proposed_lease_id: $x_ms_proposed_lease_id, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create File | Create Directory | Rename File | Rename Directory
#
# PUT /{filesystem}/{path}
# operationId: Path_Create
export def "path-create" [
  filesystem: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails. (format: int32)
  --resource: string@resource-completer-2 # Required only for Create File and Create Directory. The value must be "file" or "directory".
  --continuation: string # Optional. When renaming a directory, the number of paths that are renamed with each invocation is limited. If the number of paths to be renamed exceeds this limit, a continuation token is returned in this response header. When a continuation token is returned in the response, it must be specified in a subsequent invocation of the rename operation to continue renaming the directory.
  --mode: string@mode-completer # Optional. Valid only when namespace is enabled. This parameter determines the behavior of the rename operation. The value must be "legacy" or "posix", and the default value will be "posix".
  --x-ms-client-request-id: string # A UUID recorded in the analytics logs for troubleshooting and correlation.
  --x-ms-date: string # Specifies the Coordinated Universal Time (UTC) for the request. This is required when using shared key authorization.
  --x-ms-version: string # Specifies the version of the REST protocol used for processing the request. This is required when using shared key authorization.
  --cache-control: string # Optional. The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations for "Read File" operations.
  --content-encoding: string # Optional. Specifies which content encodings have been applied to the file. This value is returned to the client when the "Read File" operation is performed.
  --content-language: string # Optional. Specifies the natural language used by the intended audience for the file.
  --content-disposition: string # Optional. The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations.
  --x-ms-cache-control: string # Optional. The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations.
  --x-ms-content-type: string # Optional. The service stores this value and includes it in the "Content-Type" response header for "Read File" operations.
  --x-ms-content-encoding: string # Optional. The service stores this value and includes it in the "Content-Encoding" response header for "Read File" operations.
  --x-ms-content-language: string # Optional. The service stores this value and includes it in the "Content-Language" response header for "Read File" operations.
  --x-ms-content-disposition: string # Optional. The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations.
  --x-ms-rename-source: string # An optional file or directory to be renamed. The value must have the following format: "/{filesystem}/{path}". If "x-ms-properties" is specified, the properties will overwrite the existing properties; otherwise, the existing properties will be preserved. This value must be a URL percent-encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set.
  --x-ms-lease-id: string # Optional. A lease ID for the path specified in the URI. The path to be overwritten must have an active lease and the lease ID must match.
  --x-ms-source-lease-id: string # Optional for rename operations. A lease ID for the source path. The source path must have an active lease and the lease ID must match.
  --x-ms-properties: string # Optional. User-defined properties to be stored with the file or directory, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set.
  --x-ms-permissions: string # Optional and only valid if Hierarchical Namespace is enabled for the account. Sets POSIX access permissions for the file owner, the file owning group, and others. Each class may be granted read, write, or execute permission. The sticky bit is also supported. Both symbolic (rwxrw-rw-) and 4-digit octal notation (e.g. 0766) are supported.
  --x-ms-umask: string # Optional and only valid if Hierarchical Namespace is enabled for the account. When creating a file or directory and the parent folder does not have a default ACL, the umask restricts the permissions of the file or directory to be created. The resulting permission is given by p & ^u, where p is the permission and u is the umask. For example, if p is 0777 and u is 0057, then the resulting permission is 0720. The default permission is 0777 for a directory and 0666 for a file. The default umask is 0027. The umask must be specified in 4-digit octal notation (e.g. 0766).
  --if-match: string # Optional. An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes.
  --if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes.
  --if-modified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time.
  --if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time.
  --x-ms-source-if-match: string # Optional. An ETag value. Specify this header to perform the rename operation only if the source's ETag matches the value specified. The ETag must be specified in quotes.
  --x-ms-source-if-none-match: string # Optional. An ETag value or the special wildcard ("*") value. Specify this header to perform the rename operation only if the source's ETag does not match the value specified. The ETag must be specified in quotes.
  --x-ms-source-if-modified-since: string # Optional. A date and time value. Specify this header to perform the rename operation only if the source has been modified since the specified date and time.
  --x-ms-source-if-unmodified-since: string # Optional. A date and time value. Specify this header to perform the rename operation only if the source has not been modified since the specified date and time.
]: nothing -> any {
  http-request {
    method: put
    path: "/{filesystem}/{path}"
    path_params: [{name: filesystem, var: filesystem}, {name: path, var: path}]
    query: [{name: timeout, var: timeout}, {name: resource, var: resource}, {name: continuation, var: continuation}, {name: mode, var: mode}]
    header: [{name: x-ms-client-request-id, var: x_ms_client_request_id}, {name: x-ms-date, var: x_ms_date}, {name: x-ms-version, var: x_ms_version}, {name: Cache-Control, var: cache_control}, {name: Content-Encoding, var: content_encoding}, {name: Content-Language, var: content_language}, {name: Content-Disposition, var: content_disposition}, {name: x-ms-cache-control, var: x_ms_cache_control}, {name: x-ms-content-type, var: x_ms_content_type}, {name: x-ms-content-encoding, var: x_ms_content_encoding}, {name: x-ms-content-language, var: x_ms_content_language}, {name: x-ms-content-disposition, var: x_ms_content_disposition}, {name: x-ms-rename-source, var: x_ms_rename_source}, {name: x-ms-lease-id, var: x_ms_lease_id}, {name: x-ms-source-lease-id, var: x_ms_source_lease_id}, {name: x-ms-properties, var: x_ms_properties}, {name: x-ms-permissions, var: x_ms_permissions}, {name: x-ms-umask, var: x_ms_umask}, {name: If-Match, var: if_match}, {name: If-None-Match, var: if_none_match}, {name: If-Modified-Since, var: if_modified_since}, {name: If-Unmodified-Since, var: if_unmodified_since}, {name: x-ms-source-if-match, var: x_ms_source_if_match}, {name: x-ms-source-if-none-match, var: x_ms_source_if_none_match}, {name: x-ms-source-if-modified-since, var: x_ms_source_if_modified_since}, {name: x-ms-source-if-unmodified-since, var: x_ms_source_if_unmodified_since}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    filesystem: $filesystem, path: $path, timeout: $timeout, resource: $resource, continuation: $continuation, mode: $mode, x_ms_client_request_id: $x_ms_client_request_id, x_ms_date: $x_ms_date, x_ms_version: $x_ms_version, cache_control: $cache_control, content_encoding: $content_encoding, content_language: $content_language, content_disposition: $content_disposition, x_ms_cache_control: $x_ms_cache_control, x_ms_content_type: $x_ms_content_type, x_ms_content_encoding: $x_ms_content_encoding, x_ms_content_language: $x_ms_content_language, x_ms_content_disposition: $x_ms_content_disposition, x_ms_rename_source: $x_ms_rename_source, x_ms_lease_id: $x_ms_lease_id, x_ms_source_lease_id: $x_ms_source_lease_id, x_ms_properties: $x_ms_properties, x_ms_permissions: $x_ms_permissions, x_ms_umask: $x_ms_umask, if_match: $if_match, if_none_match: $if_none_match, if_modified_since: $if_modified_since, if_unmodified_since: $if_unmodified_since, x_ms_source_if_match: $x_ms_source_if_match, x_ms_source_if_none_match: $x_ms_source_if_none_match, x_ms_source_if_modified_since: $x_ms_source_if_modified_since, x_ms_source_if_unmodified_since: $x_ms_source_if_unmodified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
