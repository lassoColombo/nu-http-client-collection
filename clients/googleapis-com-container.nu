# Auto-generated client for Kubernetes Engine API v1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/container/v1beta1/openapi.json
# Auth: --token flag or $env.KUBERNETES_ENGINE_API_TOKEN

const CLIENT = {
  base_url: "https://container.googleapis.com"
  token_env_var: "KUBERNETES_ENGINE_API_TOKEN"
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

def base-url-completer [] { ["https://container.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def action-completer [] { ["GENERATE_PASSWORD" "SET_PASSWORD" "SET_USERNAME" "UNKNOWN"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    container-projects-zones-clusters-list: "record<clusters: table<addonsConfig: record, authenticatorGroupsConfig: record, autopilot: record, autoscaling: record, binaryAuthorization: record, clusterIpv4Cidr: string, clusterTelemetry: record, conditions: list, confidentialNodes: record, costManagementConfig: record, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record, defaultMaxPodsConstraint: record, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record, id: string, identityServiceConfig: record, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list, ipAllocationPolicy: record, labelFingerprint: string, legacyAbac: record, location: string, locations: list, loggingConfig: record, loggingService: string, maintenancePolicy: record, master: record, masterAuth: record, masterAuthorizedNetworksConfig: record, masterIpv4CidrBlock: string, meshCertificates: record, monitoringConfig: record, monitoringService: string, name: string, network: string, networkConfig: record, networkPolicy: record, nodeConfig: record, nodeIpv4CidrSize: int, nodePoolAutoConfig: record, nodePoolDefaults: record, nodePools: list, notificationConfig: record, podSecurityPolicyConfig: record, privateCluster: bool, privateClusterConfig: record, protectConfig: record, releaseChannel: record, resourceLabels: record, resourceUsageExportConfig: record, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record, status: string, statusMessage: string, subnetwork: string, tpuConfig: record, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record, workloadAltsConfig: record, workloadCertificates: record, workloadIdentityConfig: record, zone: string>, missingZones: list<string>>"
    container-projects-zones-clusters-create: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-delete: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-get: "record<addonsConfig: record<cloudRunConfig: record<disabled: bool, loadBalancerType: string>, configConnectorConfig: record<enabled: bool>, dnsCacheConfig: record<enabled: bool>, gcePersistentDiskCsiDriverConfig: record<enabled: bool>, gcpFilestoreCsiDriverConfig: record<enabled: bool>, gkeBackupAgentConfig: record<enabled: bool>, horizontalPodAutoscaling: record<disabled: bool>, httpLoadBalancing: record<disabled: bool>, istioConfig: record<auth: string, disabled: bool>, kalmConfig: record<enabled: bool>, kubernetesDashboard: record<disabled: bool>, networkPolicyConfig: record<disabled: bool>>, authenticatorGroupsConfig: record<enabled: bool, securityGroup: string>, autopilot: record<enabled: bool>, autoscaling: record<autoprovisioningLocations: list<string>, autoprovisioningNodePoolDefaults: record<bootDiskKmsKey: string, diskSizeGb: int, diskType: string, imageType: string, management: record, minCpuPlatform: string, oauthScopes: list, serviceAccount: string, shieldedInstanceConfig: record, upgradeSettings: record>, autoscalingProfile: string, enableNodeAutoprovisioning: bool, resourceLimits: list<record>>, binaryAuthorization: record<enabled: bool, evaluationMode: string>, clusterIpv4Cidr: string, clusterTelemetry: record<type: string>, conditions: table<canonicalCode: string, code: string, message: string>, confidentialNodes: record<enabled: bool>, costManagementConfig: record<enabled: bool>, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record<keyName: string, state: string>, defaultMaxPodsConstraint: record<maxPodsPerNode: string>, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record<membership: string, preRegistered: bool, project: string>, id: string, identityServiceConfig: record<enabled: bool>, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list<string>, ipAllocationPolicy: record<additionalPodRangesConfig: record<podRangeNames: list>, allowRouteOverlap: bool, clusterIpv4Cidr: string, clusterIpv4CidrBlock: string, clusterSecondaryRangeName: string, createSubnetwork: bool, ipv6AccessType: string, nodeIpv4Cidr: string, nodeIpv4CidrBlock: string, podCidrOverprovisionConfig: record<disable: bool>, servicesIpv4Cidr: string, servicesIpv4CidrBlock: string, servicesIpv6CidrBlock: string, servicesSecondaryRangeName: string, stackType: string, subnetIpv6CidrBlock: string, subnetworkName: string, tpuIpv4CidrBlock: string, useIpAliases: bool, useRoutes: bool>, labelFingerprint: string, legacyAbac: record<enabled: bool>, location: string, locations: list<string>, loggingConfig: record<componentConfig: record<enableComponents: list>>, loggingService: string, maintenancePolicy: record<resourceVersion: string, window: record<dailyMaintenanceWindow: record, maintenanceExclusions: record, recurringWindow: record>>, master: record, masterAuth: record<clientCertificate: string, clientCertificateConfig: record<issueClientCertificate: bool>, clientKey: string, clusterCaCertificate: string, password: string, username: string>, masterAuthorizedNetworksConfig: record<cidrBlocks: list<record>, enabled: bool, gcpPublicCidrsAccessEnabled: bool>, masterIpv4CidrBlock: string, meshCertificates: record<enableCertificates: bool>, monitoringConfig: record<componentConfig: record<enableComponents: list>, managedPrometheusConfig: record<enabled: bool>>, monitoringService: string, name: string, network: string, networkConfig: record<datapathProvider: string, defaultSnatStatus: record<disabled: bool>, dnsConfig: record<clusterDns: string, clusterDnsDomain: string, clusterDnsScope: string>, enableIntraNodeVisibility: bool, enableL4ilbSubsetting: bool, gatewayApiConfig: record<channel: string>, network: string, privateIpv6GoogleAccess: string, serviceExternalIpsConfig: record<enabled: bool>, subnetwork: string>, networkPolicy: record<enabled: bool, provider: string>, nodeConfig: record<accelerators: list<record>, advancedMachineFeatures: record<threadsPerCore: string>, bootDiskKmsKey: string, confidentialNodes: record<enabled: bool>, diskSizeGb: int, diskType: string, ephemeralStorageConfig: record<localSsdCount: int>, ephemeralStorageLocalSsdConfig: record<localSsdCount: int>, fastSocket: record<enabled: bool>, gcfsConfig: record<enabled: bool>, gvnic: record<enabled: bool>, imageType: string, kubeletConfig: record<cpuCfsQuota: bool, cpuCfsQuotaPeriod: string, cpuManagerPolicy: string, podPidsLimit: string>, labels: record, linuxNodeConfig: record<cgroupMode: string, sysctls: record>, localNvmeSsdBlockConfig: record<localSsdCount: int>, localSsdCount: int, loggingConfig: record<variantConfig: record>, machineType: string, metadata: record, minCpuPlatform: string, nodeGroup: string, oauthScopes: list<string>, preemptible: bool, reservationAffinity: record<consumeReservationType: string, key: string, values: list>, resourceLabels: record, sandboxConfig: record<sandboxType: string, type: string>, serviceAccount: string, shieldedInstanceConfig: record<enableIntegrityMonitoring: bool, enableSecureBoot: bool>, spot: bool, tags: list<string>, taints: list<record>, windowsNodeConfig: record<osVersion: string>, workloadMetadataConfig: record<mode: string, nodeMetadata: string>>, nodeIpv4CidrSize: int, nodePoolAutoConfig: record<networkTags: record<tags: list>>, nodePoolDefaults: record<nodeConfigDefaults: record<gcfsConfig: record, loggingConfig: record>>, nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>, notificationConfig: record<pubsub: record<enabled: bool, filter: record, topic: string>>, podSecurityPolicyConfig: record<enabled: bool>, privateCluster: bool, privateClusterConfig: record<enablePrivateEndpoint: bool, enablePrivateNodes: bool, masterGlobalAccessConfig: record<enabled: bool>, masterIpv4CidrBlock: string, peeringName: string, privateEndpoint: string, privateEndpointSubnetwork: string, publicEndpoint: string>, protectConfig: record<workloadConfig: record<auditMode: string>, workloadVulnerabilityMode: string>, releaseChannel: record<channel: string>, resourceLabels: record, resourceUsageExportConfig: record<bigqueryDestination: record<datasetId: string>, consumptionMeteringConfig: record<enabled: bool>, enableNetworkEgressMetering: bool>, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record<enabled: bool>, status: string, statusMessage: string, subnetwork: string, tpuConfig: record<enabled: bool, ipv4CidrBlock: string, useServiceNetworking: bool>, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record<enabled: bool>, workloadAltsConfig: record<enableAlts: bool>, workloadCertificates: record<enableCertificates: bool>, workloadIdentityConfig: record<identityNamespace: string, identityProvider: string, workloadPool: string>, zone: string>"
    container-projects-zones-clusters-update: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-addons: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-legacy-abac: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-locations: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-logging: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-master: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-monitoring: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-node-pools-list: "record<nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>>"
    container-projects-zones-clusters-node-pools-create: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-node-pools-delete: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-node-pools-get: "record<autoscaling: record<autoprovisioned: bool, enabled: bool, locationPolicy: string, maxNodeCount: int, minNodeCount: int, totalMaxNodeCount: int, totalMinNodeCount: int>, conditions: table<canonicalCode: string, code: string, message: string>, config: record<accelerators: list<record>, advancedMachineFeatures: record<threadsPerCore: string>, bootDiskKmsKey: string, confidentialNodes: record<enabled: bool>, diskSizeGb: int, diskType: string, ephemeralStorageConfig: record<localSsdCount: int>, ephemeralStorageLocalSsdConfig: record<localSsdCount: int>, fastSocket: record<enabled: bool>, gcfsConfig: record<enabled: bool>, gvnic: record<enabled: bool>, imageType: string, kubeletConfig: record<cpuCfsQuota: bool, cpuCfsQuotaPeriod: string, cpuManagerPolicy: string, podPidsLimit: string>, labels: record, linuxNodeConfig: record<cgroupMode: string, sysctls: record>, localNvmeSsdBlockConfig: record<localSsdCount: int>, localSsdCount: int, loggingConfig: record<variantConfig: record>, machineType: string, metadata: record, minCpuPlatform: string, nodeGroup: string, oauthScopes: list<string>, preemptible: bool, reservationAffinity: record<consumeReservationType: string, key: string, values: list>, resourceLabels: record, sandboxConfig: record<sandboxType: string, type: string>, serviceAccount: string, shieldedInstanceConfig: record<enableIntegrityMonitoring: bool, enableSecureBoot: bool>, spot: bool, tags: list<string>, taints: list<record>, windowsNodeConfig: record<osVersion: string>, workloadMetadataConfig: record<mode: string, nodeMetadata: string>>, etag: string, initialNodeCount: int, instanceGroupUrls: list<string>, locations: list<string>, management: record<autoRepair: bool, autoUpgrade: bool, upgradeOptions: record<autoUpgradeStartTime: string, description: string>>, maxPodsConstraint: record<maxPodsPerNode: string>, name: string, networkConfig: record<createPodRange: bool, enablePrivateNodes: bool, networkPerformanceConfig: record<externalIpEgressBandwidthTier: string, totalEgressBandwidthTier: string>, podCidrOverprovisionConfig: record<disable: bool>, podIpv4CidrBlock: string, podRange: string>, placementPolicy: record<type: string>, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record<blueGreenInfo: record<blueInstanceGroupUrls: list, bluePoolDeletionStartTime: string, greenInstanceGroupUrls: list, greenPoolVersion: string, phase: string>>, upgradeSettings: record<blueGreenSettings: record<nodePoolSoakDuration: string, standardRolloutPolicy: record>, maxSurge: int, maxUnavailable: int, strategy: string>, version: string>"
    container-projects-zones-clusters-node-pools-autoscaling: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-node-pools-set-management: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-node-pools-set-size: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-node-pools-update: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-node-pools-rollback: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-resource-labels: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-complete-ip-rotation: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-set-maintenance-policy: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-set-master-auth: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-set-network-policy: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-clusters-start-ip-rotation: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-operations-list: "record<missingZones: list<string>, operations: table<clusterConditions: list, detail: string, endTime: string, error: record, location: string, name: string, nodepoolConditions: list, operationType: string, progress: record, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>>"
    container-projects-zones-operations-get: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-zones-operations-cancel: "record"
    container-projects-zones-get-serverconfig: "record<channels: table<availableVersions: list, channel: string, defaultVersion: string, validVersions: list>, defaultClusterVersion: string, defaultImageType: string, validImageTypes: list<string>, validMasterVersions: list<string>, validNodeVersions: list<string>, windowsVersionMaps: record>"
    container-projects-locations-clusters-node-pools-delete: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-operations-get: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-node-pools-update: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-get-server-config: "record<channels: table<availableVersions: list, channel: string, defaultVersion: string, validVersions: list>, defaultClusterVersion: string, defaultImageType: string, validImageTypes: list<string>, validMasterVersions: list<string>, validNodeVersions: list<string>, windowsVersionMaps: record>"
    container-projects-locations-operations-cancel: "record"
    container-projects-locations-clusters-complete-ip-rotation: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-node-pools-complete-upgrade: "record"
    container-projects-locations-clusters-node-pools-rollback: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-addons: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-node-pools-set-autoscaling: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-legacy-abac: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-locations: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-logging: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-maintenance-policy: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-node-pools-set-management: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-master-auth: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-monitoring: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-network-policy: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-set-resource-labels: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-node-pools-set-size: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-start-ip-rotation: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-update-master: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-well-known-get-openid-configuration: "record<cacheHeader: record<age: string, directive: string, expires: string>, claims_supported: list<string>, grant_types: list<string>, id_token_signing_alg_values_supported: list<string>, issuer: string, jwks_uri: string, response_types_supported: list<string>, subject_types_supported: list<string>>"
    container-projects-aggregated-usable-subnetworks-list: "record<nextPageToken: string, subnetworks: table<ipCidrRange: string, network: string, secondaryIpRanges: list, statusMessage: string, subnetwork: string>>"
    container-projects-locations-clusters-list: "record<clusters: table<addonsConfig: record, authenticatorGroupsConfig: record, autopilot: record, autoscaling: record, binaryAuthorization: record, clusterIpv4Cidr: string, clusterTelemetry: record, conditions: list, confidentialNodes: record, costManagementConfig: record, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record, defaultMaxPodsConstraint: record, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record, id: string, identityServiceConfig: record, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list, ipAllocationPolicy: record, labelFingerprint: string, legacyAbac: record, location: string, locations: list, loggingConfig: record, loggingService: string, maintenancePolicy: record, master: record, masterAuth: record, masterAuthorizedNetworksConfig: record, masterIpv4CidrBlock: string, meshCertificates: record, monitoringConfig: record, monitoringService: string, name: string, network: string, networkConfig: record, networkPolicy: record, nodeConfig: record, nodeIpv4CidrSize: int, nodePoolAutoConfig: record, nodePoolDefaults: record, nodePools: list, notificationConfig: record, podSecurityPolicyConfig: record, privateCluster: bool, privateClusterConfig: record, protectConfig: record, releaseChannel: record, resourceLabels: record, resourceUsageExportConfig: record, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record, status: string, statusMessage: string, subnetwork: string, tpuConfig: record, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record, workloadAltsConfig: record, workloadCertificates: record, workloadIdentityConfig: record, zone: string>, missingZones: list<string>>"
    container-projects-locations-clusters-create: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-clusters-get-jwks: "record<cacheHeader: record<age: string, directive: string, expires: string>, keys: table<alg: string, crv: string, e: string, kid: string, kty: string, n: string, use: string, x: string, y: string>>"
    container-projects-locations-list: "record<locations: table<name: string, recommended: bool, type: string>, nextPageToken: string>"
    container-projects-locations-clusters-node-pools-list: "record<nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>>"
    container-projects-locations-clusters-node-pools-create: "record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>"
    container-projects-locations-operations-list: "record<missingZones: list<string>, operations: table<clusterConditions: list, detail: string, endTime: string, error: record, location: string, name: string, nodepoolConditions: list, operationType: string, progress: record, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["container-projects-zones-clusters-list" "container-projects-zones-clusters-create" "container-projects-zones-clusters-delete" "container-projects-zones-clusters-get" "container-projects-zones-clusters-update" "container-projects-zones-clusters-addons" "container-projects-zones-clusters-legacy-abac" "container-projects-zones-clusters-locations" "container-projects-zones-clusters-logging" "container-projects-zones-clusters-master" "container-projects-zones-clusters-monitoring" "container-projects-zones-clusters-node-pools-list" "container-projects-zones-clusters-node-pools-create" "container-projects-zones-clusters-node-pools-delete" "container-projects-zones-clusters-node-pools-get" "container-projects-zones-clusters-node-pools-autoscaling" "container-projects-zones-clusters-node-pools-set-management" "container-projects-zones-clusters-node-pools-set-size" "container-projects-zones-clusters-node-pools-update" "container-projects-zones-clusters-node-pools-rollback" "container-projects-zones-clusters-resource-labels" "container-projects-zones-clusters-complete-ip-rotation" "container-projects-zones-clusters-set-maintenance-policy" "container-projects-zones-clusters-set-master-auth" "container-projects-zones-clusters-set-network-policy" "container-projects-zones-clusters-start-ip-rotation" "container-projects-zones-operations-list" "container-projects-zones-operations-get" "container-projects-zones-operations-cancel" "container-projects-zones-get-serverconfig" "container-projects-locations-clusters-node-pools-delete" "container-projects-locations-operations-get" "container-projects-locations-clusters-node-pools-update" "container-projects-locations-get-server-config" "container-projects-locations-operations-cancel" "container-projects-locations-clusters-complete-ip-rotation" "container-projects-locations-clusters-node-pools-complete-upgrade" "container-projects-locations-clusters-node-pools-rollback" "container-projects-locations-clusters-set-addons" "container-projects-locations-clusters-node-pools-set-autoscaling" "container-projects-locations-clusters-set-legacy-abac" "container-projects-locations-clusters-set-locations" "container-projects-locations-clusters-set-logging" "container-projects-locations-clusters-set-maintenance-policy" "container-projects-locations-clusters-node-pools-set-management" "container-projects-locations-clusters-set-master-auth" "container-projects-locations-clusters-set-monitoring" "container-projects-locations-clusters-set-network-policy" "container-projects-locations-clusters-set-resource-labels" "container-projects-locations-clusters-node-pools-set-size" "container-projects-locations-clusters-start-ip-rotation" "container-projects-locations-clusters-update-master" "container-projects-locations-clusters-well-known-get-openid-configuration" "container-projects-aggregated-usable-subnetworks-list" "container-projects-locations-clusters-list" "container-projects-locations-clusters-create" "container-projects-locations-clusters-get-jwks" "container-projects-locations-list" "container-projects-locations-clusters-node-pools-list" "container-projects-locations-clusters-node-pools-create" "container-projects-locations-operations-list" "commands"] | sort) } | get name | first)
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

# Lists all clusters owned by a project in either the specified zone or all zones.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/clusters
# Returns: record<clusters: table<addonsConfig: record, authenticatorGroupsConfig: record, autopilot: record, autoscaling: record, binaryAuthorization: record, clusterIpv4Cidr: string, clusterTelemetry: record, conditions: list, confidentialNodes: record, costManagementConfig: record, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record, defaultMaxPodsConstraint: record, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record, id: string, identityServiceConfig: record, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list, ipAllocationPolicy: record, labelFingerprint: string, legacyAbac: record, location: string, locations: list, loggingConfig: record, loggingService: string, maintenancePolicy: record, master: record, masterAuth: record, masterAuthorizedNetworksConfig: record, masterIpv4CidrBlock: string, meshCertificates: record, monitoringConfig: record, monitoringService: string, name: string, network: string, networkConfig: record, networkPolicy: record, nodeConfig: record, nodeIpv4CidrSize: int, nodePoolAutoConfig: record, nodePoolDefaults: record, nodePools: list, notificationConfig: record, podSecurityPolicyConfig: record, privateCluster: bool, privateClusterConfig: record, protectConfig: record, releaseChannel: record, resourceLabels: record, resourceUsageExportConfig: record, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record, status: string, statusMessage: string, subnetwork: string, tpuConfig: record, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record, workloadAltsConfig: record, workloadCertificates: record, workloadIdentityConfig: record, zone: string>, missingZones: list<string>>
# operationId: container.projects.zones.clusters.list
export def "container-projects-zones-clusters-list" [
  project_id: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # The parent (project and location) where the clusters will be listed. Specified in the format `projects/*/locations/*`. Location "-" matches all zones and all regions.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: parent, var: parent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a cluster, consisting of the specified number and type of Google Compute Engine instances. By default, the cluster is created in the project's [default network](https://cloud.google.com/compute/docs/networks-and-firewalls#networks). One firewall is added for the cluster. After cluster creation, the Kubelet creates routes for each node to allow the containers on that node to communicate with all other instances in the cluster. Finally, an entry is added to the project's global metadata indicating which CIDR range the cluster is using.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.create
export def "container-projects-zones-clusters-create" [
  project_id: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster: record # A Google Kubernetes Engine cluster. — shape: {addonsConfig?: record, authenticatorGroupsConfig?: record, autopilot?: record, autoscaling?: record, binaryAuthorization?: record, clusterIpv4Cidr?: string, clusterTelemetry?: record, conditions?: list, confidentialNodes?: record, costManagementConfig?: record, createTime?: string, currentMasterVersion?: string, currentNodeCount?: int, currentNodeVersion?: string, databaseEncryption?: record, defaultMaxPodsConstraint?: record, description?: string, enableKubernetesAlpha?: bool, enableTpu?: bool, ... (53 more fields)}
  --parent: string # The parent (project and location) where the cluster will be created. Specified in the format `projects/*/locations/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cluster, var: cluster}, {name: parent, var: parent}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster: $cluster, parent: $parent, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the cluster, including the Kubernetes endpoint and all worker nodes. Firewalls and routes that were configured during cluster creation are also deleted. Other Google Compute Engine resources that might be in use by the cluster, such as load balancer resources, are not deleted if they weren't present when the cluster was initially created.
#
# DELETE /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.delete
export def "container-projects-zones-clusters-delete" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, cluster) of the cluster to delete. Specified in the format `projects/*/locations/*/clusters/*`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the details for a specific cluster.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}
# Returns: record<addonsConfig: record<cloudRunConfig: record<disabled: bool, loadBalancerType: string>, configConnectorConfig: record<enabled: bool>, dnsCacheConfig: record<enabled: bool>, gcePersistentDiskCsiDriverConfig: record<enabled: bool>, gcpFilestoreCsiDriverConfig: record<enabled: bool>, gkeBackupAgentConfig: record<enabled: bool>, horizontalPodAutoscaling: record<disabled: bool>, httpLoadBalancing: record<disabled: bool>, istioConfig: record<auth: string, disabled: bool>, kalmConfig: record<enabled: bool>, kubernetesDashboard: record<disabled: bool>, networkPolicyConfig: record<disabled: bool>>, authenticatorGroupsConfig: record<enabled: bool, securityGroup: string>, autopilot: record<enabled: bool>, autoscaling: record<autoprovisioningLocations: list<string>, autoprovisioningNodePoolDefaults: record<bootDiskKmsKey: string, diskSizeGb: int, diskType: string, imageType: string, management: record, minCpuPlatform: string, oauthScopes: list, serviceAccount: string, shieldedInstanceConfig: record, upgradeSettings: record>, autoscalingProfile: string, enableNodeAutoprovisioning: bool, resourceLimits: list<record>>, binaryAuthorization: record<enabled: bool, evaluationMode: string>, clusterIpv4Cidr: string, clusterTelemetry: record<type: string>, conditions: table<canonicalCode: string, code: string, message: string>, confidentialNodes: record<enabled: bool>, costManagementConfig: record<enabled: bool>, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record<keyName: string, state: string>, defaultMaxPodsConstraint: record<maxPodsPerNode: string>, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record<membership: string, preRegistered: bool, project: string>, id: string, identityServiceConfig: record<enabled: bool>, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list<string>, ipAllocationPolicy: record<additionalPodRangesConfig: record<podRangeNames: list>, allowRouteOverlap: bool, clusterIpv4Cidr: string, clusterIpv4CidrBlock: string, clusterSecondaryRangeName: string, createSubnetwork: bool, ipv6AccessType: string, nodeIpv4Cidr: string, nodeIpv4CidrBlock: string, podCidrOverprovisionConfig: record<disable: bool>, servicesIpv4Cidr: string, servicesIpv4CidrBlock: string, servicesIpv6CidrBlock: string, servicesSecondaryRangeName: string, stackType: string, subnetIpv6CidrBlock: string, subnetworkName: string, tpuIpv4CidrBlock: string, useIpAliases: bool, useRoutes: bool>, labelFingerprint: string, legacyAbac: record<enabled: bool>, location: string, locations: list<string>, loggingConfig: record<componentConfig: record<enableComponents: list>>, loggingService: string, maintenancePolicy: record<resourceVersion: string, window: record<dailyMaintenanceWindow: record, maintenanceExclusions: record, recurringWindow: record>>, master: record, masterAuth: record<clientCertificate: string, clientCertificateConfig: record<issueClientCertificate: bool>, clientKey: string, clusterCaCertificate: string, password: string, username: string>, masterAuthorizedNetworksConfig: record<cidrBlocks: list<record>, enabled: bool, gcpPublicCidrsAccessEnabled: bool>, masterIpv4CidrBlock: string, meshCertificates: record<enableCertificates: bool>, monitoringConfig: record<componentConfig: record<enableComponents: list>, managedPrometheusConfig: record<enabled: bool>>, monitoringService: string, name: string, network: string, networkConfig: record<datapathProvider: string, defaultSnatStatus: record<disabled: bool>, dnsConfig: record<clusterDns: string, clusterDnsDomain: string, clusterDnsScope: string>, enableIntraNodeVisibility: bool, enableL4ilbSubsetting: bool, gatewayApiConfig: record<channel: string>, network: string, privateIpv6GoogleAccess: string, serviceExternalIpsConfig: record<enabled: bool>, subnetwork: string>, networkPolicy: record<enabled: bool, provider: string>, nodeConfig: record<accelerators: list<record>, advancedMachineFeatures: record<threadsPerCore: string>, bootDiskKmsKey: string, confidentialNodes: record<enabled: bool>, diskSizeGb: int, diskType: string, ephemeralStorageConfig: record<localSsdCount: int>, ephemeralStorageLocalSsdConfig: record<localSsdCount: int>, fastSocket: record<enabled: bool>, gcfsConfig: record<enabled: bool>, gvnic: record<enabled: bool>, imageType: string, kubeletConfig: record<cpuCfsQuota: bool, cpuCfsQuotaPeriod: string, cpuManagerPolicy: string, podPidsLimit: string>, labels: record, linuxNodeConfig: record<cgroupMode: string, sysctls: record>, localNvmeSsdBlockConfig: record<localSsdCount: int>, localSsdCount: int, loggingConfig: record<variantConfig: record>, machineType: string, metadata: record, minCpuPlatform: string, nodeGroup: string, oauthScopes: list<string>, preemptible: bool, reservationAffinity: record<consumeReservationType: string, key: string, values: list>, resourceLabels: record, sandboxConfig: record<sandboxType: string, type: string>, serviceAccount: string, shieldedInstanceConfig: record<enableIntegrityMonitoring: bool, enableSecureBoot: bool>, spot: bool, tags: list<string>, taints: list<record>, windowsNodeConfig: record<osVersion: string>, workloadMetadataConfig: record<mode: string, nodeMetadata: string>>, nodeIpv4CidrSize: int, nodePoolAutoConfig: record<networkTags: record<tags: list>>, nodePoolDefaults: record<nodeConfigDefaults: record<gcfsConfig: record, loggingConfig: record>>, nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>, notificationConfig: record<pubsub: record<enabled: bool, filter: record, topic: string>>, podSecurityPolicyConfig: record<enabled: bool>, privateCluster: bool, privateClusterConfig: record<enablePrivateEndpoint: bool, enablePrivateNodes: bool, masterGlobalAccessConfig: record<enabled: bool>, masterIpv4CidrBlock: string, peeringName: string, privateEndpoint: string, privateEndpointSubnetwork: string, publicEndpoint: string>, protectConfig: record<workloadConfig: record<auditMode: string>, workloadVulnerabilityMode: string>, releaseChannel: record<channel: string>, resourceLabels: record, resourceUsageExportConfig: record<bigqueryDestination: record<datasetId: string>, consumptionMeteringConfig: record<enabled: bool>, enableNetworkEgressMetering: bool>, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record<enabled: bool>, status: string, statusMessage: string, subnetwork: string, tpuConfig: record<enabled: bool, ipv4CidrBlock: string, useServiceNetworking: bool>, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record<enabled: bool>, workloadAltsConfig: record<enableAlts: bool>, workloadCertificates: record<enableCertificates: bool>, workloadIdentityConfig: record<identityNamespace: string, identityProvider: string, workloadPool: string>, zone: string>
# operationId: container.projects.zones.clusters.get
export def "container-projects-zones-clusters-get" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, cluster) of the cluster to retrieve. Specified in the format `projects/*/locations/*/clusters/*`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the settings for a specific cluster.
#
# PUT /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.update
export def "container-projects-zones-clusters-update" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster) of the cluster to update. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --update: record # ClusterUpdate describes an update to the cluster. Exactly one update can be applied to a cluster with each request, so at most one field can be provided. — shape: {additionalPodRangesConfig?: record, desiredAddonsConfig?: record, desiredAuthenticatorGroupsConfig?: record, desiredBinaryAuthorization?: record, desiredClusterAutoscaling?: record, desiredClusterTelemetry?: record, desiredCostManagementConfig?: record, desiredDatabaseEncryption?: record, desiredDatapathProvider?: "DATAPATH_PROVIDER_UNSPECIFIED"|"LEGACY_DATAPATH"|"ADVANCED_DATAPATH", desiredDefaultSnatStatus?: record, desiredDnsConfig?: record, desiredEnablePrivateEndpoint?: bool, ... (37 more fields)}
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: update, var: update}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, name: $name, body_project_id: $body_project_id, update: $update, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the addons for a specific cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/addons
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.addons
export def "container-projects-zones-clusters-addons" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --addons-config: record # Configuration for the addons that can be automatically spun up in the cluster, enabling additional functionality. — shape: {cloudRunConfig?: record, configConnectorConfig?: record, dnsCacheConfig?: record, gcePersistentDiskCsiDriverConfig?: record, gcpFilestoreCsiDriverConfig?: record, gkeBackupAgentConfig?: record, horizontalPodAutoscaling?: record, httpLoadBalancing?: record, istioConfig?: record, kalmConfig?: record, kubernetesDashboard?: record, networkPolicyConfig?: record}
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster) of the cluster to set addons. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/addons"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: addonsConfig, var: addons_config}, {name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, addons_config: $addons_config, body_cluster_id: $body_cluster_id, name: $name, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables or disables the ABAC authorization mechanism on a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/legacyAbac
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.legacyAbac
export def "container-projects-zones-clusters-legacy-abac" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --enabled: oneof<nothing, bool> # Required. Whether ABAC authorization will be enabled in the cluster.
  --name: string # The name (project, location, cluster name) of the cluster to set legacy abac. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/legacyAbac"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: enabled, var: enabled}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, enabled: $enabled, name: $name, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the locations for a specific cluster. Deprecated. Use [projects.locations.clusters.update](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters/update) instead.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/locations
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.locations
export def "container-projects-zones-clusters-locations" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --locations: list<string> # Required. The desired list of Google Compute Engine [zones](https://cloud.google.com/compute/docs/zones#available) in which the cluster's nodes should be located. Changing the locations a cluster is in will result in nodes being either created or removed from the cluster, depending on whether locations are being added or removed. This list must always include the cluster's primary zone.
  --name: string # The name (project, location, cluster) of the cluster to set locations. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/locations"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: locations, var: locations}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, locations: $locations, name: $name, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the logging service for a specific cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/logging
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.logging
export def "container-projects-zones-clusters-logging" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --logging-service: string # Required. The logging service the cluster should use to write logs. Currently available options: * `logging.googleapis.com/kubernetes` - The Cloud Logging service with a Kubernetes-native resource model * `logging.googleapis.com` - The legacy Cloud Logging service (no longer available as of GKE 1.15). * `none` - no logs will be exported from the cluster. If left as an empty string,`logging.googleapis.com/kubernetes` will be used for GKE 1.14+ or `logging.googleapis.com` for earlier versions.
  --name: string # The name (project, location, cluster) of the cluster to set logging. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/logging"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: loggingService, var: logging_service}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, logging_service: $logging_service, name: $name, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the master for a specific cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/master
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.master
export def "container-projects-zones-clusters-master" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --master-version: string # Required. The Kubernetes version to change the master to. Users may specify either explicit versions offered by Kubernetes Engine or version aliases, which have the following behavior: - "latest": picks the highest valid Kubernetes version - "1.X": picks the highest valid patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version - "-": picks the default Kubernetes version
  --name: string # The name (project, location, cluster) of the cluster to update. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/master"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: masterVersion, var: master_version}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, master_version: $master_version, name: $name, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the monitoring service for a specific cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/monitoring
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.monitoring
export def "container-projects-zones-clusters-monitoring" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --monitoring-service: string # Required. The monitoring service the cluster should use to write metrics. Currently available options: * "monitoring.googleapis.com/kubernetes" - The Cloud Monitoring service with a Kubernetes-native resource model * `monitoring.googleapis.com` - The legacy Cloud Monitoring service (no longer available as of GKE 1.15). * `none` - No metrics will be exported from the cluster. If left as an empty string,`monitoring.googleapis.com/kubernetes` will be used for GKE 1.14+ or `monitoring.googleapis.com` for earlier versions.
  --name: string # The name (project, location, cluster) of the cluster to set monitoring. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/monitoring"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: monitoringService, var: monitoring_service}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, monitoring_service: $monitoring_service, name: $name, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the node pools for a cluster.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools
