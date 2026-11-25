# Auto-generated client for Docker HUB API vbeta
# Source: https://api.apis.guru/v2/specs/docker.com/hub/beta/openapi.json
# Auth: --token flag or $env.DOCKER_HUB_API_TOKEN

const CLIENT = {
  base_url: "https://hub.docker.com"
  token_env_var: "DOCKER_HUB_API_TOKEN"
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

def base-url-completer [] { ["https://hub.docker.com" "https://docker.com/1.33"] }
def auth-scheme-completer [] { ["none"] }

# Completers for enum parameters
def status-completer [] { ["active" "inactive"] }
def ordering-completer [] { ["-digest" "-last_activity" "digest" "last_activity"] }
def sort-order-completer [] { ["ascending" "descending"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-v2-access-tokens: "record<active_count: float, count: float, next: string, previous: string, results: table<client_id: string, created_at: string, creator_ip: string, creator_ua: string, generated_by: string, is_active: bool, last_used: string, scopes: list, token: string, token_label: string, uuid: string>>"
    post-v2-access-tokens: "record<client_id: string, created_at: string, creator_ip: string, creator_ua: string, generated_by: string, is_active: bool, last_used: string, scopes: list<string>, token: string, token_label: string, uuid: string>"
    get-v2-access-tokens-uuid: "record<client_id: string, created_at: string, creator_ip: string, creator_ua: string, generated_by: string, is_active: bool, last_used: string, scopes: list<string>, token: string, token_label: string, uuid: string>"
    patch-v2-access-tokens-uuid: "record<client_id: string, created_at: string, creator_ip: string, creator_ua: string, generated_by: string, is_active: bool, last_used: string, scopes: list<string>, token: string, token_label: string, uuid: string>"
    audit-logs-get-audit-logs: "record<logs: table<account: string, action: string, action_description: string, actor: string, data: record, name: string, timestamp: string>>"
    audit-logs-get-audit-actions: "record<actions: record>"
    post-namespaces-delete-images: "record<dry_run: bool, metrics: record<manifest_deletes: int, manifest_errors: int, tag_deletes: int, tag_errors: int>>"
    get-namespaces-repositories-images: "record<count: int, next: string, previous: string, results: table<digest: string, last_pulled: string, last_pushed: string, namespace: string, repository: string, status: string, tags: list>>"
    get-namespaces-repositories-images-summary: "record<active_from: string, statistics: record<active: int, inactive: int, total: int>>"
    get-namespaces-repositories-images-tags: "record<count: int, next: string, previous: string, results: table<is_current: bool, tag: string>>"
    get-v2-namespaces-namespace-repositories-repository-tags: "record<count: int, next: string, previous: string, results: table<creator: int, full_size: int, id: int, images: record, last_updated: string, last_updater: int, last_updater_username: string, name: string, repository: int, status: string, tag_last_pulled: string, tag_last_pushed: string, v2: string>>"
    head-v2-namespaces-namespace-repositories-repository-tags: "record"
    get-v2-namespaces-namespace-repositories-repository-tags-tag: "record<creator: int, full_size: int, id: int, images: record<architecture: string, digest: string, features: string, last_pulled: string, last_pushed: string, layers: list<record>, os: string, os_features: string, os_version: string, size: int, status: string, variant: string>, last_updated: string, last_updater: int, last_updater_username: string, name: string, repository: int, status: string, tag_last_pulled: string, tag_last_pushed: string, v2: string>"
    head-v2-namespaces-namespace-repositories-repository-tags-tag: "record"
    get-v2-orgs-name-settings: "record<restricted_images: record<allow_official_images: bool, allow_verified_publishers: bool, enabled: bool>>"
    put-v2-orgs-name-settings: "record<restricted_images: record<allow_official_images: bool, allow_verified_publishers: bool, enabled: bool>>"
    get-v2-scim-2-0-resource-types: "record<resources: table<description: string, endpoint: string, id: string, name: string, schema: string, schemas: list>, schemas: list<string>, totalResults: int>"
    get-v2-scim-2-0-resource-types-name: "record<description: string, endpoint: string, id: string, name: string, schema: string, schemas: list<string>>"
    get-v2-scim-2-0-schemas: "record<resources: table<attributes: list, description: string, id: string, name: string, schemas: list>, schemas: list<string>, totalResults: int>"
    get-v2-scim-2-0-schemas-id: "record<attributes: table<caseExact: bool, description: string, multiValued: bool, mutability: string, name: string, required: bool, returned: string, type: string, uniqueness: string, subAttributes: list>, description: string, id: string, name: string, schemas: list<string>>"
    get-v2-scim-2-0-service-provider-config: "record<authenticationSchemes: record<description: string, name: string, specUri: string, type: string>, bulk: record<maxOperations: int, maxPayloadSize: int, supported: bool>, changePassword: record<supported: bool>, documentationUri: string, etag: record<supported: bool>, filter: record<maxResults: int, supported: bool>, patch: record<supported: bool>, schemas: list<string>, sort: record<supported: bool>>"
    get-v2-scim-2-0-users: "record<itemsPerPage: int, resources: table<active: bool, displayName: string, emails: list, groups: list, id: string, meta: record, name: record, schemas: list, userName: string>, schemas: list<string>, startIndex: int, totalResults: int>"
    post-v2-scim-2-0-users: "record<active: bool, displayName: string, emails: table<display: string, primary: bool, value: string>, groups: table<display: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string>"
    get-v2-scim-2-0-users-id: "record<active: bool, displayName: string, emails: table<display: string, primary: bool, value: string>, groups: table<display: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string>"
    put-v2-scim-2-0-users-id: "record<active: bool, displayName: string, emails: table<display: string, primary: bool, value: string>, groups: table<display: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string>"
    post-users2-fa-login: "record<token: string>"
    post-users-login: "record<token: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-v2-access-tokens" "post-v2-access-tokens" "delete-v2-access-tokens-uuid" "get-v2-access-tokens-uuid" "patch-v2-access-tokens-uuid" "audit-logs-get-audit-logs" "audit-logs-get-audit-actions" "post-namespaces-delete-images" "get-namespaces-repositories-images" "get-namespaces-repositories-images-summary" "get-namespaces-repositories-images-tags" "get-v2-namespaces-namespace-repositories-repository-tags" "head-v2-namespaces-namespace-repositories-repository-tags" "get-v2-namespaces-namespace-repositories-repository-tags-tag" "head-v2-namespaces-namespace-repositories-repository-tags-tag" "get-v2-orgs-name-settings" "put-v2-orgs-name-settings" "get-v2-scim-2-0-resource-types" "get-v2-scim-2-0-resource-types-name" "get-v2-scim-2-0-schemas" "get-v2-scim-2-0-schemas-id" "get-v2-scim-2-0-service-provider-config" "get-v2-scim-2-0-users" "post-v2-scim-2-0-users" "get-v2-scim-2-0-users-id" "put-v2-scim-2-0-users-id" "post-users2-fa-login" "post-users-login" "commands"] | sort) } | get name | first)
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

