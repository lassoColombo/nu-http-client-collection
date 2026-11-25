# Auto-generated client for KeyVaultClient v7.0-preview
# Source: https://api.apis.guru/v2/specs/azure.com/keyvault/7.0-preview/swagger.json
# Auth: --token flag or $env.KEYVAULTCLIENT_TOKEN

const CLIENT = {
  base_url: "{vaultBaseUrl}"
  token_env_var: "KEYVAULTCLIENT_TOKEN"
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

def base-url-completer [] { ["{vaultBaseUrl}"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def crv-completer [] { ["P-256" "P-256K" "P-384" "P-521"] }
def kty-completer [] { ["EC" "EC-HSM" "RSA" "RSA-HSM" "oct"] }
def alg-completer [] { ["RSA-OAEP" "RSA-OAEP-256" "RSA1_5"] }
def alg-completer-1 [] { ["ES256" "ES256K" "ES384" "ES512" "PS256" "PS384" "PS512" "RS256" "RS384" "RS512" "RSNULL"] }
def sas-type-completer [] { ["account" "service"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-certificates: "record<nextLink: string, value: table<attributes: record, id: string, tags: record, x5t: string>>"
    delete-certificate-contacts: "record<contacts: table<email: string, name: string, phone: string>, id: string>"
    get-certificate-contacts: "record<contacts: table<email: string, name: string, phone: string>, id: string>"
    set-certificate-contacts: "record<contacts: table<email: string, name: string, phone: string>, id: string>"
    get-certificate-issuers: "record<nextLink: string, value: table<id: string, provider: string>>"
    delete-certificate-issuer: "record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string>"
    get-certificate-issuer: "record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string>"
    update-certificate-issuer: "record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string>"
    set-certificate-issuer: "record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string>"
    restore-certificate: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>"
    delete-certificate: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>"
    backup-certificate: "record<value: string>"
    create-certificate: "record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string>"
    import-certificate: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>"
    delete-certificate-operation: "record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string>"
    get-certificate-operation: "record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string>"
    update-certificate-operation: "record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string>"
    merge-certificate: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>"
    get-certificate-policy: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: table<action: record, trigger: record>, secret_props: record<contentType: string>, x509_props: record<ekus: list<string>, key_usage: list<string>, sans: record<dns_names: list, emails: list, upns: list>, subject: string, validity_months: int>>"
    update-certificate-policy: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: table<action: record, trigger: record>, secret_props: record<contentType: string>, x509_props: record<ekus: list<string>, key_usage: list<string>, sans: record<dns_names: list, emails: list, upns: list>, subject: string, validity_months: int>>"
    get-certificate-versions: "record<nextLink: string, value: table<attributes: record, id: string, tags: record, x5t: string>>"
    get-certificate: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>"
    update-certificate: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>"
    get-deleted-certificates: "record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, tags: record, x5t: string>>"
    get-deleted-certificate: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>"
    recover-deleted-certificate: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>"
    get-deleted-keys: "record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, kid: string, managed: bool, tags: record>>"
    get-deleted-key: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>"
    recover-deleted-key: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>"
    get-deleted-secrets: "record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, contentType: string, id: string, managed: bool, tags: record>>"
    get-deleted-secret: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>"
    recover-deleted-secret: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>"
    get-deleted-storage-accounts: "record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, resourceId: string, tags: record>>"
    get-deleted-storage-account: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>"
    recover-deleted-storage-account: "record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>"
    get-deleted-sas-definitions: "record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, sid: string, tags: record>>"
    get-deleted-sas-definition: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>"
    recover-deleted-sas-definition: "record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>"
    get-keys: "record<nextLink: string, value: table<attributes: record, kid: string, managed: bool, tags: record>>"
    restore-key: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>"
    delete-key: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>"
    import-key: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>"
    backup-key: "record<value: string>"
    create-key: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>"
    get-key-versions: "record<nextLink: string, value: table<attributes: record, kid: string, managed: bool, tags: record>>"
    get-key: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>"
    update-key: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>"
    decrypt: "record<kid: string, value: string>"
    encrypt: "record<kid: string, value: string>"
    sign: "record<kid: string, value: string>"
    unwrap-key: "record<kid: string, value: string>"
    verify: "record<value: bool>"
    wrap-key: "record<kid: string, value: string>"
    get-secrets: "record<nextLink: string, value: table<attributes: record, contentType: string, id: string, managed: bool, tags: record>>"
    restore-secret: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>"
    delete-secret: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>"
    set-secret: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>"
    backup-secret: "record<value: string>"
    get-secret-versions: "record<nextLink: string, value: table<attributes: record, contentType: string, id: string, managed: bool, tags: record>>"
    get-secret: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>"
    update-secret: "record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>"
    get-storage-accounts: "record<nextLink: string, value: table<attributes: record, id: string, resourceId: string, tags: record>>"
    restore-storage-account: "record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>"
    delete-storage-account: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>"
    get-storage-account: "record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>"
    update-storage-account: "record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>"
    set-storage-account: "record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>"
    backup-storage-account: "record<value: string>"
    regenerate-storage-account-key: "record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>"
    get-sas-definitions: "record<nextLink: string, value: table<attributes: record, id: string, sid: string, tags: record>>"
    delete-sas-definition: "record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>"
    get-sas-definition: "record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>"
    update-sas-definition: "record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>"
    set-sas-definition: "record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-certificates" "delete-certificate-contacts" "get-certificate-contacts" "set-certificate-contacts" "get-certificate-issuers" "delete-certificate-issuer" "get-certificate-issuer" "update-certificate-issuer" "set-certificate-issuer" "restore-certificate" "delete-certificate" "backup-certificate" "create-certificate" "import-certificate" "delete-certificate-operation" "get-certificate-operation" "update-certificate-operation" "merge-certificate" "get-certificate-policy" "update-certificate-policy" "get-certificate-versions" "get-certificate" "update-certificate" "get-deleted-certificates" "purge-deleted-certificate" "get-deleted-certificate" "recover-deleted-certificate" "get-deleted-keys" "purge-deleted-key" "get-deleted-key" "recover-deleted-key" "get-deleted-secrets" "purge-deleted-secret" "get-deleted-secret" "recover-deleted-secret" "get-deleted-storage-accounts" "purge-deleted-storage-account" "get-deleted-storage-account" "recover-deleted-storage-account" "get-deleted-sas-definitions" "get-deleted-sas-definition" "recover-deleted-sas-definition" "get-keys" "restore-key" "delete-key" "import-key" "backup-key" "create-key" "get-key-versions" "get-key" "update-key" "decrypt" "encrypt" "sign" "unwrap-key" "verify" "wrap-key" "get-secrets" "restore-secret" "delete-secret" "set-secret" "backup-secret" "get-secret-versions" "get-secret" "update-secret" "get-storage-accounts" "restore-storage-account" "delete-storage-account" "get-storage-account" "update-storage-account" "set-storage-account" "backup-storage-account" "regenerate-storage-account-key" "get-sas-definitions" "delete-sas-definition" "get-sas-definition" "update-sas-definition" "set-sas-definition" "commands"] | sort) } | get name | first)
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

# List certificates in a specified key vault
#
# GET /certificates
# Returns: record<nextLink: string, value: table<attributes: record, id: string, tags: record, x5t: string>>
# operationId: GetCertificates
export def "get-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --include-pending: oneof<nothing, bool> # Specifies whether to include certificates which are not completely provisioned.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates"
    query: [{name: maxresults, var: maxresults}, {name: includePending, var: include_pending}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, include_pending: $include_pending, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the certificate contacts for a specified key vault.
#
# DELETE /certificates/contacts
# Returns: record<contacts: table<email: string, name: string, phone: string>, id: string>
# operationId: DeleteCertificateContacts
export def "delete-certificate-contacts" [
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
    method: delete
    path: "/certificates/contacts"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the certificate contacts for a specified key vault.
#
# GET /certificates/contacts
# Returns: record<contacts: table<email: string, name: string, phone: string>, id: string>
# operationId: GetCertificateContacts
export def "get-certificate-contacts" [
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
    path: "/certificates/contacts"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the certificate contacts for the specified key vault.
#
# PUT /certificates/contacts
# Returns: record<contacts: table<email: string, name: string, phone: string>, id: string>
# operationId: SetCertificateContacts
export def "set-certificate-contacts" [
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
  --contacts: list # The contact list for the vault certificates. — item shape: {email?: string, name?: string, phone?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/certificates/contacts"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: contacts, var: contacts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, contacts: $contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List certificate issuers for a specified key vault.
#
# GET /certificates/issuers
# Returns: record<nextLink: string, value: table<id: string, provider: string>>
# operationId: GetCertificateIssuers
export def "get-certificate-issuers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates/issuers"
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified certificate issuer.
#
# DELETE /certificates/issuers/{issuer-name}
# Returns: record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string>
# operationId: DeleteCertificateIssuer
export def "delete-certificate-issuer" [
  issuer_name: string
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
    method: delete
    path: "/certificates/issuers/{issuer-name}"
    path_params: [{name: issuer-name, var: issuer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issuer_name: $issuer_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the specified certificate issuer.
#
# GET /certificates/issuers/{issuer-name}
# Returns: record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string>
# operationId: GetCertificateIssuer
export def "get-certificate-issuer" [
  issuer_name: string
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
    path: "/certificates/issuers/{issuer-name}"
    path_params: [{name: issuer-name, var: issuer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issuer_name: $issuer_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified certificate issuer.
#
# PATCH /certificates/issuers/{issuer-name}
# Returns: record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string>
# operationId: UpdateCertificateIssuer
export def "update-certificate-issuer" [
  issuer_name: string
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
  --attributes: any # The attributes of an issuer managed by the Key Vault service. — shape: {enabled?: bool}
  --credentials: any # The credentials to be used for the certificate issuer. — shape: {account_id?: string, pwd?: string}
  --org-details: any # Details of the organization of the certificate issuer. — shape: {admin_details?: list, id?: string}
  --provider: string # The issuer provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/certificates/issuers/{issuer-name}"
    path_params: [{name: issuer-name, var: issuer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: credentials, var: credentials}, {name: org_details, var: org_details}, {name: provider, var: provider}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issuer_name: $issuer_name, api_version: $api_version, attributes: $attributes, credentials: $credentials, org_details: $org_details, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the specified certificate issuer.
#
# PUT /certificates/issuers/{issuer-name}
# Returns: record<attributes: record<created: int, enabled: bool, updated: int>, credentials: record<account_id: string, pwd: string>, id: string, org_details: record<admin_details: list<record>, id: string>, provider: string>
# operationId: SetCertificateIssuer
export def "set-certificate-issuer" [
  issuer_name: string
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
  --attributes: any # The attributes of an issuer managed by the Key Vault service. — shape: {enabled?: bool}
  --credentials: any # The credentials to be used for the certificate issuer. — shape: {account_id?: string, pwd?: string}
  --org-details: any # Details of the organization of the certificate issuer. — shape: {admin_details?: list, id?: string}
  provider: string # The issuer provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/certificates/issuers/{issuer-name}"
    path_params: [{name: issuer-name, var: issuer_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: credentials, var: credentials}, {name: org_details, var: org_details}, {name: provider, var: provider}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    issuer_name: $issuer_name, api_version: $api_version, attributes: $attributes, credentials: $credentials, org_details: $org_details, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a backed up certificate to a vault.
#
# POST /certificates/restore
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>
# operationId: RestoreCertificate
export def "restore-certificate" [
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
  value: string # The backup blob associated with a certificate bundle. (format: base64url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/certificates/restore"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a certificate from a specified key vault.
#
# DELETE /certificates/{certificate-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>
# operationId: DeleteCertificate
export def "delete-certificate" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/certificates/{certificate-name}"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backs up the specified certificate.
#
# POST /certificates/{certificate-name}/backup
# Returns: record<value: string>
# operationId: BackupCertificate
export def "backup-certificate" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/certificates/{certificate-name}/backup"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new certificate.
#
# POST /certificates/{certificate-name}/create
# Returns: record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string>
# operationId: CreateCertificate
export def "create-certificate" [
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
  --api-version: string # Client API version. (required)
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --policy: any # Management policy for a certificate. — shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/certificates/{certificate-name}/create"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: policy, var: policy}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version, attributes: $attributes, policy: $policy, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports a certificate into a specified key vault.
#
# POST /certificates/{certificate-name}/import
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>
# operationId: ImportCertificate
export def "import-certificate" [
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
  --api-version: string # Client API version. (required)
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --policy: any # Management policy for a certificate. — shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
  --pwd: string # If the private key in base64EncodedCertificate is encrypted, the password used for encryption.
  --tags: record # Application specific metadata in the form of key-value pairs.
  value: string # Base64 encoded representation of the certificate object to import. This certificate needs to contain the private key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/certificates/{certificate-name}/import"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: policy, var: policy}, {name: pwd, var: pwd}, {name: tags, var: tags}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version, attributes: $attributes, policy: $policy, pwd: $pwd, tags: $tags, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the creation operation for a specific certificate.
#
# DELETE /certificates/{certificate-name}/pending
# Returns: record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string>
# operationId: DeleteCertificateOperation
export def "delete-certificate-operation" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/certificates/{certificate-name}/pending"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the creation operation of a certificate.
#
# GET /certificates/{certificate-name}/pending
# Returns: record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string>
# operationId: GetCertificateOperation
export def "get-certificate-operation" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates/{certificate-name}/pending"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a certificate operation.
#
# PATCH /certificates/{certificate-name}/pending
# Returns: record<cancellation_requested: bool, csr: string, error: record<code: string, innererror: any, message: string>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, request_id: string, status: string, status_details: string, target: string>
# operationId: UpdateCertificateOperation
export def "update-certificate-operation" [
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
  --api-version: string # Client API version. (required)
  --cancellation-requested: oneof<nothing, bool> # Indicates if cancellation was requested on the certificate operation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/certificates/{certificate-name}/pending"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: cancellation_requested, var: cancellation_requested, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version, cancellation_requested: $cancellation_requested
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merges a certificate or a certificate chain with a key pair existing on the server.
#
# POST /certificates/{certificate-name}/pending/merge
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>
# operationId: MergeCertificate
export def "merge-certificate" [
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
  --api-version: string # Client API version. (required)
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --tags: record # Application specific metadata in the form of key-value pairs.
  x5c: list<string> # The certificate or the certificate chain to merge.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/certificates/{certificate-name}/pending/merge"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: tags, var: tags}, {name: x5c, var: x5c}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version, attributes: $attributes, tags: $tags, x5c: $x5c
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the policy for a certificate.
#
# GET /certificates/{certificate-name}/policy
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: table<action: record, trigger: record>, secret_props: record<contentType: string>, x509_props: record<ekus: list<string>, key_usage: list<string>, sans: record<dns_names: list, emails: list, upns: list>, subject: string, validity_months: int>>
# operationId: GetCertificatePolicy
export def "get-certificate-policy" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates/{certificate-name}/policy"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the policy for a certificate.
#
# PATCH /certificates/{certificate-name}/policy
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: table<action: record, trigger: record>, secret_props: record<contentType: string>, x509_props: record<ekus: list<string>, key_usage: list<string>, sans: record<dns_names: list, emails: list, upns: list>, subject: string, validity_months: int>>
# operationId: UpdateCertificatePolicy
export def "update-certificate-policy" [
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
  --api-version: string # Client API version. (required)
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --issuer: any # Parameters for the issuer of the X509 component of a certificate. — shape: {cert_transparency?: bool, cty?: string, name?: string}
  --key-props: any # Properties of the key pair backing a certificate. — shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", exportable?: bool, key_size?: int, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", reuse_key?: bool}
  --lifetime-actions: list # Actions that will be performed by Key Vault over the lifetime of a certificate. — item shape: {action?: any, trigger?: any}
  --secret-props: any # Properties of the key backing a certificate. — shape: {contentType?: string}
  --x509-props: any # Properties of the X509 component of a certificate. — shape: {ekus?: list<string>, key_usage?: list<string>, sans?: any, subject?: string, validity_months?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/certificates/{certificate-name}/policy"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: issuer, var: issuer}, {name: key_props, var: key_props}, {name: lifetime_actions, var: lifetime_actions}, {name: secret_props, var: secret_props}, {name: x509_props, var: x509_props}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version, attributes: $attributes, issuer: $issuer, key_props: $key_props, lifetime_actions: $lifetime_actions, secret_props: $secret_props, x509_props: $x509_props
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the versions of a certificate.
#
# GET /certificates/{certificate-name}/versions
# Returns: record<nextLink: string, value: table<attributes: record, id: string, tags: record, x5t: string>>
# operationId: GetCertificateVersions
export def "get-certificate-versions" [
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
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/certificates/{certificate-name}/versions"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a certificate.
#
# GET /certificates/{certificate-name}/{certificate-version}
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>
# operationId: GetCertificate
export def "get-certificate" [
  certificate_name: string
  certificate_version: string
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
    path: "/certificates/{certificate-name}/{certificate-version}"
    path_params: [{name: certificate-name, var: certificate_name}, {name: certificate-version, var: certificate_version}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, certificate_version: $certificate_version, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attributes associated with the given certificate.
#
# PATCH /certificates/{certificate-name}/{certificate-version}
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>
# operationId: UpdateCertificate
export def "update-certificate" [
  certificate_name: string
  certificate_version: string
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
  --attributes: any # The certificate management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --policy: any # Management policy for a certificate. — shape: {attributes?: any, issuer?: any, key_props?: any, lifetime_actions?: list, secret_props?: any, x509_props?: any}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/certificates/{certificate-name}/{certificate-version}"
    path_params: [{name: certificate-name, var: certificate_name}, {name: certificate-version, var: certificate_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: policy, var: policy}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, certificate_version: $certificate_version, api_version: $api_version, attributes: $attributes, policy: $policy, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the deleted certificates in the specified vault currently available for recovery.
#
# GET /deletedcertificates
# Returns: record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, tags: record, x5t: string>>
# operationId: GetDeletedCertificates
export def "get-deleted-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --include-pending: oneof<nothing, bool> # Specifies whether to include certificates which are not completely provisioned.
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deletedcertificates"
    query: [{name: maxresults, var: maxresults}, {name: includePending, var: include_pending}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, include_pending: $include_pending, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the specified deleted certificate.
#
# DELETE /deletedcertificates/{certificate-name}
# operationId: PurgeDeletedCertificate
export def "purge-deleted-certificate" [
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
  --api-version: string # Client API version. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/deletedcertificates/{certificate-name}"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the specified deleted certificate.
#
# GET /deletedcertificates/{certificate-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>
# operationId: GetDeletedCertificate
export def "get-deleted-certificate" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deletedcertificates/{certificate-name}"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recovers the deleted certificate back to its current version under /certificates.
#
# POST /deletedcertificates/{certificate-name}/recover
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, cer: string, contentType: string, id: string, kid: string, policy: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, id: string, issuer: record<cert_transparency: bool, cty: string, name: string>, key_props: record<crv: string, exportable: bool, key_size: int, kty: string, reuse_key: bool>, lifetime_actions: list<record>, secret_props: record<contentType: string>, x509_props: record<ekus: list, key_usage: list, sans: record, subject: string, validity_months: int>>, sid: string, tags: record, x5t: string>
# operationId: RecoverDeletedCertificate
export def "recover-deleted-certificate" [
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
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/deletedcertificates/{certificate-name}/recover"
    path_params: [{name: certificate-name, var: certificate_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    certificate_name: $certificate_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the deleted keys in the specified vault.
#
# GET /deletedkeys
# Returns: record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, kid: string, managed: bool, tags: record>>
# operationId: GetDeletedKeys
export def "get-deleted-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deletedkeys"
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the specified key.
#
# DELETE /deletedkeys/{key-name}
# operationId: PurgeDeletedKey
export def "purge-deleted-key" [
  key_name: string
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
    path: "/deletedkeys/{key-name}"
    path_params: [{name: key-name, var: key_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    key_name: $key_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the public part of a deleted key.
#
# GET /deletedkeys/{key-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>
# operationId: GetDeletedKey
export def "get-deleted-key" [
  key_name: string
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
    path: "/deletedkeys/{key-name}"
    path_params: [{name: key-name, var: key_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recovers the deleted key to its latest version.
#
# POST /deletedkeys/{key-name}/recover
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>
# operationId: RecoverDeletedKey
export def "recover-deleted-key" [
  key_name: string
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
    path: "/deletedkeys/{key-name}/recover"
    path_params: [{name: key-name, var: key_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists deleted secrets for the specified vault.
#
# GET /deletedsecrets
# Returns: record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, contentType: string, id: string, managed: bool, tags: record>>
# operationId: GetDeletedSecrets
export def "get-deleted-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deletedsecrets"
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the specified secret.
#
# DELETE /deletedsecrets/{secret-name}
# operationId: PurgeDeletedSecret
export def "purge-deleted-secret" [
  secret_name: string
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
    path: "/deletedsecrets/{secret-name}"
    path_params: [{name: secret-name, var: secret_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    secret_name: $secret_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified deleted secret.
#
# GET /deletedsecrets/{secret-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>
# operationId: GetDeletedSecret
export def "get-deleted-secret" [
  secret_name: string
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
    path: "/deletedsecrets/{secret-name}"
    path_params: [{name: secret-name, var: secret_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_name: $secret_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recovers the deleted secret to the latest version.
#
# POST /deletedsecrets/{secret-name}/recover
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>
# operationId: RecoverDeletedSecret
export def "recover-deleted-secret" [
  secret_name: string
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
    path: "/deletedsecrets/{secret-name}/recover"
    path_params: [{name: secret-name, var: secret_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_name: $secret_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists deleted storage accounts for the specified vault.
#
# GET /deletedstorage
# Returns: record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, resourceId: string, tags: record>>
# operationId: GetDeletedStorageAccounts
export def "get-deleted-storage-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deletedstorage"
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Permanently deletes the specified storage account.
#
# DELETE /deletedstorage/{storage-account-name}
# operationId: PurgeDeletedStorageAccount
export def "purge-deleted-storage-account" [
  storage_account_name: string
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
    path: "/deletedstorage/{storage-account-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified deleted storage account.
#
# GET /deletedstorage/{storage-account-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>
# operationId: GetDeletedStorageAccount
export def "get-deleted-storage-account" [
  storage_account_name: string
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
    path: "/deletedstorage/{storage-account-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recovers the deleted storage account.
#
# POST /deletedstorage/{storage-account-name}/recover
# Returns: record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>
# operationId: RecoverDeletedStorageAccount
export def "recover-deleted-storage-account" [
  storage_account_name: string
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
    path: "/deletedstorage/{storage-account-name}/recover"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists deleted SAS definitions for the specified vault and storage account.
#
# GET /deletedstorage/{storage-account-name}/sas
# Returns: record<nextLink: string, value: table<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record, id: string, sid: string, tags: record>>
# operationId: GetDeletedSasDefinitions
export def "get-deleted-sas-definitions" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deletedstorage/{storage-account-name}/sas"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified deleted sas definition.
#
# GET /deletedstorage/{storage-account-name}/sas/{sas-definition-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>
# operationId: GetDeletedSasDefinition
export def "get-deleted-sas-definition" [
  storage_account_name: string
  sas_definition_name: string
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
    path: "/deletedstorage/{storage-account-name}/sas/{sas-definition-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}, {name: sas-definition-name, var: sas_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, sas_definition_name: $sas_definition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recovers the deleted SAS definition.
#
# POST /deletedstorage/{storage-account-name}/sas/{sas-definition-name}/recover
# Returns: record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>
# operationId: RecoverDeletedSasDefinition
export def "recover-deleted-sas-definition" [
  storage_account_name: string
  sas_definition_name: string
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
    path: "/deletedstorage/{storage-account-name}/sas/{sas-definition-name}/recover"
    path_params: [{name: storage-account-name, var: storage_account_name}, {name: sas-definition-name, var: sas_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, sas_definition_name: $sas_definition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List keys in the specified vault.
#
# GET /keys
# Returns: record<nextLink: string, value: table<attributes: record, kid: string, managed: bool, tags: record>>
# operationId: GetKeys
export def "get-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keys"
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a backed up key to a vault.
#
# POST /keys/restore
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>
# operationId: RestoreKey
export def "restore-key" [
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
  value: string # The backup blob associated with a key bundle. (format: base64url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/restore"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a key of any type from storage in Azure Key Vault.
#
# DELETE /keys/{key-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>
# operationId: DeleteKey
export def "delete-key" [
  key_name: string
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
    method: delete
    path: "/keys/{key-name}"
    path_params: [{name: key-name, var: key_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Imports an externally created key, stores it, and returns key parameters and attributes to the client.
#
# PUT /keys/{key-name}
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>
# operationId: ImportKey
export def "import-key" [
  key_name: string
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
  --hsm: oneof<nothing, bool> # Whether to import as a hardware key (HSM) or software key.
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  key: any # As of http://tools.ietf.org/html/draft-ietf-jose-json-web-key-18 — shape: {crv?: "P-256"|"P-384"|"P-521"|"P-256K", d?: string, dp?: string, dq?: string, e?: string, k?: string, key_hsm?: string, key_ops?: list<string>, kid?: string, kty?: "EC"|"EC-HSM"|"RSA"|"RSA-HSM"|"oct", n?: string, p?: string, q?: string, qi?: string, x?: string, y?: string}
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/keys/{key-name}"
    path_params: [{name: key-name, var: key_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Hsm, var: hsm}, {name: attributes, var: attributes}, {name: key, var: key}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, api_version: $api_version, hsm: $hsm, attributes: $attributes, key: $key, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests that a backup of the specified key be downloaded to the client.
#
# POST /keys/{key-name}/backup
# Returns: record<value: string>
# operationId: BackupKey
export def "backup-key" [
  key_name: string
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
    path: "/keys/{key-name}/backup"
    path_params: [{name: key-name, var: key_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new key, stores it, then returns key parameters and attributes to the client.
#
# POST /keys/{key-name}/create
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>
# operationId: CreateKey
export def "create-key" [
  key_name: string
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
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --crv: string@crv-completer # Elliptic curve name. For valid values, see JsonWebKeyCurveName.
  --key-ops: list<string>
  --key-size: int # The key size in bits. For example: 2048, 3072, or 4096 for RSA. (format: int32)
  kty: string@kty-completer # The type of key to create. For valid values, see JsonWebKeyType.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/{key-name}/create"
    path_params: [{name: key-name, var: key_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: crv, var: crv}, {name: key_ops, var: key_ops}, {name: key_size, var: key_size}, {name: kty, var: kty}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, api_version: $api_version, attributes: $attributes, crv: $crv, key_ops: $key_ops, key_size: $key_size, kty: $kty, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of individual key versions with the same key name.
#
# GET /keys/{key-name}/versions
# Returns: record<nextLink: string, value: table<attributes: record, kid: string, managed: bool, tags: record>>
# operationId: GetKeyVersions
export def "get-key-versions" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/keys/{key-name}/versions"
    path_params: [{name: key-name, var: key_name}]
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the public part of a stored key.
#
# GET /keys/{key-name}/{key-version}
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>
# operationId: GetKey
export def "get-key" [
  key_name: string
  key_version: string
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
    path: "/keys/{key-name}/{key-version}"
    path_params: [{name: key-name, var: key_name}, {name: key-version, var: key_version}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, key_version: $key_version, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The update key operation changes specified attributes of a stored key and can be applied to any key type and key version stored in Azure Key Vault.
#
# PATCH /keys/{key-name}/{key-version}
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, key: record<crv: string, d: string, dp: string, dq: string, e: string, k: string, key_hsm: string, key_ops: list<string>, kid: string, kty: string, n: string, p: string, q: string, qi: string, x: string, y: string>, managed: bool, tags: record>
# operationId: UpdateKey
export def "update-key" [
  key_name: string
  key_version: string
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
  --attributes: any # The attributes of a key managed by the key vault service. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --key-ops: list<string> # Json web key operations. For more information on possible key operations, see JsonWebKeyOperation.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/keys/{key-name}/{key-version}"
    path_params: [{name: key-name, var: key_name}, {name: key-version, var: key_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: key_ops, var: key_ops}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, key_version: $key_version, api_version: $api_version, attributes: $attributes, key_ops: $key_ops, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Decrypts a single block of encrypted data.
#
# POST /keys/{key-name}/{key-version}/decrypt
# Returns: record<kid: string, value: string>
# operationId: decrypt
export def "decrypt" [
  key_name: string
  key_version: string
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
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/{key-name}/{key-version}/decrypt"
    path_params: [{name: key-name, var: key_name}, {name: key-version, var: key_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: alg, var: alg}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, key_version: $key_version, api_version: $api_version, alg: $alg, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Encrypts an arbitrary sequence of bytes using an encryption key that is stored in a key vault.
#
# POST /keys/{key-name}/{key-version}/encrypt
# Returns: record<kid: string, value: string>
# operationId: encrypt
export def "encrypt" [
  key_name: string
  key_version: string
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
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/{key-name}/{key-version}/encrypt"
    path_params: [{name: key-name, var: key_name}, {name: key-version, var: key_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: alg, var: alg}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, key_version: $key_version, api_version: $api_version, alg: $alg, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a signature from a digest using the specified key.
#
# POST /keys/{key-name}/{key-version}/sign
# Returns: record<kid: string, value: string>
# operationId: sign
export def "sign" [
  key_name: string
  key_version: string
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
  alg: string@alg-completer-1 # The signing/verification algorithm identifier. For more information on possible algorithm types, see JsonWebKeySignatureAlgorithm.
  value: string # format: base64url
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/{key-name}/{key-version}/sign"
    path_params: [{name: key-name, var: key_name}, {name: key-version, var: key_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: alg, var: alg}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, key_version: $key_version, api_version: $api_version, alg: $alg, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unwraps a symmetric key using the specified key that was initially used for wrapping that key.
#
# POST /keys/{key-name}/{key-version}/unwrapkey
# Returns: record<kid: string, value: string>
# operationId: unwrapKey
export def "unwrap-key" [
  key_name: string
  key_version: string
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
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/{key-name}/{key-version}/unwrapkey"
    path_params: [{name: key-name, var: key_name}, {name: key-version, var: key_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: alg, var: alg}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, key_version: $key_version, api_version: $api_version, alg: $alg, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verifies a signature using a specified key.
#
# POST /keys/{key-name}/{key-version}/verify
# Returns: record<value: bool>
# operationId: verify
export def "verify" [
  key_name: string
  key_version: string
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
  alg: string@alg-completer-1 # The signing/verification algorithm. For more information on possible algorithm types, see JsonWebKeySignatureAlgorithm.
  digest: string # The digest used for signing. (format: base64url)
  value: string # The signature to be verified. (format: base64url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/{key-name}/{key-version}/verify"
    path_params: [{name: key-name, var: key_name}, {name: key-version, var: key_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: alg, var: alg}, {name: digest, var: digest}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, key_version: $key_version, api_version: $api_version, alg: $alg, digest: $digest, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wraps a symmetric key using a specified key.
#
# POST /keys/{key-name}/{key-version}/wrapkey
# Returns: record<kid: string, value: string>
# operationId: wrapKey
export def "wrap-key" [
  key_name: string
  key_version: string
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
  alg: string@alg-completer # algorithm identifier
  value: string # format: base64url
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/keys/{key-name}/{key-version}/wrapkey"
    path_params: [{name: key-name, var: key_name}, {name: key-version, var: key_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: alg, var: alg}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    key_name: $key_name, key_version: $key_version, api_version: $api_version, alg: $alg, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List secrets in a specified key vault.
#
# GET /secrets
# Returns: record<nextLink: string, value: table<attributes: record, contentType: string, id: string, managed: bool, tags: record>>
# operationId: GetSecrets
export def "get-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified, the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/secrets"
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a backed up secret to a vault.
#
# POST /secrets/restore
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>
# operationId: RestoreSecret
export def "restore-secret" [
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
  value: string # The backup blob associated with a secret bundle. (format: base64url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/secrets/restore"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a secret from a specified key vault.
#
# DELETE /secrets/{secret-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>
# operationId: DeleteSecret
export def "delete-secret" [
  secret_name: string
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
    method: delete
    path: "/secrets/{secret-name}"
    path_params: [{name: secret-name, var: secret_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_name: $secret_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets a secret in a specified key vault.
#
# PUT /secrets/{secret-name}
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>
# operationId: SetSecret
export def "set-secret" [
  secret_name: string
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
  --attributes: any # The secret management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --content-type: string # Type of the secret value such as a password.
  --tags: record # Application specific metadata in the form of key-value pairs.
  value: string # The value of the secret.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/secrets/{secret-name}"
    path_params: [{name: secret-name, var: secret_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: contentType, var: content_type}, {name: tags, var: tags}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_name: $secret_name, api_version: $api_version, attributes: $attributes, content_type: $content_type, tags: $tags, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backs up the specified secret.
#
# POST /secrets/{secret-name}/backup
# Returns: record<value: string>
# operationId: BackupSecret
export def "backup-secret" [
  secret_name: string
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
    path: "/secrets/{secret-name}/backup"
    path_params: [{name: secret-name, var: secret_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_name: $secret_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all versions of the specified secret.
#
# GET /secrets/{secret-name}/versions
# Returns: record<nextLink: string, value: table<attributes: record, contentType: string, id: string, managed: bool, tags: record>>
# operationId: GetSecretVersions
export def "get-secret-versions" [
  secret_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified, the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/secrets/{secret-name}/versions"
    path_params: [{name: secret-name, var: secret_name}]
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_name: $secret_name, maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specified secret from a given key vault.
#
# GET /secrets/{secret-name}/{secret-version}
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>
# operationId: GetSecret
export def "get-secret" [
  secret_name: string
  secret_version: string
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
    path: "/secrets/{secret-name}/{secret-version}"
    path_params: [{name: secret-name, var: secret_name}, {name: secret-version, var: secret_version}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_name: $secret_name, secret_version: $secret_version, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the attributes associated with a specified secret in a given key vault.
#
# PATCH /secrets/{secret-name}/{secret-version}
# Returns: record<attributes: record<recoveryLevel: string, created: int, enabled: bool, exp: int, nbf: int, updated: int>, contentType: string, id: string, kid: string, managed: bool, tags: record, value: string>
# operationId: UpdateSecret
export def "update-secret" [
  secret_name: string
  secret_version: string
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
  --attributes: any # The secret management attributes. — shape: {enabled?: bool, exp?: int, nbf?: int}
  --content-type: string # Type of the secret value such as a password.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/secrets/{secret-name}/{secret-version}"
    path_params: [{name: secret-name, var: secret_name}, {name: secret-version, var: secret_version}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: contentType, var: content_type}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_name: $secret_name, secret_version: $secret_version, api_version: $api_version, attributes: $attributes, content_type: $content_type, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List storage accounts managed by the specified key vault. This operation requires the storage/list permission.
#
# GET /storage
# Returns: record<nextLink: string, value: table<attributes: record, id: string, resourceId: string, tags: record>>
# operationId: GetStorageAccounts
export def "get-storage-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/storage"
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores a backed up storage account to a vault.
#
# POST /storage/restore
# Returns: record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>
# operationId: RestoreStorageAccount
export def "restore-storage-account" [
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
  value: string # The backup blob associated with a storage account. (format: base64url)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/storage/restore"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a storage account. This operation requires the storage/delete permission.
#
# DELETE /storage/{storage-account-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>
# operationId: DeleteStorageAccount
export def "delete-storage-account" [
  storage_account_name: string
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
    method: delete
    path: "/storage/{storage-account-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a specified storage account. This operation requires the storage/get permission.
#
# GET /storage/{storage-account-name}
# Returns: record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>
# operationId: GetStorageAccount
export def "get-storage-account" [
  storage_account_name: string
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
    path: "/storage/{storage-account-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attributes associated with the given storage account. This operation requires the storage/set/update permission.
#
# PATCH /storage/{storage-account-name}
# Returns: record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>
# operationId: UpdateStorageAccount
export def "update-storage-account" [
  storage_account_name: string
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
  --active-key-name: string # The current active storage account key name.
  --attributes: any # The storage account management attributes. — shape: {enabled?: bool}
  --auto-regenerate-key: oneof<nothing, bool> # whether keyvault should manage the storage account for the user.
  --regeneration-period: string # The key regeneration time duration specified in ISO-8601 format.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/storage/{storage-account-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeKeyName, var: active_key_name}, {name: attributes, var: attributes}, {name: autoRegenerateKey, var: auto_regenerate_key}, {name: regenerationPeriod, var: regeneration_period}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version, active_key_name: $active_key_name, attributes: $attributes, auto_regenerate_key: $auto_regenerate_key, regeneration_period: $regeneration_period, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a new storage account. This operation requires the storage/set permission.
#
# PUT /storage/{storage-account-name}
# Returns: record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>
# operationId: SetStorageAccount
export def "set-storage-account" [
  storage_account_name: string
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
  active_key_name: string # Current active storage account key name.
  --attributes: any # The storage account management attributes. — shape: {enabled?: bool}
  --auto-regenerate-key: oneof<nothing, bool> # whether keyvault should manage the storage account for the user.
  --regeneration-period: string # The key regeneration time duration specified in ISO-8601 format.
  resource_id: string # Storage account resource id.
  --tags: record # Application specific metadata in the form of key-value pairs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/storage/{storage-account-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: activeKeyName, var: active_key_name}, {name: attributes, var: attributes}, {name: autoRegenerateKey, var: auto_regenerate_key, required: true}, {name: regenerationPeriod, var: regeneration_period}, {name: resourceId, var: resource_id}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version, active_key_name: $active_key_name, attributes: $attributes, auto_regenerate_key: $auto_regenerate_key, regeneration_period: $regeneration_period, resource_id: $resource_id, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Backs up the specified storage account.
#
# POST /storage/{storage-account-name}/backup
# Returns: record<value: string>
# operationId: BackupStorageAccount
export def "backup-storage-account" [
  storage_account_name: string
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
    path: "/storage/{storage-account-name}/backup"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Regenerates the specified key value for the given storage account. This operation requires the storage/regeneratekey permission.
#
# POST /storage/{storage-account-name}/regeneratekey
# Returns: record<activeKeyName: string, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, autoRegenerateKey: bool, id: string, regenerationPeriod: string, resourceId: string, tags: record>
# operationId: RegenerateStorageAccountKey
export def "regenerate-storage-account-key" [
  storage_account_name: string
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
  key_name: string # The storage account key name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/storage/{storage-account-name}/regeneratekey"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keyName, var: key_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, api_version: $api_version, key_name: $key_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List storage SAS definitions for the given storage account. This operation requires the storage/listsas permission.
#
# GET /storage/{storage-account-name}/sas
# Returns: record<nextLink: string, value: table<attributes: record, id: string, sid: string, tags: record>>
# operationId: GetSasDefinitions
export def "get-sas-definitions" [
  storage_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # Maximum number of results to return in a page. If not specified the service will return up to 25 results. (format: int32)
  --api-version: string # Client API version. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/storage/{storage-account-name}/sas"
    path_params: [{name: storage-account-name, var: storage_account_name}]
    query: [{name: maxresults, var: maxresults}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, maxresults: $maxresults, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a SAS definition from a specified storage account. This operation requires the storage/deletesas permission.
#
# DELETE /storage/{storage-account-name}/sas/{sas-definition-name}
# Returns: record<deletedDate: int, recoveryId: string, scheduledPurgeDate: int, attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>
# operationId: DeleteSasDefinition
export def "delete-sas-definition" [
  storage_account_name: string
  sas_definition_name: string
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
    method: delete
    path: "/storage/{storage-account-name}/sas/{sas-definition-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}, {name: sas-definition-name, var: sas_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, sas_definition_name: $sas_definition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a SAS definition for the specified storage account. This operation requires the storage/getsas permission.
#
# GET /storage/{storage-account-name}/sas/{sas-definition-name}
# Returns: record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>
# operationId: GetSasDefinition
export def "get-sas-definition" [
  storage_account_name: string
  sas_definition_name: string
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
    path: "/storage/{storage-account-name}/sas/{sas-definition-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}, {name: sas-definition-name, var: sas_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, sas_definition_name: $sas_definition_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the specified attributes associated with the given SAS definition. This operation requires the storage/setsas permission.
#
# PATCH /storage/{storage-account-name}/sas/{sas-definition-name}
# Returns: record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>
# operationId: UpdateSasDefinition
export def "update-sas-definition" [
  storage_account_name: string
  sas_definition_name: string
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
  --attributes: any # The SAS definition management attributes. — shape: {enabled?: bool}
  --sas-type: string@sas-type-completer # The type of SAS token the SAS definition will create.
  --tags: record # Application specific metadata in the form of key-value pairs.
  --template-uri: string # The SAS definition token template signed with an arbitrary key. Tokens created according to the SAS definition will have the same properties as the template.
  --validity-period: string # The validity period of SAS tokens created according to the SAS definition.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/storage/{storage-account-name}/sas/{sas-definition-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}, {name: sas-definition-name, var: sas_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: sasType, var: sas_type}, {name: tags, var: tags}, {name: templateUri, var: template_uri}, {name: validityPeriod, var: validity_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, sas_definition_name: $sas_definition_name, api_version: $api_version, attributes: $attributes, sas_type: $sas_type, tags: $tags, template_uri: $template_uri, validity_period: $validity_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a new SAS definition for the specified storage account. This operation requires the storage/setsas permission.
#
# PUT /storage/{storage-account-name}/sas/{sas-definition-name}
# Returns: record<attributes: record<created: int, enabled: bool, recoveryLevel: string, updated: int>, id: string, sasType: string, sid: string, tags: record, templateUri: string, validityPeriod: string>
# operationId: SetSasDefinition
export def "set-sas-definition" [
  storage_account_name: string
  sas_definition_name: string
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
  --attributes: any # The SAS definition management attributes. — shape: {enabled?: bool}
  sas_type: string@sas-type-completer # The type of SAS token the SAS definition will create.
  --tags: record # Application specific metadata in the form of key-value pairs.
  template_uri: string # The SAS definition token template signed with an arbitrary key. Tokens created according to the SAS definition will have the same properties as the template.
  validity_period: string # The validity period of SAS tokens created according to the SAS definition.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/storage/{storage-account-name}/sas/{sas-definition-name}"
    path_params: [{name: storage-account-name, var: storage_account_name}, {name: sas-definition-name, var: sas_definition_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: attributes, var: attributes}, {name: sasType, var: sas_type}, {name: tags, var: tags}, {name: templateUri, var: template_uri}, {name: validityPeriod, var: validity_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    storage_account_name: $storage_account_name, sas_definition_name: $sas_definition_name, api_version: $api_version, attributes: $attributes, sas_type: $sas_type, tags: $tags, template_uri: $template_uri, validity_period: $validity_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
