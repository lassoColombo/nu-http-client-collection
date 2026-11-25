# Auto-generated client for  v4 (Hunt Valley)
# Source: https://api.apis.guru/v2/specs/drchrono.com/v4 (Hunt Valley)/openapi.json
# Auth: --token flag or $env._TOKEN

const CLIENT = {
  base_url: "https://app.drchrono.com"
  token_env_var: "_TOKEN"
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

def base-url-completer [] { ["https://app.drchrono.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    allergies-list: "record<data: table<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string>, next: string, previous: string>"
    allergies-create: "record<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string>"
    allergies-read: "record<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string>"
    amendments-list: "record<data: table<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int>, next: string, previous: string>"
    amendments-create: "record<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int>"
    amendments-read: "record<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int>"
    appointment-profiles-list: "record<data: table<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int>, next: string, previous: string>"
    appointment-profiles-create: "record<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int>"
    appointment-profiles-read: "record<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int>"
    appointment-templates-list: "record<data: table<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: list, profile: int, scheduled_time: string, week_days: list>, next: string, previous: string>"
    appointment-templates-create: "record<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: table<end: string, start: string>, profile: int, scheduled_time: string, week_days: list<int>>"
    appointment-templates-read: "record<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: table<end: string, start: string>, profile: int, scheduled_time: string, week_days: list<int>>"
    appointments-list: "record<data: table<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: list, billing_provider: string, billing_status: string, clinical_note: record, cloned_from: int, color: string, created_at: string, custom_fields: list, custom_vitals: list, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list, icd9_codes: list, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: list, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: list, supervising_provider: string, updated_at: string, vitals: record>, next: string, previous: string>"
    appointments-create: "record<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, billing_provider: string, billing_status: string, clinical_note: record<locked: bool, pdf: string, updated_at: string>, cloned_from: int, color: string, created_at: string, custom_fields: table<created_at: string, field_type: int, field_value: string, updated_at: string>, custom_vitals: table<value: string, vital_type: int>, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list<string>, icd9_codes: list<string>, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: table<id: int, scheduled_time: string, type: string>, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: table<appointment: string, datetime: string, from_status: string, to_status: string>, supervising_provider: string, updated_at: string, vitals: record<blood_pressure_1: int, blood_pressure_2: int, bmi: string, head_circumference: float, head_circumference_units: string, height: float, height_units: string, oxygen_saturation: float, pain: string, pulse: int, respiratory_rate: int, smoking_status: string, temperature: float, temperature_units: string, weight: float, weight_units: string>>"
    appointments-read: "record<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, billing_provider: string, billing_status: string, clinical_note: record<locked: bool, pdf: string, updated_at: string>, cloned_from: int, color: string, created_at: string, custom_fields: table<created_at: string, field_type: int, field_value: string, updated_at: string>, custom_vitals: table<value: string, vital_type: int>, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list<string>, icd9_codes: list<string>, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: table<id: int, scheduled_time: string, type: string>, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: table<appointment: string, datetime: string, from_status: string, to_status: string>, supervising_provider: string, updated_at: string, vitals: record<blood_pressure_1: int, blood_pressure_2: int, bmi: string, head_circumference: float, head_circumference_units: string, height: float, height_units: string, oxygen_saturation: float, pain: string, pulse: int, respiratory_rate: int, smoking_status: string, temperature: float, temperature_units: string, weight: float, weight_units: string>>"
    billing-profiles-list: "record<data: table<archived: bool, cpt_codes: list, created_at: string, custom_procedure_codes: list, doctor: string, hcpcs_codes: list, icd10_codes: list, icd9_codes: list, id: int, name: string, updated_at: string>, next: string, previous: string>"
    billing-profiles-read: "record<archived: bool, cpt_codes: table<code: string, diagnosis_pointers_icd10: list, diagnosis_pointers_icd9: list, modifiers: list, ndc_code: list, price: string, quantity: string>, created_at: string, custom_procedure_codes: table<code: string, price: string, quantity: string>, doctor: string, hcpcs_codes: table<code: string, diagnosis_pointers_icd10: list, diagnosis_pointers_icd9: list, modifiers: list, ndc_code: list, price: string, quantity: string>, icd10_codes: list<string>, icd9_codes: list<string>, id: int, name: string, updated_at: string>"
    care-plans-list: "record<data: table<appointment: string, code: string, code_system: string, created_at: string, description: string, id: int, instructions: string, patient: string, plan_type: string, scheduled_date: string, title: string, updated_at: string>, next: string, previous: string>"
    care-plans-read: "record<appointment: string, code: string, code_system: string, created_at: string, description: string, id: int, instructions: string, patient: string, plan_type: string, scheduled_date: string, title: string, updated_at: string>"
    care-team-members-list: "record<data: table<appointment: string, created_at: string, id: int, patient: string, user: string>, next: string, previous: string>"
    care-team-members-read: "record<appointment: string, created_at: string, id: int, patient: string, user: string>"
    claim-billing-notes-list: "record<data: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, next: string, previous: string>"
    claim-billing-notes-create: "record<appointment: int, created_at: string, created_by: string, id: int, text: string>"
    claim-billing-notes-read: "record<appointment: int, created_at: string, created_by: string, id: int, text: string>"
    clinical-note-field-types-list: "record<data: table<allowed_values: list, archived: bool, clinical_note_template: string, comment: string, data_type: string, id: int, name: string, required: bool>, next: string, previous: string>"
    clinical-note-field-types-read: "record<allowed_values: list<string>, archived: bool, clinical_note_template: string, comment: string, data_type: string, id: int, name: string, required: bool>"
    clinical-note-field-values-list: "record<data: table<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string>, next: string, previous: string>"
    clinical-note-field-values-create: "record<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string>"
    clinical-note-field-values-read: "record<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string>"
    clinical-note-templates-list: "record<data: table<archived: bool, clinical_note_fields: list, doctor: string, id: int, is_onpatient: bool, is_persistent: bool, name: string, order: record, updated_at: string>, next: string, previous: string>"
    clinical-note-templates-read: "record<archived: bool, clinical_note_fields: table<allowed_values: list, archived: bool, clinical_note_template: int, data_type: string, name: string, required: bool>, doctor: string, id: int, is_onpatient: bool, is_persistent: bool, name: string, order: record<on_complete_note: int, on_ipad: int>, updated_at: string>"
    clinical-notes-list: "record<data: table<appointment: string, archived: bool, clinical_note_sections: list, patient: string>, next: string, previous: string>"
    clinical-notes-read: "record<appointment: string, archived: bool, clinical_note_sections: table<clinical_note_template: int, name: string, values: list>, patient: string>"
    comm-logs-list: "record<data: table<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string>, next: string, previous: string>"
    comm-logs-create: "record<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string>"
    comm-logs-read: "record<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string>"
    consent-forms-list: "record<data: table<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string>, next: string, previous: string>"
    consent-forms-create: "record<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string>"
    consent-forms-read: "record<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string>"
    custom-appointment-fields-list: "record<data: table<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string>, next: string, previous: string>"
    custom-appointment-fields-create: "record<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string>"
    custom-appointment-fields-read: "record<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string>"
    custom-demographics-list: "record<data: table<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string>, next: string, previous: string>"
    custom-demographics-create: "record<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string>"
    custom-demographics-read: "record<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string>"
    custom-insurance-plan-names-list: "record<data: table<archived: bool, created_at: string, doctor: string, id: int, insurance_plan_name: string, updated_at: string, user: string>, next: string, previous: string>"
    custom-insurance-plan-names-read: "record<archived: bool, created_at: string, doctor: string, id: int, insurance_plan_name: string, updated_at: string, user: string>"
    custom-vitals-list: "record<data: table<allowed_values: list, archived: bool, data_type: string, description: string, doctor: string, fraction_delimiter: string, id: int, is_fraction_field: bool, name: string, unit: string>, next: string, previous: string>"
    custom-vitals-read: "record<allowed_values: list<string>, archived: bool, data_type: string, description: string, doctor: string, fraction_delimiter: string, id: int, is_fraction_field: bool, name: string, unit: string>"
    doctors-list: "record<data: table<cell_phone: string, country: string, email: string, first_name: string, group_npi_number: string, home_phone: string, id: int, is_account_suspended: bool, job_title: string, last_name: string, npi_number: string, office_phone: string, practice_group: string, practice_group_name: string, profile_picture: string, specialty: string, suffix: string, timezone: string, website: string>, next: string, previous: string>"
    doctors-read: "record<cell_phone: string, country: string, email: string, first_name: string, group_npi_number: string, home_phone: string, id: int, is_account_suspended: bool, job_title: string, last_name: string, npi_number: string, office_phone: string, practice_group: string, practice_group_name: string, profile_picture: string, specialty: string, suffix: string, timezone: string, website: string>"
    documents-list: "record<data: table<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string>, next: string, previous: string>"
    documents-create: "record<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string>"
    documents-read: "record<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string>"
    eligibility-checks-list: "record<data: table<appointment: string, cob_level: string, coverage_details: string, coverage_subscriber: string, eligibility: string, patient: string, payer_name: string, query_date: string, request_service_type: string, service_type_description: string>, next: string, previous: string>"
    eligibility-checks-read: "record<appointment: string, cob_level: string, coverage_details: string, coverage_subscriber: string, eligibility: string, patient: string, payer_name: string, query_date: string, request_service_type: string, service_type_description: string>"
    eobs-list: "record<data: table<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string>, next: string, previous: string>"
    eobs-create: "record<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string>"
    eobs-read: "record<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string>"
    fee-schedules-list: "record<data: table<allowed_amount: float, base_price: float, billing_description: string, cash_price: float, code: string, code_type: string, cpt_hcpcs_modifier1: string, cpt_hcpcs_modifier2: string, cpt_hcpcs_modifier3: string, cpt_hcpcs_modifier4: string, created_at: string, description: string, doctor: int, id: int, insured_out_of_network_price: float, insured_price: float, ndc_code: string, ndc_quantity: float, ndc_units: string, office: int, payer_id: string, picklist_category: string, plan_name: string, updated_at: string>, next: string, previous: string>"
    fee-schedules-read: "record<allowed_amount: float, base_price: float, billing_description: string, cash_price: float, code: string, code_type: string, cpt_hcpcs_modifier1: string, cpt_hcpcs_modifier2: string, cpt_hcpcs_modifier3: string, cpt_hcpcs_modifier4: string, created_at: string, description: string, doctor: int, id: int, insured_out_of_network_price: float, insured_price: float, ndc_code: string, ndc_quantity: float, ndc_units: string, office: int, payer_id: string, picklist_category: string, plan_name: string, updated_at: string>"
    implantable-devices-list: "record<data: table<archived: bool, brand_name: string, company_name: string, created_at: string, expiration_date: string, gmdn_pt_name: string, id: int, manufacturing_date: string, patient: string, procedure: string, serial_number: string, status: string, udi: string, updated_at: string, version_or_model: string>, next: string, previous: string>"
    implantable-devices-read: "record<archived: bool, brand_name: string, company_name: string, created_at: string, expiration_date: string, gmdn_pt_name: string, id: int, manufacturing_date: string, patient: string, procedure: string, serial_number: string, status: string, udi: string, updated_at: string, version_or_model: string>"
    insurances-list: "record<data: table<payer_id: string, payer_name: string, state: string>, next: string, previous: string>"
    insurances-read: "record<payer_id: string, payer_name: string, state: string>"
    inventory-categories-list: "record<data: table<archived: bool, category_type: string, created_at: string, doctor: string, id: int, name: string, updated_at: string>, next: string, previous: string>"
    inventory-categories-read: "record<archived: bool, category_type: string, created_at: string, doctor: string, id: int, name: string, updated_at: string>"
    inventory-vaccines-list: "record<data: table<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string>, next: string, previous: string>"
    inventory-vaccines-create: "record<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string>"
    inventory-vaccines-read: "record<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string>"
    lab-documents-list: "record<data: table<document: string, id: int, lab_order: int, timestamp: string, type: string>, next: string, previous: string>"
    lab-documents-create: "record<document: string, id: int, lab_order: int, timestamp: string, type: string>"
    lab-documents-read: "record<document: string, id: int, lab_order: int, timestamp: string, type: string>"
    lab-orders-list: "record<data: table<accession_number: string, doctor: int, documents: list, icd10_codes: list, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>, next: string, previous: string>"
    lab-orders-create: "record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>"
    lab-orders-read: "record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>"
    lab-orders-summary-list: "record<data: table<accession_number: string, doctor: int, documents: list, icd10_codes: list, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>, next: string, previous: string>"
    lab-orders-summary-read: "record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>"
    lab-results-list: "record<data: table<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool>, next: string, previous: string>"
    lab-results-create: "record<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool>"
    lab-results-read: "record<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool>"
    lab-tests-list: "record<data: table<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string>, next: string, previous: string>"
    lab-tests-create: "record<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string>"
    lab-tests-read: "record<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string>"
    line-items-list: "record<data: table<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>, next: string, previous: string>"
    line-items-create: "record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>"
    line-items-read: "record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>"
    medications-list: "record<data: table<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string>, next: string, previous: string>"
    medications-create: "record<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string>"
    medications-read: "record<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string>"
    messages-list: "record<data: table<archived: bool, attachment: string, doctor: int, id: int, message_notes: list, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string>, next: string, previous: string>"
    messages-create: "record<archived: bool, attachment: string, doctor: int, id: int, message_notes: table<created_at: string, created_by: string, text: string>, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string>"
    messages-read: "record<archived: bool, attachment: string, doctor: int, id: int, message_notes: table<created_at: string, created_by: string, text: string>, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string>"
    offices-list: "record<data: table<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: list, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string>, next: string, previous: string>"
    offices-read: "record<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: table<day: int, hour: int, minute: int>, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string>"
    offices-add-exam-room: "record<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: table<day: int, hour: int, minute: int>, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string>"
    patient-communications-list: "record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string>"
    patient-communications-create: "record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>"
    patient-communications-read: "record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>"
    patient-flag-types-list: "record<data: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, next: string, previous: string>"
    patient-flag-types-create: "record<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>"
    patient-flag-types-read: "record<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>"
    patient-interventions-list: "record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string>"
    patient-interventions-create: "record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>"
    patient-interventions-read: "record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>"
    patient-lab-results-list: "record<data: table<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string>, next: string, previous: string>"
    patient-lab-results-create: "record<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string>"
    patient-lab-results-read: "record<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string>"
    patient-messages-list: "record<data: table<attachments: list, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string>, next: string, previous: string>"
    patient-messages-create: "record<attachments: table<attachment: string, created_at: string, doctor: int, updated_at: string>, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string>"
    patient-messages-read: "record<attachments: table<attachment: string, created_at: string, doctor: int, updated_at: string>, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string>"
    patient-payment-log-list: "record<data: table<action: string, amount: float, appointment: string, created_by: string, doctor: string, id: int, patient: string, payment_method: string, source: string, updated_at: string>, next: string, previous: string>"
    patient-payment-log-read: "record<action: string, amount: float, appointment: string, created_by: string, doctor: string, id: int, patient: string, payment_method: string, source: string, updated_at: string>"
    patient-payments-list: "record<data: table<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string>, next: string, previous: string>"
    patient-payments-create: "record<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string>"
    patient-payments-read: "record<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string>"
    patient-physical-exams-list: "record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string>"
    patient-physical-exams-create: "record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>"
    patient-physical-exams-read: "record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>"
    patient-risk-assessments-list: "record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string>"
    patient-risk-assessments-create: "record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>"
    patient-risk-assessments-read: "record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>"
    patient-vaccine-records-list: "record<data: table<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: list, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string>, next: string, previous: string>"
    patient-vaccine-records-create: "record<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: table<id: int, max_age_months: int, min_age_months: int, title: string>, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string>"
    patient-vaccine-records-read: "record<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: table<id: int, max_age_months: int, min_age_months: int, title: string>, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string>"
    patients-list: "record<data: table<address: string, auto_accident_insurance: record, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: list, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list, patient_flags: list, patient_flags_attached: list, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record, race: string, referring_doctor: record, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record, social_security_number: string, state: string, tertiary_insurance: record, updated_at: string, workers_comp_insurance: record, zip_code: string>, next: string, previous: string>"
    patients-create: "record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>"
    patients-read: "record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>"
    patients-onpatient-access-read: "record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>"
    patients-onpatient-access-create: "record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>"
    patients-summary-list: "record<data: table<address: string, auto_accident_insurance: record, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: list, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list, patient_flags: list, patient_flags_attached: list, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record, race: string, referring_doctor: record, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record, social_security_number: string, state: string, tertiary_insurance: record, updated_at: string, workers_comp_insurance: record, zip_code: string>, next: string, previous: string>"
    patients-summary-create: "record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>"
    patients-summary-read: "record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>"
    prescription-messages-list: "record<data: table<created_at: string, doctor: int, id: int, json_data: string, message_direction: string, message_status: string, message_type: string, parent_message: string, patient: int, pharmacy: string>, next: string, previous: string>"
    prescription-messages-read: "record<created_at: string, doctor: int, id: int, json_data: string, message_direction: string, message_status: string, message_type: string, parent_message: string, patient: int, pharmacy: string>"
    problems-list: "record<data: table<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string>, next: string, previous: string>"
    problems-create: "record<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string>"
    problems-read: "record<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string>"
    procedures-list: "record<data: table<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>, next: string, previous: string>"
    procedures-read: "record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>"
    reminder-profiles-list: "record<data: table<doctor: int, id: int, name: string, reminders: list>, next: string, previous: string>"
    reminder-profiles-create: "record<doctor: int, id: int, name: string, reminders: table<amount: int, type: string, unit: string>>"
    reminder-profiles-read: "record<doctor: int, id: int, name: string, reminders: table<amount: int, type: string, unit: string>>"
    sublabs-list: "record<data: table<facility_code: string, id: int, name: string, vendor_name: string>, next: string, previous: string>"
    sublabs-create: "record<facility_code: string, id: int, name: string, vendor_name: string>"
    sublabs-read: "record<facility_code: string, id: int, name: string, vendor_name: string>"
    task-categories-list: "record<data: table<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string>, next: string, previous: string>"
    task-categories-create: "record<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string>"
    task-categories-read: "record<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string>"
    task-notes-list: "record<data: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, next: string, previous: string>"
    task-notes-create: "record<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>"
    task-notes-read: "record<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>"
    task-statuses-list: "record<data: table<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string>, next: string, previous: string>"
    task-statuses-create: "record<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string>"
    task-statuses-read: "record<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string>"
    task-templates-list: "record<data: table<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string>, next: string, previous: string>"
    task-templates-create: "record<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string>"
    task-templates-read: "record<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string>"
    tasks-list: "record<data: table<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: list, category: int, created_at: string, created_by: string, due_date: record, id: int, notes: list, priority: string, status: int, title: string, updated_at: string>, next: string, previous: string>"
    tasks-create: "record<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: table<task: int, type: string, value: int>, category: int, created_at: string, created_by: string, due_date: record<time: string>, id: int, notes: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, priority: string, status: int, title: string, updated_at: string>"
    tasks-read: "record<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: table<task: int, type: string, value: int>, category: int, created_at: string, created_by: string, due_date: record<time: string>, id: int, notes: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, priority: string, status: int, title: string, updated_at: string>"
    transactions-list: "record<data: table<adjustment: float, adjustment_group_code: string, adjustment_reason: string, appointment: int, check_date: string, claim_status: string, created_at: string, doctor: int, id: int, ins_name: int, ins_paid: float, line_item: int, patient: int, posted_date: string, trace_number: string, updated_at: string>, next: string, previous: string>"
    transactions-read: "record<adjustment: float, adjustment_group_code: string, adjustment_reason: string, appointment: int, check_date: string, claim_status: string, created_at: string, doctor: int, id: int, ins_name: int, ins_paid: float, line_item: int, patient: int, posted_date: string, trace_number: string, updated_at: string>"
    user-groups-list: "record<data: table<archived: bool, created_at: string, id: int, members: list, name: string, practice_group: string, updated_at: string>, next: string, previous: string>"
    user-groups-read: "record<archived: bool, created_at: string, id: int, members: list<string>, name: string, practice_group: string, updated_at: string>"
    users-list: "record<data: table<doctor: string, id: string, is_doctor: string, is_staff: string, permissions: string, practice_group: string, username: string>, next: string, previous: string>"
    users-read: "record<doctor: string, id: string, is_doctor: string, is_staff: string, permissions: string, practice_group: string, username: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["allergies-list" "allergies-create" "allergies-read" "allergies-partial-update" "allergies-update" "amendments-list" "amendments-create" "amendments-delete" "amendments-read" "amendments-partial-update" "amendments-update" "appointment-profiles-list" "appointment-profiles-create" "appointment-profiles-delete" "appointment-profiles-read" "appointment-profiles-partial-update" "appointment-profiles-update" "appointment-templates-list" "appointment-templates-create" "appointment-templates-delete" "appointment-templates-read" "appointment-templates-partial-update" "appointment-templates-update" "appointments-list" "appointments-create" "appointments-delete" "appointments-read" "appointments-partial-update" "appointments-update" "billing-profiles-list" "billing-profiles-read" "care-plans-list" "care-plans-read" "care-team-members-list" "care-team-members-read" "claim-billing-notes-list" "claim-billing-notes-create" "claim-billing-notes-read" "clinical-note-field-types-list" "clinical-note-field-types-read" "clinical-note-field-values-list" "clinical-note-field-values-create" "clinical-note-field-values-read" "clinical-note-field-values-partial-update" "clinical-note-field-values-update" "clinical-note-templates-list" "clinical-note-templates-read" "clinical-notes-list" "clinical-notes-read" "comm-logs-list" "comm-logs-create" "comm-logs-read" "comm-logs-partial-update" "comm-logs-update" "consent-forms-list" "consent-forms-create" "consent-forms-read" "consent-forms-partial-update" "consent-forms-update" "consent-forms-apply-to-appointment" "consent-forms-unapply-from-appointment" "custom-appointment-fields-list" "custom-appointment-fields-create" "custom-appointment-fields-read" "custom-appointment-fields-partial-update" "custom-appointment-fields-update" "custom-demographics-list" "custom-demographics-create" "custom-demographics-read" "custom-demographics-partial-update" "custom-demographics-update" "custom-insurance-plan-names-list" "custom-insurance-plan-names-read" "custom-vitals-list" "custom-vitals-read" "doctors-list" "doctors-read" "documents-list" "documents-create" "documents-delete" "documents-read" "documents-partial-update" "documents-update" "eligibility-checks-list" "eligibility-checks-read" "eobs-list" "eobs-create" "eobs-read" "fee-schedules-list" "fee-schedules-read" "implantable-devices-list" "implantable-devices-read" "insurances-list" "insurances-read" "inventory-categories-list" "inventory-categories-read" "inventory-vaccines-list" "inventory-vaccines-create" "inventory-vaccines-read" "lab-documents-list" "lab-documents-create" "lab-documents-delete" "lab-documents-read" "lab-documents-partial-update" "lab-documents-update" "lab-orders-list" "lab-orders-create" "lab-orders-delete" "lab-orders-read" "lab-orders-partial-update" "lab-orders-update" "lab-orders-summary-list" "lab-orders-summary-read" "lab-results-list" "lab-results-create" "lab-results-delete" "lab-results-read" "lab-results-partial-update" "lab-results-update" "lab-tests-list" "lab-tests-create" "lab-tests-delete" "lab-tests-read" "lab-tests-partial-update" "lab-tests-update" "line-items-list" "line-items-create" "line-items-delete" "line-items-read" "line-items-partial-update" "line-items-update" "medications-list" "medications-create" "medications-read" "medications-partial-update" "medications-update" "medications-append-to-pharmacy-note" "messages-list" "messages-create" "messages-delete" "messages-read" "messages-partial-update" "messages-update" "offices-list" "offices-read" "offices-partial-update" "offices-update" "offices-add-exam-room" "patient-communications-list" "patient-communications-create" "patient-communications-read" "patient-communications-partial-update" "patient-communications-update" "patient-flag-types-list" "patient-flag-types-create" "patient-flag-types-read" "patient-flag-types-partial-update" "patient-flag-types-update" "patient-interventions-list" "patient-interventions-create" "patient-interventions-read" "patient-interventions-partial-update" "patient-interventions-update" "patient-lab-results-list" "patient-lab-results-create" "patient-lab-results-delete" "patient-lab-results-read" "patient-lab-results-partial-update" "patient-lab-results-update" "patient-messages-list" "patient-messages-create" "patient-messages-read" "patient-messages-partial-update" "patient-messages-update" "patient-payment-log-list" "patient-payment-log-read" "patient-payments-list" "patient-payments-create" "patient-payments-read" "patient-physical-exams-list" "patient-physical-exams-create" "patient-physical-exams-read" "patient-physical-exams-partial-update" "patient-physical-exams-update" "patient-risk-assessments-list" "patient-risk-assessments-create" "patient-risk-assessments-read" "patient-risk-assessments-partial-update" "patient-risk-assessments-update" "patient-vaccine-records-list" "patient-vaccine-records-create" "patient-vaccine-records-read" "patient-vaccine-records-partial-update" "patient-vaccine-records-update" "patients-list" "patients-create" "patients-delete" "patients-read" "patients-partial-update" "patients-update" "patients-ccda" "patients-onpatient-access-delete" "patients-onpatient-access-read" "patients-onpatient-access-create" "patients-qrda1" "patients-summary-list" "patients-summary-create" "patients-summary-delete" "patients-summary-read" "patients-summary-partial-update" "patients-summary-update" "prescription-messages-list" "prescription-messages-read" "problems-list" "problems-create" "problems-read" "problems-partial-update" "problems-update" "procedures-list" "procedures-read" "reminder-profiles-list" "reminder-profiles-create" "reminder-profiles-delete" "reminder-profiles-read" "reminder-profiles-partial-update" "reminder-profiles-update" "sublabs-list" "sublabs-create" "sublabs-delete" "sublabs-read" "sublabs-partial-update" "sublabs-update" "task-categories-list" "task-categories-create" "task-categories-read" "task-categories-partial-update" "task-categories-update" "task-notes-list" "task-notes-create" "task-notes-read" "task-notes-partial-update" "task-notes-update" "task-statuses-list" "task-statuses-create" "task-statuses-read" "task-statuses-partial-update" "task-statuses-update" "task-templates-list" "task-templates-create" "task-templates-read" "task-templates-partial-update" "task-templates-update" "tasks-list" "tasks-create" "tasks-read" "tasks-partial-update" "tasks-update" "transactions-list" "transactions-read" "user-groups-list" "user-groups-read" "users-list" "users-read" "commands"] | sort) } | get name | first)
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

# Retrieve or search patient allergies
#
# GET /api/allergies
# Returns: record<data: table<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string>, next: string, previous: string>
# operationId: allergies_list
export def "allergies-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/allergies"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient allergy
#
# POST /api/allergies
# Returns: record<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string>
# operationId: allergies_create
export def "allergies-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/allergies"
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient allergy
#
# GET /api/allergies/{id}
# Returns: record<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string>
# operationId: allergies_read
export def "allergies-read" [
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
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/allergies/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient allergy
#
# PATCH /api/allergies/{id}
# operationId: allergies_partial_update
export def "allergies-partial-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/allergies/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient allergy
#
# PUT /api/allergies/{id}
# operationId: allergies_update
export def "allergies-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/allergies/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient amendments. You can only interact with amendments created by your API application
#
# GET /api/amendments
# Returns: record<data: table<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int>, next: string, previous: string>
# operationId: amendments_list
export def "amendments-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/amendments"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: appointment, var: appointment}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, appointment: $appointment, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient amendments to a patient's clinical records
#
# POST /api/amendments
# Returns: record<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int>
# operationId: amendments_create
export def "amendments-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/amendments"
    query: [{name: appointment, var: appointment}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    appointment: $appointment, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing patient amendment, you can only interact with amendments created by your API application
#
# DELETE /api/amendments/{id}
# operationId: amendments_delete
export def "amendments-delete" [
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
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/amendments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: appointment, var: appointment}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, appointment: $appointment, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient amendment, you can only interact with amendments created by your API application
#
# GET /api/amendments/{id}
# Returns: record<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int>
# operationId: amendments_read
export def "amendments-read" [
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
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/amendments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: appointment, var: appointment}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, appointment: $appointment, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient amendment, you can only interact with amendments created by your API application
#
# PATCH /api/amendments/{id}
# operationId: amendments_partial_update
export def "amendments-partial-update" [
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
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/amendments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: appointment, var: appointment}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, appointment: $appointment, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient amendment, you can only interact with amendments created by your API application
#
# PUT /api/amendments/{id}
# operationId: amendments_update
export def "amendments-update" [
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
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/amendments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: appointment, var: appointment}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, appointment: $appointment, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search appointment profiles for a doctor's calendar
#
# GET /api/appointment_profiles
# Returns: record<data: table<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int>, next: string, previous: string>
# operationId: appointment_profiles_list
export def "appointment-profiles-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/appointment_profiles"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create appointment profiles for a doctor's calendar
#
# POST /api/appointment_profiles
# Returns: record<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int>
# operationId: appointment_profiles_create
export def "appointment-profiles-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/appointment_profiles"
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing appointment profile
#
# DELETE /api/appointment_profiles/{id}
# operationId: appointment_profiles_delete
export def "appointment-profiles-delete" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/appointment_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing appointment profile
#
# GET /api/appointment_profiles/{id}
# Returns: record<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int>
# operationId: appointment_profiles_read
export def "appointment-profiles-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/appointment_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing appointment profile
#
# PATCH /api/appointment_profiles/{id}
# operationId: appointment_profiles_partial_update
export def "appointment-profiles-partial-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/appointment_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing appointment profile
#
# PUT /api/appointment_profiles/{id}
# operationId: appointment_profiles_update
export def "appointment-profiles-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/appointment_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search appointment templates for a doctor's calendar
#
# GET /api/appointment_templates
# Returns: record<data: table<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: list, profile: int, scheduled_time: string, week_days: list>, next: string, previous: string>
# operationId: appointment_templates_list
export def "appointment-templates-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --profile: int
  --office: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/appointment_templates"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: profile, var: profile}, {name: office, var: office}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, profile: $profile, office: $office, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create appointment templates for a doctor's calendar
#
# POST /api/appointment_templates
# Returns: record<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: table<end: string, start: string>, profile: int, scheduled_time: string, week_days: list<int>>
# operationId: appointment_templates_create
export def "appointment-templates-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --profile: int
  --office: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/appointment_templates"
    query: [{name: profile, var: profile}, {name: office, var: office}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    profile: $profile, office: $office, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing appointment template
#
# DELETE /api/appointment_templates/{id}
# operationId: appointment_templates_delete
export def "appointment-templates-delete" [
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
  --profile: int
  --office: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/appointment_templates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: profile, var: profile}, {name: office, var: office}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, profile: $profile, office: $office, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing appointment template
#
# GET /api/appointment_templates/{id}
# Returns: record<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: table<end: string, start: string>, profile: int, scheduled_time: string, week_days: list<int>>
# operationId: appointment_templates_read
export def "appointment-templates-read" [
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
  --profile: int
  --office: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/appointment_templates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: profile, var: profile}, {name: office, var: office}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, profile: $profile, office: $office, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing appointment template
#
# PATCH /api/appointment_templates/{id}
# operationId: appointment_templates_partial_update
export def "appointment-templates-partial-update" [
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
  --profile: int
  --office: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/appointment_templates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: profile, var: profile}, {name: office, var: office}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, profile: $profile, office: $office, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing appointment template
#
# PUT /api/appointment_templates/{id}
# operationId: appointment_templates_update
export def "appointment-templates-update" [
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
  --profile: int
  --office: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/appointment_templates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: profile, var: profile}, {name: office, var: office}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, profile: $profile, office: $office, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search appointment or breaks. Note: Either `since`, `date` or `date_range` parameter must be specified.
#
# GET /api/appointments
# Returns: record<data: table<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: list, billing_provider: string, billing_status: string, clinical_note: record, cloned_from: int, color: string, created_at: string, custom_fields: list, custom_vitals: list, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list, icd9_codes: list, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: list, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: list, supervising_provider: string, updated_at: string, vitals: record>, next: string, previous: string>
# operationId: appointments_list
export def "appointments-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/appointments"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: status, var: status}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: date_range, var: date_range}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, status: $status, patient: $patient, office: $office, doctor: $doctor, since: $since, date_range: $date_range, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new appointment or break on doctor's calendar
#
# POST /api/appointments
# Returns: record<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, billing_provider: string, billing_status: string, clinical_note: record<locked: bool, pdf: string, updated_at: string>, cloned_from: int, color: string, created_at: string, custom_fields: table<created_at: string, field_type: int, field_value: string, updated_at: string>, custom_vitals: table<value: string, vital_type: int>, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list<string>, icd9_codes: list<string>, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: table<id: int, scheduled_time: string, type: string>, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: table<appointment: string, datetime: string, from_status: string, to_status: string>, supervising_provider: string, updated_at: string, vitals: record<blood_pressure_1: int, blood_pressure_2: int, bmi: string, head_circumference: float, head_circumference_units: string, height: float, height_units: string, oxygen_saturation: float, pain: string, pulse: int, respiratory_rate: int, smoking_status: string, temperature: float, temperature_units: string, weight: float, weight_units: string>>
# operationId: appointments_create
export def "appointments-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/appointments"
    query: [{name: status, var: status}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: date_range, var: date_range}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    status: $status, patient: $patient, office: $office, doctor: $doctor, since: $since, date_range: $date_range, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing appointment or break
#
# DELETE /api/appointments/{id}
# operationId: appointments_delete
export def "appointments-delete" [
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
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/appointments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: date_range, var: date_range}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, status: $status, patient: $patient, office: $office, doctor: $doctor, since: $since, date_range: $date_range, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing appointment or break
#
# GET /api/appointments/{id}
# Returns: record<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, billing_provider: string, billing_status: string, clinical_note: record<locked: bool, pdf: string, updated_at: string>, cloned_from: int, color: string, created_at: string, custom_fields: table<created_at: string, field_type: int, field_value: string, updated_at: string>, custom_vitals: table<value: string, vital_type: int>, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list<string>, icd9_codes: list<string>, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: table<id: int, scheduled_time: string, type: string>, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: table<appointment: string, datetime: string, from_status: string, to_status: string>, supervising_provider: string, updated_at: string, vitals: record<blood_pressure_1: int, blood_pressure_2: int, bmi: string, head_circumference: float, head_circumference_units: string, height: float, height_units: string, oxygen_saturation: float, pain: string, pulse: int, respiratory_rate: int, smoking_status: string, temperature: float, temperature_units: string, weight: float, weight_units: string>>
# operationId: appointments_read
export def "appointments-read" [
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
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/appointments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: date_range, var: date_range}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, status: $status, patient: $patient, office: $office, doctor: $doctor, since: $since, date_range: $date_range, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing appointment or break
#
# PATCH /api/appointments/{id}
# operationId: appointments_partial_update
export def "appointments-partial-update" [
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
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/appointments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: date_range, var: date_range}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, status: $status, patient: $patient, office: $office, doctor: $doctor, since: $since, date_range: $date_range, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing appointment or break
#
# PUT /api/appointments/{id}
# operationId: appointments_update
export def "appointments-update" [
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
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/appointments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: date_range, var: date_range}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, status: $status, patient: $patient, office: $office, doctor: $doctor, since: $since, date_range: $date_range, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search billing profiles
#
# GET /api/billing_profiles
# Returns: record<data: table<archived: bool, cpt_codes: list, created_at: string, custom_procedure_codes: list, doctor: string, hcpcs_codes: list, icd10_codes: list, icd9_codes: list, id: int, name: string, updated_at: string>, next: string, previous: string>
# operationId: billing_profiles_list
export def "billing-profiles-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/billing_profiles"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing billing profiles
#
# GET /api/billing_profiles/{id}
# Returns: record<archived: bool, cpt_codes: table<code: string, diagnosis_pointers_icd10: list, diagnosis_pointers_icd9: list, modifiers: list, ndc_code: list, price: string, quantity: string>, created_at: string, custom_procedure_codes: table<code: string, price: string, quantity: string>, doctor: string, hcpcs_codes: table<code: string, diagnosis_pointers_icd10: list, diagnosis_pointers_icd9: list, modifiers: list, ndc_code: list, price: string, quantity: string>, icd10_codes: list<string>, icd9_codes: list<string>, id: int, name: string, updated_at: string>
# operationId: billing_profiles_read
export def "billing-profiles-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/billing_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search care plans
#
# GET /api/care_plans
# Returns: record<data: table<appointment: string, code: string, code_system: string, created_at: string, description: string, id: int, instructions: string, patient: string, plan_type: string, scheduled_date: string, title: string, updated_at: string>, next: string, previous: string>
# operationId: care_plans_list
export def "care-plans-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --plan-type: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/care_plans"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: plan_type, var: plan_type}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, plan_type: $plan_type, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing care plan
#
# GET /api/care_plans/{id}
# Returns: record<appointment: string, code: string, code_system: string, created_at: string, description: string, id: int, instructions: string, patient: string, plan_type: string, scheduled_date: string, title: string, updated_at: string>
# operationId: care_plans_read
export def "care-plans-read" [
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
  --patient: int
  --plan-type: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/care_plans/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: plan_type, var: plan_type}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, plan_type: $plan_type, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/care_team_members
#
# Returns: record<data: table<appointment: string, created_at: string, id: int, patient: string, user: string>, next: string, previous: string>
# operationId: care_team_members_list
export def "care-team-members-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --appointment: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/care_team_members"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: appointment, var: appointment}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, appointment: $appointment, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/care_team_members/{id}
#
# Returns: record<appointment: string, created_at: string, id: int, patient: string, user: string>
# operationId: care_team_members_read
export def "care-team-members-read" [
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
  --patient: int
  --appointment: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/care_team_members/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: appointment, var: appointment}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, appointment: $appointment, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search billing notes
#
# GET /api/claim_billing_notes
# Returns: record<data: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, next: string, previous: string>
# operationId: claim_billing_notes_list
export def "claim-billing-notes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --appointment: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/claim_billing_notes"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: appointment, var: appointment}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, appointment: $appointment, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new billing note
#
# POST /api/claim_billing_notes
# Returns: record<appointment: int, created_at: string, created_by: string, id: int, text: string>
# operationId: claim_billing_notes_create
export def "claim-billing-notes-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/claim_billing_notes"
    query: [{name: appointment, var: appointment}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    appointment: $appointment, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing billing note
#
# GET /api/claim_billing_notes/{id}
# Returns: record<appointment: int, created_at: string, created_by: string, id: int, text: string>
# operationId: claim_billing_notes_read
export def "claim-billing-notes-read" [
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
  --appointment: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/claim_billing_notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: appointment, var: appointment}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, appointment: $appointment, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search clinical note field types
#
# GET /api/clinical_note_field_types
# Returns: record<data: table<allowed_values: list, archived: bool, clinical_note_template: string, comment: string, data_type: string, id: int, name: string, required: bool>, next: string, previous: string>
# operationId: clinical_note_field_types_list
export def "clinical-note-field-types-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/clinical_note_field_types"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: clinical_note_template, var: clinical_note_template}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, clinical_note_template: $clinical_note_template, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing clinial note field type
#
# GET /api/clinical_note_field_types/{id}
# Returns: record<allowed_values: list<string>, archived: bool, clinical_note_template: string, comment: string, data_type: string, id: int, name: string, required: bool>
# operationId: clinical_note_field_types_read
export def "clinical-note-field-types-read" [
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
  --clinical-note-template: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/clinical_note_field_types/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: clinical_note_template, var: clinical_note_template}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, clinical_note_template: $clinical_note_template, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search clinical note field values
