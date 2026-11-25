# Auto-generated client for Azure Container Registry v2019-08-15-preview
# Source: https://api.apis.guru/v2/specs/azure.com/containerregistry/2019-08-15-preview/swagger.json
# Auth: --token flag or $env.AZURE_CONTAINER_REGISTRY_TOKEN
# Auth (registry_auth): --token-registryauth flag or $env.AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN
# Auth (registry_oauth2): --token-registryoauth2 flag or $env.AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN

const CLIENT = {
  base_url: "{url}"
  token_env_var: "AZURE_CONTAINER_REGISTRY_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["{url}"] }
def auth-scheme-completer [] { ["basic" "bearer" "none" "basic-credentials"] }

# Completers for enum parameters
def grant-type-completer [] { ["access_token" "access_token_refresh_token" "refresh_token"] }
def grant-type-completer-1 [] { ["refresh_token"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-registryauth" "token-registryoauth2"]
  let return_types = {
    repository-get-list: "record<repositories: list<string>>"
    repository-delete: "record<manifestsDeleted: list<string>, tagsDeleted: list<string>>"
    repository-get-attributes: "record<changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, createdTime: string, imageName: string, lastUpdateTime: string, manifestCount: int, registry: string, tagCount: int>"
    manifests-get-list: "record<imageName: string, manifests: table<architecture: string, changeableAttributes: record, configMediaType: string, createdTime: string, digest: string, imageSize: int, lastUpdateTime: string, mediaType: string, os: string, tags: list>, registry: string>"
    manifests-get-attributes: "record<imageName: string, manifest: record<architecture: string, changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, configMediaType: string, createdTime: string, digest: string, imageSize: int, lastUpdateTime: string, mediaType: string, os: string, tags: list<string>>, registry: string>"
    tag-get-list: "record<imageName: string, registry: string, tags: table<changeableAttributes: record, createdTime: string, digest: string, lastUpdateTime: string, name: string, signed: bool>>"
    tag-get-attributes: "record<imageName: string, registry: string, tag: record<changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, createdTime: string, digest: string, lastUpdateTime: string, name: string, signed: bool>>"
    refresh-tokens-get-from-exchange: "record<refresh_token: string>"
    access-tokens-get-from-login: "record<access_token: string>"
    access-tokens-get: "record<access_token: string>"
    blob-delete: "binary"
    blob-get: "binary"
    blob-check: "record"
    manifests-get: "record<annotations: record<\"org.opencontainers.image.authors\": string, \"org.opencontainers.image.created\": string, \"org.opencontainers.image.description\": string, \"org.opencontainers.image.documentation\": string, \"org.opencontainers.image.licenses\": string, \"org.opencontainers.image.ref.name\": string, \"org.opencontainers.image.revision\": string, \"org.opencontainers.image.source\": string, \"org.opencontainers.image.title\": string, \"org.opencontainers.image.url\": string, \"org.opencontainers.image.vendor\": string, \"org.opencontainers.image.version\": string>, architecture: string, config: record<annotations: record<\"org.opencontainers.image.authors\": string, \"org.opencontainers.image.created\": string, \"org.opencontainers.image.description\": string, \"org.opencontainers.image.documentation\": string, \"org.opencontainers.image.licenses\": string, \"org.opencontainers.image.ref.name\": string, \"org.opencontainers.image.revision\": string, \"org.opencontainers.image.source\": string, \"org.opencontainers.image.title\": string, \"org.opencontainers.image.url\": string, \"org.opencontainers.image.vendor\": string, \"org.opencontainers.image.version\": string>, digest: string, mediaType: string, size: int, urls: list<string>>, fsLayers: table<blobSum: string>, history: table<v1Compatibility: string>, layers: table<annotations: record, digest: string, mediaType: string, size: int, urls: list>, manifests: table<digest: string, mediaType: string, platform: record, size: int>, mediaType: string, name: string, signatures: table<header: record, protected: string, signature: string>, tag: string, schemaVersion: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["repository-get-list" "repository-delete" "repository-get-attributes" "repository-update-attributes" "manifests-get-list" "manifests-get-attributes" "manifests-update-attributes" "tag-get-list" "tag-delete" "tag-get-attributes" "tag-update-attributes" "refresh-tokens-get-from-exchange" "access-tokens-get-from-login" "access-tokens-get" "v2-support-check" "blob-mount" "blob-delete" "blob-get" "blob-check" "manifests-delete" "manifests-get" "manifests-create" "blob-cancel-upload" "blob-get-status" "blob-upload" "blob-end-upload" "commands"] | sort) } | get name | first)
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

# List repositories
#
# GET /acr/v1/_catalog
# Returns: record<repositories: list<string>>
# operationId: Repository_GetList
export def "repository-get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last: string # Query parameter for the last item in previous query. Result set will include values lexically after last.
  --n: int # query parameter for max number of items
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/acr/v1/_catalog"
    query: [{name: last, var: last}, {name: n, var: n}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    last: $last, n: $n
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the repository identified by `name`
#
# DELETE /acr/v1/{name}
# Returns: record<manifestsDeleted: list<string>, tagsDeleted: list<string>>
# operationId: Repository_Delete
export def "repository-delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/acr/v1/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [202]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get repository attributes
#
# GET /acr/v1/{name}
# Returns: record<changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, createdTime: string, imageName: string, lastUpdateTime: string, manifestCount: int, registry: string, tagCount: int>
# operationId: Repository_GetAttributes
export def "repository-get-attributes" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/acr/v1/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the attribute identified by `name` where `reference` is the name of the repository.
#
# PATCH /acr/v1/{name}
# operationId: Repository_UpdateAttributes
export def "repository-update-attributes" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-enabled: oneof<nothing, bool> # Delete enabled
  --list-enabled: oneof<nothing, bool> # List enabled
  --read-enabled: oneof<nothing, bool> # Read enabled
  --write-enabled: oneof<nothing, bool> # Write enabled
]: any -> any {
  $in | http-request {
    method: patch
    path: "/acr/v1/{name}"
    path_params: [{name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: deleteEnabled, var: delete_enabled}, {name: listEnabled, var: list_enabled}, {name: readEnabled, var: read_enabled}, {name: writeEnabled, var: write_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, delete_enabled: $delete_enabled, list_enabled: $list_enabled, read_enabled: $read_enabled, write_enabled: $write_enabled
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List manifests of a repository
#
# GET /acr/v1/{name}/_manifests
# Returns: record<imageName: string, manifests: table<architecture: string, changeableAttributes: record, configMediaType: string, createdTime: string, digest: string, imageSize: int, lastUpdateTime: string, mediaType: string, os: string, tags: list>, registry: string>
# operationId: Manifests_GetList
export def "manifests-get-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last: string # Query parameter for the last item in previous query. Result set will include values lexically after last.
  --n: int # query parameter for max number of items
  --orderby: string # orderby query parameter
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/acr/v1/{name}/_manifests"
    path_params: [{name: name, var: name}]
    query: [{name: last, var: last}, {name: n, var: n}, {name: orderby, var: orderby}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, last: $last, n: $n, orderby: $orderby
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get manifest attributes
#
# GET /acr/v1/{name}/_manifests/{reference}
# Returns: record<imageName: string, manifest: record<architecture: string, changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, configMediaType: string, createdTime: string, digest: string, imageSize: int, lastUpdateTime: string, mediaType: string, os: string, tags: list<string>>, registry: string>
# operationId: Manifests_GetAttributes
export def "manifests-get-attributes" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/acr/v1/{name}/_manifests/{reference}"
    path_params: [{name: name, var: name}, {name: reference, var: reference}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, reference: $reference
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update attributes of a manifest
#
# PATCH /acr/v1/{name}/_manifests/{reference}
# operationId: Manifests_UpdateAttributes
export def "manifests-update-attributes" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-enabled: oneof<nothing, bool> # Delete enabled
  --list-enabled: oneof<nothing, bool> # List enabled
  --read-enabled: oneof<nothing, bool> # Read enabled
  --write-enabled: oneof<nothing, bool> # Write enabled
]: any -> any {
  $in | http-request {
    method: patch
    path: "/acr/v1/{name}/_manifests/{reference}"
    path_params: [{name: name, var: name}, {name: reference, var: reference}]
    body: {content_type: "application/json", kind: json, fields: [{name: deleteEnabled, var: delete_enabled}, {name: listEnabled, var: list_enabled}, {name: readEnabled, var: read_enabled}, {name: writeEnabled, var: write_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, reference: $reference, delete_enabled: $delete_enabled, list_enabled: $list_enabled, read_enabled: $read_enabled, write_enabled: $write_enabled
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tags of a repository
#
# GET /acr/v1/{name}/_tags
# Returns: record<imageName: string, registry: string, tags: table<changeableAttributes: record, createdTime: string, digest: string, lastUpdateTime: string, name: string, signed: bool>>
# operationId: Tag_GetList
export def "tag-get-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last: string # Query parameter for the last item in previous query. Result set will include values lexically after last.
  --n: int # query parameter for max number of items
  --orderby: string # orderby query parameter
  --digest: string # filter by digest
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/acr/v1/{name}/_tags"
    path_params: [{name: name, var: name}]
    query: [{name: last, var: last}, {name: n, var: n}, {name: orderby, var: orderby}, {name: digest, var: digest}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, last: $last, n: $n, orderby: $orderby, digest: $digest
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete tag
#
# DELETE /acr/v1/{name}/_tags/{reference}
# operationId: Tag_Delete
export def "tag-delete" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/acr/v1/{name}/_tags/{reference}"
    path_params: [{name: name, var: name}, {name: reference, var: reference}]
    accept: ["application/json"]
    ok: [202]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, reference: $reference
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tag attributes by tag
#
# GET /acr/v1/{name}/_tags/{reference}
# Returns: record<imageName: string, registry: string, tag: record<changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, createdTime: string, digest: string, lastUpdateTime: string, name: string, signed: bool>>
# operationId: Tag_GetAttributes
export def "tag-get-attributes" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/acr/v1/{name}/_tags/{reference}"
    path_params: [{name: name, var: name}, {name: reference, var: reference}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, reference: $reference
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update tag attributes
#
# PATCH /acr/v1/{name}/_tags/{reference}
# operationId: Tag_UpdateAttributes
export def "tag-update-attributes" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-enabled: oneof<nothing, bool> # Delete enabled
  --list-enabled: oneof<nothing, bool> # List enabled
  --read-enabled: oneof<nothing, bool> # Read enabled
  --write-enabled: oneof<nothing, bool> # Write enabled
]: any -> any {
  $in | http-request {
    method: patch
    path: "/acr/v1/{name}/_tags/{reference}"
    path_params: [{name: name, var: name}, {name: reference, var: reference}]
    body: {content_type: "application/json", kind: json, fields: [{name: deleteEnabled, var: delete_enabled}, {name: listEnabled, var: list_enabled}, {name: readEnabled, var: read_enabled}, {name: writeEnabled, var: write_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, reference: $reference, delete_enabled: $delete_enabled, list_enabled: $list_enabled, read_enabled: $read_enabled, write_enabled: $write_enabled
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange AAD tokens for an ACR refresh Token
#
# POST /oauth2/exchange
# Returns: record<refresh_token: string>
# operationId: RefreshTokens_GetFromExchange
export def "refresh-tokens-get-from-exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string@grant-type-completer # Can take a value of access_token_refresh_token, or access_token, or refresh_token
  service: string # Indicates the name of your Azure container registry.
  --tenant: string # AAD tenant associated to the AAD credentials.
  --refresh-token: string # AAD refresh token, mandatory when grant_type is access_token_refresh_token or refresh_token
  --access-token: string # AAD access token, mandatory when grant_type is access_token_refresh_token or access_token.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/exchange"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: grant_type, var: grant_type}, {name: service, var: service}, {name: tenant, var: tenant}, {name: refresh_token, var: refresh_token}, {name: access_token, var: access_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    grant_type: $grant_type, service: $service, tenant: $tenant, refresh_token: $refresh_token, access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange Username, Password and Scope an ACR Access Token
#
# GET /oauth2/token
# Returns: record<access_token: string>
# operationId: AccessTokens_GetFromLogin
export def "access-tokens-get-from-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string # Indicates the name of your Azure container registry. (required)
  --scope: string # Expected to be a valid scope, and can be specified more than once for multiple scope requests. You can obtain this from the Www-Authenticate response header from the challenge. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/oauth2/token"
    query: [{name: service, var: service, required: true}, {name: scope, var: scope, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: basic
  } {
    service: $service, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange ACR Refresh token for an ACR Access Token
#
# POST /oauth2/token
# Returns: record<access_token: string>
# operationId: AccessTokens_Get
export def "access-tokens-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string@grant-type-completer-1 # Grant type is expected to be refresh_token
  service: string # Indicates the name of your Azure container registry.
  scope: string # Which is expected to be a valid scope, and can be specified more than once for multiple scope requests. You obtained this from the Www-Authenticate response header from the challenge.
  refresh_token: string # Must be a valid ACR refresh token
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth2/token"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: grant_type, var: grant_type}, {name: service, var: service}, {name: scope, var: scope}, {name: refresh_token, var: refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    grant_type: $grant_type, service: $service, scope: $scope, refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tells whether this Docker Registry instance supports Docker Registry HTTP API v2
#
# GET /v2/
# operationId: V2Support_Check
export def "v2-support-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/"
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mount a blob identified by the `mount` parameter from another repository.
#
# POST /v2/{name}/blobs/uploads/
# operationId: Blob_Mount
export def "blob-mount" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # Name of the source repository. (required)
  --mount: string # Digest of blob to mount from the source repository. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/{name}/blobs/uploads/"
    path_params: [{name: name, var: name}]
    query: [{name: from, var: from, required: true}, {name: mount, var: mount, required: true}]
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, from: $from, mount: $mount
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an already uploaded blob.
#
# DELETE /v2/{name}/blobs/{digest}
# Returns: binary
# operationId: Blob_Delete
export def "blob-delete" [
  name: string
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/{name}/blobs/{digest}"
    path_params: [{name: name, var: name}, {name: digest, var: digest}]
    accept: ["application/octet-stream"]
    ok: [202]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, digest: $digest
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the blob from the registry identified by digest.
#
# GET /v2/{name}/blobs/{digest}
# Returns: binary
# operationId: Blob_Get
export def "blob-get" [
  name: string
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/v2/{name}/blobs/{digest}"
    path_params: [{name: name, var: name}, {name: digest, var: digest}]
    accept: ["application/octet-stream"]
    ok: [200, 307]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, digest: $digest
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Same as GET, except only the headers are returned.
#
# HEAD /v2/{name}/blobs/{digest}
# Returns: record
# operationId: Blob_Check
export def "blob-check" [
  name: string
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/v2/{name}/blobs/{digest}"
    path_params: [{name: name, var: name}, {name: digest, var: digest}]
    accept: ["application/json"]
    ok: [200, 307]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, digest: $digest
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the manifest identified by `name` and `reference`. Note that a manifest can _only_ be deleted by `digest`.
#
# DELETE /v2/{name}/manifests/{reference}
# operationId: Manifests_Delete
export def "manifests-delete" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/{name}/manifests/{reference}"
    path_params: [{name: name, var: name}, {name: reference, var: reference}]
    accept: ["application/json"]
    ok: [202]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, reference: $reference
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the manifest identified by `name` and `reference` where `reference` can be a tag or digest.
#
# GET /v2/{name}/manifests/{reference}
# Returns: record<annotations: record<"org.opencontainers.image.authors": string, "org.opencontainers.image.created": string, "org.opencontainers.image.description": string, "org.opencontainers.image.documentation": string, "org.opencontainers.image.licenses": string, "org.opencontainers.image.ref.name": string, "org.opencontainers.image.revision": string, "org.opencontainers.image.source": string, "org.opencontainers.image.title": string, "org.opencontainers.image.url": string, "org.opencontainers.image.vendor": string, "org.opencontainers.image.version": string>, architecture: string, config: record<annotations: record<"org.opencontainers.image.authors": string, "org.opencontainers.image.created": string, "org.opencontainers.image.description": string, "org.opencontainers.image.documentation": string, "org.opencontainers.image.licenses": string, "org.opencontainers.image.ref.name": string, "org.opencontainers.image.revision": string, "org.opencontainers.image.source": string, "org.opencontainers.image.title": string, "org.opencontainers.image.url": string, "org.opencontainers.image.vendor": string, "org.opencontainers.image.version": string>, digest: string, mediaType: string, size: int, urls: list<string>>, fsLayers: table<blobSum: string>, history: table<v1Compatibility: string>, layers: table<annotations: record, digest: string, mediaType: string, size: int, urls: list>, manifests: table<digest: string, mediaType: string, platform: record, size: int>, mediaType: string, name: string, signatures: table<header: record, protected: string, signature: string>, tag: string, schemaVersion: int>
# operationId: Manifests_Get
export def "manifests-get" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Accept header string delimited by comma. For example, application/vnd.docker.distribution.manifest.v2+json (spec name: accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/{name}/manifests/{reference}"
    path_params: [{name: name, var: name}, {name: reference, var: reference}]
    header: [{name: accept, var: hdr_accept}]
    accept: ["application/json"]
    ok: [200]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, reference: $reference, hdr_accept: $hdr_accept
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Put the manifest identified by `name` and `reference` where `reference` can be a tag or digest.
#
# PUT /v2/{name}/manifests/{reference}
# operationId: Manifests_Create
export def "manifests-create" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema-version: int # Schema version
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/{name}/manifests/{reference}"
    path_params: [{name: name, var: name}, {name: reference, var: reference}]
    body: {content_type: "application/vnd.docker.distribution.manifest.v2+json", kind: json, fields: [{name: schemaVersion, var: schema_version}]}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    name: $name, reference: $reference, schema_version: $schema_version
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel outstanding upload processes, releasing associated resources. If this is not called, the unfinished uploads will eventually timeout.
#
# DELETE /{nextBlobUuidLink}
# operationId: Blob_CancelUpload
export def "blob-cancel-upload" [
  next_blob_uuid_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/{nextBlobUuidLink}"
    path_params: [{name: nextBlobUuidLink, var: next_blob_uuid_link}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    next_blob_uuid_link: $next_blob_uuid_link
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve status of upload identified by uuid. The primary purpose of this endpoint is to resolve the current status of a resumable upload.
#
# GET /{nextBlobUuidLink}
# operationId: Blob_GetStatus
export def "blob-get-status" [
  next_blob_uuid_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: get
    path: "/{nextBlobUuidLink}"
    path_params: [{name: nextBlobUuidLink, var: next_blob_uuid_link}]
    accept: ["application/json"]
    ok: [204]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    next_blob_uuid_link: $next_blob_uuid_link
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a stream of data without completing the upload.
#
# PATCH /{nextBlobUuidLink}
# operationId: Blob_Upload
export def "blob-upload" [
  next_blob_uuid_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  $in | http-request {
    method: patch
    path: "/{nextBlobUuidLink}"
    path_params: [{name: nextBlobUuidLink, var: next_blob_uuid_link}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    next_blob_uuid_link: $next_blob_uuid_link, body: $body
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete the upload, providing all the data in the body, if necessary. A request without a body will just complete the upload with previously uploaded content.
#
# PUT /{nextBlobUuidLink}
# operationId: Blob_EndUpload
export def "blob-end-upload" [
  next_blob_uuid_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --digest: string # Digest of a BLOB (required)
  --body: any
]: any -> any {
  $in | http-request {
    method: put
    path: "/{nextBlobUuidLink}"
    path_params: [{name: nextBlobUuidLink, var: next_blob_uuid_link}]
    query: [{name: digest, var: digest, required: true}]
    body: {content_type: "application/octet-stream", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth_all: [{scheme: basic, var: token_registryauth, env: AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN}, {scheme: bearer, var: token_registryoauth2, env: AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN}]
  } {
    next_blob_uuid_link: $next_blob_uuid_link, digest: $digest, body: $body
    base_url: $base_url, token_registryauth: $token_registryauth, token_registryoauth2: $token_registryoauth2, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