# Get a list of personal access tokens
#
# GET /v2/access-tokens
# Returns: record<active_count: float, count: float, next: string, previous: string, results: table<client_id: string, created_at: string, creator_ip: string, creator_ua: string, generated_by: string, is_active: bool, last_used: string, scopes: list, token: string, token_label: string, uuid: string>>
export def "get-v2-access-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # default: 1
  --page-size: float # default: 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/access-tokens"
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a personal access token
#
# POST /v2/access-tokens
# Returns: record<client_id: string, created_at: string, creator_ip: string, creator_ua: string, generated_by: string, is_active: bool, last_used: string, scopes: list<string>, token: string, token_label: string, uuid: string>
export def "post-v2-access-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  scopes: list<string> # Valid scopes: "repo:admin", "repo:write", "repo:read", "repo:public_read" (e.g. [repo:read])
  token_label: string # Friendly name for you to identify the token. (e.g. My read only token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/access-tokens"
    body: {content_type: "application/json", kind: json, fields: [{name: scopes, var: scopes}, {name: token_label, var: token_label}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    scopes: $scopes, token_label: $token_label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a personal access token
#
# DELETE /v2/access-tokens/{uuid}
export def "delete-v2-access-tokens-uuid" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/access-tokens/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a personal access token
#
# GET /v2/access-tokens/{uuid}
# Returns: record<client_id: string, created_at: string, creator_ip: string, creator_ua: string, generated_by: string, is_active: bool, last_used: string, scopes: list<string>, token: string, token_label: string, uuid: string>
export def "get-v2-access-tokens-uuid" [
  uuid: string
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
    path: "/v2/access-tokens/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a personal access token
#
# PATCH /v2/access-tokens/{uuid}
# Returns: record<client_id: string, created_at: string, creator_ip: string, creator_ua: string, generated_by: string, is_active: bool, last_used: string, scopes: list<string>, token: string, token_label: string, uuid: string>
export def "patch-v2-access-tokens-uuid" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-active: oneof<nothing, bool> # e.g. false
  --token-label: string # e.g. My read only token
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v2/access-tokens/{uuid}"
    path_params: [{name: uuid, var: uuid}]
    body: {content_type: "application/json", kind: json, fields: [{name: is_active, var: is_active}, {name: token_label, var: token_label}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uuid: $uuid, is_active: $is_active, token_label: $token_label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of audit log events.
#
# GET /v2/auditlogs/{account}
# Returns: record<logs: table<account: string, action: string, action_description: string, actor: string, data: record, name: string, timestamp: string>>
# operationId: AuditLogs_GetAuditLogs
export def "audit-logs-get-audit-logs" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # action name one of ["repo.tag.push", ...]. Optional parameter to filter specific audit log actions.
  --name: string # name. Optional parameter to filter audit log events to a specific name. For repository events, this is the name of the repository. For organization events, this is the name of the organization. For team member events, this is the username of the team member.
  --actor: string # actor name. Optional parameter to filter audit log events to the specific user who triggered the event.
  --from: string # Start of the time window you wish to query audit events for. (format: date-time)
  --to: string # End of the time window you wish to query audit events for. (format: date-time)
  --page: int # page - specify page number. Page number to get. (format: int32, default: 1)
  --page-size: int # page_size - specify page size. Number of events to return per page. (format: int32, default: 25)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/auditlogs/{account}"
    path_params: [{name: account, var: account}]
    query: [{name: action, var: action}, {name: name, var: name}, {name: actor, var: actor}, {name: from, var: from}, {name: to, var: to}, {name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account, action: $action, name: $name, actor: $actor, from: $from, to: $to, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of audit log actions.
#
# GET /v2/auditlogs/{account}/actions
# Returns: record<actions: record>
# operationId: AuditLogs_GetAuditActions
export def "audit-logs-get-audit-actions" [
  account: string
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
    path: "/v2/auditlogs/{account}/actions"
    path_params: [{name: account, var: account}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete images
#
# POST /v2/namespaces/{namespace}/delete-images
# Returns: record<dry_run: bool, metrics: record<manifest_deletes: int, manifest_errors: int, tag_deletes: int, tag_errors: int>>
# operationId: PostNamespacesDeleteImages
export def "post-namespaces-delete-images" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-from: string # Sets the time from which an image must have been pushed or pulled to be counted as active. Defaults to 1 month before the current time. (e.g. 2020-12-01T12:00:00Z)
  --body-dry-run: oneof<nothing, bool> # If `true` then will check and return errors and unignored warnings for the deletion request but will not delete any images. (e.g. false) (spec name: dry_run)
  --ignore-warnings: list # Warnings to ignore. If a warning is not ignored then no deletions will happen and the warning is returned in the response. These warnings include: - is_active: warning when attempting to delete an image that is marked as active. - current_tag: warning when attempting to delete an image that has one or more current tags in the repository. Warnings can be copied from the response to the request. — item shape: {digest: string, repository: string, tags?: list<string>, warning: "is_active"|"current_tag"}
  --manifests: list # Image manifests to delete. — item shape: {digest: string, repository: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/namespaces/{namespace}/delete-images"
    path_params: [{name: namespace, var: namespace}]
    body: {content_type: "application/json", kind: json, fields: [{name: active_from, var: active_from}, {name: dry_run, var: body_dry_run}, {name: ignore_warnings, var: ignore_warnings}, {name: manifests, var: manifests}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, active_from: $active_from, body_dry_run: $body_dry_run, ignore_warnings: $ignore_warnings, manifests: $manifests
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details of repository's images
#
# GET /v2/namespaces/{namespace}/repositories/{repository}/images
# Returns: record<count: int, next: string, previous: string, results: table<digest: string, last_pulled: string, last_pushed: string, namespace: string, repository: string, status: string, tags: list>>
# operationId: GetNamespacesRepositoriesImages
export def "get-namespaces-repositories-images" [
  namespace: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Filters to only show images of this status.
  --currently-tagged: oneof<nothing, bool> # Filters to only show images with: - `true`: at least 1 current tag. - `false`: no current tags.
  --ordering: string@ordering-completer # Orders the results by this property. Prefixing with `-` sorts by descending order.
  --active-from: string # Sets the time from which an image must have been pushed or pulled to be counted as active. Defaults to 1 month before the current time.
  --page: int # Page number to get. Defaults to 1.
  --page-size: int # Number of images to get per page. Defaults to 10. Max of 100.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/namespaces/{namespace}/repositories/{repository}/images"
    path_params: [{name: namespace, var: namespace}, {name: repository, var: repository}]
    query: [{name: status, var: status}, {name: currently_tagged, var: currently_tagged}, {name: ordering, var: ordering}, {name: active_from, var: active_from}, {name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, repository: $repository, status: $status, currently_tagged: $currently_tagged, ordering: $ordering, active_from: $active_from, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get summary of repository's images
#
# GET /v2/namespaces/{namespace}/repositories/{repository}/images-summary
# Returns: record<active_from: string, statistics: record<active: int, inactive: int, total: int>>
# operationId: GetNamespacesRepositoriesImagesSummary
export def "get-namespaces-repositories-images-summary" [
  namespace: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-from: string # Sets the time from which an image must have been pushed or pulled to be counted as active. Defaults to 1 month before the current time.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/namespaces/{namespace}/repositories/{repository}/images-summary"
    path_params: [{name: namespace, var: namespace}, {name: repository, var: repository}]
    query: [{name: active_from, var: active_from}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, repository: $repository, active_from: $active_from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get image's tags
#
# GET /v2/namespaces/{namespace}/repositories/{repository}/images/{digest}/tags
# Returns: record<count: int, next: string, previous: string, results: table<is_current: bool, tag: string>>
# operationId: GetNamespacesRepositoriesImagesTags
export def "get-namespaces-repositories-images-tags" [
  namespace: string
  repository: string
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number to get. Defaults to 1.
  --page-size: int # Number of images to get per page. Defaults to 10. Max of 100.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/namespaces/{namespace}/repositories/{repository}/images/{digest}/tags"
    path_params: [{name: namespace, var: namespace}, {name: repository, var: repository}, {name: digest, var: digest}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, repository: $repository, digest: $digest, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List repository tags
#
# GET /v2/namespaces/{namespace}/repositories/{repository}/tags
# Returns: record<count: int, next: string, previous: string, results: table<creator: int, full_size: int, id: int, images: record, last_updated: string, last_updater: int, last_updater_username: string, name: string, repository: int, status: string, tag_last_pulled: string, tag_last_pushed: string, v2: string>>
export def "get-v2-namespaces-namespace-repositories-repository-tags" [
  namespace: string
  repository: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number to get. Defaults to 1.
  --page-size: int # Number of items to get per page. Defaults to 10. Max of 100.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/namespaces/{namespace}/repositories/{repository}/tags"
    path_params: [{name: namespace, var: namespace}, {name: repository, var: repository}]
    query: [{name: page, var: page}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, repository: $repository, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check repository tags
#
# HEAD /v2/namespaces/{namespace}/repositories/{repository}/tags
# Returns: record
export def "head-v2-namespaces-namespace-repositories-repository-tags" [
  namespace: string
  repository: string
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
    method: head
    path: "/v2/namespaces/{namespace}/repositories/{repository}/tags"
    path_params: [{name: namespace, var: namespace}, {name: repository, var: repository}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, repository: $repository
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Read repository tag
#
# GET /v2/namespaces/{namespace}/repositories/{repository}/tags/{tag}
# Returns: record<creator: int, full_size: int, id: int, images: record<architecture: string, digest: string, features: string, last_pulled: string, last_pushed: string, layers: list<record>, os: string, os_features: string, os_version: string, size: int, status: string, variant: string>, last_updated: string, last_updater: int, last_updater_username: string, name: string, repository: int, status: string, tag_last_pulled: string, tag_last_pushed: string, v2: string>
export def "get-v2-namespaces-namespace-repositories-repository-tags-tag" [
  namespace: string
  repository: string
  tag: string
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
    path: "/v2/namespaces/{namespace}/repositories/{repository}/tags/{tag}"
    path_params: [{name: namespace, var: namespace}, {name: repository, var: repository}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, repository: $repository, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check repository tag
#
# HEAD /v2/namespaces/{namespace}/repositories/{repository}/tags/{tag}
# Returns: record
export def "head-v2-namespaces-namespace-repositories-repository-tags-tag" [
  namespace: string
  repository: string
  tag: string
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
    method: head
    path: "/v2/namespaces/{namespace}/repositories/{repository}/tags/{tag}"
    path_params: [{name: namespace, var: namespace}, {name: repository, var: repository}, {name: tag, var: tag}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    namespace: $namespace, repository: $repository, tag: $tag
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get organization settings
#
# GET /v2/orgs/{name}/settings
# Returns: record<restricted_images: record<allow_official_images: bool, allow_verified_publishers: bool, enabled: bool>>
export def "get-v2-orgs-name-settings" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/orgs/{name}/settings"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update organization settings
#
# PUT /v2/orgs/{name}/settings
# Returns: record<restricted_images: record<allow_official_images: bool, allow_verified_publishers: bool, enabled: bool>>
export def "put-v2-orgs-name-settings" [
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
  restricted_images: record # shape: {allow_official_images: bool, allow_verified_publishers: bool, enabled: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/orgs/{name}/settings"
    path_params: [{name: name, var: name}]
    body: {content_type: "application/json", kind: json, fields: [{name: restricted_images, var: restricted_images}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, restricted_images: $restricted_images
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List resource types
#
# GET /v2/scim/2.0/ResourceTypes
# Returns: record<resources: table<description: string, endpoint: string, id: string, name: string, schema: string, schemas: list>, schemas: list<string>, totalResults: int>
export def "get-v2-scim-2-0-resource-types" [
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
    path: "/v2/scim/2.0/ResourceTypes"
    accept: ["application/scim+json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a resource type
#
# GET /v2/scim/2.0/ResourceTypes/{name}
# Returns: record<description: string, endpoint: string, id: string, name: string, schema: string, schemas: list<string>>
export def "get-v2-scim-2-0-resource-types-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/scim/2.0/ResourceTypes/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/scim+json"]
    ok: [200]
    auth: none
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List schemas
#
# GET /v2/scim/2.0/Schemas
# Returns: record<resources: table<attributes: list, description: string, id: string, name: string, schemas: list>, schemas: list<string>, totalResults: int>
export def "get-v2-scim-2-0-schemas" [
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
    path: "/v2/scim/2.0/Schemas"
    accept: ["application/scim+json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a schema
#
# GET /v2/scim/2.0/Schemas/{id}
# Returns: record<attributes: table<caseExact: bool, description: string, multiValued: bool, mutability: string, name: string, required: bool, returned: string, type: string, uniqueness: string, subAttributes: list>, description: string, id: string, name: string, schemas: list<string>>
export def "get-v2-scim-2-0-schemas-id" [
  id: string
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
    path: "/v2/scim/2.0/Schemas/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/scim+json"]
    ok: [200]
    auth: none
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get service provider config
#
# GET /v2/scim/2.0/ServiceProviderConfig
# Returns: record<authenticationSchemes: record<description: string, name: string, specUri: string, type: string>, bulk: record<maxOperations: int, maxPayloadSize: int, supported: bool>, changePassword: record<supported: bool>, documentationUri: string, etag: record<supported: bool>, filter: record<maxResults: int, supported: bool>, patch: record<supported: bool>, schemas: list<string>, sort: record<supported: bool>>
export def "get-v2-scim-2-0-service-provider-config" [
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
    path: "/v2/scim/2.0/ServiceProviderConfig"
    accept: ["application/scim+json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /v2/scim/2.0/Users
# Returns: record<itemsPerPage: int, resources: table<active: bool, displayName: string, emails: list, groups: list, id: string, meta: record, name: record, schemas: list, userName: string>, schemas: list<string>, startIndex: int, totalResults: int>
export def "get-v2-scim-2-0-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # e.g. 1
  --count: int # e.g. 10
  --filter: string # e.g. userName eq "jon.snow@docker.com"
  --attributes: string # Comma delimited list of attributes to limit to in the response. (e.g. userName,displayName)
  --sort-order: string@sort-order-completer
  --sort-by: string # User attribute to sort by. (e.g. userName)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/scim/2.0/Users"
    query: [{name: startIndex, var: start_index}, {name: count, var: count}, {name: filter, var: filter}, {name: attributes, var: attributes}, {name: sortOrder, var: sort_order}, {name: sortBy, var: sort_by}]
    accept: ["application/scim+json"]
    ok: [200]
    auth: none
  } {
    start_index: $start_index, count: $count, filter: $filter, attributes: $attributes, sort_order: $sort_order, sort_by: $sort_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user
#
# POST /v2/scim/2.0/Users
# Returns: record<active: bool, displayName: string, emails: table<display: string, primary: bool, value: string>, groups: table<display: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string>
export def "post-v2-scim-2-0-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: record # shape: {familyName?: string, givenName?: string}
  schemas: list<string>
  user_name: string # The user's email address. This must be reachable via email. (e.g. jon.snow@docker.com)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/scim/2.0/Users"
    body: {content_type: "application/scim+json", kind: json, fields: [{name: name, var: name}, {name: schemas, var: schemas}, {name: userName, var: user_name}]}
    accept: ["application/scim+json"]
    ok: [201]
    auth: none
  } {
    name: $name, schemas: $schemas, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /v2/scim/2.0/Users/{id}
# Returns: record<active: bool, displayName: string, emails: table<display: string, primary: bool, value: string>, groups: table<display: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string>
export def "get-v2-scim-2-0-users-id" [
  id: string
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
    path: "/v2/scim/2.0/Users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/scim+json"]
    ok: [200]
    auth: none
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user
#
# PUT /v2/scim/2.0/Users/{id}
# Returns: record<active: bool, displayName: string, emails: table<display: string, primary: bool, value: string>, groups: table<display: string, value: string>, id: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>, name: record<familyName: string, givenName: string>, schemas: list<string>, userName: string>
export def "put-v2-scim-2-0-users-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # If this is omitted from the request, it will default to false resulting in a deactivated user. (default: false)
  --name: record # If this is omitted from the request, the update will skip the update on it. We will only ever change the name, but not clear it. — shape: {familyName?: string, givenName?: string}
  schemas: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v2/scim/2.0/Users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/scim+json", kind: json, fields: [{name: enabled, var: enabled}, {name: name, var: name}, {name: schemas, var: schemas}]}
    accept: ["application/scim+json"]
    ok: [200]
    auth: none
  } {
    id: $id, enabled: $enabled, name: $name, schemas: $schemas
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Second factor authentication.
#
# POST /v2/users/2fa-login
# Returns: record<token: string>
# operationId: PostUsers2FALogin
export def "post-users2-fa-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # The Time-based One-Time Password of the Docker Hub account to authenticate with. (e.g. 123456)
  login_2fa_token: string # The intermediate 2FA token returned from `/v2/users/login` API. (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/users/2fa-login"
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: login_2fa_token, var: login_2fa_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    code: $code, login_2fa_token: $login_2fa_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an authentication token
#
# POST /v2/users/login
# Returns: record<token: string>
# operationId: PostUsersLogin
export def "post-users-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The password or personal access token (PAT) of the Docker Hub account to authenticate with. (e.g. hunter2)
  username: string # The username of the Docker Hub account to authenticate with. (e.g. myusername)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v2/users/login"
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