# Returns: record<nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>>
# operationId: container.projects.zones.clusters.nodePools.list
export def "container-projects-zones-clusters-node-pools-list" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # The parent (project, location, cluster name) where the node pools will be listed. Specified in the format `projects/*/locations/*/clusters/*`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: parent, var: parent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a node pool for a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.nodePools.create
export def "container-projects-zones-clusters-node-pools-create" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the parent field. (spec name: clusterId)
  --node-pool: record # NodePool contains the name and configuration for a cluster's node pool. Node pools are a set of nodes (i.e. VM's), with a common configuration and specification, under the control of the cluster master. They may have a set of Kubernetes labels applied to them, which may be used to reference them during pod scheduling. They may also be resized up or down, to accommodate the workload. These upgrade settings control the level of parallelism and the level of disruption caused by an upgrade. maxUnavailable controls the number of nodes that can be simultaneously unavailable. maxSurge controls the number of additional nodes that can be added to the node pool temporarily for the time of the upgrade to increase the number of available nodes. (maxUnavailable + maxSurge) determines the level of parallelism (how many nodes are being upgraded at the same time). Note: upgrades inevitably introduce some disruption since workloads need to be moved from old nodes to new, upgraded ones. Even if maxUnavailable=0, this holds true. (Disruption stays within the limits of PodDisruptionBudget, if it is configured.) Consider a hypothetical node pool with 5 nodes having maxSurge=2, maxUnavailable=1. This means the upgrade process upgrades 3 nodes simultaneously. It creates 2 additional (upgraded) nodes, then it brings down 3 old (not yet upgraded) nodes at the same time. This ensures that there are always at least 4 nodes available. — shape: {autoscaling?: record, conditions?: list, config?: record, etag?: string, initialNodeCount?: int, instanceGroupUrls?: list<string>, locations?: list<string>, management?: record, maxPodsConstraint?: record, name?: string, networkConfig?: record, placementPolicy?: record, podIpv4CidrSize?: int, selfLink?: string, status?: "STATUS_UNSPECIFIED"|"PROVISIONING"|"RUNNING"|"RUNNING_WITH_ERROR"|"RECONCILING"|"STOPPING"|"ERROR", statusMessage?: string, updateInfo?: record, upgradeSettings?: record, ... (1 more fields)}
  --parent: string # The parent (project, location, cluster name) where the node pool will be created. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: nodePool, var: node_pool}, {name: parent, var: parent}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, node_pool: $node_pool, parent: $parent, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a node pool from a cluster.
