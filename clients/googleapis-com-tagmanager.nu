# Auto-generated client for Tag Manager API v2
# Source: https://api.apis.guru/v2/specs/googleapis.com/tagmanager/v2/openapi.json
# Auth: --token flag or $env.TAG_MANAGER_API_TOKEN

const CLIENT = {
  base_url: "https://tagmanager.googleapis.com"
  token_env_var: "TAG_MANAGER_API_TOKEN"
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

def base-url-completer [] { ["https://tagmanager.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def type-completer [] { ["latest" "live" "user" "workspace"] }
def tag-firing-option-completer [] { ["oncePerEvent" "oncePerLoad" "tagFiringOptionUnspecified" "unlimited"] }
def type-completer-1 [] { ["always" "ampClick" "ampScroll" "ampTimer" "ampVisibility" "click" "consentInit" "customEvent" "domReady" "elementVisibility" "eventTypeUnspecified" "firebaseAppException" "firebaseAppUpdate" "firebaseCampaign" "firebaseFirstOpen" "firebaseInAppPurchase" "firebaseNotificationDismiss" "firebaseNotificationForeground" "firebaseNotificationOpen" "firebaseNotificationReceive" "firebaseOsUpdate" "firebaseSessionStart" "firebaseUserEngagement" "formSubmission" "historyChange" "init" "jsError" "linkClick" "pageview" "scrollDepth" "serverPageview" "timer" "triggerGroup" "windowLoaded" "youTubeVideo"] }
def type-completer-2 [] { ["advertiserId" "advertisingTrackingEnabled" "ampBrowserLanguage" "ampCanonicalHost" "ampCanonicalPath" "ampCanonicalUrl" "ampClientId" "ampClientMaxScrollX" "ampClientMaxScrollY" "ampClientScreenHeight" "ampClientScreenWidth" "ampClientScrollX" "ampClientScrollY" "ampClientTimestamp" "ampClientTimezone" "ampGtmEvent" "ampPageDownloadTime" "ampPageLoadTime" "ampPageViewId" "ampReferrer" "ampTitle" "ampTotalEngagedTime" "appId" "appName" "appVersionCode" "appVersionName" "builtInVariableTypeUnspecified" "clickClasses" "clickElement" "clickId" "clickTarget" "clickText" "clickUrl" "clientName" "containerId" "containerVersion" "debugMode" "deviceName" "elementVisibilityFirstTime" "elementVisibilityRatio" "elementVisibilityRecentTime" "elementVisibilityTime" "environmentName" "errorLine" "errorMessage" "errorUrl" "event" "eventName" "firebaseEventParameterCampaign" "firebaseEventParameterCampaignAclid" "firebaseEventParameterCampaignAnid" "firebaseEventParameterCampaignClickTimestamp" "firebaseEventParameterCampaignContent" "firebaseEventParameterCampaignCp1" "firebaseEventParameterCampaignGclid" "firebaseEventParameterCampaignSource" "firebaseEventParameterCampaignTerm" "firebaseEventParameterCurrency" "firebaseEventParameterDynamicLinkAcceptTime" "firebaseEventParameterDynamicLinkLinkid" "firebaseEventParameterNotificationMessageDeviceTime" "firebaseEventParameterNotificationMessageId" "firebaseEventParameterNotificationMessageName" "firebaseEventParameterNotificationMessageTime" "firebaseEventParameterNotificationTopic" "firebaseEventParameterPreviousAppVersion" "firebaseEventParameterPreviousOsVersion" "firebaseEventParameterPrice" "firebaseEventParameterProductId" "firebaseEventParameterQuantity" "firebaseEventParameterValue" "firstPartyServingUrl" "formClasses" "formElement" "formId" "formTarget" "formText" "formUrl" "historySource" "htmlId" "language" "newHistoryFragment" "newHistoryState" "newHistoryUrl" "oldHistoryFragment" "oldHistoryState" "oldHistoryUrl" "osVersion" "pageHostname" "pagePath" "pageUrl" "platform" "queryString" "randomNumber" "referrer" "requestMethod" "requestPath" "resolution" "scrollDepthDirection" "scrollDepthThreshold" "scrollDepthUnits" "sdkVersion" "serverPageLocationHostname" "serverPageLocationPath" "serverPageLocationUrl" "videoCurrentTime" "videoDuration" "videoPercent" "videoProvider" "videoStatus" "videoTitle" "videoUrl" "videoVisible" "visitorRegion"] }
def setting-source-completer [] { ["current" "other" "settingSourceUnspecified"] }
def change-status-completer [] { ["added" "changeStatusUnspecified" "deleted" "none" "updated"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    tagmanager-accounts-list: "record<account: table<accountId: string, features: record, fingerprint: string, name: string, path: string, shareData: bool, tagManagerUrl: string>, nextPageToken: string>"
    tagmanager-accounts-containers-lookup: "record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>"
    tagmanager-accounts-containers-workspaces-built-in-variables-list: "record<builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, nextPageToken: string>"
    tagmanager-accounts-containers-workspaces-built-in-variables-create: "record<builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>>"
    tagmanager-accounts-containers-workspaces-clients-list: "record<client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, nextPageToken: string>"
    tagmanager-accounts-containers-workspaces-clients-create: "record<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>"
    tagmanager-accounts-containers-list: "record<container: table<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, nextPageToken: string>"
    tagmanager-accounts-containers-create: "record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>"
    tagmanager-accounts-containers-destinations-list: "record<destination: table<accountId: string, containerId: string, destinationId: string, destinationLinkId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string>, nextPageToken: string>"
    tagmanager-accounts-containers-destinations-link: "record<accountId: string, containerId: string, destinationId: string, destinationLinkId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string>"
    tagmanager-accounts-containers-environments-list: "record<environment: table<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string>, nextPageToken: string>"
    tagmanager-accounts-containers-environments-create: "record<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string>"
    tagmanager-accounts-containers-workspaces-folders-list: "record<folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, nextPageToken: string>"
    tagmanager-accounts-containers-workspaces-folders-create: "record<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>"
    tagmanager-accounts-containers-workspaces-gtag-config-list: "record<gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, nextPageToken: string>"
    tagmanager-accounts-containers-workspaces-gtag-config-create: "record<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, path: string, tagManagerUrl: string, type: string, workspaceId: string>"
    tagmanager-accounts-containers-workspaces-tags-list: "record<nextPageToken: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>>"
    tagmanager-accounts-containers-workspaces-tags-create: "record<accountId: string, blockingRuleId: list<string>, blockingTriggerId: list<string>, consentSettings: record<consentStatus: string, consentType: record<key: string, list: list, map: list, type: string, value: string>>, containerId: string, fingerprint: string, firingRuleId: list<string>, firingTriggerId: list<string>, liveOnly: bool, monitoringMetadata: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, paused: bool, priority: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, scheduleEndMs: string, scheduleStartMs: string, setupTag: table<stopOnSetupFailure: bool, tagName: string>, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: table<stopTeardownOnFailure: bool, tagName: string>, type: string, workspaceId: string>"
    tagmanager-accounts-containers-workspaces-templates-list: "record<nextPageToken: string, template: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>>"
    tagmanager-accounts-containers-workspaces-templates-create: "record<accountId: string, containerId: string, fingerprint: string, galleryReference: record<host: string, isModified: bool, owner: string, repository: string, signature: string, version: string>, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>"
    tagmanager-accounts-containers-workspaces-triggers-list: "record<nextPageToken: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>>"
    tagmanager-accounts-containers-workspaces-triggers-create: "record<accountId: string, autoEventFilter: table<parameter: list, type: string>, checkValidation: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, containerId: string, continuousTimeMinMilliseconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, customEventFilter: table<parameter: list, type: string>, eventName: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, filter: table<parameter: list, type: string>, fingerprint: string, horizontalScrollPercentageList: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, interval: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, intervalSeconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, limit: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, maxTimerLengthSeconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, selector: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, tagManagerUrl: string, totalTimeMinMilliseconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, triggerId: string, type: string, uniqueTriggerId: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, verticalScrollPercentageList: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visibilitySelector: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visiblePercentageMax: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visiblePercentageMin: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, waitForTags: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, waitForTagsTimeout: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, workspaceId: string>"
    tagmanager-accounts-user-permissions-list: "record<nextPageToken: string, userPermission: table<accountAccess: record, accountId: string, containerAccess: list, emailAddress: string, path: string>>"
    tagmanager-accounts-user-permissions-create: "record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string>"
    tagmanager-accounts-containers-workspaces-variables-list: "record<nextPageToken: string, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>>"
    tagmanager-accounts-containers-workspaces-variables-create: "record<accountId: string, containerId: string, disablingTriggerId: list<string>, enablingTriggerId: list<string>, fingerprint: string, formatValue: record<caseConversionType: string, convertFalseToValue: record<key: string, list: list, map: list, type: string, value: string>, convertNullToValue: record<key: string, list: list, map: list, type: string, value: string>, convertTrueToValue: record<key: string, list: list, map: list, type: string, value: string>, convertUndefinedToValue: record<key: string, list: list, map: list, type: string, value: string>>, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>"
    tagmanager-accounts-containers-version-headers-list: "record<containerVersionHeader: table<accountId: string, containerId: string, containerVersionId: string, deleted: bool, name: string, numClients: string, numCustomTemplates: string, numGtagConfigs: string, numMacros: string, numRules: string, numTags: string, numTransformations: string, numTriggers: string, numVariables: string, numZones: string, path: string>, nextPageToken: string>"
    tagmanager-accounts-containers-version-headers-latest: "record<accountId: string, containerId: string, containerVersionId: string, deleted: bool, name: string, numClients: string, numCustomTemplates: string, numGtagConfigs: string, numMacros: string, numRules: string, numTags: string, numTransformations: string, numTriggers: string, numVariables: string, numZones: string, path: string>"
    tagmanager-accounts-containers-versions-live: "record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>>"
    tagmanager-accounts-containers-workspaces-list: "record<nextPageToken: string, workspace: table<accountId: string, containerId: string, description: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, workspaceId: string>>"
    tagmanager-accounts-containers-workspaces-create: "record<accountId: string, containerId: string, description: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, workspaceId: string>"
    tagmanager-accounts-containers-workspaces-zones-list: "record<nextPageToken: string, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>>"
    tagmanager-accounts-containers-workspaces-zones-create: "record<accountId: string, boundary: record<condition: list<record>, customEvaluationTriggerId: list<string>>, childContainer: table<nickname: string, publicId: string>, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record<enable: bool, whitelistedTypeId: list<string>>, workspaceId: string, zoneId: string>"
    tagmanager-accounts-user-permissions-get: "record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string>"
    tagmanager-accounts-user-permissions-update: "record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string>"
    tagmanager-accounts-containers-workspaces-built-in-variables-revert: "record<enabled: bool>"
    tagmanager-accounts-containers-workspaces-get-status: "record<mergeConflict: table<entityInBaseVersion: record, entityInWorkspace: record>, workspaceChange: table<changeStatus: string, client: record, folder: record, tag: record, trigger: record, variable: record>>"
    tagmanager-accounts-containers-combine: "record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>"
    tagmanager-accounts-containers-workspaces-create-version: "record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>, newWorkspacePath: string, syncStatus: record<mergeConflict: bool, syncError: bool>>"
    tagmanager-accounts-containers-workspaces-folders-entities: "record<nextPageToken: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>>"
    tagmanager-accounts-containers-move-tag-id: "record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>"
    tagmanager-accounts-containers-versions-publish: "record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>>"
    tagmanager-accounts-containers-workspaces-quick-preview: "record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>, syncStatus: record<mergeConflict: bool, syncError: bool>>"
    tagmanager-accounts-containers-environments-reauthorize: "record<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string>"
    tagmanager-accounts-containers-workspaces-zones-revert: "record<zone: record<accountId: string, boundary: record<condition: list, customEvaluationTriggerId: list>, childContainer: list<record>, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record<enable: bool, whitelistedTypeId: list>, workspaceId: string, zoneId: string>>"
    tagmanager-accounts-containers-versions-set-latest: "record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>>"
    tagmanager-accounts-containers-snippet: "record<snippet: string>"
    tagmanager-accounts-containers-workspaces-sync: "record<mergeConflict: table<entityInBaseVersion: record, entityInWorkspace: record>, syncStatus: record<mergeConflict: bool, syncError: bool>>"
    tagmanager-accounts-containers-versions-undelete: "record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["tagmanager-accounts-list" "tagmanager-accounts-containers-lookup" "tagmanager-accounts-containers-workspaces-built-in-variables-list" "tagmanager-accounts-containers-workspaces-built-in-variables-create" "tagmanager-accounts-containers-workspaces-clients-list" "tagmanager-accounts-containers-workspaces-clients-create" "tagmanager-accounts-containers-list" "tagmanager-accounts-containers-create" "tagmanager-accounts-containers-destinations-list" "tagmanager-accounts-containers-destinations-link" "tagmanager-accounts-containers-environments-list" "tagmanager-accounts-containers-environments-create" "tagmanager-accounts-containers-workspaces-folders-list" "tagmanager-accounts-containers-workspaces-folders-create" "tagmanager-accounts-containers-workspaces-gtag-config-list" "tagmanager-accounts-containers-workspaces-gtag-config-create" "tagmanager-accounts-containers-workspaces-tags-list" "tagmanager-accounts-containers-workspaces-tags-create" "tagmanager-accounts-containers-workspaces-templates-list" "tagmanager-accounts-containers-workspaces-templates-create" "tagmanager-accounts-containers-workspaces-triggers-list" "tagmanager-accounts-containers-workspaces-triggers-create" "tagmanager-accounts-user-permissions-list" "tagmanager-accounts-user-permissions-create" "tagmanager-accounts-containers-workspaces-variables-list" "tagmanager-accounts-containers-workspaces-variables-create" "tagmanager-accounts-containers-version-headers-list" "tagmanager-accounts-containers-version-headers-latest" "tagmanager-accounts-containers-versions-live" "tagmanager-accounts-containers-workspaces-list" "tagmanager-accounts-containers-workspaces-create" "tagmanager-accounts-containers-workspaces-zones-list" "tagmanager-accounts-containers-workspaces-zones-create" "tagmanager-accounts-user-permissions-delete" "tagmanager-accounts-user-permissions-get" "tagmanager-accounts-user-permissions-update" "tagmanager-accounts-containers-workspaces-built-in-variables-revert" "tagmanager-accounts-containers-workspaces-get-status" "tagmanager-accounts-containers-combine" "tagmanager-accounts-containers-workspaces-create-version" "tagmanager-accounts-containers-workspaces-folders-entities" "tagmanager-accounts-containers-workspaces-folders-move-entities-to-folder" "tagmanager-accounts-containers-move-tag-id" "tagmanager-accounts-containers-versions-publish" "tagmanager-accounts-containers-workspaces-quick-preview" "tagmanager-accounts-containers-environments-reauthorize" "tagmanager-accounts-containers-workspaces-resolve-conflict" "tagmanager-accounts-containers-workspaces-zones-revert" "tagmanager-accounts-containers-versions-set-latest" "tagmanager-accounts-containers-snippet" "tagmanager-accounts-containers-workspaces-sync" "tagmanager-accounts-containers-versions-undelete" "commands"] | sort) } | get name | first)
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

# Lists all GTM Accounts that a user has access to.
#
# GET /tagmanager/v2/accounts
# Returns: record<account: table<accountId: string, features: record, fingerprint: string, name: string, path: string, shareData: bool, tagManagerUrl: string>, nextPageToken: string>
# operationId: tagmanager.accounts.list
export def "tagmanager-accounts-list" [
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
  --include-google-tags: oneof<nothing, bool> # Also retrieve accounts associated with Google Tag when true.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/accounts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeGoogleTags, var: include_google_tags}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_google_tags: $include_google_tags, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Looks up a Container by destination ID.
#
# GET /tagmanager/v2/accounts/containers:lookup
# Returns: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>
# operationId: tagmanager.accounts.containers.lookup
export def "tagmanager-accounts-containers-lookup" [
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
  --destination-id: string # Destination ID linked to a GTM Container, e.g. AW-123456789. Example: accounts/containers:lookup?destination_id={destination_id}.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/accounts/containers:lookup"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: destinationId, var: destination_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, destination_id: $destination_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the enabled Built-In Variables of a GTM Container.
#
# GET /tagmanager/v2/{parent}/built_in_variables
# Returns: record<builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, nextPageToken: string>
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.list
export def "tagmanager-accounts-containers-workspaces-built-in-variables-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/built_in_variables"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates one or more GTM Built-In Variables.
#
# POST /tagmanager/v2/{parent}/built_in_variables
# Returns: record<builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>>
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.create
export def "tagmanager-accounts-containers-workspaces-built-in-variables-create" [
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
  --type: list<string> # The types of built-in variables to enable.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tagmanager/v2/{parent}/built_in_variables"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: type, var: type, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all GTM Clients of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/clients
# Returns: record<client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, nextPageToken: string>
# operationId: tagmanager.accounts.containers.workspaces.clients.list
export def "tagmanager-accounts-containers-workspaces-clients-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/clients"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GTM Client.
#
# POST /tagmanager/v2/{parent}/clients
# Returns: record<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.workspaces.clients.create
export def "tagmanager-accounts-containers-workspaces-clients-create" [
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
  --account-id: string # GTM Account ID.
  --client-id: string # The Client ID uniquely identifies the GTM client.
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Client as computed at storage time. This value is recomputed whenever the client is modified.
  --name: string # Client display name. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update
  --notes: string # User notes on how to apply this tag in the container. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --parameter: list # The client's parameters. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parent-folder-id: string # Parent folder id.
  --path: string # GTM client's API relative path.
  --priority: int # Priority determines relative firing order. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update (format: int32)
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string # Client type. @mutable tagmanager.accounts.containers.workspaces.clients.create @mutable tagmanager.accounts.containers.workspaces.clients.update
  --workspace-id: string # GTM Workspace ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/clients"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: clientId, var: client_id}, {name: containerId, var: container_id}, {name: fingerprint, var: fingerprint}, {name: name, var: name}, {name: notes, var: notes}, {name: parameter, var: parameter}, {name: parentFolderId, var: parent_folder_id}, {name: path, var: path}, {name: priority, var: priority}, {name: tagManagerUrl, var: tag_manager_url}, {name: type, var: type}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, client_id: $client_id, container_id: $container_id, fingerprint: $fingerprint, name: $name, notes: $notes, parameter: $parameter, parent_folder_id: $parent_folder_id, path: $path, priority: $priority, tag_manager_url: $tag_manager_url, type: $type, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Containers that belongs to a GTM Account.
#
# GET /tagmanager/v2/{parent}/containers
# Returns: record<container: table<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, nextPageToken: string>
# operationId: tagmanager.accounts.containers.list
export def "tagmanager-accounts-containers-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/containers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Container.
#
# POST /tagmanager/v2/{parent}/containers
# Returns: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>
# operationId: tagmanager.accounts.containers.create
export def "tagmanager-accounts-containers-create" [
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
  --account-id: string # GTM Account ID.
  --container-id: string # The Container ID uniquely identifies the GTM Container.
  --domain-name: list<string> # List of domain names associated with the Container. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --features: record # shape: {supportBuiltInVariables?: bool, supportClients?: bool, supportEnvironments?: bool, supportFolders?: bool, supportGtagConfigs?: bool, supportTags?: bool, supportTemplates?: bool, supportTriggers?: bool, supportUserPermissions?: bool, supportVariables?: bool, supportVersions?: bool, supportWorkspaces?: bool, supportZones?: bool}
  --fingerprint: string # The fingerprint of the GTM Container as computed at storage time. This value is recomputed whenever the account is modified.
  --name: string # Container display name. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --notes: string # Container Notes. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --path: string # GTM Container's API relative path.
  --public-id: string # Container Public ID.
  --tag-ids: list<string> # All Tag IDs that refer to this Container.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --tagging-server-urls: list<string> # List of server-side container URLs for the Container. If multiple URLs are provided, all URL paths must match. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
  --usage-context: list<string> # List of Usage Contexts for the Container. Valid values include: web, android, or ios. @mutable tagmanager.accounts.containers.create @mutable tagmanager.accounts.containers.update
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/containers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: containerId, var: container_id}, {name: domainName, var: domain_name}, {name: features, var: features}, {name: fingerprint, var: fingerprint}, {name: name, var: name}, {name: notes, var: notes}, {name: path, var: path}, {name: publicId, var: public_id}, {name: tagIds, var: tag_ids}, {name: tagManagerUrl, var: tag_manager_url}, {name: taggingServerUrls, var: tagging_server_urls}, {name: usageContext, var: usage_context}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, container_id: $container_id, domain_name: $domain_name, features: $features, fingerprint: $fingerprint, name: $name, notes: $notes, path: $path, public_id: $public_id, tag_ids: $tag_ids, tag_manager_url: $tag_manager_url, tagging_server_urls: $tagging_server_urls, usage_context: $usage_context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Destinations linked to a GTM Container.
#
# GET /tagmanager/v2/{parent}/destinations
# Returns: record<destination: table<accountId: string, containerId: string, destinationId: string, destinationLinkId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string>, nextPageToken: string>
# operationId: tagmanager.accounts.containers.destinations.list
export def "tagmanager-accounts-containers-destinations-list" [
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
    path: "/tagmanager/v2/{parent}/destinations"
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

# Adds a Destination to this Container and removes it from the Container to which it is currently linked.
#
# POST /tagmanager/v2/{parent}/destinations:link
# Returns: record<accountId: string, containerId: string, destinationId: string, destinationLinkId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string>
# operationId: tagmanager.accounts.containers.destinations.link
export def "tagmanager-accounts-containers-destinations-link" [
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
  --allow-user-permission-feature-update: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --destination-id: string # Destination ID to be linked to the current container.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tagmanager/v2/{parent}/destinations:link"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: allowUserPermissionFeatureUpdate, var: allow_user_permission_feature_update}, {name: destinationId, var: destination_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, allow_user_permission_feature_update: $allow_user_permission_feature_update, destination_id: $destination_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all GTM Environments of a GTM Container.
#
# GET /tagmanager/v2/{parent}/environments
# Returns: record<environment: table<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string>, nextPageToken: string>
# operationId: tagmanager.accounts.containers.environments.list
export def "tagmanager-accounts-containers-environments-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/environments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GTM Environment.
#
# POST /tagmanager/v2/{parent}/environments
# Returns: record<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.environments.create
export def "tagmanager-accounts-containers-environments-create" [
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
  --account-id: string # GTM Account ID.
  --authorization-code: string # The environment authorization code.
  --authorization-timestamp: string # The last update time-stamp for the authorization code. (format: google-datetime)
  --container-id: string # GTM Container ID.
  --container-version-id: string # Represents a link to a container version.
  --description: string # The environment description. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --enable-debug: oneof<nothing, bool> # Whether or not to enable debug by default for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --environment-id: string # GTM Environment ID uniquely identifies the GTM Environment.
  --fingerprint: string # The fingerprint of the GTM environment as computed at storage time. This value is recomputed whenever the environment is modified.
  --name: string # The environment display name. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --path: string # GTM Environment's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string@type-completer # The type of this environment.
  --url: string # Default preview page url for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --workspace-id: string # Represents a link to a quick preview of a workspace.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/environments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: authorizationCode, var: authorization_code}, {name: authorizationTimestamp, var: authorization_timestamp}, {name: containerId, var: container_id}, {name: containerVersionId, var: container_version_id}, {name: description, var: description}, {name: enableDebug, var: enable_debug}, {name: environmentId, var: environment_id}, {name: fingerprint, var: fingerprint}, {name: name, var: name}, {name: path, var: path}, {name: tagManagerUrl, var: tag_manager_url}, {name: type, var: type}, {name: url, var: url}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, authorization_code: $authorization_code, authorization_timestamp: $authorization_timestamp, container_id: $container_id, container_version_id: $container_version_id, description: $description, enable_debug: $enable_debug, environment_id: $environment_id, fingerprint: $fingerprint, name: $name, path: $path, tag_manager_url: $tag_manager_url, type: $type, url: $url, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all GTM Folders of a Container.
#
# GET /tagmanager/v2/{parent}/folders
# Returns: record<folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, nextPageToken: string>
# operationId: tagmanager.accounts.containers.workspaces.folders.list
export def "tagmanager-accounts-containers-workspaces-folders-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/folders"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GTM Folder.
#
# POST /tagmanager/v2/{parent}/folders
# Returns: record<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.workspaces.folders.create
export def "tagmanager-accounts-containers-workspaces-folders-create" [
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
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Folder as computed at storage time. This value is recomputed whenever the folder is modified.
  --folder-id: string # The Folder ID uniquely identifies the GTM Folder.
  --name: string # Folder display name. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --notes: string # User notes on how to apply this folder in the container. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --path: string # GTM Folder's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --workspace-id: string # GTM Workspace ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/folders"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: containerId, var: container_id}, {name: fingerprint, var: fingerprint}, {name: folderId, var: folder_id}, {name: name, var: name}, {name: notes, var: notes}, {name: path, var: path}, {name: tagManagerUrl, var: tag_manager_url}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, container_id: $container_id, fingerprint: $fingerprint, folder_id: $folder_id, name: $name, notes: $notes, path: $path, tag_manager_url: $tag_manager_url, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Google tag configs in a Container.
#
# GET /tagmanager/v2/{parent}/gtag_config
# Returns: record<gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, nextPageToken: string>
# operationId: tagmanager.accounts.containers.workspaces.gtag_config.list
export def "tagmanager-accounts-containers-workspaces-gtag-config-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/gtag_config"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Google tag config.
#
# POST /tagmanager/v2/{parent}/gtag_config
# Returns: record<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, path: string, tagManagerUrl: string, type: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.workspaces.gtag_config.create
export def "tagmanager-accounts-containers-workspaces-gtag-config-create" [
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
  --account-id: string # Google tag account ID.
  --container-id: string # Google tag container ID.
  --fingerprint: string # The fingerprint of the Google tag config as computed at storage time. This value is recomputed whenever the config is modified.
  --gtag-config-id: string # The ID uniquely identifies the Google tag config.
  --parameter: list # The Google tag config's parameters. @mutable tagmanager.accounts.containers.workspaces.gtag_config.create @mutable tagmanager.accounts.containers.workspaces.gtag_config.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --path: string # Google tag config's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string # Google tag config type. @required tagmanager.accounts.containers.workspaces.gtag_config.create @required tagmanager.accounts.containers.workspaces.gtag_config.update @mutable tagmanager.accounts.containers.workspaces.gtag_config.create @mutable tagmanager.accounts.containers.workspaces.gtag_config.update
  --workspace-id: string # Google tag workspace ID. Only used by GTM containers. Set to 0 otherwise.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/gtag_config"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: containerId, var: container_id}, {name: fingerprint, var: fingerprint}, {name: gtagConfigId, var: gtag_config_id}, {name: parameter, var: parameter}, {name: path, var: path}, {name: tagManagerUrl, var: tag_manager_url}, {name: type, var: type}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, container_id: $container_id, fingerprint: $fingerprint, gtag_config_id: $gtag_config_id, parameter: $parameter, path: $path, tag_manager_url: $tag_manager_url, type: $type, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all GTM Tags of a Container.
#
# GET /tagmanager/v2/{parent}/tags
# Returns: record<nextPageToken: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>>
# operationId: tagmanager.accounts.containers.workspaces.tags.list
export def "tagmanager-accounts-containers-workspaces-tags-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/tags"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GTM Tag.
#
# POST /tagmanager/v2/{parent}/tags
# Returns: record<accountId: string, blockingRuleId: list<string>, blockingTriggerId: list<string>, consentSettings: record<consentStatus: string, consentType: record<key: string, list: list, map: list, type: string, value: string>>, containerId: string, fingerprint: string, firingRuleId: list<string>, firingTriggerId: list<string>, liveOnly: bool, monitoringMetadata: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, paused: bool, priority: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, scheduleEndMs: string, scheduleStartMs: string, setupTag: table<stopOnSetupFailure: bool, tagName: string>, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: table<stopTeardownOnFailure: bool, tagName: string>, type: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.workspaces.tags.create
export def "tagmanager-accounts-containers-workspaces-tags-create" [
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
  --account-id: string # GTM Account ID.
  --blocking-rule-id: list<string> # Blocking rule IDs. If any of the listed rules evaluate to true, the tag will not fire. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --blocking-trigger-id: list<string> # Blocking trigger IDs. If any of the listed triggers evaluate to true, the tag will not fire. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --consent-settings: record # shape: {consentStatus?: "notSet"|"notNeeded"|"needed", consentType?: record}
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Tag as computed at storage time. This value is recomputed whenever the tag is modified.
  --firing-rule-id: list<string> # Firing rule IDs. A tag will fire when any of the listed rules are true and all of its blockingRuleIds (if any specified) are false. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --firing-trigger-id: list<string> # Firing trigger IDs. A tag will fire when any of the listed triggers are true and all of its blockingTriggerIds (if any specified) are false. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --live-only: oneof<nothing, bool> # If set to true, this tag will only fire in the live environment (e.g. not in preview or debug mode). @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --monitoring-metadata: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --monitoring-metadata-tag-name-key: string # If non-empty, then the tag display name will be included in the monitoring metadata map using the key specified. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --name: string # Tag display name. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --notes: string # User notes on how to apply this tag in the container. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --parameter: list # The tag's parameters. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parent-folder-id: string # Parent folder id.
  --path: string # GTM Tag's API relative path.
  --paused: oneof<nothing, bool> # Indicates whether the tag is paused, which prevents the tag from firing. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --priority: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --schedule-end-ms: string # The end timestamp in milliseconds to schedule a tag. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update (format: int64)
  --schedule-start-ms: string # The start timestamp in milliseconds to schedule a tag. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update (format: int64)
  --setup-tag: list # The list of setup tags. Currently we only allow one. — item shape: {stopOnSetupFailure?: bool, tagName?: string}
  --tag-firing-option: string@tag-firing-option-completer # Option to fire this tag.
  --tag-id: string # The Tag ID uniquely identifies the GTM Tag.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --teardown-tag: list # The list of teardown tags. Currently we only allow one. — item shape: {stopTeardownOnFailure?: bool, tagName?: string}
  --type: string # GTM Tag Type. @mutable tagmanager.accounts.containers.workspaces.tags.create @mutable tagmanager.accounts.containers.workspaces.tags.update
  --workspace-id: string # GTM Workspace ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/tags"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: blockingRuleId, var: blocking_rule_id}, {name: blockingTriggerId, var: blocking_trigger_id}, {name: consentSettings, var: consent_settings}, {name: containerId, var: container_id}, {name: fingerprint, var: fingerprint}, {name: firingRuleId, var: firing_rule_id}, {name: firingTriggerId, var: firing_trigger_id}, {name: liveOnly, var: live_only}, {name: monitoringMetadata, var: monitoring_metadata}, {name: monitoringMetadataTagNameKey, var: monitoring_metadata_tag_name_key}, {name: name, var: name}, {name: notes, var: notes}, {name: parameter, var: parameter}, {name: parentFolderId, var: parent_folder_id}, {name: path, var: path}, {name: paused, var: paused}, {name: priority, var: priority}, {name: scheduleEndMs, var: schedule_end_ms}, {name: scheduleStartMs, var: schedule_start_ms}, {name: setupTag, var: setup_tag}, {name: tagFiringOption, var: tag_firing_option}, {name: tagId, var: tag_id}, {name: tagManagerUrl, var: tag_manager_url}, {name: teardownTag, var: teardown_tag}, {name: type, var: type}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, blocking_rule_id: $blocking_rule_id, blocking_trigger_id: $blocking_trigger_id, consent_settings: $consent_settings, container_id: $container_id, fingerprint: $fingerprint, firing_rule_id: $firing_rule_id, firing_trigger_id: $firing_trigger_id, live_only: $live_only, monitoring_metadata: $monitoring_metadata, monitoring_metadata_tag_name_key: $monitoring_metadata_tag_name_key, name: $name, notes: $notes, parameter: $parameter, parent_folder_id: $parent_folder_id, path: $path, paused: $paused, priority: $priority, schedule_end_ms: $schedule_end_ms, schedule_start_ms: $schedule_start_ms, setup_tag: $setup_tag, tag_firing_option: $tag_firing_option, tag_id: $tag_id, tag_manager_url: $tag_manager_url, teardown_tag: $teardown_tag, type: $type, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all GTM Templates of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/templates
# Returns: record<nextPageToken: string, template: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>>
# operationId: tagmanager.accounts.containers.workspaces.templates.list
export def "tagmanager-accounts-containers-workspaces-templates-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/templates"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GTM Custom Template.
#
# POST /tagmanager/v2/{parent}/templates
# Returns: record<accountId: string, containerId: string, fingerprint: string, galleryReference: record<host: string, isModified: bool, owner: string, repository: string, signature: string, version: string>, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.workspaces.templates.create
export def "tagmanager-accounts-containers-workspaces-templates-create" [
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
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Custom Template as computed at storage time. This value is recomputed whenever the template is modified.
  --gallery-reference: record # Represents the link between a custom template and an entry on the Community Template Gallery site. — shape: {host?: string, isModified?: bool, owner?: string, repository?: string, signature?: string, version?: string}
  --name: string # Custom Template display name.
  --path: string # GTM Custom Template's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --template-data: string # The custom template in text format.
  --template-id: string # The Custom Template ID uniquely identifies the GTM custom template.
  --workspace-id: string # GTM Workspace ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/templates"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: containerId, var: container_id}, {name: fingerprint, var: fingerprint}, {name: galleryReference, var: gallery_reference}, {name: name, var: name}, {name: path, var: path}, {name: tagManagerUrl, var: tag_manager_url}, {name: templateData, var: template_data}, {name: templateId, var: template_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, container_id: $container_id, fingerprint: $fingerprint, gallery_reference: $gallery_reference, name: $name, path: $path, tag_manager_url: $tag_manager_url, template_data: $template_data, template_id: $template_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all GTM Triggers of a Container.
#
# GET /tagmanager/v2/{parent}/triggers
# Returns: record<nextPageToken: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>>
# operationId: tagmanager.accounts.containers.workspaces.triggers.list
export def "tagmanager-accounts-containers-workspaces-triggers-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/triggers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GTM Trigger.
#
# POST /tagmanager/v2/{parent}/triggers
# Returns: record<accountId: string, autoEventFilter: table<parameter: list, type: string>, checkValidation: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, containerId: string, continuousTimeMinMilliseconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, customEventFilter: table<parameter: list, type: string>, eventName: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, filter: table<parameter: list, type: string>, fingerprint: string, horizontalScrollPercentageList: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, interval: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, intervalSeconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, limit: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, maxTimerLengthSeconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, selector: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, tagManagerUrl: string, totalTimeMinMilliseconds: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, triggerId: string, type: string, uniqueTriggerId: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, verticalScrollPercentageList: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visibilitySelector: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visiblePercentageMax: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, visiblePercentageMin: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, waitForTags: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, waitForTagsTimeout: record<key: string, list: list<any>, map: list<any>, type: string, value: string>, workspaceId: string>
# operationId: tagmanager.accounts.containers.workspaces.triggers.create
export def "tagmanager-accounts-containers-workspaces-triggers-create" [
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
  --account-id: string # GTM Account ID.
  --auto-event-filter: list # Used in the case of auto event tracking. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --check-validation: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --container-id: string # GTM Container ID.
  --continuous-time-min-milliseconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --custom-event-filter: list # Used in the case of custom event, which is fired iff all Conditions are true. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --event-name: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --filter: list # The trigger will only fire iff all Conditions are true. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {parameter?: list, type?: "conditionTypeUnspecified"|"equals"|"contains"|"startsWith"|"endsWith"|"matchRegex"|"greater"|"greaterOrEquals"|"less"|"lessOrEquals"|"cssSelector"|"urlMatches"}
  --fingerprint: string # The fingerprint of the GTM Trigger as computed at storage time. This value is recomputed whenever the trigger is modified.
  --horizontal-scroll-percentage-list: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --interval: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --interval-seconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --limit: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --max-timer-length-seconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --name: string # Trigger display name. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --notes: string # User notes on how to apply this trigger in the container. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --parameter: list # Additional parameters. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parent-folder-id: string # Parent folder id.
  --path: string # GTM Trigger's API relative path.
  --selector: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --total-time-min-milliseconds: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --trigger-id: string # The Trigger ID uniquely identifies the GTM Trigger.
  --type: string@type-completer-1 # Defines the data layer event that causes this trigger. @mutable tagmanager.accounts.containers.workspaces.triggers.create @mutable tagmanager.accounts.containers.workspaces.triggers.update
  --unique-trigger-id: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --vertical-scroll-percentage-list: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visibility-selector: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visible-percentage-max: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --visible-percentage-min: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --wait-for-tags: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --wait-for-tags-timeout: record # Represents a Google Tag Manager Parameter. — shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --workspace-id: string # GTM Workspace ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/triggers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: autoEventFilter, var: auto_event_filter}, {name: checkValidation, var: check_validation}, {name: containerId, var: container_id}, {name: continuousTimeMinMilliseconds, var: continuous_time_min_milliseconds}, {name: customEventFilter, var: custom_event_filter}, {name: eventName, var: event_name}, {name: filter, var: filter}, {name: fingerprint, var: fingerprint}, {name: horizontalScrollPercentageList, var: horizontal_scroll_percentage_list}, {name: interval, var: interval}, {name: intervalSeconds, var: interval_seconds}, {name: limit, var: limit}, {name: maxTimerLengthSeconds, var: max_timer_length_seconds}, {name: name, var: name}, {name: notes, var: notes}, {name: parameter, var: parameter}, {name: parentFolderId, var: parent_folder_id}, {name: path, var: path}, {name: selector, var: selector}, {name: tagManagerUrl, var: tag_manager_url}, {name: totalTimeMinMilliseconds, var: total_time_min_milliseconds}, {name: triggerId, var: trigger_id}, {name: type, var: type}, {name: uniqueTriggerId, var: unique_trigger_id}, {name: verticalScrollPercentageList, var: vertical_scroll_percentage_list}, {name: visibilitySelector, var: visibility_selector}, {name: visiblePercentageMax, var: visible_percentage_max}, {name: visiblePercentageMin, var: visible_percentage_min}, {name: waitForTags, var: wait_for_tags}, {name: waitForTagsTimeout, var: wait_for_tags_timeout}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, auto_event_filter: $auto_event_filter, check_validation: $check_validation, container_id: $container_id, continuous_time_min_milliseconds: $continuous_time_min_milliseconds, custom_event_filter: $custom_event_filter, event_name: $event_name, filter: $filter, fingerprint: $fingerprint, horizontal_scroll_percentage_list: $horizontal_scroll_percentage_list, interval: $interval, interval_seconds: $interval_seconds, limit: $limit, max_timer_length_seconds: $max_timer_length_seconds, name: $name, notes: $notes, parameter: $parameter, parent_folder_id: $parent_folder_id, path: $path, selector: $selector, tag_manager_url: $tag_manager_url, total_time_min_milliseconds: $total_time_min_milliseconds, trigger_id: $trigger_id, type: $type, unique_trigger_id: $unique_trigger_id, vertical_scroll_percentage_list: $vertical_scroll_percentage_list, visibility_selector: $visibility_selector, visible_percentage_max: $visible_percentage_max, visible_percentage_min: $visible_percentage_min, wait_for_tags: $wait_for_tags, wait_for_tags_timeout: $wait_for_tags_timeout, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all users that have access to the account along with Account and Container user access granted to each of them.
#
# GET /tagmanager/v2/{parent}/user_permissions
# Returns: record<nextPageToken: string, userPermission: table<accountAccess: record, accountId: string, containerAccess: list, emailAddress: string, path: string>>
# operationId: tagmanager.accounts.user_permissions.list
export def "tagmanager-accounts-user-permissions-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/user_permissions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a user's Account & Container access.
#
# POST /tagmanager/v2/{parent}/user_permissions
# Returns: record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string>
# operationId: tagmanager.accounts.user_permissions.create
export def "tagmanager-accounts-user-permissions-create" [
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
  --account-access: record # Defines the Google Tag Manager Account access permissions. — shape: {permission?: "accountPermissionUnspecified"|"noAccess"|"user"|"admin"}
  --account-id: string # The Account ID uniquely identifies the GTM Account.
  --container-access: list # GTM Container access permissions. @mutable tagmanager.accounts.permissions.create @mutable tagmanager.accounts.permissions.update — item shape: {containerId?: string, permission?: "containerPermissionUnspecified"|"noAccess"|"read"|"edit"|"approve"|"publish"}
  --email-address: string # User's email address. @mutable tagmanager.accounts.permissions.create
  --path: string # GTM UserPermission's API relative path.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/user_permissions"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountAccess, var: account_access}, {name: accountId, var: account_id}, {name: containerAccess, var: container_access}, {name: emailAddress, var: email_address}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_access: $account_access, account_id: $account_id, container_access: $container_access, email_address: $email_address, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all GTM Variables of a Container.
#
# GET /tagmanager/v2/{parent}/variables
# Returns: record<nextPageToken: string, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>>
# operationId: tagmanager.accounts.containers.workspaces.variables.list
export def "tagmanager-accounts-containers-workspaces-variables-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/variables"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GTM Variable.
#
# POST /tagmanager/v2/{parent}/variables
# Returns: record<accountId: string, containerId: string, disablingTriggerId: list<string>, enablingTriggerId: list<string>, fingerprint: string, formatValue: record<caseConversionType: string, convertFalseToValue: record<key: string, list: list, map: list, type: string, value: string>, convertNullToValue: record<key: string, list: list, map: list, type: string, value: string>, convertTrueToValue: record<key: string, list: list, map: list, type: string, value: string>, convertUndefinedToValue: record<key: string, list: list, map: list, type: string, value: string>>, name: string, notes: string, parameter: table<key: string, list: list, map: list, type: string, value: string>, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.workspaces.variables.create
export def "tagmanager-accounts-containers-workspaces-variables-create" [
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
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --disabling-trigger-id: list<string> # For mobile containers only: A list of trigger IDs for disabling conditional variables; the variable is enabled if one of the enabling trigger is true while all the disabling trigger are false. Treated as an unordered set. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --enabling-trigger-id: list<string> # For mobile containers only: A list of trigger IDs for enabling conditional variables; the variable is enabled if one of the enabling triggers is true while all the disabling triggers are false. Treated as an unordered set. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --fingerprint: string # The fingerprint of the GTM Variable as computed at storage time. This value is recomputed whenever the variable is modified.
  --format-value: record # shape: {caseConversionType?: "none"|"lowercase"|"uppercase", convertFalseToValue?: record, convertNullToValue?: record, convertTrueToValue?: record, convertUndefinedToValue?: record}
  --name: string # Variable display name. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --notes: string # User notes on how to apply this variable in the container. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --parameter: list # The variable's parameters. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update — item shape: {key?: string, list?: list, map?: list, type?: "typeUnspecified"|"template"|"integer"|"boolean"|"list"|"map"|"triggerReference"|"tagReference", value?: string}
  --parent-folder-id: string # Parent folder id.
  --path: string # GTM Variable's API relative path.
  --schedule-end-ms: string # The end timestamp in milliseconds to schedule a variable. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update (format: int64)
  --schedule-start-ms: string # The start timestamp in milliseconds to schedule a variable. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update (format: int64)
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string # GTM Variable Type. @mutable tagmanager.accounts.containers.workspaces.variables.create @mutable tagmanager.accounts.containers.workspaces.variables.update
  --variable-id: string # The Variable ID uniquely identifies the GTM Variable.
  --workspace-id: string # GTM Workspace ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/variables"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: containerId, var: container_id}, {name: disablingTriggerId, var: disabling_trigger_id}, {name: enablingTriggerId, var: enabling_trigger_id}, {name: fingerprint, var: fingerprint}, {name: formatValue, var: format_value}, {name: name, var: name}, {name: notes, var: notes}, {name: parameter, var: parameter}, {name: parentFolderId, var: parent_folder_id}, {name: path, var: path}, {name: scheduleEndMs, var: schedule_end_ms}, {name: scheduleStartMs, var: schedule_start_ms}, {name: tagManagerUrl, var: tag_manager_url}, {name: type, var: type}, {name: variableId, var: variable_id}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, container_id: $container_id, disabling_trigger_id: $disabling_trigger_id, enabling_trigger_id: $enabling_trigger_id, fingerprint: $fingerprint, format_value: $format_value, name: $name, notes: $notes, parameter: $parameter, parent_folder_id: $parent_folder_id, path: $path, schedule_end_ms: $schedule_end_ms, schedule_start_ms: $schedule_start_ms, tag_manager_url: $tag_manager_url, type: $type, variable_id: $variable_id, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Container Versions of a GTM Container.
#
# GET /tagmanager/v2/{parent}/version_headers
# Returns: record<containerVersionHeader: table<accountId: string, containerId: string, containerVersionId: string, deleted: bool, name: string, numClients: string, numCustomTemplates: string, numGtagConfigs: string, numMacros: string, numRules: string, numTags: string, numTransformations: string, numTriggers: string, numVariables: string, numZones: string, path: string>, nextPageToken: string>
# operationId: tagmanager.accounts.containers.version_headers.list
export def "tagmanager-accounts-containers-version-headers-list" [
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
  --include-deleted: oneof<nothing, bool> # Also retrieve deleted (archived) versions when true.
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/version_headers"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: includeDeleted, var: include_deleted}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, include_deleted: $include_deleted, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the latest container version header
#
# GET /tagmanager/v2/{parent}/version_headers:latest
# Returns: record<accountId: string, containerId: string, containerVersionId: string, deleted: bool, name: string, numClients: string, numCustomTemplates: string, numGtagConfigs: string, numMacros: string, numRules: string, numTags: string, numTransformations: string, numTriggers: string, numVariables: string, numZones: string, path: string>
# operationId: tagmanager.accounts.containers.version_headers.latest
export def "tagmanager-accounts-containers-version-headers-latest" [
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
    path: "/tagmanager/v2/{parent}/version_headers:latest"
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

# Gets the live (i.e. published) container version
#
# GET /tagmanager/v2/{parent}/versions:live
# Returns: record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>>
# operationId: tagmanager.accounts.containers.versions.live
export def "tagmanager-accounts-containers-versions-live" [
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
    path: "/tagmanager/v2/{parent}/versions:live"
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

# Lists all Workspaces that belong to a GTM Container.
#
# GET /tagmanager/v2/{parent}/workspaces
# Returns: record<nextPageToken: string, workspace: table<accountId: string, containerId: string, description: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, workspaceId: string>>
# operationId: tagmanager.accounts.containers.workspaces.list
export def "tagmanager-accounts-containers-workspaces-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/workspaces"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Workspace.
#
# POST /tagmanager/v2/{parent}/workspaces
# Returns: record<accountId: string, containerId: string, description: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.workspaces.create
export def "tagmanager-accounts-containers-workspaces-create" [
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
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --description: string # Workspace description. @mutable tagmanager.accounts.containers.workspaces.create @mutable tagmanager.accounts.containers.workspaces.update
  --fingerprint: string # The fingerprint of the GTM Workspace as computed at storage time. This value is recomputed whenever the workspace is modified.
  --name: string # Workspace display name. @mutable tagmanager.accounts.containers.workspaces.create @mutable tagmanager.accounts.containers.workspaces.update
  --path: string # GTM Workspace's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --workspace-id: string # The Workspace ID uniquely identifies the GTM Workspace.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/workspaces"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: containerId, var: container_id}, {name: description, var: description}, {name: fingerprint, var: fingerprint}, {name: name, var: name}, {name: path, var: path}, {name: tagManagerUrl, var: tag_manager_url}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, container_id: $container_id, description: $description, fingerprint: $fingerprint, name: $name, path: $path, tag_manager_url: $tag_manager_url, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all GTM Zones of a GTM container workspace.
#
# GET /tagmanager/v2/{parent}/zones
# Returns: record<nextPageToken: string, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>>
# operationId: tagmanager.accounts.containers.workspaces.zones.list
export def "tagmanager-accounts-containers-workspaces-zones-list" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{parent}/zones"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a GTM Zone.
#
# POST /tagmanager/v2/{parent}/zones
# Returns: record<accountId: string, boundary: record<condition: list<record>, customEvaluationTriggerId: list<string>>, childContainer: table<nickname: string, publicId: string>, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record<enable: bool, whitelistedTypeId: list<string>>, workspaceId: string, zoneId: string>
# operationId: tagmanager.accounts.containers.workspaces.zones.create
export def "tagmanager-accounts-containers-workspaces-zones-create" [
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
  --account-id: string # GTM Account ID.
  --boundary: record # Represents a Zone's boundaries. — shape: {condition?: list, customEvaluationTriggerId?: list<string>}
  --child-container: list # Containers that are children of this Zone. — item shape: {nickname?: string, publicId?: string}
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Zone as computed at storage time. This value is recomputed whenever the zone is modified.
  --name: string # Zone display name.
  --notes: string # User notes on how to apply this zone in the container.
  --path: string # GTM Zone's API relative path.
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type-restriction: record # Represents a Zone's type restrictions. — shape: {enable?: bool, whitelistedTypeId?: list<string>}
  --workspace-id: string # GTM Workspace ID.
  --zone-id: string # The Zone ID uniquely identifies the GTM Zone.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{parent}/zones"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: boundary, var: boundary}, {name: childContainer, var: child_container}, {name: containerId, var: container_id}, {name: fingerprint, var: fingerprint}, {name: name, var: name}, {name: notes, var: notes}, {name: path, var: path}, {name: tagManagerUrl, var: tag_manager_url}, {name: typeRestriction, var: type_restriction}, {name: workspaceId, var: workspace_id}, {name: zoneId, var: zone_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, boundary: $boundary, child_container: $child_container, container_id: $container_id, fingerprint: $fingerprint, name: $name, notes: $notes, path: $path, tag_manager_url: $tag_manager_url, type_restriction: $type_restriction, workspace_id: $workspace_id, zone_id: $zone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from the account, revoking access to it and all of its containers.
#
# DELETE /tagmanager/v2/{path}
# operationId: tagmanager.accounts.user_permissions.delete
export def "tagmanager-accounts-user-permissions-delete" [
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
  --type: list<string> # The types of built-in variables to delete.
]: nothing -> any {
  http-request {
    method: delete
    path: "/tagmanager/v2/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: type, var: type, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a user's Account & Container access.
#
# GET /tagmanager/v2/{path}
# Returns: record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string>
# operationId: tagmanager.accounts.user_permissions.get
export def "tagmanager-accounts-user-permissions-get" [
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
  --container-version-id: string # The GTM ContainerVersion ID. Specify published to retrieve the currently published version.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tagmanager/v2/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: containerVersionId, var: container_version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, container_version_id: $container_version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a user's Account & Container access.
#
# PUT /tagmanager/v2/{path}
# Returns: record<accountAccess: record<permission: string>, accountId: string, containerAccess: table<containerId: string, permission: string>, emailAddress: string, path: string>
# operationId: tagmanager.accounts.user_permissions.update
export def "tagmanager-accounts-user-permissions-update" [
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
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the zone in storage.
  --account-access: record # Defines the Google Tag Manager Account access permissions. — shape: {permission?: "accountPermissionUnspecified"|"noAccess"|"user"|"admin"}
  --account-id: string # The Account ID uniquely identifies the GTM Account.
  --container-access: list # GTM Container access permissions. @mutable tagmanager.accounts.permissions.create @mutable tagmanager.accounts.permissions.update — item shape: {containerId?: string, permission?: "containerPermissionUnspecified"|"noAccess"|"read"|"edit"|"approve"|"publish"}
  --email-address: string # User's email address. @mutable tagmanager.accounts.permissions.create
  --body-path: string # GTM UserPermission's API relative path. (spec name: path)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tagmanager/v2/{path}"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fingerprint, var: fingerprint}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountAccess, var: account_access}, {name: accountId, var: account_id}, {name: containerAccess, var: container_access}, {name: emailAddress, var: email_address}, {name: path, var: body_path}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fingerprint: $fingerprint, account_access: $account_access, account_id: $account_id, container_access: $container_access, email_address: $email_address, body_path: $body_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reverts changes to a GTM Built-In Variables in a GTM Workspace.
#
# POST /tagmanager/v2/{path}/built_in_variables:revert
# Returns: record<enabled: bool>
# operationId: tagmanager.accounts.containers.workspaces.built_in_variables.revert
export def "tagmanager-accounts-containers-workspaces-built-in-variables-revert" [
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
  --type: string@type-completer-2 # The type of built-in variable to revert.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tagmanager/v2/{path}/built_in_variables:revert"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finds conflicting and modified entities in the workspace.
#
# GET /tagmanager/v2/{path}/status
# Returns: record<mergeConflict: table<entityInBaseVersion: record, entityInWorkspace: record>, workspaceChange: table<changeStatus: string, client: record, folder: record, tag: record, trigger: record, variable: record>>
# operationId: tagmanager.accounts.containers.workspaces.getStatus
export def "tagmanager-accounts-containers-workspaces-get-status" [
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
    path: "/tagmanager/v2/{path}/status"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Combines Containers.
#
# POST /tagmanager/v2/{path}:combine
# Returns: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>
# operationId: tagmanager.accounts.containers.combine
export def "tagmanager-accounts-containers-combine" [
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
  --allow-user-permission-feature-update: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --container-id: string # ID of container that will be merged into the current container.
  --setting-source: string@setting-source-completer # Specify the source of config setting after combine
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tagmanager/v2/{path}:combine"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: allowUserPermissionFeatureUpdate, var: allow_user_permission_feature_update}, {name: containerId, var: container_id}, {name: settingSource, var: setting_source}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, allow_user_permission_feature_update: $allow_user_permission_feature_update, container_id: $container_id, setting_source: $setting_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a Container Version from the entities present in the workspace, deletes the workspace, and sets the base container version to the newly created version.
#
# POST /tagmanager/v2/{path}:create_version
# Returns: record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>, newWorkspacePath: string, syncStatus: record<mergeConflict: bool, syncError: bool>>
# operationId: tagmanager.accounts.containers.workspaces.create_version
export def "tagmanager-accounts-containers-workspaces-create-version" [
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
  --name: string # The name of the container version to be created.
  --notes: string # The notes of the container version to be created.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{path}:create_version"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: notes, var: notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, name: $name, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all entities in a GTM Folder.
#
# POST /tagmanager/v2/{path}:entities
# Returns: record<nextPageToken: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>>
# operationId: tagmanager.accounts.containers.workspaces.folders.entities
export def "tagmanager-accounts-containers-workspaces-folders-entities" [
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
  --page-token: string # Continuation token for fetching the next page of results.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tagmanager/v2/{path}:entities"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves entities to a GTM Folder.
#
# POST /tagmanager/v2/{path}:move_entities_to_folder
# operationId: tagmanager.accounts.containers.workspaces.folders.move_entities_to_folder
export def "tagmanager-accounts-containers-workspaces-folders-move-entities-to-folder" [
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
  --tag-id: list<string> # The tags to be moved to the folder.
  --trigger-id: list<string> # The triggers to be moved to the folder.
  --variable-id: list<string> # The variables to be moved to the folder.
  --account-id: string # GTM Account ID.
  --container-id: string # GTM Container ID.
  --fingerprint: string # The fingerprint of the GTM Folder as computed at storage time. This value is recomputed whenever the folder is modified.
  --folder-id: string # The Folder ID uniquely identifies the GTM Folder.
  --name: string # Folder display name. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --notes: string # User notes on how to apply this folder in the container. @mutable tagmanager.accounts.containers.workspaces.folders.create @mutable tagmanager.accounts.containers.workspaces.folders.update
  --body-path: string # GTM Folder's API relative path. (spec name: path)
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --workspace-id: string # GTM Workspace ID.
]: any -> any {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{path}:move_entities_to_folder"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: tagId, var: tag_id, style: multi}, {name: triggerId, var: trigger_id, style: multi}, {name: variableId, var: variable_id, style: multi}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: containerId, var: container_id}, {name: fingerprint, var: fingerprint}, {name: folderId, var: folder_id}, {name: name, var: name}, {name: notes, var: notes}, {name: path, var: body_path}, {name: tagManagerUrl, var: tag_manager_url}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, tag_id: $tag_id, trigger_id: $trigger_id, variable_id: $variable_id, account_id: $account_id, container_id: $container_id, fingerprint: $fingerprint, folder_id: $folder_id, name: $name, notes: $notes, body_path: $body_path, tag_manager_url: $tag_manager_url, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move Tag ID out of a Container.
#
# POST /tagmanager/v2/{path}:move_tag_id
# Returns: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>
# operationId: tagmanager.accounts.containers.move_tag_id
export def "tagmanager-accounts-containers-move-tag-id" [
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
  --allow-user-permission-feature-update: oneof<nothing, bool> # Must be set to true to allow features.user_permissions to change from false to true. If this operation causes an update but this bit is false, the operation will fail.
  --copy-settings: oneof<nothing, bool> # Whether or not to copy tag settings from this tag to the new tag.
  --copy-terms-of-service: oneof<nothing, bool> # Must be set to true to accept all terms of service agreements copied from the current tag to the newly created tag. If this bit is false, the operation will fail.
  --copy-users: oneof<nothing, bool> # Whether or not to copy users from this tag to the new tag.
  --tag-id: string # Tag ID to be removed from the current Container.
  --tag-name: string # The name for the newly created tag.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tagmanager/v2/{path}:move_tag_id"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: allowUserPermissionFeatureUpdate, var: allow_user_permission_feature_update}, {name: copySettings, var: copy_settings}, {name: copyTermsOfService, var: copy_terms_of_service}, {name: copyUsers, var: copy_users}, {name: tagId, var: tag_id}, {name: tagName, var: tag_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, allow_user_permission_feature_update: $allow_user_permission_feature_update, copy_settings: $copy_settings, copy_terms_of_service: $copy_terms_of_service, copy_users: $copy_users, tag_id: $tag_id, tag_name: $tag_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publishes a Container Version.
#
# POST /tagmanager/v2/{path}:publish
# Returns: record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>>
# operationId: tagmanager.accounts.containers.versions.publish
export def "tagmanager-accounts-containers-versions-publish" [
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
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the container version in storage.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tagmanager/v2/{path}:publish"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fingerprint, var: fingerprint}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fingerprint: $fingerprint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Quick previews a workspace by creating a fake container version from all entities in the provided workspace.
#
# POST /tagmanager/v2/{path}:quick_preview
# Returns: record<compilerError: bool, containerVersion: record<accountId: string, builtInVariable: list<record>, client: list<record>, container: record<accountId: string, containerId: string, domainName: list, features: record, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list, tagManagerUrl: string, taggingServerUrls: list, usageContext: list>, containerId: string, containerVersionId: string, customTemplate: list<record>, deleted: bool, description: string, fingerprint: string, folder: list<record>, gtagConfig: list<record>, name: string, path: string, tag: list<record>, tagManagerUrl: string, trigger: list<record>, variable: list<record>, zone: list<record>>, syncStatus: record<mergeConflict: bool, syncError: bool>>
# operationId: tagmanager.accounts.containers.workspaces.quick_preview
export def "tagmanager-accounts-containers-workspaces-quick-preview" [
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
    method: post
    path: "/tagmanager/v2/{path}:quick_preview"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Re-generates the authorization code for a GTM Environment.
#
# POST /tagmanager/v2/{path}:reauthorize
# Returns: record<accountId: string, authorizationCode: string, authorizationTimestamp: string, containerId: string, containerVersionId: string, description: string, enableDebug: bool, environmentId: string, fingerprint: string, name: string, path: string, tagManagerUrl: string, type: string, url: string, workspaceId: string>
# operationId: tagmanager.accounts.containers.environments.reauthorize
export def "tagmanager-accounts-containers-environments-reauthorize" [
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
  --account-id: string # GTM Account ID.
  --authorization-code: string # The environment authorization code.
  --authorization-timestamp: string # The last update time-stamp for the authorization code. (format: google-datetime)
  --container-id: string # GTM Container ID.
  --container-version-id: string # Represents a link to a container version.
  --description: string # The environment description. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --enable-debug: oneof<nothing, bool> # Whether or not to enable debug by default for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --environment-id: string # GTM Environment ID uniquely identifies the GTM Environment.
  --fingerprint: string # The fingerprint of the GTM environment as computed at storage time. This value is recomputed whenever the environment is modified.
  --name: string # The environment display name. Can be set or changed only on USER type environments. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --body-path: string # GTM Environment's API relative path. (spec name: path)
  --tag-manager-url: string # Auto generated link to the tag manager UI
  --type: string@type-completer # The type of this environment.
  --url: string # Default preview page url for the environment. @mutable tagmanager.accounts.containers.environments.create @mutable tagmanager.accounts.containers.environments.update
  --workspace-id: string # Represents a link to a quick preview of a workspace.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{path}:reauthorize"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: authorizationCode, var: authorization_code}, {name: authorizationTimestamp, var: authorization_timestamp}, {name: containerId, var: container_id}, {name: containerVersionId, var: container_version_id}, {name: description, var: description}, {name: enableDebug, var: enable_debug}, {name: environmentId, var: environment_id}, {name: fingerprint, var: fingerprint}, {name: name, var: name}, {name: path, var: body_path}, {name: tagManagerUrl, var: tag_manager_url}, {name: type, var: type}, {name: url, var: url}, {name: workspaceId, var: workspace_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, account_id: $account_id, authorization_code: $authorization_code, authorization_timestamp: $authorization_timestamp, container_id: $container_id, container_version_id: $container_version_id, description: $description, enable_debug: $enable_debug, environment_id: $environment_id, fingerprint: $fingerprint, name: $name, body_path: $body_path, tag_manager_url: $tag_manager_url, type: $type, url: $url, workspace_id: $workspace_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resolves a merge conflict for a workspace entity by updating it to the resolved entity passed in the request.
#
# POST /tagmanager/v2/{path}:resolve_conflict
# operationId: tagmanager.accounts.containers.workspaces.resolve_conflict
export def "tagmanager-accounts-containers-workspaces-resolve-conflict" [
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
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the entity_in_workspace in the merge conflict.
  --change-status: string@change-status-completer # Represents how the entity has been changed in the workspace.
  --client: record # shape: {accountId?: string, clientId?: string, containerId?: string, fingerprint?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, priority?: int, tagManagerUrl?: string, type?: string, workspaceId?: string}
  --folder: record # Represents a Google Tag Manager Folder. — shape: {accountId?: string, containerId?: string, fingerprint?: string, folderId?: string, name?: string, notes?: string, path?: string, tagManagerUrl?: string, workspaceId?: string}
  --tag: record # Represents a Google Tag Manager Tag. — shape: {accountId?: string, blockingRuleId?: list<string>, blockingTriggerId?: list<string>, consentSettings?: record, containerId?: string, fingerprint?: string, firingRuleId?: list<string>, firingTriggerId?: list<string>, liveOnly?: bool, monitoringMetadata?: record, monitoringMetadataTagNameKey?: string, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, paused?: bool, priority?: record, scheduleEndMs?: string, scheduleStartMs?: string, setupTag?: list, ... (6 more fields)}
  --trigger: record # Represents a Google Tag Manager Trigger — shape: {accountId?: string, autoEventFilter?: list, checkValidation?: record, containerId?: string, continuousTimeMinMilliseconds?: record, customEventFilter?: list, eventName?: record, filter?: list, fingerprint?: string, horizontalScrollPercentageList?: record, interval?: record, intervalSeconds?: record, limit?: record, maxTimerLengthSeconds?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, selector?: record, tagManagerUrl?: string, ... (11 more fields)}
  --variable: record # Represents a Google Tag Manager Variable. — shape: {accountId?: string, containerId?: string, disablingTriggerId?: list<string>, enablingTriggerId?: list<string>, fingerprint?: string, formatValue?: record, name?: string, notes?: string, parameter?: list, parentFolderId?: string, path?: string, scheduleEndMs?: string, scheduleStartMs?: string, tagManagerUrl?: string, type?: string, variableId?: string, workspaceId?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/tagmanager/v2/{path}:resolve_conflict"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fingerprint, var: fingerprint}]
    body: {content_type: "application/json", kind: json, fields: [{name: changeStatus, var: change_status}, {name: client, var: client}, {name: folder, var: folder}, {name: tag, var: tag}, {name: trigger, var: trigger}, {name: variable, var: variable}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fingerprint: $fingerprint, change_status: $change_status, client: $client, folder: $folder, tag: $tag, trigger: $trigger, variable: $variable
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reverts changes to a GTM Zone in a GTM Workspace.
#
# POST /tagmanager/v2/{path}:revert
# Returns: record<zone: record<accountId: string, boundary: record<condition: list, customEvaluationTriggerId: list>, childContainer: list<record>, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record<enable: bool, whitelistedTypeId: list>, workspaceId: string, zoneId: string>>
# operationId: tagmanager.accounts.containers.workspaces.zones.revert
export def "tagmanager-accounts-containers-workspaces-zones-revert" [
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
  --fingerprint: string # When provided, this fingerprint must match the fingerprint of the zone in storage.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/tagmanager/v2/{path}:revert"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fingerprint, var: fingerprint}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fingerprint: $fingerprint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the latest version used for synchronization of workspaces when detecting conflicts and errors.
#
# POST /tagmanager/v2/{path}:set_latest
# Returns: record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>>
# operationId: tagmanager.accounts.containers.versions.set_latest
export def "tagmanager-accounts-containers-versions-set-latest" [
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
    method: post
    path: "/tagmanager/v2/{path}:set_latest"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the tagging snippet for a Container.
#
# GET /tagmanager/v2/{path}:snippet
# Returns: record<snippet: string>
# operationId: tagmanager.accounts.containers.snippet
export def "tagmanager-accounts-containers-snippet" [
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
    path: "/tagmanager/v2/{path}:snippet"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Syncs a workspace to the latest container version by updating all unmodified workspace entities and displaying conflicts for modified entities.
#
# POST /tagmanager/v2/{path}:sync
# Returns: record<mergeConflict: table<entityInBaseVersion: record, entityInWorkspace: record>, syncStatus: record<mergeConflict: bool, syncError: bool>>
# operationId: tagmanager.accounts.containers.workspaces.sync
export def "tagmanager-accounts-containers-workspaces-sync" [
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
    method: post
    path: "/tagmanager/v2/{path}:sync"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undeletes a Container Version.
#
# POST /tagmanager/v2/{path}:undelete
# Returns: record<accountId: string, builtInVariable: table<accountId: string, containerId: string, name: string, path: string, type: string, workspaceId: string>, client: table<accountId: string, clientId: string, containerId: string, fingerprint: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, priority: int, tagManagerUrl: string, type: string, workspaceId: string>, container: record<accountId: string, containerId: string, domainName: list<string>, features: record<supportBuiltInVariables: bool, supportClients: bool, supportEnvironments: bool, supportFolders: bool, supportGtagConfigs: bool, supportTags: bool, supportTemplates: bool, supportTriggers: bool, supportUserPermissions: bool, supportVariables: bool, supportVersions: bool, supportWorkspaces: bool, supportZones: bool>, fingerprint: string, name: string, notes: string, path: string, publicId: string, tagIds: list<string>, tagManagerUrl: string, taggingServerUrls: list<string>, usageContext: list<string>>, containerId: string, containerVersionId: string, customTemplate: table<accountId: string, containerId: string, fingerprint: string, galleryReference: record, name: string, path: string, tagManagerUrl: string, templateData: string, templateId: string, workspaceId: string>, deleted: bool, description: string, fingerprint: string, folder: table<accountId: string, containerId: string, fingerprint: string, folderId: string, name: string, notes: string, path: string, tagManagerUrl: string, workspaceId: string>, gtagConfig: table<accountId: string, containerId: string, fingerprint: string, gtagConfigId: string, parameter: list, path: string, tagManagerUrl: string, type: string, workspaceId: string>, name: string, path: string, tag: table<accountId: string, blockingRuleId: list, blockingTriggerId: list, consentSettings: record, containerId: string, fingerprint: string, firingRuleId: list, firingTriggerId: list, liveOnly: bool, monitoringMetadata: record, monitoringMetadataTagNameKey: string, name: string, notes: string, parameter: list, parentFolderId: string, path: string, paused: bool, priority: record, scheduleEndMs: string, scheduleStartMs: string, setupTag: list, tagFiringOption: string, tagId: string, tagManagerUrl: string, teardownTag: list, type: string, workspaceId: string>, tagManagerUrl: string, trigger: table<accountId: string, autoEventFilter: list, checkValidation: record, containerId: string, continuousTimeMinMilliseconds: record, customEventFilter: list, eventName: record, filter: list, fingerprint: string, horizontalScrollPercentageList: record, interval: record, intervalSeconds: record, limit: record, maxTimerLengthSeconds: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, selector: record, tagManagerUrl: string, totalTimeMinMilliseconds: record, triggerId: string, type: string, uniqueTriggerId: record, verticalScrollPercentageList: record, visibilitySelector: record, visiblePercentageMax: record, visiblePercentageMin: record, waitForTags: record, waitForTagsTimeout: record, workspaceId: string>, variable: table<accountId: string, containerId: string, disablingTriggerId: list, enablingTriggerId: list, fingerprint: string, formatValue: record, name: string, notes: string, parameter: list, parentFolderId: string, path: string, scheduleEndMs: string, scheduleStartMs: string, tagManagerUrl: string, type: string, variableId: string, workspaceId: string>, zone: table<accountId: string, boundary: record, childContainer: list, containerId: string, fingerprint: string, name: string, notes: string, path: string, tagManagerUrl: string, typeRestriction: record, workspaceId: string, zoneId: string>>
# operationId: tagmanager.accounts.containers.versions.undelete
export def "tagmanager-accounts-containers-versions-undelete" [
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
    method: post
    path: "/tagmanager/v2/{path}:undelete"
    path_params: [{name: path, var: path}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    path: $path, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