#
# GET /api/clinical_note_field_values
# Returns: record<data: table<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string>, next: string, previous: string>
# operationId: clinical_note_field_values_list
export def "clinical-note-field-values-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/clinical_note_field_values"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: clinical_note_field, var: clinical_note_field}, {name: since, var: since}, {name: appointment, var: appointment}, {name: clinical_note_template, var: clinical_note_template}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, clinical_note_field: $clinical_note_field, since: $since, appointment: $appointment, clinical_note_template: $clinical_note_template, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create clinical note field value
#
# POST /api/clinical_note_field_values
# Returns: record<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string>
# operationId: clinical_note_field_values_create
export def "clinical-note-field-values-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/clinical_note_field_values"
    query: [{name: clinical_note_field, var: clinical_note_field}, {name: since, var: since}, {name: appointment, var: appointment}, {name: clinical_note_template, var: clinical_note_template}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    clinical_note_field: $clinical_note_field, since: $since, appointment: $appointment, clinical_note_template: $clinical_note_template, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing clinical note field value
#
# GET /api/clinical_note_field_values/{id}
# Returns: record<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string>
# operationId: clinical_note_field_values_read
export def "clinical-note-field-values-read" [
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
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/clinical_note_field_values/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: clinical_note_field, var: clinical_note_field}, {name: since, var: since}, {name: appointment, var: appointment}, {name: clinical_note_template, var: clinical_note_template}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, clinical_note_field: $clinical_note_field, since: $since, appointment: $appointment, clinical_note_template: $clinical_note_template, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing clinical note field value
#
# PATCH /api/clinical_note_field_values/{id}
# operationId: clinical_note_field_values_partial_update
export def "clinical-note-field-values-partial-update" [
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
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/clinical_note_field_values/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: clinical_note_field, var: clinical_note_field}, {name: since, var: since}, {name: appointment, var: appointment}, {name: clinical_note_template, var: clinical_note_template}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, clinical_note_field: $clinical_note_field, since: $since, appointment: $appointment, clinical_note_template: $clinical_note_template, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing clinical note field value
#
# PUT /api/clinical_note_field_values/{id}
# operationId: clinical_note_field_values_update
export def "clinical-note-field-values-update" [
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
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/clinical_note_field_values/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: clinical_note_field, var: clinical_note_field}, {name: since, var: since}, {name: appointment, var: appointment}, {name: clinical_note_template, var: clinical_note_template}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, clinical_note_field: $clinical_note_field, since: $since, appointment: $appointment, clinical_note_template: $clinical_note_template, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search clinical note templates
#
# GET /api/clinical_note_templates
# Returns: record<data: table<archived: bool, clinical_note_fields: list, doctor: string, id: int, is_onpatient: bool, is_persistent: bool, name: string, order: record, updated_at: string>, next: string, previous: string>
# operationId: clinical_note_templates_list
export def "clinical-note-templates-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/clinical_note_templates"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing clinical note tempalte
#
# GET /api/clinical_note_templates/{id}
# Returns: record<archived: bool, clinical_note_fields: table<allowed_values: list, archived: bool, clinical_note_template: int, data_type: string, name: string, required: bool>, doctor: string, id: int, is_onpatient: bool, is_persistent: bool, name: string, order: record<on_complete_note: int, on_ipad: int>, updated_at: string>
# operationId: clinical_note_templates_read
export def "clinical-note-templates-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/clinical_note_templates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/clinical_notes
#
# Returns: record<data: table<appointment: string, archived: bool, clinical_note_sections: list, patient: string>, next: string, previous: string>
# operationId: clinical_notes_list
export def "clinical-notes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/clinical_notes"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: date_range, var: date_range}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, office: $office, doctor: $doctor, since: $since, date_range: $date_range, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/clinical_notes/{id}
#
# Returns: record<appointment: string, archived: bool, clinical_note_sections: table<clinical_note_template: int, name: string, values: list>, patient: string>
# operationId: clinical_notes_read
export def "clinical-notes-read" [
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
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/clinical_notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: date_range, var: date_range}, {name: date, var: date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, office: $office, doctor: $doctor, since: $since, date_range: $date_range, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search communicatioin (phone call) logs
#
# GET /api/comm_logs
# Returns: record<data: table<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string>, next: string, previous: string>
# operationId: comm_logs_list
export def "comm-logs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/comm_logs"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create communication (phone call) logs
#
# POST /api/comm_logs
# Returns: record<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string>
# operationId: comm_logs_create
export def "comm-logs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/comm_logs"
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing communication (phone call) logs
#
# GET /api/comm_logs/{id}
# Returns: record<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string>
# operationId: comm_logs_read
export def "comm-logs-read" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/comm_logs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing communication (phone call) logs
#
# PATCH /api/comm_logs/{id}
# operationId: comm_logs_partial_update
export def "comm-logs-partial-update" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/comm_logs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing communication (phone call) logs
#
# PUT /api/comm_logs/{id}
# operationId: comm_logs_update
export def "comm-logs-update" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/comm_logs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient consent forms
#
# GET /api/consent_forms
# Returns: record<data: table<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string>, next: string, previous: string>
# operationId: consent_forms_list
export def "consent-forms-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/consent_forms"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a patient consent form
#
# POST /api/consent_forms
# Returns: record<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string>
# operationId: consent_forms_create
export def "consent-forms-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/consent_forms"
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient consent form
#
# GET /api/consent_forms/{id}
# Returns: record<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string>
# operationId: consent_forms_read
export def "consent-forms-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/consent_forms/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient consent form
#
# PATCH /api/consent_forms/{id}
# operationId: consent_forms_partial_update
export def "consent-forms-partial-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/consent_forms/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient consent form
#
# PUT /api/consent_forms/{id}
# operationId: consent_forms_update
export def "consent-forms-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/consent_forms/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign (apply) a consent form to appointment
#
# POST /api/consent_forms/{id}/apply_to_appointment
# operationId: consent_forms_apply_to_appointment
export def "consent-forms-apply-to-appointment" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: post
    path: "/api/consent_forms/{id}/apply_to_appointment"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unassign (unapply) a consent form from appointment
#
# POST /api/consent_forms/{id}/unapply_from_appointment
# operationId: consent_forms_unapply_from_appointment
export def "consent-forms-unapply-from-appointment" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: post
    path: "/api/consent_forms/{id}/unapply_from_appointment"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search custom appointment fields
#
# GET /api/custom_appointment_fields
# Returns: record<data: table<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string>, next: string, previous: string>
# operationId: custom_appointment_fields_list
export def "custom-appointment-fields-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/custom_appointment_fields"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create custom appointment fields
#
# POST /api/custom_appointment_fields
# Returns: record<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string>
# operationId: custom_appointment_fields_create
export def "custom-appointment-fields-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/custom_appointment_fields"
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing custom appointment field
#
# GET /api/custom_appointment_fields/{id}
# Returns: record<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string>
# operationId: custom_appointment_fields_read
export def "custom-appointment-fields-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/custom_appointment_fields/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing custom appointment field
#
# PATCH /api/custom_appointment_fields/{id}
# operationId: custom_appointment_fields_partial_update
export def "custom-appointment-fields-partial-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/custom_appointment_fields/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing custom appointment field
#
# PUT /api/custom_appointment_fields/{id}
# operationId: custom_appointment_fields_update
export def "custom-appointment-fields-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/custom_appointment_fields/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search custom demographics fields
#
# GET /api/custom_demographics
# Returns: record<data: table<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string>, next: string, previous: string>
# operationId: custom_demographics_list
export def "custom-demographics-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/custom_demographics"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create custom demographics fields
#
# POST /api/custom_demographics
# Returns: record<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string>
# operationId: custom_demographics_create
export def "custom-demographics-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/custom_demographics"
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing custom demographics field
#
# GET /api/custom_demographics/{id}
# Returns: record<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string>
# operationId: custom_demographics_read
export def "custom-demographics-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/custom_demographics/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing custom demographics field
#
# PATCH /api/custom_demographics/{id}
# operationId: custom_demographics_partial_update
export def "custom-demographics-partial-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/custom_demographics/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing custom demographics field
#
# PUT /api/custom_demographics/{id}
# operationId: custom_demographics_update
export def "custom-demographics-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/custom_demographics/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search custom insurance plan names
#
# GET /api/custom_insurance_plan_names
# Returns: record<data: table<archived: bool, created_at: string, doctor: string, id: int, insurance_plan_name: string, updated_at: string, user: string>, next: string, previous: string>
# operationId: custom_insurance_plan_names_list
export def "custom-insurance-plan-names-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --user: int
  --name: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/custom_insurance_plan_names"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: user, var: user}, {name: name, var: name}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, user: $user, name: $name, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing custom insurance plan name
#
# GET /api/custom_insurance_plan_names/{id}
# Returns: record<archived: bool, created_at: string, doctor: string, id: int, insurance_plan_name: string, updated_at: string, user: string>
# operationId: custom_insurance_plan_names_read
export def "custom-insurance-plan-names-read" [
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
  --since: string
  --user: int
  --name: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/custom_insurance_plan_names/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: user, var: user}, {name: name, var: name}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, user: $user, name: $name, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search custom vital types
#
# GET /api/custom_vitals
# Returns: record<data: table<allowed_values: list, archived: bool, data_type: string, description: string, doctor: string, fraction_delimiter: string, id: int, is_fraction_field: bool, name: string, unit: string>, next: string, previous: string>
# operationId: custom_vitals_list
export def "custom-vitals-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/custom_vitals"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing custom vital type
#
# GET /api/custom_vitals/{id}
# Returns: record<allowed_values: list<string>, archived: bool, data_type: string, description: string, doctor: string, fraction_delimiter: string, id: int, is_fraction_field: bool, name: string, unit: string>
# operationId: custom_vitals_read
export def "custom-vitals-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/custom_vitals/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search doctors within practice group
#
# GET /api/doctors
# Returns: record<data: table<cell_phone: string, country: string, email: string, first_name: string, group_npi_number: string, home_phone: string, id: int, is_account_suspended: bool, job_title: string, last_name: string, npi_number: string, office_phone: string, practice_group: string, practice_group_name: string, profile_picture: string, specialty: string, suffix: string, timezone: string, website: string>, next: string, previous: string>
# operationId: doctors_list
export def "doctors-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/doctors"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing dcotor
#
# GET /api/doctors/{id}
# Returns: record<cell_phone: string, country: string, email: string, first_name: string, group_npi_number: string, home_phone: string, id: int, is_account_suspended: bool, job_title: string, last_name: string, npi_number: string, office_phone: string, practice_group: string, practice_group_name: string, profile_picture: string, specialty: string, suffix: string, timezone: string, website: string>
# operationId: doctors_read
export def "doctors-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/doctors/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search documents
#
# GET /api/documents
# Returns: record<data: table<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string>, next: string, previous: string>
# operationId: documents_list
export def "documents-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/documents"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create documents
#
# POST /api/documents
# Returns: record<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string>
# operationId: documents_create
export def "documents-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/documents"
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing appointment template
#
# DELETE /api/documents/{id}
# operationId: documents_delete
export def "documents-delete" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing appointment template
#
# GET /api/documents/{id}
# Returns: record<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string>
# operationId: documents_read
export def "documents-read" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing appointment template
#
# PATCH /api/documents/{id}
# operationId: documents_partial_update
export def "documents-partial-update" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing appointment template
#
# PUT /api/documents/{id}
# operationId: documents_update
export def "documents-update" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search past eligibility checks for patient
#
# GET /api/eligibility_checks
# Returns: record<data: table<appointment: string, cob_level: string, coverage_details: string, coverage_subscriber: string, eligibility: string, patient: string, payer_name: string, query_date: string, request_service_type: string, service_type_description: string>, next: string, previous: string>
# operationId: eligibility_checks_list
export def "eligibility-checks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --appointment: int
  --appointment-date: string
  --doctor: int
  --query-date-range: string
  --appointment-date-range: string
  --query-date: string
  --patient: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/eligibility_checks"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: appointment, var: appointment}, {name: appointment_date, var: appointment_date}, {name: doctor, var: doctor}, {name: query_date_range, var: query_date_range}, {name: appointment_date_range, var: appointment_date_range}, {name: query_date, var: query_date}, {name: patient, var: patient}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, appointment: $appointment, appointment_date: $appointment_date, doctor: $doctor, query_date_range: $query_date_range, appointment_date_range: $appointment_date_range, query_date: $query_date, patient: $patient
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing past eligibility check
#
# GET /api/eligibility_checks/{id}
# Returns: record<appointment: string, cob_level: string, coverage_details: string, coverage_subscriber: string, eligibility: string, patient: string, payer_name: string, query_date: string, request_service_type: string, service_type_description: string>
# operationId: eligibility_checks_read
export def "eligibility-checks-read" [
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
  --appointment: int
  --appointment-date: string
  --doctor: int
  --query-date-range: string
  --appointment-date-range: string
  --query-date: string
  --patient: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/eligibility_checks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: appointment, var: appointment}, {name: appointment_date, var: appointment_date}, {name: doctor, var: doctor}, {name: query_date_range, var: query_date_range}, {name: appointment_date_range, var: appointment_date_range}, {name: query_date, var: query_date}, {name: patient, var: patient}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, appointment: $appointment, appointment_date: $appointment_date, doctor: $doctor, query_date_range: $query_date_range, appointment_date_range: $appointment_date_range, query_date: $query_date, patient: $patient
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search EOB objects
#
# GET /api/eobs
# Returns: record<data: table<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string>, next: string, previous: string>
# operationId: eobs_list
export def "eobs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/eobs"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create EOB object
#
# POST /api/eobs
# Returns: record<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string>
# operationId: eobs_create
export def "eobs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/eobs"
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing EOB object
#
# GET /api/eobs/{id}
# Returns: record<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string>
# operationId: eobs_read
export def "eobs-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/eobs/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/fee_schedules
#
# Returns: record<data: table<allowed_amount: float, base_price: float, billing_description: string, cash_price: float, code: string, code_type: string, cpt_hcpcs_modifier1: string, cpt_hcpcs_modifier2: string, cpt_hcpcs_modifier3: string, cpt_hcpcs_modifier4: string, created_at: string, description: string, doctor: int, id: int, insured_out_of_network_price: float, insured_price: float, ndc_code: string, ndc_quantity: float, ndc_units: string, office: int, payer_id: string, picklist_category: string, plan_name: string, updated_at: string>, next: string, previous: string>
# operationId: fee_schedules_list
export def "fee-schedules-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --code: string
  --code-type: string
  --since: string
  --payer-id: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/fee_schedules"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: code, var: code}, {name: code_type, var: code_type}, {name: since, var: since}, {name: payer_id, var: payer_id}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, code: $code, code_type: $code_type, since: $since, payer_id: $payer_id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/fee_schedules/{id}
#
# Returns: record<allowed_amount: float, base_price: float, billing_description: string, cash_price: float, code: string, code_type: string, cpt_hcpcs_modifier1: string, cpt_hcpcs_modifier2: string, cpt_hcpcs_modifier3: string, cpt_hcpcs_modifier4: string, created_at: string, description: string, doctor: int, id: int, insured_out_of_network_price: float, insured_price: float, ndc_code: string, ndc_quantity: float, ndc_units: string, office: int, payer_id: string, picklist_category: string, plan_name: string, updated_at: string>
# operationId: fee_schedules_read
export def "fee-schedules-read" [
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
  --code: string
  --code-type: string
  --since: string
  --payer-id: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/fee_schedules/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: code, var: code}, {name: code_type, var: code_type}, {name: since, var: since}, {name: payer_id, var: payer_id}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, code: $code, code_type: $code_type, since: $since, payer_id: $payer_id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search implantable devices
#
# GET /api/implantable_devices
# Returns: record<data: table<archived: bool, brand_name: string, company_name: string, created_at: string, expiration_date: string, gmdn_pt_name: string, id: int, manufacturing_date: string, patient: string, procedure: string, serial_number: string, status: string, udi: string, updated_at: string, version_or_model: string>, next: string, previous: string>
# operationId: implantable_devices_list
export def "implantable-devices-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --mu-date: string
  --patient: int
  --mu-date-range: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/implantable_devices"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: mu_date, var: mu_date}, {name: patient, var: patient}, {name: mu_date_range, var: mu_date_range}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, mu_date: $mu_date, patient: $patient, mu_date_range: $mu_date_range, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing implantable device
#
# GET /api/implantable_devices/{id}
# Returns: record<archived: bool, brand_name: string, company_name: string, created_at: string, expiration_date: string, gmdn_pt_name: string, id: int, manufacturing_date: string, patient: string, procedure: string, serial_number: string, status: string, udi: string, updated_at: string, version_or_model: string>
# operationId: implantable_devices_read
export def "implantable-devices-read" [
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
  --mu-date: string
  --patient: int
  --mu-date-range: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/implantable_devices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: mu_date, var: mu_date}, {name: patient, var: patient}, {name: mu_date_range, var: mu_date_range}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, mu_date: $mu_date, patient: $patient, mu_date_range: $mu_date_range, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/insurances
#
# Returns: record<data: table<payer_id: string, payer_name: string, state: string>, next: string, previous: string>
# operationId: insurances_list
export def "insurances-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --payer-type: string # One of `"emdeon"`, `"gateway"`, `"ihcfa"` (required)
  --term: string # Search term, which can be either a partial name, partial ID or the state.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/insurances"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: payer_type, var: payer_type, required: true}, {name: term, var: term}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, payer_type: $payer_type, term: $term
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/insurances/{id}
#
# Returns: record<payer_id: string, payer_name: string, state: string>
# operationId: insurances_read
export def "insurances-read" [
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
  --payer-type: string # One of `"emdeon"`, `"gateway"`, `"ihcfa"` (required)
  --term: string # Search term, which can be either a partial name, partial ID or the state.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/insurances/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: payer_type, var: payer_type, required: true}, {name: term, var: term}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, payer_type: $payer_type, term: $term
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search inventory categories
#
# GET /api/inventory_categories
# Returns: record<data: table<archived: bool, category_type: string, created_at: string, doctor: string, id: int, name: string, updated_at: string>, next: string, previous: string>
# operationId: inventory_categories_list
export def "inventory-categories-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/inventory_categories"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing inventory category
#
# GET /api/inventory_categories/{id}
# Returns: record<archived: bool, category_type: string, created_at: string, doctor: string, id: int, name: string, updated_at: string>
# operationId: inventory_categories_read
export def "inventory-categories-read" [
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
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/inventory_categories/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search vaccine inventories
#
# GET /api/inventory_vaccines
# Returns: record<data: table<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string>, next: string, previous: string>
# operationId: inventory_vaccines_list
export def "inventory-vaccines-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --status: string
  --cvx-code: string
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/inventory_vaccines"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: status, var: status}, {name: cvx_code, var: cvx_code}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, status: $status, cvx_code: $cvx_code, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create vaccine inventory
#
# POST /api/inventory_vaccines
# Returns: record<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string>
# operationId: inventory_vaccines_create
export def "inventory-vaccines-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --cvx-code: string
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/inventory_vaccines"
    query: [{name: status, var: status}, {name: cvx_code, var: cvx_code}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    status: $status, cvx_code: $cvx_code, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing vaccine inventory
#
# GET /api/inventory_vaccines/{id}
# Returns: record<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string>
# operationId: inventory_vaccines_read
export def "inventory-vaccines-read" [
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
  --status: string
  --cvx-code: string
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/inventory_vaccines/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: cvx_code, var: cvx_code}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, status: $status, cvx_code: $cvx_code, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search lab order documents
#
# GET /api/lab_documents
# Returns: record<data: table<document: string, id: int, lab_order: int, timestamp: string, type: string>, next: string, previous: string>
# operationId: lab_documents_list
export def "lab-documents-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_documents"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create lab order documents. An example lab workflow is as following: - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/lab_documents
# Returns: record<document: string, id: int, lab_order: int, timestamp: string, type: string>
# operationId: lab_documents_create
export def "lab-documents-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/lab_documents"
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing lab order document
#
# DELETE /api/lab_documents/{id}
# operationId: lab_documents_delete
export def "lab-documents-delete" [
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
  --since: string
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/lab_documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing lab order document
#
# GET /api/lab_documents/{id}
# Returns: record<document: string, id: int, lab_order: int, timestamp: string, type: string>
# operationId: lab_documents_read
export def "lab-documents-read" [
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
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing lab order document
#
# PATCH /api/lab_documents/{id}
# operationId: lab_documents_partial_update
export def "lab-documents-partial-update" [
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
  --since: string
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/lab_documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing lab order document
#
# PUT /api/lab_documents/{id}
# operationId: lab_documents_update
export def "lab-documents-update" [
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
  --since: string
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/lab_documents/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search lab orders
#
# GET /api/lab_orders
# Returns: record<data: table<accession_number: string, doctor: int, documents: list, icd10_codes: list, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>, next: string, previous: string>
# operationId: lab_orders_list
export def "lab-orders-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_orders"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create lab orders. An example lab workflow is as following: - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/lab_orders
# Returns: record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>
# operationId: lab_orders_create
export def "lab-orders-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/lab_orders"
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing lab order
#
# DELETE /api/lab_orders/{id}
# operationId: lab_orders_delete
export def "lab-orders-delete" [
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
  --since: string
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/lab_orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing lab order
#
# GET /api/lab_orders/{id}
# Returns: record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>
# operationId: lab_orders_read
export def "lab-orders-read" [
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
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing lab order
#
# PATCH /api/lab_orders/{id}
# operationId: lab_orders_partial_update
export def "lab-orders-partial-update" [
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
  --since: string
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/lab_orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing lab order
#
# PUT /api/lab_orders/{id}
# operationId: lab_orders_update
export def "lab-orders-update" [
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
  --since: string
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/lab_orders/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/lab_orders_summary
#
# Returns: record<data: table<accession_number: string, doctor: int, documents: list, icd10_codes: list, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>, next: string, previous: string>
# operationId: lab_orders_summary_list
export def "lab-orders-summary-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_orders_summary"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/lab_orders_summary/{id}
#
# Returns: record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>
# operationId: lab_orders_summary_read
export def "lab-orders-summary-read" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_orders_summary/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search lab results
#
# GET /api/lab_results
# Returns: record<data: table<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool>, next: string, previous: string>
# operationId: lab_results_list
export def "lab-results-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --order: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_results"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create lab results. An example lab workflow is as following: - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/lab_results
# Returns: record<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool>
# operationId: lab_results_create
export def "lab-results-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/lab_results"
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing lab result
#
# DELETE /api/lab_results/{id}
# operationId: lab_results_delete
export def "lab-results-delete" [
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
  --order: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/lab_results/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing lab result
#
# GET /api/lab_results/{id}
# Returns: record<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool>
# operationId: lab_results_read
export def "lab-results-read" [
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
  --order: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_results/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing lab result
#
# PATCH /api/lab_results/{id}
# operationId: lab_results_partial_update
export def "lab-results-partial-update" [
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
  --order: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/lab_results/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing lab result
#
# PUT /api/lab_results/{id}
# operationId: lab_results_update
export def "lab-results-update" [
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
  --order: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/lab_results/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search lab tests
#
# GET /api/lab_tests
# Returns: record<data: table<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string>, next: string, previous: string>
# operationId: lab_tests_list
export def "lab-tests-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --order: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_tests"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create lab tests. An example lab workflow is as following: - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/lab_tests
# Returns: record<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string>
# operationId: lab_tests_create
export def "lab-tests-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/lab_tests"
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing lab test
#
# DELETE /api/lab_tests/{id}
# operationId: lab_tests_delete
export def "lab-tests-delete" [
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
  --order: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/lab_tests/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing lab test
#
# GET /api/lab_tests/{id}
# Returns: record<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string>
# operationId: lab_tests_read
export def "lab-tests-read" [
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
  --order: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/lab_tests/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing lab test
#
# PATCH /api/lab_tests/{id}
# operationId: lab_tests_partial_update
export def "lab-tests-partial-update" [
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
  --order: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/lab_tests/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing lab test
#
# PUT /api/lab_tests/{id}
# operationId: lab_tests_update
export def "lab-tests-update" [
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
  --order: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/lab_tests/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, order: $order, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search billing line items
#
# GET /api/line_items
# Returns: record<data: table<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>, next: string, previous: string>
# operationId: line_items_list
export def "line-items-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/line_items"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: posted_date, var: posted_date}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: appointment, var: appointment}, {name: service_date, var: service_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, posted_date: $posted_date, patient: $patient, office: $office, doctor: $doctor, since: $since, appointment: $appointment, service_date: $service_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create billing line item for appointments
#
# POST /api/line_items
# Returns: record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>
# operationId: line_items_create
export def "line-items-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/line_items"
    query: [{name: posted_date, var: posted_date}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: appointment, var: appointment}, {name: service_date, var: service_date}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    posted_date: $posted_date, patient: $patient, office: $office, doctor: $doctor, since: $since, appointment: $appointment, service_date: $service_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/line_items/{id}
#
# operationId: line_items_delete
export def "line-items-delete" [
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
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/line_items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: posted_date, var: posted_date}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: appointment, var: appointment}, {name: service_date, var: service_date}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, posted_date: $posted_date, patient: $patient, office: $office, doctor: $doctor, since: $since, appointment: $appointment, service_date: $service_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing billing line item
#
# GET /api/line_items/{id}
# Returns: record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>
# operationId: line_items_read
export def "line-items-read" [
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
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/line_items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: posted_date, var: posted_date}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: appointment, var: appointment}, {name: service_date, var: service_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, posted_date: $posted_date, patient: $patient, office: $office, doctor: $doctor, since: $since, appointment: $appointment, service_date: $service_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /api/line_items/{id}
#
# operationId: line_items_partial_update
export def "line-items-partial-update" [
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
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/line_items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: posted_date, var: posted_date}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: appointment, var: appointment}, {name: service_date, var: service_date}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, posted_date: $posted_date, patient: $patient, office: $office, doctor: $doctor, since: $since, appointment: $appointment, service_date: $service_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/line_items/{id}
#
# operationId: line_items_update
export def "line-items-update" [
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
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/line_items/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: posted_date, var: posted_date}, {name: patient, var: patient}, {name: office, var: office}, {name: doctor, var: doctor}, {name: since, var: since}, {name: appointment, var: appointment}, {name: service_date, var: service_date}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, posted_date: $posted_date, patient: $patient, office: $office, doctor: $doctor, since: $since, appointment: $appointment, service_date: $service_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient medications
#
# GET /api/medications
# Returns: record<data: table<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string>, next: string, previous: string>
# operationId: medications_list
export def "medications-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/medications"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient medications
#
# POST /api/medications
# Returns: record<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string>
# operationId: medications_create
export def "medications-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/medications"
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient medications
#
# GET /api/medications/{id}
# Returns: record<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string>
# operationId: medications_read
export def "medications-read" [
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
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/medications/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient medications
#
# PATCH /api/medications/{id}
# operationId: medications_partial_update
export def "medications-partial-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/medications/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient medications
#
# PUT /api/medications/{id}
# operationId: medications_update
export def "medications-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/medications/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Append a message to the "pharmacy_note" section of the prescription, in a new paragraph
#
# PATCH /api/medications/{id}/append_to_pharmacy_note
# operationId: medications_append_to_pharmacy_note
export def "medications-append-to-pharmacy-note" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/medications/{id}/append_to_pharmacy_note"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search messages in doctor's message center
#
# GET /api/messages
# Returns: record<data: table<archived: bool, attachment: string, doctor: int, id: int, message_notes: list, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string>, next: string, previous: string>
# operationId: messages_list
export def "messages-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/messages"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: doctor, var: doctor}, {name: responsible_user, var: responsible_user}, {name: updated_since, var: updated_since}, {name: received_since, var: received_since}, {name: owner, var: owner}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, doctor: $doctor, responsible_user: $responsible_user, updated_since: $updated_since, received_since: $received_since, owner: $owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create messages in doctor's message center
#
# POST /api/messages
# Returns: record<archived: bool, attachment: string, doctor: int, id: int, message_notes: table<created_at: string, created_by: string, text: string>, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string>
# operationId: messages_create
export def "messages-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/messages"
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}, {name: responsible_user, var: responsible_user}, {name: updated_since, var: updated_since}, {name: received_since, var: received_since}, {name: owner, var: owner}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    patient: $patient, doctor: $doctor, responsible_user: $responsible_user, updated_since: $updated_since, received_since: $received_since, owner: $owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing message in doctor's message center
#
# DELETE /api/messages/{id}
# operationId: messages_delete
export def "messages-delete" [
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
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}, {name: responsible_user, var: responsible_user}, {name: updated_since, var: updated_since}, {name: received_since, var: received_since}, {name: owner, var: owner}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor, responsible_user: $responsible_user, updated_since: $updated_since, received_since: $received_since, owner: $owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing message in doctor's message center
#
# GET /api/messages/{id}
# Returns: record<archived: bool, attachment: string, doctor: int, id: int, message_notes: table<created_at: string, created_by: string, text: string>, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string>
# operationId: messages_read
export def "messages-read" [
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
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}, {name: responsible_user, var: responsible_user}, {name: updated_since, var: updated_since}, {name: received_since, var: received_since}, {name: owner, var: owner}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor, responsible_user: $responsible_user, updated_since: $updated_since, received_since: $received_since, owner: $owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing message in doctor's message center
#
# PATCH /api/messages/{id}
# operationId: messages_partial_update
export def "messages-partial-update" [
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
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}, {name: responsible_user, var: responsible_user}, {name: updated_since, var: updated_since}, {name: received_since, var: received_since}, {name: owner, var: owner}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor, responsible_user: $responsible_user, updated_since: $updated_since, received_since: $received_since, owner: $owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing message in doctor's message center
#
# PUT /api/messages/{id}
# operationId: messages_update
export def "messages-update" [
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
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}, {name: responsible_user, var: responsible_user}, {name: updated_since, var: updated_since}, {name: received_since, var: received_since}, {name: owner, var: owner}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor, responsible_user: $responsible_user, updated_since: $updated_since, received_since: $received_since, owner: $owner, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search offices
#
# GET /api/offices
# Returns: record<data: table<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: list, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string>, next: string, previous: string>
# operationId: offices_list
export def "offices-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/offices"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing office
#
# GET /api/offices/{id}
# Returns: record<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: table<day: int, hour: int, minute: int>, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string>
# operationId: offices_read
export def "offices-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/offices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing office
#
# PATCH /api/offices/{id}
# operationId: offices_partial_update
export def "offices-partial-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/offices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing office
#
# PUT /api/offices/{id}
# operationId: offices_update
export def "offices-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/offices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an exam room to the office
#
# POST /api/offices/{id}/add_exam_room
# Returns: record<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: table<day: int, hour: int, minute: int>, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string>
# operationId: offices_add_exam_room
export def "offices-add-exam-room" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/offices/{id}/add_exam_room"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient communications for CQM
#
# GET /api/patient_communications
# Returns: record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string>
# operationId: patient_communications_list
export def "patient-communications-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_communications"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient communication for CQM
#
# POST /api/patient_communications
# Returns: record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>
# operationId: patient_communications_create
export def "patient-communications-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_communications"
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient communication for CQM
#
# GET /api/patient_communications/{id}
# Returns: record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>
# operationId: patient_communications_read
export def "patient-communications-read" [
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
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_communications/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient communication for CQM
#
# PATCH /api/patient_communications/{id}
# operationId: patient_communications_partial_update
export def "patient-communications-partial-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patient_communications/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient communication for CQM
#
# PUT /api/patient_communications/{id}
# operationId: patient_communications_update
export def "patient-communications-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patient_communications/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient flag types
#
# GET /api/patient_flag_types
# Returns: record<data: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, next: string, previous: string>
# operationId: patient_flag_types_list
export def "patient-flag-types-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_flag_types"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient flag types
#
# POST /api/patient_flag_types
# Returns: record<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>
# operationId: patient_flag_types_create
export def "patient-flag-types-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_flag_types"
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient flag type
#
# GET /api/patient_flag_types/{id}
# Returns: record<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>
# operationId: patient_flag_types_read
export def "patient-flag-types-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_flag_types/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient flag type
#
# PATCH /api/patient_flag_types/{id}
# operationId: patient_flag_types_partial_update
export def "patient-flag-types-partial-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patient_flag_types/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient flag type
#
# PUT /api/patient_flag_types/{id}
# operationId: patient_flag_types_update
export def "patient-flag-types-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patient_flag_types/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient interventions for CQM
#
# GET /api/patient_interventions
# Returns: record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string>
# operationId: patient_interventions_list
export def "patient-interventions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_interventions"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient intervention for CQM
#
# POST /api/patient_interventions
# Returns: record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>
# operationId: patient_interventions_create
export def "patient-interventions-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_interventions"
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient intervention for CQM
#
# GET /api/patient_interventions/{id}
# Returns: record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>
# operationId: patient_interventions_read
export def "patient-interventions-read" [
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
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_interventions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient intervention for CQM
#
# PATCH /api/patient_interventions/{id}
# operationId: patient_interventions_partial_update
export def "patient-interventions-partial-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patient_interventions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient intervention for CQM
#
# PUT /api/patient_interventions/{id}
# operationId: patient_interventions_update
export def "patient-interventions-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patient_interventions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/patient_lab_results
#
# Returns: record<data: table<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string>, next: string, previous: string>
# operationId: patient_lab_results_list
export def "patient-lab-results-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_lab_results"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: ordering_doctor, var: ordering_doctor}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, ordering_doctor: $ordering_doctor, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/patient_lab_results
#
# Returns: record<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string>
# operationId: patient_lab_results_create
export def "patient-lab-results-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_lab_results"
    query: [{name: ordering_doctor, var: ordering_doctor}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    ordering_doctor: $ordering_doctor, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/patient_lab_results/{id}
#
# operationId: patient_lab_results_delete
export def "patient-lab-results-delete" [
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
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/patient_lab_results/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ordering_doctor, var: ordering_doctor}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ordering_doctor: $ordering_doctor, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/patient_lab_results/{id}
#
# Returns: record<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string>
# operationId: patient_lab_results_read
export def "patient-lab-results-read" [
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
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_lab_results/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ordering_doctor, var: ordering_doctor}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, ordering_doctor: $ordering_doctor, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /api/patient_lab_results/{id}
#
# operationId: patient_lab_results_partial_update
export def "patient-lab-results-partial-update" [
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
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patient_lab_results/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ordering_doctor, var: ordering_doctor}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ordering_doctor: $ordering_doctor, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/patient_lab_results/{id}
#
# operationId: patient_lab_results_update
export def "patient-lab-results-update" [
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
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patient_lab_results/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: ordering_doctor, var: ordering_doctor}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, ordering_doctor: $ordering_doctor, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/patient_messages
#
# Returns: record<data: table<attachments: list, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string>, next: string, previous: string>
# operationId: patient_messages_list
export def "patient-messages-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_messages"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/patient_messages
#
# Returns: record<attachments: table<attachment: string, created_at: string, doctor: int, updated_at: string>, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string>
# operationId: patient_messages_create
export def "patient-messages-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_messages"
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/patient_messages/{id}
#
# Returns: record<attachments: table<attachment: string, created_at: string, doctor: int, updated_at: string>, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string>
# operationId: patient_messages_read
export def "patient-messages-read" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /api/patient_messages/{id}
#
# operationId: patient_messages_partial_update
export def "patient-messages-partial-update" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patient_messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/patient_messages/{id}
#
# operationId: patient_messages_update
export def "patient-messages-update" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patient_messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient payment logs
#
# GET /api/patient_payment_log
# Returns: record<data: table<action: string, amount: float, appointment: string, created_by: string, doctor: string, id: int, patient: string, payment_method: string, source: string, updated_at: string>, next: string, previous: string>
# operationId: patient_payment_log_list
export def "patient-payment-log-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --office: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_payment_log"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: office, var: office}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, office: $office, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient payment log
#
# GET /api/patient_payment_log/{id}
# Returns: record<action: string, amount: float, appointment: string, created_by: string, doctor: string, id: int, patient: string, payment_method: string, source: string, updated_at: string>
# operationId: patient_payment_log_read
export def "patient-payment-log-read" [
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
  --since: string
  --office: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_payment_log/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: office, var: office}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, office: $office, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient payments
#
# GET /api/patient_payments
# Returns: record<data: table<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string>, next: string, previous: string>
# operationId: patient_payments_list
export def "patient-payments-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_payments"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient payment
#
# POST /api/patient_payments
# Returns: record<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string>
# operationId: patient_payments_create
export def "patient-payments-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_payments"
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient payment
#
# GET /api/patient_payments/{id}
# Returns: record<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string>
# operationId: patient_payments_read
export def "patient-payments-read" [
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
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_payments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient physical exams for CQM
#
# GET /api/patient_physical_exams
# Returns: record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string>
# operationId: patient_physical_exams_list
export def "patient-physical-exams-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_physical_exams"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient physical exam for CQM
#
# POST /api/patient_physical_exams
# Returns: record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>
# operationId: patient_physical_exams_create
export def "patient-physical-exams-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_physical_exams"
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient physical exam for CQM
#
# GET /api/patient_physical_exams/{id}
# Returns: record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>
# operationId: patient_physical_exams_read
export def "patient-physical-exams-read" [
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
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_physical_exams/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient physical exam for CQM
#
# PATCH /api/patient_physical_exams/{id}
# operationId: patient_physical_exams_partial_update
export def "patient-physical-exams-partial-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patient_physical_exams/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient physical exam for CQM
#
# PUT /api/patient_physical_exams/{id}
# operationId: patient_physical_exams_update
export def "patient-physical-exams-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patient_physical_exams/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/patient_risk_assessments
#
# Returns: record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string>
# operationId: patient_risk_assessments_list
export def "patient-risk-assessments-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_risk_assessments"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/patient_risk_assessments
#
# Returns: record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>
# operationId: patient_risk_assessments_create
export def "patient-risk-assessments-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_risk_assessments"
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/patient_risk_assessments/{id}
#
# Returns: record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>
# operationId: patient_risk_assessments_read
export def "patient-risk-assessments-read" [
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
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_risk_assessments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /api/patient_risk_assessments/{id}
#
# operationId: patient_risk_assessments_partial_update
export def "patient-risk-assessments-partial-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patient_risk_assessments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/patient_risk_assessments/{id}
#
# operationId: patient_risk_assessments_update
export def "patient-risk-assessments-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patient_risk_assessments/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient vaccine records
#
# GET /api/patient_vaccine_records
# Returns: record<data: table<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: list, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string>, next: string, previous: string>
# operationId: patient_vaccine_records_list
export def "patient-vaccine-records-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_vaccine_records"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: cvx_code, var: cvx_code}, {name: patient, var: patient}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, cvx_code: $cvx_code, patient: $patient, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient vaccine records
#
# POST /api/patient_vaccine_records
# Returns: record<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: table<id: int, max_age_months: int, min_age_months: int, title: string>, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string>
# operationId: patient_vaccine_records_create
export def "patient-vaccine-records-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patient_vaccine_records"
    query: [{name: cvx_code, var: cvx_code}, {name: patient, var: patient}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    cvx_code: $cvx_code, patient: $patient, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient vaccine records
#
# GET /api/patient_vaccine_records/{id}
# Returns: record<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: table<id: int, max_age_months: int, min_age_months: int, title: string>, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string>
# operationId: patient_vaccine_records_read
export def "patient-vaccine-records-read" [
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
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patient_vaccine_records/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: cvx_code, var: cvx_code}, {name: patient, var: patient}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, cvx_code: $cvx_code, patient: $patient, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient vaccine records
#
# PATCH /api/patient_vaccine_records/{id}
# operationId: patient_vaccine_records_partial_update
export def "patient-vaccine-records-partial-update" [
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
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patient_vaccine_records/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: cvx_code, var: cvx_code}, {name: patient, var: patient}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, cvx_code: $cvx_code, patient: $patient, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient vaccine records
#
# PUT /api/patient_vaccine_records/{id}
# operationId: patient_vaccine_records_update
export def "patient-vaccine-records-update" [
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
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patient_vaccine_records/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: cvx_code, var: cvx_code}, {name: patient, var: patient}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, cvx_code: $cvx_code, patient: $patient, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patients
#
# GET /api/patients
# Returns: record<data: table<address: string, auto_accident_insurance: record, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: list, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list, patient_flags: list, patient_flags_attached: list, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record, race: string, referring_doctor: record, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record, social_security_number: string, state: string, tertiary_insurance: record, updated_at: string, workers_comp_insurance: record, zip_code: string>, next: string, previous: string>
# operationId: patients_list
export def "patients-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patients"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient
#
# POST /api/patients
# Returns: record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>
# operationId: patients_create
export def "patients-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patients"
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing patient
#
# DELETE /api/patients/{id}
# operationId: patients_delete
export def "patients-delete" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/patients/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient
#
# GET /api/patients/{id}
# Returns: record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>
# operationId: patients_read
export def "patients-read" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patients/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient
#
# PATCH /api/patients/{id}
# operationId: patients_partial_update
export def "patients-partial-update" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patients/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient
#
# PUT /api/patients/{id}
# operationId: patients_update
export def "patients-update" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patients/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve patient CCDA
#
# GET /api/patients/{id}/ccda
# operationId: patients_ccda
export def "patients-ccda" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/patients/{id}/ccda"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke sent onpatient invites
#
# DELETE /api/patients/{id}/onpatient_access
# operationId: patients_onpatient_access_delete
export def "patients-onpatient-access-delete" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/patients/{id}/onpatient_access"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search existing onpatient access invites
#
# GET /api/patients/{id}/onpatient_access
# Returns: record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>
# operationId: patients_onpatient_access_read
export def "patients-onpatient-access-read" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patients/{id}/onpatient_access"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send new onpatient invite to patient
#
# POST /api/patients/{id}/onpatient_access
# Returns: record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>
# operationId: patients_onpatient_access_create
export def "patients-onpatient-access-create" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patients/{id}/onpatient_access"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve patient QRDA1
#
# GET /api/patients/{id}/qrda1
# operationId: patients_qrda1
export def "patients-qrda1" [
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
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  http-request {
    method: get
    path: "/api/patients/{id}/qrda1"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: preferred_language, var: preferred_language}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}, {name: race, var: race}, {name: chart_id, var: chart_id}, {name: email, var: email}, {name: ethnicity, var: ethnicity}]
    accept: ["application/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, preferred_language: $preferred_language, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth, race: $race, chart_id: $chart_id, email: $email, ethnicity: $ethnicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/patients_summary
#
# Returns: record<data: table<address: string, auto_accident_insurance: record, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: list, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list, patient_flags: list, patient_flags_attached: list, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record, race: string, referring_doctor: record, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record, social_security_number: string, state: string, tertiary_insurance: record, updated_at: string, workers_comp_insurance: record, zip_code: string>, next: string, previous: string>
# operationId: patients_summary_list
export def "patients-summary-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patients_summary"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, first_name: $first_name, last_name: $last_name, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /api/patients_summary
#
# Returns: record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>
# operationId: patients_summary_create
export def "patients-summary-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/patients_summary"
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    first_name: $first_name, last_name: $last_name, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /api/patients_summary/{id}
#
# operationId: patients_summary_delete
export def "patients-summary-delete" [
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
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/patients_summary/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/patients_summary/{id}
#
# Returns: record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string>
# operationId: patients_summary_read
export def "patients-summary-read" [
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
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/patients_summary/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PATCH /api/patients_summary/{id}
#
# operationId: patients_summary_partial_update
export def "patients-summary-partial-update" [
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
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/patients_summary/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# PUT /api/patients_summary/{id}
#
# operationId: patients_summary_update
export def "patients-summary-update" [
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
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/patients_summary/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: first_name, var: first_name}, {name: last_name, var: last_name}, {name: doctor, var: doctor}, {name: gender, var: gender}, {name: since, var: since}, {name: date_of_birth, var: date_of_birth}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, first_name: $first_name, last_name: $last_name, doctor: $doctor, gender: $gender, since: $since, date_of_birth: $date_of_birth
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search prescription messages
#
# GET /api/prescription_messages
# Returns: record<data: table<created_at: string, doctor: int, id: int, json_data: string, message_direction: string, message_status: string, message_type: string, parent_message: string, patient: int, pharmacy: string>, next: string, previous: string>
# operationId: prescription_messages_list
export def "prescription-messages-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --parent-message: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/prescription_messages"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: parent_message, var: parent_message}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, parent_message: $parent_message, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing prescription message
#
# GET /api/prescription_messages/{id}
# Returns: record<created_at: string, doctor: int, id: int, json_data: string, message_direction: string, message_status: string, message_type: string, parent_message: string, patient: int, pharmacy: string>
# operationId: prescription_messages_read
export def "prescription-messages-read" [
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
  --parent-message: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/prescription_messages/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: parent_message, var: parent_message}, {name: since, var: since}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, parent_message: $parent_message, since: $since, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search patient problems
#
# GET /api/problems
# Returns: record<data: table<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string>, next: string, previous: string>
# operationId: problems_list
export def "problems-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/problems"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient problems
#
# POST /api/problems
# Returns: record<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string>
# operationId: problems_create
export def "problems-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/problems"
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing patient problems
#
# GET /api/problems/{id}
# Returns: record<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string>
# operationId: problems_read
export def "problems-read" [
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
  --patient: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/problems/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient problems
#
# PATCH /api/problems/{id}
# operationId: problems_partial_update
export def "problems-partial-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/problems/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing patient problems
#
# PUT /api/problems/{id}
# operationId: problems_update
export def "problems-update" [
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
  --patient: int
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/problems/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: patient, var: patient}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, patient: $patient, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/procedures
#
# Returns: record<data: table<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>, next: string, previous: string>
# operationId: procedures_list
export def "procedures-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --mu-date: string
  --patient: int
  --doctor: int
  --mu-date-range: string
  --appointment: int
  --service-date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/procedures"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: mu_date, var: mu_date}, {name: patient, var: patient}, {name: doctor, var: doctor}, {name: mu_date_range, var: mu_date_range}, {name: appointment, var: appointment}, {name: service_date, var: service_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, mu_date: $mu_date, patient: $patient, doctor: $doctor, mu_date_range: $mu_date_range, appointment: $appointment, service_date: $service_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/procedures/{id}
#
# Returns: record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>
# operationId: procedures_read
export def "procedures-read" [
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
  --mu-date: string
  --patient: int
  --doctor: int
  --mu-date-range: string
  --appointment: int
  --service-date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/procedures/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: mu_date, var: mu_date}, {name: patient, var: patient}, {name: doctor, var: doctor}, {name: mu_date_range, var: mu_date_range}, {name: appointment, var: appointment}, {name: service_date, var: service_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, mu_date: $mu_date, patient: $patient, doctor: $doctor, mu_date_range: $mu_date_range, appointment: $appointment, service_date: $service_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search reminder profiles
#
# GET /api/reminder_profiles
# Returns: record<data: table<doctor: int, id: int, name: string, reminders: list>, next: string, previous: string>
# operationId: reminder_profiles_list
export def "reminder-profiles-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/reminder_profiles"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create reminder profile
#
# POST /api/reminder_profiles
# Returns: record<doctor: int, id: int, name: string, reminders: table<amount: int, type: string, unit: string>>
# operationId: reminder_profiles_create
export def "reminder-profiles-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/reminder_profiles"
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing reminder profile
#
# DELETE /api/reminder_profiles/{id}
# operationId: reminder_profiles_delete
export def "reminder-profiles-delete" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/reminder_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing reminder profile
#
# GET /api/reminder_profiles/{id}
# Returns: record<doctor: int, id: int, name: string, reminders: table<amount: int, type: string, unit: string>>
# operationId: reminder_profiles_read
export def "reminder-profiles-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/reminder_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing reminder profile
#
# PATCH /api/reminder_profiles/{id}
# operationId: reminder_profiles_partial_update
export def "reminder-profiles-partial-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/reminder_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing reminder profile
#
# PUT /api/reminder_profiles/{id}
# operationId: reminder_profiles_update
export def "reminder-profiles-update" [
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
  --doctor: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/reminder_profiles/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search sub vendors
#
# GET /api/sublabs
# Returns: record<data: table<facility_code: string, id: int, name: string, vendor_name: string>, next: string, previous: string>
# operationId: sublabs_list
export def "sublabs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/sublabs"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create sub-vendors - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/sublabs
# Returns: record<facility_code: string, id: int, name: string, vendor_name: string>
# operationId: sublabs_create
export def "sublabs-create" [
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
    path: "/api/sublabs"
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing sub vendor
#
# DELETE /api/sublabs/{id}
# operationId: sublabs_delete
export def "sublabs-delete" [
  id: int
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
    path: "/api/sublabs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing sub vendor
#
# GET /api/sublabs/{id}
# Returns: record<facility_code: string, id: int, name: string, vendor_name: string>
# operationId: sublabs_read
export def "sublabs-read" [
  id: int
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
    path: "/api/sublabs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing sub vendor
#
# PATCH /api/sublabs/{id}
# operationId: sublabs_partial_update
export def "sublabs-partial-update" [
  id: int
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
    method: patch
    path: "/api/sublabs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing sub vendor
#
# PUT /api/sublabs/{id}
# operationId: sublabs_update
export def "sublabs-update" [
  id: int
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
    method: put
    path: "/api/sublabs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search task categories
#
# GET /api/task_categories
# Returns: record<data: table<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string>, next: string, previous: string>
# operationId: task_categories_list
export def "task-categories-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/task_categories"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a task category
#
# POST /api/task_categories
# Returns: record<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string>
# operationId: task_categories_create
export def "task-categories-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/task_categories"
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing task category
#
# GET /api/task_categories/{id}
# Returns: record<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string>
# operationId: task_categories_read
export def "task-categories-read" [
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
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/task_categories/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task category
#
# PATCH /api/task_categories/{id}
# operationId: task_categories_partial_update
export def "task-categories-partial-update" [
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
  --since: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/task_categories/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task category
#
# PUT /api/task_categories/{id}
# operationId: task_categories_update
export def "task-categories-update" [
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
  --since: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/task_categories/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search task notes
#
# GET /api/task_notes
# Returns: record<data: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, next: string, previous: string>
# operationId: task_notes_list
export def "task-notes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --task: int
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/task_notes"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: task, var: task}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, task: $task, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a task note
#
# POST /api/task_notes
# Returns: record<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>
# operationId: task_notes_create
export def "task-notes-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task: int
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/task_notes"
    query: [{name: task, var: task}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    task: $task, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing task note
#
# GET /api/task_notes/{id}
# Returns: record<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>
# operationId: task_notes_read
export def "task-notes-read" [
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
  --task: int
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/task_notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: task, var: task}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, task: $task, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task note
#
# PATCH /api/task_notes/{id}
# operationId: task_notes_partial_update
export def "task-notes-partial-update" [
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
  --task: int
  --since: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/task_notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: task, var: task}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, task: $task, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task note
#
# PUT /api/task_notes/{id}
# operationId: task_notes_update
export def "task-notes-update" [
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
  --task: int
  --since: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/task_notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: task, var: task}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, task: $task, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search task statuses
#
# GET /api/task_statuses
# Returns: record<data: table<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string>, next: string, previous: string>
# operationId: task_statuses_list
export def "task-statuses-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/task_statuses"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a task status
#
# POST /api/task_statuses
# Returns: record<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string>
# operationId: task_statuses_create
export def "task-statuses-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/task_statuses"
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing task status
#
# GET /api/task_statuses/{id}
# Returns: record<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string>
# operationId: task_statuses_read
export def "task-statuses-read" [
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
  --since: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/task_statuses/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task status
#
# PATCH /api/task_statuses/{id}
# operationId: task_statuses_partial_update
export def "task-statuses-partial-update" [
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
  --since: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/task_statuses/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task status
#
# PUT /api/task_statuses/{id}
# operationId: task_statuses_update
export def "task-statuses-update" [
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
  --since: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/task_statuses/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: since, var: since}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search task templates
#
# GET /api/task_templates
# Returns: record<data: table<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string>, next: string, previous: string>
# operationId: task_templates_list
export def "task-templates-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/task_templates"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: assignee_user, var: assignee_user}, {name: status, var: status}, {name: assignee_group, var: assignee_group}, {name: since, var: since}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, assignee_user: $assignee_user, status: $status, assignee_group: $assignee_group, since: $since, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a task template
#
# POST /api/task_templates
# Returns: record<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string>
# operationId: task_templates_create
export def "task-templates-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/task_templates"
    query: [{name: assignee_user, var: assignee_user}, {name: status, var: status}, {name: assignee_group, var: assignee_group}, {name: since, var: since}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    assignee_user: $assignee_user, status: $status, assignee_group: $assignee_group, since: $since, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing task template
#
# GET /api/task_templates/{id}
# Returns: record<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string>
# operationId: task_templates_read
export def "task-templates-read" [
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
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/task_templates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: assignee_user, var: assignee_user}, {name: status, var: status}, {name: assignee_group, var: assignee_group}, {name: since, var: since}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, assignee_user: $assignee_user, status: $status, assignee_group: $assignee_group, since: $since, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task template
#
# PATCH /api/task_templates/{id}
# operationId: task_templates_partial_update
export def "task-templates-partial-update" [
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
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/task_templates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: assignee_user, var: assignee_user}, {name: status, var: status}, {name: assignee_group, var: assignee_group}, {name: since, var: since}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, assignee_user: $assignee_user, status: $status, assignee_group: $assignee_group, since: $since, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task template
#
# PUT /api/task_templates/{id}
# operationId: task_templates_update
export def "task-templates-update" [
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
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> any {
  http-request {
    method: put
    path: "/api/task_templates/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: assignee_user, var: assignee_user}, {name: status, var: status}, {name: assignee_group, var: assignee_group}, {name: since, var: since}, {name: category, var: category}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, assignee_user: $assignee_user, status: $status, assignee_group: $assignee_group, since: $since, category: $category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search tasks
#
# GET /api/tasks
# Returns: record<data: table<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: list, category: int, created_at: string, created_by: string, due_date: record, id: int, notes: list, priority: string, status: int, title: string, updated_at: string>, next: string, previous: string>
# operationId: tasks_list
export def "tasks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/tasks"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: status, var: status}, {name: category, var: category}, {name: due_at_date, var: due_at_date}, {name: due_at_unknown, var: due_at_unknown}, {name: since, var: since}, {name: due_at_since, var: due_at_since}, {name: assignee_user, var: assignee_user}, {name: assignee_group, var: assignee_group}, {name: due_at_range, var: due_at_range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, status: $status, category: $category, due_at_date: $due_at_date, due_at_unknown: $due_at_unknown, since: $since, due_at_since: $due_at_since, assignee_user: $assignee_user, assignee_group: $assignee_group, due_at_range: $due_at_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a task
#
# POST /api/tasks
# Returns: record<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: table<task: int, type: string, value: int>, category: int, created_at: string, created_by: string, due_date: record<time: string>, id: int, notes: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, priority: string, status: int, title: string, updated_at: string>
# operationId: tasks_create
export def "tasks-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/tasks"
    query: [{name: status, var: status}, {name: category, var: category}, {name: due_at_date, var: due_at_date}, {name: due_at_unknown, var: due_at_unknown}, {name: since, var: since}, {name: due_at_since, var: due_at_since}, {name: assignee_user, var: assignee_user}, {name: assignee_group, var: assignee_group}, {name: due_at_range, var: due_at_range}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    status: $status, category: $category, due_at_date: $due_at_date, due_at_unknown: $due_at_unknown, since: $since, due_at_since: $due_at_since, assignee_user: $assignee_user, assignee_group: $assignee_group, due_at_range: $due_at_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing task
#
# GET /api/tasks/{id}
# Returns: record<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: table<task: int, type: string, value: int>, category: int, created_at: string, created_by: string, due_date: record<time: string>, id: int, notes: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, priority: string, status: int, title: string, updated_at: string>
# operationId: tasks_read
export def "tasks-read" [
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
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/tasks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: category, var: category}, {name: due_at_date, var: due_at_date}, {name: due_at_unknown, var: due_at_unknown}, {name: since, var: since}, {name: due_at_since, var: due_at_since}, {name: assignee_user, var: assignee_user}, {name: assignee_group, var: assignee_group}, {name: due_at_range, var: due_at_range}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, status: $status, category: $category, due_at_date: $due_at_date, due_at_unknown: $due_at_unknown, since: $since, due_at_since: $due_at_since, assignee_user: $assignee_user, assignee_group: $assignee_group, due_at_range: $due_at_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task
#
# PATCH /api/tasks/{id}
# operationId: tasks_partial_update
export def "tasks-partial-update" [
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
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> any {
  http-request {
    method: patch
    path: "/api/tasks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: category, var: category}, {name: due_at_date, var: due_at_date}, {name: due_at_unknown, var: due_at_unknown}, {name: since, var: since}, {name: due_at_since, var: due_at_since}, {name: assignee_user, var: assignee_user}, {name: assignee_group, var: assignee_group}, {name: due_at_range, var: due_at_range}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, status: $status, category: $category, due_at_date: $due_at_date, due_at_unknown: $due_at_unknown, since: $since, due_at_since: $due_at_since, assignee_user: $assignee_user, assignee_group: $assignee_group, due_at_range: $due_at_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing task
#
# PUT /api/tasks/{id}
# operationId: tasks_update
export def "tasks-update" [
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
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> any {
  http-request {
    method: put
    path: "/api/tasks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: status, var: status}, {name: category, var: category}, {name: due_at_date, var: due_at_date}, {name: due_at_unknown, var: due_at_unknown}, {name: since, var: since}, {name: due_at_since, var: due_at_since}, {name: assignee_user, var: assignee_user}, {name: assignee_group, var: assignee_group}, {name: due_at_range, var: due_at_range}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, status: $status, category: $category, due_at_date: $due_at_date, due_at_unknown: $due_at_unknown, since: $since, due_at_since: $due_at_since, assignee_user: $assignee_user, assignee_group: $assignee_group, due_at_range: $due_at_range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search insurance transactions associated with billing line items
#
# GET /api/transactions
# Returns: record<data: table<adjustment: float, adjustment_group_code: string, adjustment_reason: string, appointment: int, check_date: string, claim_status: string, created_at: string, doctor: int, id: int, ins_name: int, ins_paid: float, line_item: int, patient: int, posted_date: string, trace_number: string, updated_at: string>, next: string, previous: string>
# operationId: transactions_list
export def "transactions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --line-item: int
  --posted-date: string
  --appointment: int
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/transactions"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: line_item, var: line_item}, {name: posted_date, var: posted_date}, {name: appointment, var: appointment}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, line_item: $line_item, posted_date: $posted_date, appointment: $appointment, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing insurance transaction
#
# GET /api/transactions/{id}
# Returns: record<adjustment: float, adjustment_group_code: string, adjustment_reason: string, appointment: int, check_date: string, claim_status: string, created_at: string, doctor: int, id: int, ins_name: int, ins_paid: float, line_item: int, patient: int, posted_date: string, trace_number: string, updated_at: string>
# operationId: transactions_read
export def "transactions-read" [
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
  --line-item: int
  --posted-date: string
  --appointment: int
  --since: string
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/transactions/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: line_item, var: line_item}, {name: posted_date, var: posted_date}, {name: appointment, var: appointment}, {name: since, var: since}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, line_item: $line_item, posted_date: $posted_date, appointment: $appointment, since: $since, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search user groups
#
# GET /api/user_groups
# Returns: record<data: table<archived: bool, created_at: string, id: int, members: list, name: string, practice_group: string, updated_at: string>, next: string, previous: string>
# operationId: user_groups_list
export def "user-groups-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/user_groups"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing user group
#
# GET /api/user_groups/{id}
# Returns: record<archived: bool, created_at: string, id: int, members: list<string>, name: string, practice_group: string, updated_at: string>
# operationId: user_groups_read
export def "user-groups-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/user_groups/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve or search users, `/api/users/current` can be used to identify logged in user, it will redirect to `/api/users/{current_user_id}`
#
# GET /api/users
# Returns: record<data: table<doctor: string, id: string, is_doctor: string, is_staff: string, permissions: string, practice_group: string, username: string>, next: string, previous: string>
# operationId: users_list
export def "users-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users"
    query: [{name: cursor, var: cursor}, {name: page_size, var: page_size}, {name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cursor: $cursor, page_size: $page_size, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve an existing user, `/api/users/current` can be used to identify logged in user, it will redirect to `/api/users/{current_user_id}`
#
# GET /api/users/{id}
# Returns: record<doctor: string, id: string, is_doctor: string, is_staff: string, permissions: string, practice_group: string, username: string>
# operationId: users_read
export def "users-read" [
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
  --doctor: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: doctor, var: doctor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, doctor: $doctor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