#
# DELETE /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.nodePools.delete
export def "container-projects-zones-clusters-node-pools-delete" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, cluster, node pool id) of the node pool to delete. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}, {name: nodePoolId, var: node_pool_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, node_pool_id: $node_pool_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the requested node pool.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}
# Returns: record<autoscaling: record<autoprovisioned: bool, enabled: bool, locationPolicy: string, maxNodeCount: int, minNodeCount: int, totalMaxNodeCount: int, totalMinNodeCount: int>, conditions: table<canonicalCode: string, code: string, message: string>, config: record<accelerators: list<record>, advancedMachineFeatures: record<threadsPerCore: string>, bootDiskKmsKey: string, confidentialNodes: record<enabled: bool>, diskSizeGb: int, diskType: string, ephemeralStorageConfig: record<localSsdCount: int>, ephemeralStorageLocalSsdConfig: record<localSsdCount: int>, fastSocket: record<enabled: bool>, gcfsConfig: record<enabled: bool>, gvnic: record<enabled: bool>, imageType: string, kubeletConfig: record<cpuCfsQuota: bool, cpuCfsQuotaPeriod: string, cpuManagerPolicy: string, podPidsLimit: string>, labels: record, linuxNodeConfig: record<cgroupMode: string, sysctls: record>, localNvmeSsdBlockConfig: record<localSsdCount: int>, localSsdCount: int, loggingConfig: record<variantConfig: record>, machineType: string, metadata: record, minCpuPlatform: string, nodeGroup: string, oauthScopes: list<string>, preemptible: bool, reservationAffinity: record<consumeReservationType: string, key: string, values: list>, resourceLabels: record, sandboxConfig: record<sandboxType: string, type: string>, serviceAccount: string, shieldedInstanceConfig: record<enableIntegrityMonitoring: bool, enableSecureBoot: bool>, spot: bool, tags: list<string>, taints: list<record>, windowsNodeConfig: record<osVersion: string>, workloadMetadataConfig: record<mode: string, nodeMetadata: string>>, etag: string, initialNodeCount: int, instanceGroupUrls: list<string>, locations: list<string>, management: record<autoRepair: bool, autoUpgrade: bool, upgradeOptions: record<autoUpgradeStartTime: string, description: string>>, maxPodsConstraint: record<maxPodsPerNode: string>, name: string, networkConfig: record<createPodRange: bool, enablePrivateNodes: bool, networkPerformanceConfig: record<externalIpEgressBandwidthTier: string, totalEgressBandwidthTier: string>, podCidrOverprovisionConfig: record<disable: bool>, podIpv4CidrBlock: string, podRange: string>, placementPolicy: record<type: string>, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record<blueGreenInfo: record<blueInstanceGroupUrls: list, bluePoolDeletionStartTime: string, greenInstanceGroupUrls: list, greenPoolVersion: string, phase: string>>, upgradeSettings: record<blueGreenSettings: record<nodePoolSoakDuration: string, standardRolloutPolicy: record>, maxSurge: int, maxUnavailable: int, strategy: string>, version: string>
# operationId: container.projects.zones.clusters.nodePools.get
export def "container-projects-zones-clusters-node-pools-get" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, cluster, node pool id) of the node pool to get. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}, {name: nodePoolId, var: node_pool_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, node_pool_id: $node_pool_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the autoscaling settings of a specific node pool.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/autoscaling
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.nodePools.autoscaling
export def "container-projects-zones-clusters-node-pools-autoscaling" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --autoscaling: record # NodePoolAutoscaling contains information required by cluster autoscaler to adjust the size of the node pool to the current cluster usage. — shape: {autoprovisioned?: bool, enabled?: bool, locationPolicy?: "LOCATION_POLICY_UNSPECIFIED"|"BALANCED"|"ANY", maxNodeCount?: int, minNodeCount?: int, totalMaxNodeCount?: int, totalMinNodeCount?: int}
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster, node pool) of the node pool to set autoscaler settings. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to upgrade. This field has been deprecated and replaced by the name field. (spec name: nodePoolId)
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/autoscaling"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}, {name: nodePoolId, var: node_pool_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoscaling, var: autoscaling}, {name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: nodePoolId, var: body_node_pool_id}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, node_pool_id: $node_pool_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, autoscaling: $autoscaling, body_cluster_id: $body_cluster_id, name: $name, body_node_pool_id: $body_node_pool_id, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the NodeManagement options for a node pool.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/setManagement
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.nodePools.setManagement
export def "container-projects-zones-clusters-node-pools-set-management" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --management: record # NodeManagement defines the set of node management services turned on for the node pool. — shape: {autoRepair?: bool, autoUpgrade?: bool, upgradeOptions?: record}
  --name: string # The name (project, location, cluster, node pool id) of the node pool to set management properties. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to update. This field has been deprecated and replaced by the name field. (spec name: nodePoolId)
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/setManagement"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}, {name: nodePoolId, var: node_pool_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: management, var: management}, {name: name, var: name}, {name: nodePoolId, var: body_node_pool_id}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, node_pool_id: $node_pool_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, management: $management, name: $name, body_node_pool_id: $body_node_pool_id, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SetNodePoolSizeRequest sets the size of a node pool. The new size will be used for all replicas, including future replicas created by modifying NodePool.locations.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/setSize
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.nodePools.setSize
export def "container-projects-zones-clusters-node-pools-set-size" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster, node pool id) of the node pool to set size. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-count: int # Required. The desired node count for the pool. (format: int32)
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to update. This field has been deprecated and replaced by the name field. (spec name: nodePoolId)
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/setSize"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}, {name: nodePoolId, var: node_pool_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: nodeCount, var: node_count}, {name: nodePoolId, var: body_node_pool_id}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, node_pool_id: $node_pool_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, name: $name, node_count: $node_count, body_node_pool_id: $body_node_pool_id, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the version and/or image type of a specific node pool.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/update
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.nodePools.update
export def "container-projects-zones-clusters-node-pools-update" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --confidential-nodes: record # ConfidentialNodes is configuration for the confidential nodes feature, which makes nodes run on confidential VMs. — shape: {enabled?: bool}
  --etag: string # The current etag of the node pool. If an etag is provided and does not match the current etag of the node pool, update will be blocked and an ABORTED error will be returned.
  --fast-socket: record # Configuration of Fast Socket feature. — shape: {enabled?: bool}
  --gcfs-config: record # GcfsConfig contains configurations of Google Container File System. — shape: {enabled?: bool}
  --gvnic: record # Configuration of gVNIC feature. — shape: {enabled?: bool}
  --image-type: string # Required. The desired image type for the node pool. Please see https://cloud.google.com/kubernetes-engine/docs/concepts/node-images for available image types.
  --kubelet-config: record # Node kubelet configs. — shape: {cpuCfsQuota?: bool, cpuCfsQuotaPeriod?: string, cpuManagerPolicy?: string, podPidsLimit?: string}
  --labels: record # Collection of node-level [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels). — shape: {labels?: record}
  --linux-node-config: record # Parameters that can be configured on Linux nodes. — shape: {cgroupMode?: "CGROUP_MODE_UNSPECIFIED"|"CGROUP_MODE_V1"|"CGROUP_MODE_V2", sysctls?: record}
  --locations: list<string> # The desired list of Google Compute Engine [zones](https://cloud.google.com/compute/docs/zones#available) in which the node pool's nodes should be located. Changing the locations for a node pool will result in nodes being either created or removed from the node pool, depending on whether locations are being added or removed.
  --logging-config: record # NodePoolLoggingConfig specifies logging configuration for nodepools. — shape: {variantConfig?: record}
  --name: string # The name (project, location, cluster, node pool) of the node pool to update. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --node-network-config: record # Parameters for node pool-level network config. — shape: {createPodRange?: bool, enablePrivateNodes?: bool, networkPerformanceConfig?: record, podCidrOverprovisionConfig?: record, podIpv4CidrBlock?: string, podRange?: string}
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to upgrade. This field has been deprecated and replaced by the name field. (spec name: nodePoolId)
  --node-version: string # Required. The Kubernetes version to change the nodes to (typically an upgrade). Users may specify either explicit versions offered by Kubernetes Engine or version aliases, which have the following behavior: - "latest": picks the highest valid Kubernetes version - "1.X": picks the highest valid patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version - "-": picks the Kubernetes master version
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --resource-labels: record # Collection of [GCP labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels). — shape: {labels?: record}
  --tags: record # Collection of Compute Engine network tags that can be applied to a node's underlying VM instance. (See `tags` field in [`NodeConfig`](/kubernetes-engine/docs/reference/rest/v1/NodeConfig)). — shape: {tags?: list<string>}
  --taints: record # Collection of Kubernetes [node taints](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration). — shape: {taints?: list}
  --upgrade-settings: record # These upgrade settings configure the upgrade strategy for the node pool. Use strategy to switch between the strategies applied to the node pool. If the strategy is SURGE, use max_surge and max_unavailable to control the level of parallelism and the level of disruption caused by upgrade. 1. maxSurge controls the number of additional nodes that can be added to the node pool temporarily for the time of the upgrade to increase the number of available nodes. 2. maxUnavailable controls the number of nodes that can be simultaneously unavailable. 3. (maxUnavailable + maxSurge) determines the level of parallelism (how many nodes are being upgraded at the same time). If the strategy is BLUE_GREEN, use blue_green_settings to configure the blue-green upgrade related settings. 1. standard_rollout_policy is the default policy. The policy is used to control the way blue pool gets drained. The draining is executed in the batch mode. The batch size could be specified as either percentage of the node pool size or the number of nodes. batch_soak_duration is the soak time after each batch gets drained. 2. node_pool_soak_duration is the soak time after all blue nodes are drained. After this period, the blue pool nodes will be deleted. — shape: {blueGreenSettings?: record, maxSurge?: int, maxUnavailable?: int, strategy?: "NODE_POOL_UPDATE_STRATEGY_UNSPECIFIED"|"BLUE_GREEN"|"SURGE"}
  --windows-node-config: record # Parameters that can be configured on Windows nodes. Windows Node Config that define the parameters that will be used to configure the Windows node pool settings — shape: {osVersion?: "OS_VERSION_UNSPECIFIED"|"OS_VERSION_LTSC2019"|"OS_VERSION_LTSC2022"}
  --workload-metadata-config: record # WorkloadMetadataConfig defines the metadata configuration to expose to workloads on the node pool. — shape: {mode?: "MODE_UNSPECIFIED"|"GCE_METADATA"|"GKE_METADATA", nodeMetadata?: "UNSPECIFIED"|"SECURE"|"EXPOSE"|"GKE_METADATA_SERVER"}
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}/update"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}, {name: nodePoolId, var: node_pool_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: confidentialNodes, var: confidential_nodes}, {name: etag, var: etag}, {name: fastSocket, var: fast_socket}, {name: gcfsConfig, var: gcfs_config}, {name: gvnic, var: gvnic}, {name: imageType, var: image_type}, {name: kubeletConfig, var: kubelet_config}, {name: labels, var: labels}, {name: linuxNodeConfig, var: linux_node_config}, {name: locations, var: locations}, {name: loggingConfig, var: logging_config}, {name: name, var: name}, {name: nodeNetworkConfig, var: node_network_config}, {name: nodePoolId, var: body_node_pool_id}, {name: nodeVersion, var: node_version}, {name: projectId, var: body_project_id}, {name: resourceLabels, var: resource_labels}, {name: tags, var: tags}, {name: taints, var: taints}, {name: upgradeSettings, var: upgrade_settings}, {name: windowsNodeConfig, var: windows_node_config}, {name: workloadMetadataConfig, var: workload_metadata_config}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, node_pool_id: $node_pool_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, confidential_nodes: $confidential_nodes, etag: $etag, fast_socket: $fast_socket, gcfs_config: $gcfs_config, gvnic: $gvnic, image_type: $image_type, kubelet_config: $kubelet_config, labels: $labels, linux_node_config: $linux_node_config, locations: $locations, logging_config: $logging_config, name: $name, node_network_config: $node_network_config, body_node_pool_id: $body_node_pool_id, node_version: $node_version, body_project_id: $body_project_id, resource_labels: $resource_labels, tags: $tags, taints: $taints, upgrade_settings: $upgrade_settings, windows_node_config: $windows_node_config, workload_metadata_config: $workload_metadata_config, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rolls back a previously Aborted or Failed NodePool upgrade. This makes no changes if the last upgrade successfully completed.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}:rollback
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.nodePools.rollback
export def "container-projects-zones-clusters-node-pools-rollback" [
  project_id: string
  zone: string
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to rollback. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster, node pool id) of the node poll to rollback upgrade. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`.
  --body-node-pool-id: string # Required. Deprecated. The name of the node pool to rollback. This field has been deprecated and replaced by the name field. (spec name: nodePoolId)
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --respect-pdb: oneof<nothing, bool> # Option for rollback to ignore the PodDisruptionBudget. Default value is false.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/nodePools/{nodePoolId}:rollback"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}, {name: nodePoolId, var: node_pool_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: nodePoolId, var: body_node_pool_id}, {name: projectId, var: body_project_id}, {name: respectPdb, var: respect_pdb}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, node_pool_id: $node_pool_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, name: $name, body_node_pool_id: $body_node_pool_id, body_project_id: $body_project_id, respect_pdb: $respect_pdb, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets labels on a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/resourceLabels
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.resourceLabels
export def "container-projects-zones-clusters-resource-labels" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --label-fingerprint: string # Required. The fingerprint of the previous set of labels for this resource, used to detect conflicts. The fingerprint is initially generated by Kubernetes Engine and changes after every request to modify or update labels. You must always provide an up-to-date fingerprint hash when updating or changing labels. Make a `get()` request to the resource to get the latest fingerprint.
  --name: string # The name (project, location, cluster name) of the cluster to set labels. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --resource-labels: record # Required. The labels to set for that cluster.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}/resourceLabels"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: labelFingerprint, var: label_fingerprint}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: resourceLabels, var: resource_labels}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, label_fingerprint: $label_fingerprint, name: $name, body_project_id: $body_project_id, resource_labels: $resource_labels, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completes master IP rotation.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:completeIpRotation
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.completeIpRotation
export def "container-projects-zones-clusters-complete-ip-rotation" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster name) of the cluster to complete IP rotation. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:completeIpRotation"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, name: $name, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the maintenance policy for a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setMaintenancePolicy
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.setMaintenancePolicy
export def "container-projects-zones-clusters-set-maintenance-policy" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. The name of the cluster to update. (spec name: clusterId)
  --maintenance-policy: record # MaintenancePolicy defines the maintenance policy to be used for the cluster. — shape: {resourceVersion?: string, window?: record}
  --name: string # The name (project, location, cluster name) of the cluster to set maintenance policy. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). (spec name: projectId)
  --body-zone: string # Required. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setMaintenancePolicy"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: maintenancePolicy, var: maintenance_policy}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, maintenance_policy: $maintenance_policy, name: $name, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets master auth materials. Currently supports changing the admin password or a specific cluster, either via password generation or explicitly setting the password.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setMasterAuth
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.setMasterAuth
export def "container-projects-zones-clusters-set-master-auth" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --action: string@action-completer # Required. The exact form of action to be taken on the master auth.
  --body-cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster) of the cluster to set auth. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --update: record # The authentication information for accessing the master endpoint. Authentication can be done using HTTP basic auth or using client certificates. — shape: {clientCertificate?: string, clientCertificateConfig?: record, clientKey?: string, clusterCaCertificate?: string, password?: string, username?: string}
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setMasterAuth"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: update, var: update}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action, body_cluster_id: $body_cluster_id, name: $name, body_project_id: $body_project_id, update: $update, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables or disables Network Policy for a cluster.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setNetworkPolicy
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.setNetworkPolicy
export def "container-projects-zones-clusters-set-network-policy" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster name) of the cluster to set networking policy. Specified in the format `projects/*/locations/*/clusters/*`.
  --network-policy: record # Configuration options for the NetworkPolicy feature. https://kubernetes.io/docs/concepts/services-networking/networkpolicies/ — shape: {enabled?: bool, provider?: "PROVIDER_UNSPECIFIED"|"CALICO"}
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:setNetworkPolicy"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: networkPolicy, var: network_policy}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, name: $name, network_policy: $network_policy, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts master IP rotation.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:startIpRotation
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.clusters.startIpRotation
export def "container-projects-zones-clusters-start-ip-rotation" [
  project_id: string
  zone: string
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field. (spec name: clusterId)
  --name: string # The name (project, location, cluster name) of the cluster to start IP rotation. Specified in the format `projects/*/locations/*/clusters/*`.
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --rotate-credentials: oneof<nothing, bool> # Whether to rotate credentials during IP rotation.
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/clusters/{clusterId}:startIpRotation"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: clusterId, var: cluster_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: body_cluster_id}, {name: name, var: name}, {name: projectId, var: body_project_id}, {name: rotateCredentials, var: rotate_credentials}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, cluster_id: $cluster_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_cluster_id: $body_cluster_id, name: $name, body_project_id: $body_project_id, rotate_credentials: $rotate_credentials, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all operations in a project in the specified zone or all zones.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/operations
# Returns: record<missingZones: list<string>, operations: table<clusterConditions: list, detail: string, endTime: string, error: record, location: string, name: string, nodepoolConditions: list, operationType: string, progress: record, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>>
# operationId: container.projects.zones.operations.list
export def "container-projects-zones-operations-list" [
  project_id: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # The parent (project and location) where the operations will be listed. Specified in the format `projects/*/locations/*`. Location "-" matches all zones and all regions.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/projects/{projectId}/zones/{zone}/operations"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: parent, var: parent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified operation.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/operations/{operationId}
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.zones.operations.get
export def "container-projects-zones-operations-get" [
  project_id: string
  zone: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, operation id) of the operation to get. Specified in the format `projects/*/locations/*/operations/*`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/projects/{projectId}/zones/{zone}/operations/{operationId}"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: operationId, var: operation_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, operation_id: $operation_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the specified operation.
#
# POST /v1beta1/projects/{projectId}/zones/{zone}/operations/{operationId}:cancel
# Returns: record
# operationId: container.projects.zones.operations.cancel
export def "container-projects-zones-operations-cancel" [
  project_id: string
  zone: string
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project, location, operation id) of the operation to cancel. Specified in the format `projects/*/locations/*/operations/*`.
  --body-operation-id: string # Required. Deprecated. The server-assigned `name` of the operation. This field has been deprecated and replaced by the name field. (spec name: operationId)
  --body-project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field. (spec name: projectId)
  --body-zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the operation resides. This field has been deprecated and replaced by the name field. (spec name: zone)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/projects/{projectId}/zones/{zone}/operations/{operationId}:cancel"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}, {name: operationId, var: operation_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: operationId, var: body_operation_id}, {name: projectId, var: body_project_id}, {name: zone, var: body_zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, operation_id: $operation_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name, body_operation_id: $body_operation_id, body_project_id: $body_project_id, body_zone: $body_zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns configuration info about the Google Kubernetes Engine service.
#
# GET /v1beta1/projects/{projectId}/zones/{zone}/serverconfig
# Returns: record<channels: table<availableVersions: list, channel: string, defaultVersion: string, validVersions: list>, defaultClusterVersion: string, defaultImageType: string, validImageTypes: list<string>, validMasterVersions: list<string>, validNodeVersions: list<string>, windowsVersionMaps: record>
# operationId: container.projects.zones.getServerconfig
export def "container-projects-zones-get-serverconfig" [
  project_id: string
  zone: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --name: string # The name (project and location) of the server config to get, specified in the format `projects/*/locations/*`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/projects/{projectId}/zones/{zone}/serverconfig"
    path_params: [{name: projectId, var: project_id}, {name: zone, var: zone}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_id: $project_id, zone: $zone, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a node pool from a cluster.
#
# DELETE /v1beta1/{name}
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.nodePools.delete
export def "container-projects-locations-clusters-node-pools-delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --node-pool-id: string # Required. Deprecated. The name of the node pool to delete. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clusterId, var: cluster_id}, {name: nodePoolId, var: node_pool_id}, {name: projectId, var: project_id}, {name: zone, var: zone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, node_pool_id: $node_pool_id, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified operation.
#
# GET /v1beta1/{name}
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.operations.get
export def "container-projects-locations-operations-get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --operation-id: string # Required. Deprecated. The server-assigned `name` of the operation. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: operationId, var: operation_id}, {name: projectId, var: project_id}, {name: zone, var: zone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, operation_id: $operation_id, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the version and/or image type of a specific node pool.
#
# PUT /v1beta1/{name}
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.nodePools.update
export def "container-projects-locations-clusters-node-pools-update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --confidential-nodes: record # ConfidentialNodes is configuration for the confidential nodes feature, which makes nodes run on confidential VMs. — shape: {enabled?: bool}
  --etag: string # The current etag of the node pool. If an etag is provided and does not match the current etag of the node pool, update will be blocked and an ABORTED error will be returned.
  --fast-socket: record # Configuration of Fast Socket feature. — shape: {enabled?: bool}
  --gcfs-config: record # GcfsConfig contains configurations of Google Container File System. — shape: {enabled?: bool}
  --gvnic: record # Configuration of gVNIC feature. — shape: {enabled?: bool}
  --image-type: string # Required. The desired image type for the node pool. Please see https://cloud.google.com/kubernetes-engine/docs/concepts/node-images for available image types.
  --kubelet-config: record # Node kubelet configs. — shape: {cpuCfsQuota?: bool, cpuCfsQuotaPeriod?: string, cpuManagerPolicy?: string, podPidsLimit?: string}
  --labels: record # Collection of node-level [Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels). — shape: {labels?: record}
  --linux-node-config: record # Parameters that can be configured on Linux nodes. — shape: {cgroupMode?: "CGROUP_MODE_UNSPECIFIED"|"CGROUP_MODE_V1"|"CGROUP_MODE_V2", sysctls?: record}
  --locations: list<string> # The desired list of Google Compute Engine [zones](https://cloud.google.com/compute/docs/zones#available) in which the node pool's nodes should be located. Changing the locations for a node pool will result in nodes being either created or removed from the node pool, depending on whether locations are being added or removed.
  --logging-config: record # NodePoolLoggingConfig specifies logging configuration for nodepools. — shape: {variantConfig?: record}
  --body-name: string # The name (project, location, cluster, node pool) of the node pool to update. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`. (spec name: name)
  --node-network-config: record # Parameters for node pool-level network config. — shape: {createPodRange?: bool, enablePrivateNodes?: bool, networkPerformanceConfig?: record, podCidrOverprovisionConfig?: record, podIpv4CidrBlock?: string, podRange?: string}
  --node-pool-id: string # Required. Deprecated. The name of the node pool to upgrade. This field has been deprecated and replaced by the name field.
  --node-version: string # Required. The Kubernetes version to change the nodes to (typically an upgrade). Users may specify either explicit versions offered by Kubernetes Engine or version aliases, which have the following behavior: - "latest": picks the highest valid Kubernetes version - "1.X": picks the highest valid patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version - "-": picks the Kubernetes master version
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --resource-labels: record # Collection of [GCP labels](https://cloud.google.com/resource-manager/docs/creating-managing-labels). — shape: {labels?: record}
  --tags: record # Collection of Compute Engine network tags that can be applied to a node's underlying VM instance. (See `tags` field in [`NodeConfig`](/kubernetes-engine/docs/reference/rest/v1/NodeConfig)). — shape: {tags?: list<string>}
  --taints: record # Collection of Kubernetes [node taints](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration). — shape: {taints?: list}
  --upgrade-settings: record # These upgrade settings configure the upgrade strategy for the node pool. Use strategy to switch between the strategies applied to the node pool. If the strategy is SURGE, use max_surge and max_unavailable to control the level of parallelism and the level of disruption caused by upgrade. 1. maxSurge controls the number of additional nodes that can be added to the node pool temporarily for the time of the upgrade to increase the number of available nodes. 2. maxUnavailable controls the number of nodes that can be simultaneously unavailable. 3. (maxUnavailable + maxSurge) determines the level of parallelism (how many nodes are being upgraded at the same time). If the strategy is BLUE_GREEN, use blue_green_settings to configure the blue-green upgrade related settings. 1. standard_rollout_policy is the default policy. The policy is used to control the way blue pool gets drained. The draining is executed in the batch mode. The batch size could be specified as either percentage of the node pool size or the number of nodes. batch_soak_duration is the soak time after each batch gets drained. 2. node_pool_soak_duration is the soak time after all blue nodes are drained. After this period, the blue pool nodes will be deleted. — shape: {blueGreenSettings?: record, maxSurge?: int, maxUnavailable?: int, strategy?: "NODE_POOL_UPDATE_STRATEGY_UNSPECIFIED"|"BLUE_GREEN"|"SURGE"}
  --windows-node-config: record # Parameters that can be configured on Windows nodes. Windows Node Config that define the parameters that will be used to configure the Windows node pool settings — shape: {osVersion?: "OS_VERSION_UNSPECIFIED"|"OS_VERSION_LTSC2019"|"OS_VERSION_LTSC2022"}
  --workload-metadata-config: record # WorkloadMetadataConfig defines the metadata configuration to expose to workloads on the node pool. — shape: {mode?: "MODE_UNSPECIFIED"|"GCE_METADATA"|"GKE_METADATA", nodeMetadata?: "UNSPECIFIED"|"SECURE"|"EXPOSE"|"GKE_METADATA_SERVER"}
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: confidentialNodes, var: confidential_nodes}, {name: etag, var: etag}, {name: fastSocket, var: fast_socket}, {name: gcfsConfig, var: gcfs_config}, {name: gvnic, var: gvnic}, {name: imageType, var: image_type}, {name: kubeletConfig, var: kubelet_config}, {name: labels, var: labels}, {name: linuxNodeConfig, var: linux_node_config}, {name: locations, var: locations}, {name: loggingConfig, var: logging_config}, {name: name, var: body_name}, {name: nodeNetworkConfig, var: node_network_config}, {name: nodePoolId, var: node_pool_id}, {name: nodeVersion, var: node_version}, {name: projectId, var: project_id}, {name: resourceLabels, var: resource_labels}, {name: tags, var: tags}, {name: taints, var: taints}, {name: upgradeSettings, var: upgrade_settings}, {name: windowsNodeConfig, var: windows_node_config}, {name: workloadMetadataConfig, var: workload_metadata_config}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, confidential_nodes: $confidential_nodes, etag: $etag, fast_socket: $fast_socket, gcfs_config: $gcfs_config, gvnic: $gvnic, image_type: $image_type, kubelet_config: $kubelet_config, labels: $labels, linux_node_config: $linux_node_config, locations: $locations, logging_config: $logging_config, body_name: $body_name, node_network_config: $node_network_config, node_pool_id: $node_pool_id, node_version: $node_version, project_id: $project_id, resource_labels: $resource_labels, tags: $tags, taints: $taints, upgrade_settings: $upgrade_settings, windows_node_config: $windows_node_config, workload_metadata_config: $workload_metadata_config, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns configuration info about the Google Kubernetes Engine service.
#
# GET /v1beta1/{name}/serverConfig
# Returns: record<channels: table<availableVersions: list, channel: string, defaultVersion: string, validVersions: list>, defaultClusterVersion: string, defaultImageType: string, validImageTypes: list<string>, validMasterVersions: list<string>, validNodeVersions: list<string>, windowsVersionMaps: record>
# operationId: container.projects.locations.getServerConfig
export def "container-projects-locations-get-server-config" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) to return operations for. This field has been deprecated and replaced by the name field.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{name}/serverConfig"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: projectId, var: project_id}, {name: zone, var: zone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels the specified operation.
#
# POST /v1beta1/{name}:cancel
# Returns: record
# operationId: container.projects.locations.operations.cancel
export def "container-projects-locations-operations-cancel" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-name: string # The name (project, location, operation id) of the operation to cancel. Specified in the format `projects/*/locations/*/operations/*`. (spec name: name)
  --operation-id: string # Required. Deprecated. The server-assigned `name` of the operation. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the operation resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:cancel"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: body_name}, {name: operationId, var: operation_id}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body_name: $body_name, operation_id: $operation_id, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completes master IP rotation.
#
# POST /v1beta1/{name}:completeIpRotation
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.completeIpRotation
export def "container-projects-locations-clusters-complete-ip-rotation" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster name) of the cluster to complete IP rotation. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:completeIpRotation"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, body_name: $body_name, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# CompleteNodePoolUpgrade will signal an on-going node pool upgrade to complete.
#
# POST /v1beta1/{name}:completeUpgrade
# Returns: record
# operationId: container.projects.locations.clusters.nodePools.completeUpgrade
export def "container-projects-locations-clusters-node-pools-complete-upgrade" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:completeUpgrade"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rolls back a previously Aborted or Failed NodePool upgrade. This makes no changes if the last upgrade successfully completed.
#
# POST /v1beta1/{name}:rollback
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.nodePools.rollback
export def "container-projects-locations-clusters-node-pools-rollback" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to rollback. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster, node pool id) of the node poll to rollback upgrade. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`. (spec name: name)
  --node-pool-id: string # Required. Deprecated. The name of the node pool to rollback. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --respect-pdb: oneof<nothing, bool> # Option for rollback to ignore the PodDisruptionBudget. Default value is false.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:rollback"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: name, var: body_name}, {name: nodePoolId, var: node_pool_id}, {name: projectId, var: project_id}, {name: respectPdb, var: respect_pdb}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, body_name: $body_name, node_pool_id: $node_pool_id, project_id: $project_id, respect_pdb: $respect_pdb, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the addons for a specific cluster.
#
# POST /v1beta1/{name}:setAddons
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setAddons
export def "container-projects-locations-clusters-set-addons" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --addons-config: record # Configuration for the addons that can be automatically spun up in the cluster, enabling additional functionality. — shape: {cloudRunConfig?: record, configConnectorConfig?: record, dnsCacheConfig?: record, gcePersistentDiskCsiDriverConfig?: record, gcpFilestoreCsiDriverConfig?: record, gkeBackupAgentConfig?: record, horizontalPodAutoscaling?: record, httpLoadBalancing?: record, istioConfig?: record, kalmConfig?: record, kubernetesDashboard?: record, networkPolicyConfig?: record}
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster) of the cluster to set addons. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setAddons"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: addonsConfig, var: addons_config}, {name: clusterId, var: cluster_id}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, addons_config: $addons_config, cluster_id: $cluster_id, body_name: $body_name, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the autoscaling settings of a specific node pool.
#
# POST /v1beta1/{name}:setAutoscaling
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.nodePools.setAutoscaling
export def "container-projects-locations-clusters-node-pools-set-autoscaling" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --autoscaling: record # NodePoolAutoscaling contains information required by cluster autoscaler to adjust the size of the node pool to the current cluster usage. — shape: {autoprovisioned?: bool, enabled?: bool, locationPolicy?: "LOCATION_POLICY_UNSPECIFIED"|"BALANCED"|"ANY", maxNodeCount?: int, minNodeCount?: int, totalMaxNodeCount?: int, totalMinNodeCount?: int}
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster, node pool) of the node pool to set autoscaler settings. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`. (spec name: name)
  --node-pool-id: string # Required. Deprecated. The name of the node pool to upgrade. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setAutoscaling"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: autoscaling, var: autoscaling}, {name: clusterId, var: cluster_id}, {name: name, var: body_name}, {name: nodePoolId, var: node_pool_id}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, autoscaling: $autoscaling, cluster_id: $cluster_id, body_name: $body_name, node_pool_id: $node_pool_id, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables or disables the ABAC authorization mechanism on a cluster.
#
# POST /v1beta1/{name}:setLegacyAbac
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setLegacyAbac
export def "container-projects-locations-clusters-set-legacy-abac" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --enabled: oneof<nothing, bool> # Required. Whether ABAC authorization will be enabled in the cluster.
  --body-name: string # The name (project, location, cluster name) of the cluster to set legacy abac. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setLegacyAbac"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: enabled, var: enabled}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, enabled: $enabled, body_name: $body_name, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the locations for a specific cluster. Deprecated. Use [projects.locations.clusters.update](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters/update) instead.
#
# POST /v1beta1/{name}:setLocations
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setLocations
export def "container-projects-locations-clusters-set-locations" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --locations: list<string> # Required. The desired list of Google Compute Engine [zones](https://cloud.google.com/compute/docs/zones#available) in which the cluster's nodes should be located. Changing the locations a cluster is in will result in nodes being either created or removed from the cluster, depending on whether locations are being added or removed. This list must always include the cluster's primary zone.
  --body-name: string # The name (project, location, cluster) of the cluster to set locations. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setLocations"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: locations, var: locations}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, locations: $locations, body_name: $body_name, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the logging service for a specific cluster.
#
# POST /v1beta1/{name}:setLogging
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setLogging
export def "container-projects-locations-clusters-set-logging" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --logging-service: string # Required. The logging service the cluster should use to write logs. Currently available options: * `logging.googleapis.com/kubernetes` - The Cloud Logging service with a Kubernetes-native resource model * `logging.googleapis.com` - The legacy Cloud Logging service (no longer available as of GKE 1.15). * `none` - no logs will be exported from the cluster. If left as an empty string,`logging.googleapis.com/kubernetes` will be used for GKE 1.14+ or `logging.googleapis.com` for earlier versions.
  --body-name: string # The name (project, location, cluster) of the cluster to set logging. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setLogging"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: loggingService, var: logging_service}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, logging_service: $logging_service, body_name: $body_name, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the maintenance policy for a cluster.
#
# POST /v1beta1/{name}:setMaintenancePolicy
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setMaintenancePolicy
export def "container-projects-locations-clusters-set-maintenance-policy" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. The name of the cluster to update.
  --maintenance-policy: record # MaintenancePolicy defines the maintenance policy to be used for the cluster. — shape: {resourceVersion?: string, window?: record}
  --body-name: string # The name (project, location, cluster name) of the cluster to set maintenance policy. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
  --zone: string # Required. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setMaintenancePolicy"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: maintenancePolicy, var: maintenance_policy}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, maintenance_policy: $maintenance_policy, body_name: $body_name, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the NodeManagement options for a node pool.
#
# POST /v1beta1/{name}:setManagement
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.nodePools.setManagement
export def "container-projects-locations-clusters-node-pools-set-management" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --management: record # NodeManagement defines the set of node management services turned on for the node pool. — shape: {autoRepair?: bool, autoUpgrade?: bool, upgradeOptions?: record}
  --body-name: string # The name (project, location, cluster, node pool id) of the node pool to set management properties. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`. (spec name: name)
  --node-pool-id: string # Required. Deprecated. The name of the node pool to update. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setManagement"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: management, var: management}, {name: name, var: body_name}, {name: nodePoolId, var: node_pool_id}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, management: $management, body_name: $body_name, node_pool_id: $node_pool_id, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets master auth materials. Currently supports changing the admin password or a specific cluster, either via password generation or explicitly setting the password.
#
# POST /v1beta1/{name}:setMasterAuth
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setMasterAuth
export def "container-projects-locations-clusters-set-master-auth" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --action: string@action-completer # Required. The exact form of action to be taken on the master auth.
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster) of the cluster to set auth. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --update: record # The authentication information for accessing the master endpoint. Authentication can be done using HTTP basic auth or using client certificates. — shape: {clientCertificate?: string, clientCertificateConfig?: record, clientKey?: string, clusterCaCertificate?: string, password?: string, username?: string}
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setMasterAuth"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: action, var: action}, {name: clusterId, var: cluster_id}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: update, var: update}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, action: $action, cluster_id: $cluster_id, body_name: $body_name, project_id: $project_id, update: $update, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the monitoring service for a specific cluster.
#
# POST /v1beta1/{name}:setMonitoring
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setMonitoring
export def "container-projects-locations-clusters-set-monitoring" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --monitoring-service: string # Required. The monitoring service the cluster should use to write metrics. Currently available options: * "monitoring.googleapis.com/kubernetes" - The Cloud Monitoring service with a Kubernetes-native resource model * `monitoring.googleapis.com` - The legacy Cloud Monitoring service (no longer available as of GKE 1.15). * `none` - No metrics will be exported from the cluster. If left as an empty string,`monitoring.googleapis.com/kubernetes` will be used for GKE 1.14+ or `monitoring.googleapis.com` for earlier versions.
  --body-name: string # The name (project, location, cluster) of the cluster to set monitoring. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setMonitoring"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: monitoringService, var: monitoring_service}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, monitoring_service: $monitoring_service, body_name: $body_name, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables or disables Network Policy for a cluster.
#
# POST /v1beta1/{name}:setNetworkPolicy
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setNetworkPolicy
export def "container-projects-locations-clusters-set-network-policy" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster name) of the cluster to set networking policy. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --network-policy: record # Configuration options for the NetworkPolicy feature. https://kubernetes.io/docs/concepts/services-networking/networkpolicies/ — shape: {enabled?: bool, provider?: "PROVIDER_UNSPECIFIED"|"CALICO"}
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setNetworkPolicy"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: name, var: body_name}, {name: networkPolicy, var: network_policy}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, body_name: $body_name, network_policy: $network_policy, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets labels on a cluster.
#
# POST /v1beta1/{name}:setResourceLabels
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.setResourceLabels
export def "container-projects-locations-clusters-set-resource-labels" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --label-fingerprint: string # Required. The fingerprint of the previous set of labels for this resource, used to detect conflicts. The fingerprint is initially generated by Kubernetes Engine and changes after every request to modify or update labels. You must always provide an up-to-date fingerprint hash when updating or changing labels. Make a `get()` request to the resource to get the latest fingerprint.
  --body-name: string # The name (project, location, cluster name) of the cluster to set labels. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --resource-labels: record # Required. The labels to set for that cluster.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setResourceLabels"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: labelFingerprint, var: label_fingerprint}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: resourceLabels, var: resource_labels}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, label_fingerprint: $label_fingerprint, body_name: $body_name, project_id: $project_id, resource_labels: $resource_labels, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SetNodePoolSizeRequest sets the size of a node pool. The new size will be used for all replicas, including future replicas created by modifying NodePool.locations.
#
# POST /v1beta1/{name}:setSize
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.nodePools.setSize
export def "container-projects-locations-clusters-node-pools-set-size" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to update. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster, node pool id) of the node pool to set size. Specified in the format `projects/*/locations/*/clusters/*/nodePools/*`. (spec name: name)
  --node-count: int # Required. The desired node count for the pool. (format: int32)
  --node-pool-id: string # Required. Deprecated. The name of the node pool to update. This field has been deprecated and replaced by the name field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:setSize"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: name, var: body_name}, {name: nodeCount, var: node_count}, {name: nodePoolId, var: node_pool_id}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, body_name: $body_name, node_count: $node_count, node_pool_id: $node_pool_id, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts master IP rotation.
#
# POST /v1beta1/{name}:startIpRotation
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.startIpRotation
export def "container-projects-locations-clusters-start-ip-rotation" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the name field.
  --body-name: string # The name (project, location, cluster name) of the cluster to start IP rotation. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --rotate-credentials: oneof<nothing, bool> # Whether to rotate credentials during IP rotation.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:startIpRotation"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: rotateCredentials, var: rotate_credentials}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, body_name: $body_name, project_id: $project_id, rotate_credentials: $rotate_credentials, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the master for a specific cluster.
#
# POST /v1beta1/{name}:updateMaster
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.updateMaster
export def "container-projects-locations-clusters-update-master" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster to upgrade. This field has been deprecated and replaced by the name field.
  --master-version: string # Required. The Kubernetes version to change the master to. Users may specify either explicit versions offered by Kubernetes Engine or version aliases, which have the following behavior: - "latest": picks the highest valid Kubernetes version - "1.X": picks the highest valid patch+gke.N patch in the 1.X version - "1.X.Y": picks the highest valid gke.N patch in the 1.X.Y version - "1.X.Y-gke.N": picks an explicit Kubernetes version - "-": picks the default Kubernetes version
  --body-name: string # The name (project, location, cluster) of the cluster to update. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: name)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the name field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the name field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{name}:updateMaster"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: masterVersion, var: master_version}, {name: name, var: body_name}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, master_version: $master_version, body_name: $body_name, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the OIDC discovery document for the cluster. See the [OpenID Connect Discovery 1.0 specification](https://openid.net/specs/openid-connect-discovery-1_0.html) for details. This API is not yet intended for general use, and is not available for all clusters.
#
# GET /v1beta1/{parent}/.well-known/openid-configuration
# Returns: record<cacheHeader: record<age: string, directive: string, expires: string>, claims_supported: list<string>, grant_types: list<string>, id_token_signing_alg_values_supported: list<string>, issuer: string, jwks_uri: string, response_types_supported: list<string>, subject_types_supported: list<string>>
# operationId: container.projects.locations.clusters.well-known.getOpenid-configuration
export def "container-projects-locations-clusters-well-known-get-openid-configuration" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/.well-known/openid-configuration"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists subnetworks that can be used for creating clusters in a project.
#
# GET /v1beta1/{parent}/aggregated/usableSubnetworks
# Returns: record<nextPageToken: string, subnetworks: table<ipCidrRange: string, network: string, secondaryIpRanges: list, statusMessage: string, subnetwork: string>>
# operationId: container.projects.aggregated.usableSubnetworks.list
export def "container-projects-aggregated-usable-subnetworks-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filtering currently only supports equality on the networkProjectId and must be in the form: "networkProjectId=[PROJECTID]", where `networkProjectId` is the project which owns the listed subnetworks. This defaults to the parent project ID.
  --page-size: int # The max number of results per page that should be returned. If the number of available results is larger than `page_size`, a `next_page_token` is returned which can be used to get the next page of results in subsequent requests. Acceptable values are 0 to 500, inclusive. (Default: 500)
  --page-token: string # Specifies a page token to use. Set this to the nextPageToken returned by previous list requests to get the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/aggregated/usableSubnetworks"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all clusters owned by a project in either the specified zone or all zones.
#
# GET /v1beta1/{parent}/clusters
# Returns: record<clusters: table<addonsConfig: record, authenticatorGroupsConfig: record, autopilot: record, autoscaling: record, binaryAuthorization: record, clusterIpv4Cidr: string, clusterTelemetry: record, conditions: list, confidentialNodes: record, costManagementConfig: record, createTime: string, currentMasterVersion: string, currentNodeCount: int, currentNodeVersion: string, databaseEncryption: record, defaultMaxPodsConstraint: record, description: string, enableKubernetesAlpha: bool, enableTpu: bool, endpoint: string, etag: string, expireTime: string, fleet: record, id: string, identityServiceConfig: record, initialClusterVersion: string, initialNodeCount: int, instanceGroupUrls: list, ipAllocationPolicy: record, labelFingerprint: string, legacyAbac: record, location: string, locations: list, loggingConfig: record, loggingService: string, maintenancePolicy: record, master: record, masterAuth: record, masterAuthorizedNetworksConfig: record, masterIpv4CidrBlock: string, meshCertificates: record, monitoringConfig: record, monitoringService: string, name: string, network: string, networkConfig: record, networkPolicy: record, nodeConfig: record, nodeIpv4CidrSize: int, nodePoolAutoConfig: record, nodePoolDefaults: record, nodePools: list, notificationConfig: record, podSecurityPolicyConfig: record, privateCluster: bool, privateClusterConfig: record, protectConfig: record, releaseChannel: record, resourceLabels: record, resourceUsageExportConfig: record, selfLink: string, servicesIpv4Cidr: string, shieldedNodes: record, status: string, statusMessage: string, subnetwork: string, tpuConfig: record, tpuIpv4CidrBlock: string, verticalPodAutoscaling: record, workloadAltsConfig: record, workloadCertificates: record, workloadIdentityConfig: record, zone: string>, missingZones: list<string>>
# operationId: container.projects.locations.clusters.list
export def "container-projects-locations-clusters-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides, or "-" for all zones. This field has been deprecated and replaced by the parent field.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/clusters"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: projectId, var: project_id}, {name: zone, var: zone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a cluster, consisting of the specified number and type of Google Compute Engine instances. By default, the cluster is created in the project's [default network](https://cloud.google.com/compute/docs/networks-and-firewalls#networks). One firewall is added for the cluster. After cluster creation, the Kubelet creates routes for each node to allow the containers on that node to communicate with all other instances in the cluster. Finally, an entry is added to the project's global metadata indicating which CIDR range the cluster is using.
#
# POST /v1beta1/{parent}/clusters
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.create
export def "container-projects-locations-clusters-create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster: record # A Google Kubernetes Engine cluster. — shape: {addonsConfig?: record, authenticatorGroupsConfig?: record, autopilot?: record, autoscaling?: record, binaryAuthorization?: record, clusterIpv4Cidr?: string, clusterTelemetry?: record, conditions?: list, confidentialNodes?: record, costManagementConfig?: record, createTime?: string, currentMasterVersion?: string, currentNodeCount?: int, currentNodeVersion?: string, databaseEncryption?: record, defaultMaxPodsConstraint?: record, description?: string, enableKubernetesAlpha?: bool, enableTpu?: bool, ... (53 more fields)}
  --body-parent: string # The parent (project and location) where the cluster will be created. Specified in the format `projects/*/locations/*`. (spec name: parent)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/clusters"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: cluster, var: cluster}, {name: parent, var: body_parent}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster: $cluster, body_parent: $body_parent, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the public component of the cluster signing keys in JSON Web Key format. This API is not yet intended for general use, and is not available for all clusters.
#
# GET /v1beta1/{parent}/jwks
# Returns: record<cacheHeader: record<age: string, directive: string, expires: string>, keys: table<alg: string, crv: string, e: string, kid: string, kty: string, n: string, use: string, x: string, y: string>>
# operationId: container.projects.locations.clusters.getJwks
export def "container-projects-locations-clusters-get-jwks" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/jwks"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches locations that offer Google Kubernetes Engine.
#
# GET /v1beta1/{parent}/locations
# Returns: record<locations: table<name: string, recommended: bool, type: string>, nextPageToken: string>
# operationId: container.projects.locations.list
export def "container-projects-locations-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/locations"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the node pools for a cluster.
#
# GET /v1beta1/{parent}/nodePools
# Returns: record<nodePools: table<autoscaling: record, conditions: list, config: record, etag: string, initialNodeCount: int, instanceGroupUrls: list, locations: list, management: record, maxPodsConstraint: record, name: string, networkConfig: record, placementPolicy: record, podIpv4CidrSize: int, selfLink: string, status: string, statusMessage: string, updateInfo: record, upgradeSettings: record, version: string>>
# operationId: container.projects.locations.clusters.nodePools.list
export def "container-projects-locations-clusters-node-pools-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the parent field.
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/nodePools"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: clusterId, var: cluster_id}, {name: projectId, var: project_id}, {name: zone, var: zone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a node pool for a cluster.
#
# POST /v1beta1/{parent}/nodePools
# Returns: record<clusterConditions: table<canonicalCode: string, code: string, message: string>, detail: string, endTime: string, error: record<code: int, details: list<record>, message: string>, location: string, name: string, nodepoolConditions: table<canonicalCode: string, code: string, message: string>, operationType: string, progress: record<metrics: list<record>, name: string, stages: list<any>, status: string>, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>
# operationId: container.projects.locations.clusters.nodePools.create
export def "container-projects-locations-clusters-node-pools-create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cluster-id: string # Required. Deprecated. The name of the cluster. This field has been deprecated and replaced by the parent field.
  --node-pool: record # NodePool contains the name and configuration for a cluster's node pool. Node pools are a set of nodes (i.e. VM's), with a common configuration and specification, under the control of the cluster master. They may have a set of Kubernetes labels applied to them, which may be used to reference them during pod scheduling. They may also be resized up or down, to accommodate the workload. These upgrade settings control the level of parallelism and the level of disruption caused by an upgrade. maxUnavailable controls the number of nodes that can be simultaneously unavailable. maxSurge controls the number of additional nodes that can be added to the node pool temporarily for the time of the upgrade to increase the number of available nodes. (maxUnavailable + maxSurge) determines the level of parallelism (how many nodes are being upgraded at the same time). Note: upgrades inevitably introduce some disruption since workloads need to be moved from old nodes to new, upgraded ones. Even if maxUnavailable=0, this holds true. (Disruption stays within the limits of PodDisruptionBudget, if it is configured.) Consider a hypothetical node pool with 5 nodes having maxSurge=2, maxUnavailable=1. This means the upgrade process upgrades 3 nodes simultaneously. It creates 2 additional (upgraded) nodes, then it brings down 3 old (not yet upgraded) nodes at the same time. This ensures that there are always at least 4 nodes available. — shape: {autoscaling?: record, conditions?: list, config?: record, etag?: string, initialNodeCount?: int, instanceGroupUrls?: list<string>, locations?: list<string>, management?: record, maxPodsConstraint?: record, name?: string, networkConfig?: record, placementPolicy?: record, podIpv4CidrSize?: int, selfLink?: string, status?: "STATUS_UNSPECIFIED"|"PROVISIONING"|"RUNNING"|"RUNNING_WITH_ERROR"|"RECONCILING"|"STOPPING"|"ERROR", statusMessage?: string, updateInfo?: record, upgradeSettings?: record, ... (1 more fields)}
  --body-parent: string # The parent (project, location, cluster name) where the node pool will be created. Specified in the format `projects/*/locations/*/clusters/*`. (spec name: parent)
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) in which the cluster resides. This field has been deprecated and replaced by the parent field.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta1/{parent}/nodePools"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clusterId, var: cluster_id}, {name: nodePool, var: node_pool}, {name: parent, var: body_parent}, {name: projectId, var: project_id}, {name: zone, var: zone}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, cluster_id: $cluster_id, node_pool: $node_pool, body_parent: $body_parent, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all operations in a project in the specified zone or all zones.
#
# GET /v1beta1/{parent}/operations
# Returns: record<missingZones: list<string>, operations: table<clusterConditions: list, detail: string, endTime: string, error: record, location: string, name: string, nodepoolConditions: list, operationType: string, progress: record, selfLink: string, startTime: string, status: string, statusMessage: string, targetLink: string, zone: string>>
# operationId: container.projects.locations.operations.list
export def "container-projects-locations-operations-list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # Required. Deprecated. The Google Developers Console [project ID or project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects). This field has been deprecated and replaced by the parent field.
  --zone: string # Required. Deprecated. The name of the Google Compute Engine [zone](https://cloud.google.com/compute/docs/zones#available) to return operations for, or `-` for all zones. This field has been deprecated and replaced by the parent field.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta1/{parent}/operations"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: projectId, var: project_id}, {name: zone, var: zone}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, project_id: $project_id, zone: $zone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
