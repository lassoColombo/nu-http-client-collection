# Auto-generated client for DRACOON API v4.42.2
# Source: https://api.apis.guru/v2/specs/dracoon.team/4.42.2/openapi.json
# Auth: --token flag or $env.DRACOON_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/api"
  token_env_var: "DRACOON_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru/api"] }
def auth-scheme-completer [] { ["bearer" "none"] }

# Completers for enum parameters
def auth-type-completer [] { ["active_directory" "basic" "radius"] }
def x-sds-date-format-completer [] { ["EPOCH" "LEET" "LOCAL" "OFFSET" "UTC"] }
def status-completer [] { ["0" "2"] }
def resolution-strategy-completer [] { ["autorename" "fail" "overwrite"] }
def classification-completer [] { ["1" "2" "3" "4"] }
def use-key-completer [] { ["previous_room_rescue_key" "previous_system_rescue_key" "previous_user_key" "room_rescue_key" "system_rescue_key"] }
def new-group-member-acceptance-completer [] { ["autoallow" "pending"] }
def customer-contract-type-completer [] { ["demo" "free" "pay"] }
def flow-completer [] { ["authorization_code" "hybrid"] }
def user-info-source-completer [] { ["id_token" "user_info_endpoint"] }
def client-type-completer [] { ["confidential" "public"] }
def grant-types-completer [] { ["authorization_code" "client_credentials" "implicit" "password" "refresh_token"] }
def password-type-completer [] { ["encryption" "login" "shares"] }
def protocol-completer [] { ["TCP" "UDP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    login: "record<token: string>"
    complete-open-id-login: "record<token: string>"
    ping: "string"
    validate-reset-password-token: "record<allowSystemGlobalWeakPassword: bool, firstName: string, gender: string, lastName: string, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, title: string>"
    request-system-defaults-info: "record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int>"
    request-general-settings-info: "record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, homeRoomParentId: int, homeRoomsActive: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, subscriptionPlan: int, useS3Storage: bool, weakPasswordEnabled: bool>"
    request-infrastructure-properties-info: "record<isDracoonCloud: bool, mediaServerConfigEnabled: bool, s3DefaultRegion: string, s3EnforceDirectUpload: bool, smsConfigEnabled: bool, tenantUuid: string>"
    request-notification-channels-info: "record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>>"
    request-algorithms: "record<fileKeyAlgorithms: table<description: string, status: string, version: string>, keyPairAlgorithms: table<description: string, status: string, version: string>>"
    request-classification-policies-config-info: "record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>>"
    request-guest-users-policies-config-info: "record<isInviteUsersEnabled: bool>"
    request-password-policies-config-info: "record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>>"
    request-product-packages: "record<packages: table<clients: list, features: list, productPackageId: int, productPackageName: string>>"
    request-current-product-packages: "record<packages: table<clients: list, features: list, productPackageId: int, productPackageName: string>>"
    request-s3-tags-info: "record<items: table<id: int, isMandatory: bool, key: string, value: string>>"
    request-system-settings: "record<items: table<key: string, value: string>>"
    download-avatar: "string"
    download-file-via-token-1: "record"
    request-audit-node-info: "record<items: table<countChildren: int, nodeId: int, nodeIsEncrypted: bool, nodeName: string, nodeParentId: int, nodeParentPath: string>, range: record<limit: int, offset: int, total: int>>"
    request-audit-node-user-data: "table<auditUserPermissionList: list<record>, nodeCntChildren: int, nodeCreatedAt: string, nodeCreatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, nodeHasActivitiesLog: bool, nodeHasRecycleBin: bool, nodeId: int, nodeIsEncrypted: bool, nodeName: string, nodeParentId: int, nodeParentPath: string, nodeQuota: int, nodeRecycleBinRetentionPeriod: int, nodeSize: int, nodeUpdatedAt: string, nodeUpdatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-log-events-as-json: "record<items: table<attribute1: string, attribute2: string, attribute3: string, authParentSource: string, authParentTarget: string, customerId: int, id: int, message: string, objectId1: int, objectId2: int, objectName1: string, objectName2: string, objectType1: int, objectType2: int, operationId: int, operationName: string, status: int, time: string, userClient: string, userId: int, userIp: string, userName: string>, range: record<limit: int, offset: int, total: int>>"
    request-log-operations: "record<operationList: table<id: int, isDeprecated: bool, name: string>>"
    request-groups: "record<items: table<cntUsers: int, createdAt: string, createdBy: record, expireAt: string, groupRoles: record, id: int, name: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    create-group: "record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-group: "record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    update-group: "record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-last-admin-rooms-groups: "record<items: table<id: int, name: string, parentId: int, parentPath: string>>"
    request-group-roles: "record<items: table<description: string, id: int, items: list, name: string>>"
    request-group-rooms: "record<items: table<children: list, cntDownloadShares: int, cntUploadShares: int, createdAt: string, createdBy: record, hasRecycleBin: bool, id: int, isEncrypted: bool, isFavorite: bool, isGranted: bool, name: string, parentId: int, permissions: record, quota: int, recycleBinRetentionPeriod: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    remove-group-members: "record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-group-members: "record<items: table<displayName: string, email: string, id: int, isMember: bool, login: string, userInfo: record>, range: record<limit: int, offset: int, total: int>>"
    add-group-members: "record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    internal-request-subscription-plan: "record<subscriptionPlanId: int>"
    internal-set-subscription-plan: "record<subscriptionPlanId: int>"
    request-nodes: "record<items: table<authParentId: int, branchVersion: int, children: list, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record, encryptionInfo: record, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    update-node-comment: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-deleted-node: "record<accessedAt: string, classification: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, deletedAt: string, deletedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, id: int, isEncrypted: bool, name: string, notes: string, parentId: int, parentPath: string, referenceId: int, size: int, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    create-file-upload-channel: "record<token: string, uploadId: string, uploadUrl: string>"
    request-upload-status-files: "record<errorDetails: record<code: int, debugInfo: string, errorCode: int, message: string>, node: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, status: string>"
    upload-file-as-multipart: "record<hash: string, size: int>"
    complete-file-upload: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    generate-presigned-urls-files: "record<urls: table<partNumber: int, url: string>>"
    request-file-version-list: "record<items: table<deleted: bool, id: int, name: string, parentId: int, referenceId: int>, range: record<limit: int, offset: int, total: int>>"
    update-file: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-room-rescue-key: "record<iv: string, key: string, tag: string, version: string>"
    request-system-rescue-key: "record<iv: string, key: string, tag: string, version: string>"
    generate-download-url: "record<downloadUrl: string>"
    request-user-file-key: "record<iv: string, key: string, tag: string, version: string>"
    create-folder: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    update-folder: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-missing-file-keys: "record<files: table<fileKeyContainer: record, id: int>, items: table<fileId: int, userId: int>, range: record<limit: int, offset: int, total: int>, users: table<id: int, publicKeyContainer: record>>"
    create-room: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-pending-assignments: "record<items: table<groupInfo: record, pendingGroupData: record, pendingUserData: record, roomId: int, roomName: string, state: string, userInfo: record>, range: record<limit: int, offset: int, total: int>>"
    update-room: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    configure-room: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    encrypt-room: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-room-activities-log-as-json: "record<items: table<attribute1: string, attribute2: string, attribute3: string, authParentSource: string, authParentTarget: string, customerId: int, id: int, message: string, objectId1: int, objectId2: int, objectName1: string, objectName2: string, objectType1: int, objectType2: int, operationId: int, operationName: string, status: int, time: string, userClient: string, userId: int, userIp: string, userName: string>, range: record<limit: int, offset: int, total: int>>"
    request-room-groups: "record<items: table<id: int, isGranted: bool, name: string, newGroupMemberAcceptance: string, permissions: record>, range: record<limit: int, offset: int, total: int>>"
    request-room-rescue-key-pair: "record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>"
    request-room-rescue-key-pairs: "table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>"
    request-room-policies: "record<defaultExpirationPeriod: int>"
    request-room-s3-tags: "record<items: table<id: int, isMandatory: bool, key: string, value: string>>"
    set-room-s3-tags: "record<items: table<id: int, isMandatory: bool, key: string, value: string>>"
    request-room-users: "record<items: table<displayName: string, email: string, id: int, isGranted: bool, login: string, permissions: record, publicKeyContainer: record, userInfo: record>, range: record<limit: int, offset: int, total: int>>"
    request-list-of-webhooks-for-room: "record<items: table<isAssigned: bool, webhook: record>, range: record<limit: int, offset: int, total: int>>"
    handle-room-webhook-assignments: "record<items: table<isAssigned: bool, webhook: record>, range: record<limit: int, offset: int, total: int>>"
    search-nodes: "record<items: table<authParentId: int, branchVersion: int, children: list, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record, encryptionInfo: record, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    generate-download-url-for-zip-archive: "record<downloadUrl: string>"
    request-node: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-node-comments: "record<items: table<createdAt: string, createdBy: record, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    create-node-comment: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    copy-nodes: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-deleted-nodes-summary: "record<items: table<cntVersions: int, firstDeletedAt: string, lastDeletedAt: string, lastDeletedNodeId: int, name: string, parentId: int, parentPath: string, referenceId: int, timestampCreation: string, timestampModification: string, type: string>, range: record<limit: int, offset: int, total: int>>"
    request-deleted-node-versions: "record<items: table<accessedAt: string, classification: int, createdAt: string, createdBy: record, deletedAt: string, deletedBy: record, expireAt: string, id: int, isEncrypted: bool, name: string, notes: string, parentId: int, parentPath: string, referenceId: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    add-favorite: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    move-nodes: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-node-parents: "record<items: table<id: int, name: string, parentId: int, type: string>>"
    request-customers: "record<items: table<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>, range: record<limit: int, offset: int, total: int>>"
    create-customer: "record<activationCode: string, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, firstAdminUser: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: list<record>, email: string, firstName: string, gender: string, language: string, lastName: string, login: string, needsToChangePassword: bool, needsToChangeUserName: bool, notifyUser: bool, password: string, phone: string, receiverLanguage: string, title: string, userName: string>, id: int, isLocked: bool, lockStatus: bool, providerCustomerId: string, quotaMax: int, trialDays: int, userMax: int, webhooksMax: int>"
    request-customer: "record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>"
    update-customer: "record<activationCode: string, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lockStatus: bool, providerCustomerId: string, quotaMax: int, trialDays: int, updatedAt: string, userMax: int, webhooksMax: int>"
    request-customer-attributes: "record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>"
    set-customer-attributes: "record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>"
    update-customer-attributes: "record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>"
    request-customer-users: "record<items: table<avatarUuid: string, createdAt: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, title: string, userAttributes: record, userName: string, userRoles: record>, range: record<limit: int, offset: int, total: int>>"
    request-list-of-tenant-webhooks: "record<items: table<createdAt: string, createdBy: record, eventTypeNames: list, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record, url: string>, range: record<limit: int, offset: int, total: int>>"
    create-tenant-webhook: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>"
    request-list-of-event-types-for-tenant: "record<items: table<id: int, name: string, usableCustomerAdminWebhook: bool, usableNodeWebhook: bool, usablePushNotification: bool, usableTenantWebhook: bool>>"
    request-tenant-webhook: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>"
    update-tenant-webhook: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>"
    reset-tenant-webhook-lifetime: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>"
    request-public-download-share-info: "record<createdAt: string, creatorName: string, creatorUsername: string, expireAt: string, fileKey: record<iv: string, key: string, tag: string, version: string>, fileName: string, hasDownloadLimit: bool, isEncrypted: bool, isProtected: bool, limitReached: bool, mediaType: string, name: string, notes: string, privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, size: int>"
    check-public-download-share-password: "record"
    generate-download-url-public: "record<downloadUrl: string>"
    download-file-via-token-public-1: "record"
    request-public-upload-share-info: "record<createdAt: string, creatorName: string, creatorUsername: string, expireAt: string, isEncrypted: bool, isProtected: bool, name: string, notes: string, remainingSize: int, remainingSlots: int, showUploadedFiles: bool, uploadedFiles: table<createdAt: string, hash: string, name: string, size: int>, userUserPublicKeyList: record<items: list<record>>>"
    create-share-upload-channel: "record<uploadId: string, uploadUrl: string>"
    request-upload-status-public: "record<errorDetails: record<code: int, debugInfo: string, errorCode: int, message: string>, fileName: string, size: int, status: string>"
    upload-file-as-multipart-public-1: "record<hash: string, size: int>"
    complete-file-upload-via-share: "record<createdAt: string, hash: string, name: string, size: int>"
    generate-presigned-urls-public: "record<urls: table<partNumber: int, url: string>>"
    request-third-party-dependencies: "table<artifactId: string, description: string, groupId: string, id: string, licenses: list<string>, name: string, type: string, url: string, version: string>"
    request-software-version: "record<buildDate: string, isDracoonCloud: bool, restApiVersion: string, scmRevisionNumber: string, sdsServerVersion: string>"
    request-system-info: "record<authMethods: table<isEnabled: bool, name: string, priority: int>, hideLoginInputFields: bool, languageDefault: string, s3EnforceDirectUpload: bool, s3Hosts: list<string>, useS3Storage: bool>"
    request-active-directory-auth-info: "record<items: table<alias: string, id: int, isGlobalAvailable: bool>>"
    request-open-id-auth-info: "record<items: table<id: int, isGlobalAvailable: bool, issuer: string, mappingClaim: string, name: string, userManagementUrl: string>>"
    request-system-time: "record<time: string>"
    request-subscription-scopes: "record<items: table<id: int, name: string>>"
    request-user-avatar: "record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool>"
    request-roles: "record<items: table<description: string, id: int, items: list, name: string>>"
    revoke-role-groups: "record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>>"
    request-role-groups: "record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>>"
    add-role-groups: "record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>>"
    revoke-role-users: "record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>>"
    request-role-users: "record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>>"
    add-role-users: "record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>>"
    request-settings: "record<homeRoomParentId: int, homeRoomParentName: string, homeRoomQuota: int, homeRoomsActive: bool>"
    set-settings: "record<homeRoomParentId: int, homeRoomParentName: string, homeRoomQuota: int, homeRoomsActive: bool>"
    request-system-rescue-key-pair: "record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>"
    request-all-system-rescue-key-pairs: "table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>"
    request-notification-channels: "record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>>"
    toggle-notification-channels: "record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>>"
    request-list-of-webhooks: "record<items: table<createdAt: string, createdBy: record, eventTypeNames: list, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record, url: string>, range: record<limit: int, offset: int, total: int>>"
    create-webhook: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>"
    request-list-of-event-types-for-config-manager: "record<items: table<id: int, name: string, usableCustomerAdminWebhook: bool, usableNodeWebhook: bool, usablePushNotification: bool, usableTenantWebhook: bool>>"
    request-webhook: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>"
    update-webhook: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>"
    reset-webhook-lifetime: "record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>"
    request-download-shares: "record<items: table<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    create-download-share: "record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-download-share: "record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    update-download-share: "record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-download-share-qr: "record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-upload-shares: "record<items: table<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    create-upload-share: "record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-upload-share: "record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    update-upload-share: "record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-upload-share-qr: "record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    test-ad-config: "record<ldapUsersDomain: string, serverAdminName: string, serverAdminPassword: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool>"
    request-ad-configs: "record<items: table<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>>"
    create-ad-config: "record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>"
    request-ad-config: "record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>"
    update-ad-config: "record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>"
    request-open-id-idp-configs: "table<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool>"
    create-open-id-idp-config: "record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool>"
    request-open-id-idp-config: "record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool>"
    update-open-id-idp-config: "record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool>"
    request-radius-config: "record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string>"
    create-radius-config: "record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string>"
    update-radius-config: "record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string>"
    request-o-auth-clients: "table<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int>"
    create-o-auth-client: "record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int>"
    request-o-auth-client: "record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int>"
    update-o-auth-client: "record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int>"
    request-classification-policies-config: "record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>>"
    change-classification-policies-config: "record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>>"
    request-guest-users-policies-config: "record<isInviteUsersEnabled: bool>"
    change-guest-users-policies-config: "record<isInviteUsersEnabled: bool>"
    request-mfa-policies-config: "record<isMfaEnforced: bool>"
    change-mfa-policies-config: "record<isMfaEnforced: bool>"
    request-password-policies-config: "record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>>"
    change-password-policies-config: "record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>>"
    request-password-policies-for-password-type: "record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>>"
    request-auth-config: "record<authMethods: table<isEnabled: bool, name: string, priority: int>>"
    update-auth-config: "record<authMethods: table<isEnabled: bool, name: string, priority: int>>"
    request-system-defaults: "record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int>"
    update-system-defaults: "record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int>"
    request-eventlog-config: "record<enabled: bool, logIpEnabled: bool, retentionPeriod: int>"
    update-eventlog-config: "record<enabled: bool, logIpEnabled: bool, retentionPeriod: int>"
    request-general-settings: "record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, useS3Storage: bool, weakPasswordEnabled: bool>"
    update-general-settings: "record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, useS3Storage: bool, weakPasswordEnabled: bool>"
    request-infrastructure-properties: "record<isDracoonCloud: bool, mediaServerConfigEnabled: bool, s3DefaultRegion: string, s3EnforceDirectUpload: bool, smsConfigEnabled: bool, tenantUuid: string>"
    request-syslog-config: "record<enabled: bool, host: string, logIpEnabled: bool, port: int, protocol: string>"
    update-syslog-config: "record<enabled: bool, host: string, logIpEnabled: bool, port: int, protocol: string>"
    request3-config: "record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool>"
    create-s3-config: "record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool>"
    update-s3-config: "record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool>"
    request-s3-tag-list: "record<items: table<id: int, isMandatory: bool, key: string, value: string>>"
    create-s3-tag: "record<id: int, isMandatory: bool, key: string, value: string>"
    request-s3-tag: "record<id: int, isMandatory: bool, key: string, value: string>"
    upload-file-by-token-as-multipart-1: "record<hash: string, size: int>"
    complete-file-upload-by-token: "record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>"
    request-user-info: "record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, language: string, lastLoginFailAt: string, lastLoginFailIp: string, lastLoginSuccessAt: string, lastLoginSuccessIp: string, lastName: string, lockStatus: int, login: string, mustSetEmail: bool, needsToAcceptEULA: bool, needsToChangePassword: bool, needsToChangeUserName: bool, phone: string, title: string, userAttributes: record<items: list<record>>, userGroups: table<id: int, isMember: bool, name: string>, userName: string, userRoles: record<items: list<record>>>"
    update-user-account: "record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, language: string, lastLoginFailAt: string, lastLoginFailIp: string, lastLoginSuccessAt: string, lastLoginSuccessIp: string, lastName: string, lockStatus: int, login: string, mustSetEmail: bool, needsToAcceptEULA: bool, needsToChangePassword: bool, needsToChangeUserName: bool, phone: string, title: string, userAttributes: record<items: list<record>>, userGroups: table<id: int, isMember: bool, name: string>, userName: string, userRoles: record<items: list<record>>>"
    reset-avatar: "record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool>"
    request-avatar: "record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool>"
    upload-avatar-as-multipart: "record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool>"
    request-customer-info: "record<accountsLimit: int, accountsUsed: int, cntGuestUser: int, cntInternalUser: int, customerEncryptionEnabled: bool, id: int, isProviderCustomer: bool, name: string, spaceLimit: int, spaceUsed: int>"
    enable-customer-encryption: "record<accountsLimit: int, accountsUsed: int, cntGuestUser: int, cntInternalUser: int, customerEncryptionEnabled: bool, id: int, isProviderCustomer: bool, name: string, spaceLimit: int, spaceUsed: int>"
    request-customer-key-pair: "record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>"
    request-user-key-pair: "record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>"
    request-user-key-pairs: "table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>"
    get-mfa-status-for-user: "record<mfaEnforced: bool, mfaSetups: table<createdAt: string, id: int, mfaType: string, name: string>>"
    get-totp-setup-information: "record<id: int, otpUri: string, qrCode: string, secret: string>"
    request-list-of-notification-configs: "record<items: table<channelIds: list, eventTypeName: string, id: int, scopeId: int>>"
    update-notification-config: "record<channelIds: list<int>, eventTypeName: string, id: int, scopeId: int>"
    request-o-auth-approvals: "table<clientId: string, clientName: string, expiresAt: string>"
    request-o-auth-authorizations: "table<clientId: string, clientName: string, createdAt: string, expiresAt: string, id: int, isCurrentAuthorization: bool, isStandard: bool, usedAt: string, userAgentCategory: string, userAgentInfo: string, userAgentOs: string, userAgentType: string>"
    ping-user: "string"
    request-profile-attributes: "record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>"
    set-profile-attributes: "record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>"
    update-profile-attributes: "record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>"
    list-download-share-subscriptions: "record<items: table<authParentId: int, id: int>, range: record<limit: int, offset: int, total: int>>"
    subscribe-download-share: "record<authParentId: int, id: int>"
    list-node-subscriptions: "record<items: table<authParentId: int, id: int, type: string>, range: record<limit: int, offset: int, total: int>>"
    subscribe-node: "record<authParentId: int, id: int, type: string>"
    list-upload-share-subscriptions: "record<items: table<id: int, targetNodeId: int>, range: record<limit: int, offset: int, total: int>>"
    subscribe-upload-share: "record<id: int, targetNodeId: int>"
    request-users: "record<items: table<avatarUuid: string, createdAt: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, title: string, userAttributes: record, userName: string, userRoles: record>, range: record<limit: int, offset: int, total: int>>"
    create-user: "record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>"
    request-user: "record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>"
    update-user: "record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>"
    request-user-groups: "record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>>"
    request-last-admin-rooms-users: "record<items: table<id: int, lastAdminInGroup: bool, lastAdminInGroupId: int, name: string, parentId: int, parentPath: string>>"
    request-emergency-mfa-code: "record<code: string>"
    request-user-roles: "record<items: table<description: string, id: int, items: list, name: string>>"
    request-users-rooms: "record<items: table<children: list, cntDownloadShares: int, cntUploadShares: int, createdAt: string, createdBy: record, hasRecycleBin: bool, id: int, isEncrypted: bool, isFavorite: bool, isGranted: bool, name: string, parentId: int, permissions: record, quota: int, recycleBinRetentionPeriod: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>"
    request-user-attributes: "record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>"
    set-user-attributes: "record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>"
    update-user-attributes: "record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["login" "initiate-open-id-login" "complete-open-id-login" "ping" "recover-user-name" "request-password-reset" "validate-reset-password-token" "reset-password" "request-system-defaults-info" "request-general-settings-info" "request-infrastructure-properties-info" "request-notification-channels-info" "request-algorithms" "request-classification-policies-config-info" "request-guest-users-policies-config-info" "request-password-policies-config-info" "request-product-packages" "request-current-product-packages" "request-s3-tags-info" "request-system-settings" "update-system-settings" "download-avatar" "download-zip-archive-via-token" "download-file-via-token" "download-file-via-token-1" "request-audit-node-info" "request-audit-node-user-data" "request-log-events-as-json" "request-log-operations" "request-groups" "create-group" "remove-group" "request-group" "update-group" "request-last-admin-rooms-groups" "request-group-roles" "request-group-rooms" "remove-group-members" "request-group-members" "add-group-members" "internal-request-subscription-plan" "internal-set-subscription-plan" "remove-nodes" "request-nodes" "remove-node-comment" "update-node-comment" "remove-deleted-nodes" "restore-nodes" "request-deleted-node" "update-favorites" "update-files" "set-user-file-keys" "create-file-upload-channel" "cancel-file-upload" "request-upload-status-files" "upload-file-as-multipart" "complete-file-upload" "complete-s3-file-upload" "generate-presigned-urls-files" "request-file-version-list" "update-file" "request-room-rescue-key" "request-system-rescue-key" "generate-download-url" "request-user-file-key" "create-folder" "update-folder" "request-missing-file-keys" "create-room" "request-pending-assignments" "change-pending-assignments" "update-room" "configure-room" "encrypt-room" "request-room-activities-log-as-json" "revoke-room-groups" "request-room-groups" "update-room-groups" "add-room-guest-users" "remove-room-rescue-key-pair" "request-room-rescue-key-pair" "set-room-rescue-key-pair" "request-room-rescue-key-pairs" "create-and-preserve-room-rescue-key-pair" "request-room-policies" "set-room-policies" "request-room-s3-tags" "set-room-s3-tags" "revoke-room-users" "request-room-users" "update-room-users" "request-list-of-webhooks-for-room" "handle-room-webhook-assignments" "search-nodes" "generate-download-url-for-zip-archive" "download-zip-archive" "remove-node" "request-node" "request-node-comments" "create-node-comment" "copy-nodes" "empty-deleted-nodes" "request-deleted-nodes-summary" "request-deleted-node-versions" "remove-favorite" "add-favorite" "move-nodes" "request-node-parents" "request-customers" "create-customer" "remove-customer" "request-customer" "update-customer" "request-customer-attributes" "set-customer-attributes" "update-customer-attributes" "remove-customer-attribute" "request-customer-users" "request-list-of-tenant-webhooks" "create-tenant-webhook" "request-list-of-event-types-for-tenant" "remove-tenant-webhook" "request-tenant-webhook" "update-tenant-webhook" "reset-tenant-webhook-lifetime" "request-public-download-share-info" "check-public-download-share-password" "generate-download-url-public" "download-file-via-token-public" "download-file-via-token-public-1" "request-public-upload-share-info" "create-share-upload-channel" "cancel-file-upload-via-share" "request-upload-status-public" "upload-file-as-multipart-public-1" "complete-file-upload-via-share" "complete-s3-file-upload-via-share" "generate-presigned-urls-public" "request-third-party-dependencies" "request-software-version" "request-system-info" "request-active-directory-auth-info" "request-open-id-auth-info" "request-system-time" "request-subscription-scopes" "request-user-avatar" "request-roles" "revoke-role-groups" "request-role-groups" "add-role-groups" "revoke-role-users" "request-role-users" "add-role-users" "request-settings" "set-settings" "remove-system-rescue-key-pair" "request-system-rescue-key-pair" "set-system-rescue-key-pair" "request-all-system-rescue-key-pairs" "create-and-preserve-key-pair" "request-notification-channels" "toggle-notification-channels" "request-list-of-webhooks" "create-webhook" "request-list-of-event-types-for-config-manager" "remove-webhook" "request-webhook" "update-webhook" "reset-webhook-lifetime" "delete-download-shares" "request-download-shares" "create-download-share" "update-download-shares" "remove-download-share" "request-download-share" "update-download-share" "send-download-share-link-via-email" "request-download-share-qr" "delete-upload-shares" "request-upload-shares" "create-upload-share" "update-upload-shares" "remove-upload-share" "request-upload-share" "update-upload-share" "send-upload-share-link-via-email" "request-upload-share-qr" "test-ad-config" "test-radius-config" "request-ad-configs" "create-ad-config" "remove-ad-config" "request-ad-config" "update-ad-config" "request-open-id-idp-configs" "create-open-id-idp-config" "remove-open-id-idp-config" "request-open-id-idp-config" "update-open-id-idp-config" "remove-radius-config" "request-radius-config" "create-radius-config" "update-radius-config" "request-o-auth-clients" "create-o-auth-client" "remove-o-auth-client" "request-o-auth-client" "update-o-auth-client" "request-classification-policies-config" "change-classification-policies-config" "request-guest-users-policies-config" "change-guest-users-policies-config" "request-mfa-policies-config" "change-mfa-policies-config" "request-password-policies-config" "change-password-policies-config" "enforce-login-password-change" "request-password-policies-for-password-type" "request-auth-config" "update-auth-config" "request-system-defaults" "update-system-defaults" "request-eventlog-config" "update-eventlog-config" "request-general-settings" "update-general-settings" "request-infrastructure-properties" "request-syslog-config" "update-syslog-config" "request3-config" "create-s3-config" "update-s3-config" "request-s3-tag-list" "create-s3-tag" "remove-s3-tag" "request-s3-tag" "cancel-file-upload-by-token" "upload-file-by-token-as-multipart-1" "complete-file-upload-by-token" "request-user-info" "update-user-account" "reset-avatar" "request-avatar" "upload-avatar-as-multipart" "request-customer-info" "enable-customer-encryption" "request-customer-key-pair" "remove-user-key-pair" "request-user-key-pair" "set-user-key-pair" "request-user-key-pairs" "create-and-preserve-user-key-pair" "use-emergency-code" "get-mfa-status-for-user" "get-totp-setup-information" "confirm-totp-setup" "delete-mfa-totp-setup" "change-user-password" "logout" "request-list-of-notification-configs" "update-notification-config" "request-o-auth-approvals" "remove-o-auth-approval" "request-o-auth-authorizations" "remove-o-auth-authorizations" "remove-o-auth-authorization" "ping-user" "request-profile-attributes" "set-profile-attributes" "update-profile-attributes" "remove-profile-attribute" "list-download-share-subscriptions" "subscribe-download-shares" "unsubscribe-download-share" "subscribe-download-share" "list-node-subscriptions" "update-node-subscriptions" "unsubscribe-node" "subscribe-node" "list-upload-share-subscriptions" "subscribe-upload-shares" "unsubscribe-upload-share" "subscribe-upload-share" "request-users" "create-user" "remove-user" "request-user" "update-user" "request-user-groups" "request-last-admin-rooms-users" "request-emergency-mfa-code" "request-user-roles" "request-users-rooms" "request-user-attributes" "set-user-attributes" "update-user-attributes" "remove-user-attribute" "commands"] | sort) } | get name | first)
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

# Authenticate user (Login)
#
# POST /v4/auth/login
# DEPRECATED
# Docs: https://tools.ietf.org/html/rfc2865 — Remote Authentication Dial In User Service (RADIUS)
# Returns: record<token: string>
# operationId: login
@deprecated
@deprecated --flag language
@deprecated --flag login
export def "login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-type: string@auth-type-completer # Authentication methods
  --language: string # &#128679; Deprecated since v4.7.0 Language ID or ISO 639-1 code (DEPRECATED)
  --login: string # &#128679; Deprecated since v4.7.0 User login name (DEPRECATED)
  password: string # Password
  --state: string # For RADIUS Access-Challenge If a `replyState` is returned, it must be included as `state` in the following request.
  --body-token: string # RADIUS Token (spec name: token)
  --user-name: string # &#128640; Since v4.13.0 Username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/auth/login"
    body: {content_type: "application/json", kind: json, fields: [{name: authType, var: auth_type}, {name: language, var: language}, {name: login, var: login}, {name: password, var: password}, {name: state, var: state}, {name: token, var: body_token}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    auth_type: $auth_type, language: $language, login: $login, password: $password, state: $state, body_token: $body_token, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate OpenID Connect authentication
#
# GET /v4/auth/openid/login
# DEPRECATED
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: initiateOpenIdLogin
@deprecated
@deprecated --flag language
export def "initiate-open-id-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --issuer: string # Issuer identifier of the OpenID Connect identity provider (required)
  --redirect-uri: string # Redirect URI to complete the OpenID Connect authentication (required)
  --language: string # Language ID or ISO 639-1 code (required, DEPRECATED)
  --test: oneof<nothing, bool> # Flag to test the authentication parameters. If the request is valid, the API will respond with `204 No Content`. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v4/auth/openid/login"
    query: [{name: issuer, var: issuer, required: true}, {name: redirect_uri, var: redirect_uri, required: true}, {name: language, var: language, required: true}, {name: test, var: test, required: true}]
    accept: ["application/json"]
    ok: [204, 302]
    auth: none
  } {
    issuer: $issuer, redirect_uri: $redirect_uri, language: $language, test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete OpenID Connect authentication
#
# POST /v4/auth/openid/login
# DEPRECATED
# Docs: http://openid.net/developers/specs — OpenID Specifications
# Returns: record<token: string>
# operationId: completeOpenIdLogin
@deprecated
export def "complete-open-id-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # Authorization code (required)
  --id-token: string # Identity token
  --state: string # Authentication state (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/auth/openid/login"
    query: [{name: code, var: code, required: true}, {name: id_token, var: id_token}, {name: state, var: state, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    code: $code, id_token: $id_token, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping
#
# GET /v4/auth/ping
# Returns: string
# operationId: ping
export def "ping" [
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
    method: get
    path: "/v4/auth/ping"
    accept: ["text/plain"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover username
#
# POST /v4/auth/recover_username
# operationId: recoverUserName
export def "recover-user-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --creator-language: string # IETF language tag
  email: string # Email
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/auth/recover_username"
    body: {content_type: "application/json", kind: json, fields: [{name: creatorLanguage, var: creator_language}, {name: email, var: email}]}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    creator_language: $creator_language, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request password reset
#
# POST /v4/auth/reset_password
# operationId: requestPasswordReset
@deprecated --flag language
@deprecated --flag login
export def "request-password-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --creator-language: string # IETF language tag
  --language: string # &#128679; Deprecated since v4.7.0 Language ID or ISO 639-1 code (DEPRECATED)
  --login: string # &#128679; Deprecated since v4.13.0 User login name (DEPRECATED)
  --user-name: string # &#128640; Since v4.13.0 Username
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/auth/reset_password"
    body: {content_type: "application/json", kind: json, fields: [{name: creatorLanguage, var: creator_language}, {name: language, var: language}, {name: login, var: login}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    creator_language: $creator_language, language: $language, login: $login, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validate information for password reset
#
# GET /v4/auth/reset_password/{token}
# Returns: record<allowSystemGlobalWeakPassword: bool, firstName: string, gender: string, lastName: string, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, title: string>
# operationId: validateResetPasswordToken
export def "validate-reset-password-token" [
  token_arg: string
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
    path: "/v4/auth/reset_password/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset password
#
# PUT /v4/auth/reset_password/{token}
# operationId: resetPassword
export def "reset-password" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # New password
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/auth/reset_password/{token}"
    path_params: [{name: token, var: token_arg}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    token_arg: $token_arg, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request default values
#
# GET /v4/config/info/defaults
# Docs: https://tools.ietf.org/html/rfc5646 — Tags for Identifying Languages
# Returns: record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int>
# operationId: requestSystemDefaultsInfo
export def "request-system-defaults-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/defaults"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request general settings
#
# GET /v4/config/info/general
# Returns: record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, homeRoomParentId: int, homeRoomsActive: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, subscriptionPlan: int, useS3Storage: bool, weakPasswordEnabled: bool>
# operationId: requestGeneralSettingsInfo
export def "request-general-settings-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/general"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request infrastructure properties
#
# GET /v4/config/info/infrastructure
# Returns: record<isDracoonCloud: bool, mediaServerConfigEnabled: bool, s3DefaultRegion: string, s3EnforceDirectUpload: bool, smsConfigEnabled: bool, tenantUuid: string>
# operationId: requestInfrastructurePropertiesInfo
export def "request-infrastructure-properties-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/infrastructure"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of notification channels
#
# GET /v4/config/info/notifications/channels
# Returns: record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>>
# operationId: requestNotificationChannelsInfo
export def "request-notification-channels-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/notifications/channels"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request algorithms
#
# GET /v4/config/info/policies/algorithms
# Returns: record<fileKeyAlgorithms: table<description: string, status: string, version: string>, keyPairAlgorithms: table<description: string, status: string, version: string>>
# operationId: requestAlgorithms
export def "request-algorithms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/policies/algorithms"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request classification policies
#
# GET /v4/config/info/policies/classifications
# Returns: record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>>
# operationId: requestClassificationPoliciesConfigInfo
export def "request-classification-policies-config-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/policies/classifications"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request guest users policies
#
# GET /v4/config/info/policies/guest_users
# Returns: record<isInviteUsersEnabled: bool>
# operationId: requestGuestUsersPoliciesConfigInfo
export def "request-guest-users-policies-config-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/policies/guest_users"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request password policies
#
# GET /v4/config/info/policies/passwords
# Returns: record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>>
# operationId: requestPasswordPoliciesConfigInfo
export def "request-password-policies-config-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/policies/passwords"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of product packages
#
# GET /v4/config/info/product_packages
# Returns: record<packages: table<clients: list, features: list, productPackageId: int, productPackageName: string>>
# operationId: requestProductPackages
export def "request-product-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/product_packages"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of currently enabled product packages
#
# GET /v4/config/info/product_packages/current
# Returns: record<packages: table<clients: list, features: list, productPackageId: int, productPackageName: string>>
# operationId: requestCurrentProductPackages
export def "request-current-product-packages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/product_packages/current"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of configured S3 tags
#
# GET /v4/config/info/s3_tags
# Returns: record<items: table<id: int, isMandatory: bool, key: string, value: string>>
# operationId: requestS3TagsInfo
export def "request-s3-tags-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/info/s3_tags"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request system settings
#
# GET /v4/config/settings
# DEPRECATED
# Returns: record<items: table<key: string, value: string>>
# operationId: requestSystemSettings
@deprecated
export def "request-system-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/config/settings"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update system settings
#
# PUT /v4/config/settings
# DEPRECATED
# operationId: updateSystemSettings
@deprecated
export def "update-system-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/config/settings"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download avatar
#
# GET /v4/downloads/avatar/{user_id}/{uuid}
# Returns: string
# operationId: downloadAvatar
export def "download-avatar" [
  user_id: int
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
    method: get
    path: "/v4/downloads/avatar/{user_id}/{uuid}"
    path_params: [{name: user_id, var: user_id}, {name: uuid, var: uuid}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: none
  } {
    user_id: $user_id, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download ZIP archive
#
# GET /v4/downloads/zip/{token}
# operationId: downloadZipArchiveViaToken
export def "download-zip-archive-via-token" [
  token_arg: string
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
    method: get
    path: "/v4/downloads/zip/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download file
#
# GET /v4/downloads/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: downloadFileViaToken
export def "download-file-via-token" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --generic-mimetype: oneof<nothing, bool> # Always return `application/octet-stream` instead of specific mimetype
  --inline: oneof<nothing, bool> # Use Content-Disposition: `inline` instead of `attachment`
  --range: string # Range e.g. `bytes=0-999`
]: nothing -> any {
  http-request {
    method: get
    path: "/v4/downloads/{token}"
    path_params: [{name: token, var: token_arg}]
    query: [{name: generic_mimetype, var: generic_mimetype}, {name: inline, var: inline}]
    header: [{name: Range, var: range}]
    accept: ["application/json"]
    ok: [200, 206]
    auth: none
  } {
    token_arg: $token_arg, generic_mimetype: $generic_mimetype, inline: $inline, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download file
#
# HEAD /v4/downloads/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# Returns: record
# operationId: downloadFileViaToken_1
export def "download-file-via-token-1" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --generic-mimetype: oneof<nothing, bool> # Always return `application/octet-stream` instead of specific mimetype
  --inline: oneof<nothing, bool> # Use Content-Disposition: `inline` instead of `attachment`
  --range: string # Range e.g. `bytes=0-999`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/v4/downloads/{token}"
    path_params: [{name: token, var: token_arg}]
    query: [{name: generic_mimetype, var: generic_mimetype}, {name: inline, var: inline}]
    header: [{name: Range, var: range}]
    accept: ["application/json"]
    ok: [200, 206]
    auth: none
  } {
    token_arg: $token_arg, generic_mimetype: $generic_mimetype, inline: $inline, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request nodes
#
# GET /v4/eventlog/audits/node_info
# Returns: record<items: table<countChildren: int, nodeId: int, nodeIsEncrypted: bool, nodeName: string, nodeParentId: int, nodeParentPath: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestAuditNodeInfo
export def "request-audit-node-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-id: int # Parent node ID. Only rooms can be parents. Parent ID `0` or empty is the root node. (format: int64)
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/eventlog/audits/node_info"
    query: [{name: parent_id, var: parent_id}, {name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent_id: $parent_id, offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request node assigned users with permissions
#
# GET /v4/eventlog/audits/nodes
# DEPRECATED
# Returns: table<auditUserPermissionList: list<record>, nodeCntChildren: int, nodeCreatedAt: string, nodeCreatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, nodeHasActivitiesLog: bool, nodeHasRecycleBin: bool, nodeId: int, nodeIsEncrypted: bool, nodeName: string, nodeParentId: int, nodeParentPath: string, nodeQuota: int, nodeRecycleBinRetentionPeriod: int, nodeSize: int, nodeUpdatedAt: string, nodeUpdatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: requestAuditNodeUserData
@deprecated
export def "request-audit-node-user-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/eventlog/audits/nodes"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request system events
#
# GET /v4/eventlog/events
# Returns: record<items: table<attribute1: string, attribute2: string, attribute3: string, authParentSource: string, authParentTarget: string, customerId: int, id: int, message: string, objectId1: int, objectId2: int, objectName1: string, objectName2: string, objectType1: int, objectType2: int, operationId: int, operationName: string, status: int, time: string, userClient: string, userId: int, userIp: string, userName: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestLogEventsAsJson
export def "request-log-events-as-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --date-start: string # Filter events from given date e.g. `2015-12-31T23:59:00`
  --date-end: string # Filter events until given date e.g. `2015-12-31T23:59:00`
  --type: int # Operation ID cf. `GET /eventlog/operations` (format: int32)
  --user-id: int # User ID (format: int64)
  --status: string@status-completer # Operation status: * `0` - Success * `2` - Error
  --user-client: string # User client
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/eventlog/events"
    query: [{name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}, {name: date_start, var: date_start}, {name: date_end, var: date_end}, {name: type, var: type}, {name: user_id, var: user_id}, {name: status, var: status}, {name: user_client, var: user_client}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, offset: $offset, limit: $limit, date_start: $date_start, date_end: $date_end, type: $type, user_id: $user_id, status: $status, user_client: $user_client, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request allowed Log Operations
#
# GET /v4/eventlog/operations
# Returns: record<operationList: table<id: int, isDeprecated: bool, name: string>>
# operationId: requestLogOperations
export def "request-log-operations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-deprecated: oneof<nothing, bool> # Show only deprecated operations
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/eventlog/operations"
    query: [{name: is_deprecated, var: is_deprecated}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    is_deprecated: $is_deprecated, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of user groups
#
# GET /v4/groups
# Returns: record<items: table<cntUsers: int, createdAt: string, createdBy: record, expireAt: string, groupRoles: record, id: int, name: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestGroups
export def "request-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/groups"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new user group
#
# POST /v4/groups
# Returns: record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: createGroup
export def "create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  name: string # Group name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/groups"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: expiration, var: expiration}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, expiration: $expiration, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove user group
#
# DELETE /v4/groups/{group_id}
# operationId: removeGroup
export def "remove-group" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    group_id: $group_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user group
#
# GET /v4/groups/{group_id}
# Returns: record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: requestGroup
export def "request-group" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user group's metadata
#
# PUT /v4/groups/{group_id}
# Returns: record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: updateGroup
export def "update-group" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --name: string # Group name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: expiration, var: expiration}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, expiration: $expiration, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request rooms where the group is defined as last admin group
#
# GET /v4/groups/{group_id}/last_admin_rooms
# Returns: record<items: table<id: int, name: string, parentId: int, parentPath: string>>
# operationId: requestLastAdminRoomsGroups
export def "request-last-admin-rooms-groups" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/groups/{group_id}/last_admin_rooms"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of roles assigned to the group
#
# GET /v4/groups/{group_id}/roles
# Returns: record<items: table<description: string, id: int, items: list, name: string>>
# operationId: requestGroupRoles
export def "request-group-roles" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/groups/{group_id}/roles"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request rooms granted to the group or / and rooms that can be granted
#
# GET /v4/groups/{group_id}/rooms
# DEPRECATED
# Returns: record<items: table<children: list, cntDownloadShares: int, cntUploadShares: int, createdAt: string, createdBy: record, hasRecycleBin: bool, id: int, isEncrypted: bool, isFavorite: bool, isGranted: bool, name: string, parentId: int, permissions: record, quota: int, recycleBinRetentionPeriod: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestGroupRooms
@deprecated
export def "request-group-rooms" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/groups/{group_id}/rooms"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, offset: $offset, limit: $limit, filter: $filter, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove group members
#
# DELETE /v4/groups/{group_id}/users
# Returns: record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: removeGroupMembers
export def "remove-group-members" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of user IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/v4/groups/{group_id}/users"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request group member users or / and users who can become a member
#
# GET /v4/groups/{group_id}/users
# Returns: record<items: table<displayName: string, email: string, id: int, isMember: bool, login: string, userInfo: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestGroupMembers
export def "request-group-members" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/groups/{group_id}/users"
    path_params: [{name: group_id, var: group_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, offset: $offset, limit: $limit, filter: $filter, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add group members
#
# POST /v4/groups/{group_id}/users
# Returns: record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: addGroupMembers
export def "add-group-members" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of user IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/groups/{group_id}/users"
    path_params: [{name: group_id, var: group_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request subscription plan
#
# GET /v4/internal/tenant/subscription_plan
# Returns: record<subscriptionPlanId: int>
# operationId: internalRequestSubscriptionPlan
export def "internal-request-subscription-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/internal/tenant/subscription_plan"
    header: [{name: X-Sds-Service-Token, var: x_sds_service_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set subscription plan
#
# PUT /v4/internal/tenant/subscription_plan
# Returns: record<subscriptionPlanId: int>
# operationId: internalSetSubscriptionPlan
export def "internal-set-subscription-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token (required)
  subscription_plan_id: int # subscription plan id (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/internal/tenant/subscription_plan"
    header: [{name: X-Sds-Service-Token, var: x_sds_service_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: subscriptionPlanId, var: subscription_plan_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    x_sds_service_token: $x_sds_service_token, subscription_plan_id: $subscription_plan_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove nodes
#
# DELETE /v4/nodes
# operationId: removeNodes
export def "remove-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  node_ids: list<int> # List of node IDs
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/nodes"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: nodeIds, var: node_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, node_ids: $node_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of nodes
#
# GET /v4/nodes
# Returns: record<items: table<authParentId: int, branchVersion: int, children: list, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record, encryptionInfo: record, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestNodes
@deprecated --flag depth-level
export def "request-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --depth-level: int # * `0` - top level nodes only * `n` (any positive number) - include `n` levels starting from the current node (DEPRECATED, format: int32)
  --parent-id: int # Parent node ID. Only rooms and folders can be parents. Parent ID `0` or empty is the root node. (format: int64)
  --room-manager: oneof<nothing, bool> # Show all rooms for management perspective. Only possible for _Rooms Managers_ / _Room Admins_. For all other users, it will be ignored.
  --filter: string # Filter string
  --sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes"
    query: [{name: depth_level, var: depth_level}, {name: parent_id, var: parent_id}, {name: room_manager, var: room_manager}, {name: filter, var: filter}, {name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    depth_level: $depth_level, parent_id: $parent_id, room_manager: $room_manager, filter: $filter, sort: $sort, offset: $offset, limit: $limit, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove node comment
#
# DELETE /v4/nodes/comments/{comment_id}
# operationId: removeNodeComment
export def "remove-node-comment" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/nodes/comments/{comment_id}"
    path_params: [{name: comment_id, var: comment_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    comment_id: $comment_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit node comment
#
# PUT /v4/nodes/comments/{comment_id}
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: updateNodeComment
export def "update-node-comment" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  text: string # Comment text
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/nodes/comments/{comment_id}"
    path_params: [{name: comment_id, var: comment_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_id: $comment_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove nodes from recycle bin
#
# DELETE /v4/nodes/deleted_nodes
# operationId: removeDeletedNodes
export def "remove-deleted-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  deleted_node_ids: list<int> # List of deleted node IDs
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/nodes/deleted_nodes"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: deletedNodeIds, var: deleted_node_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, deleted_node_ids: $deleted_node_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restore deleted nodes
#
# POST /v4/nodes/deleted_nodes/actions/restore
# operationId: restoreNodes
export def "restore-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  deleted_node_ids: list<int> # List of deleted node IDs
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --parent-id: int # Node parent ID (default: previous parent ID) (format: int64)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy: * `autorename` * `overwrite` * `fail` (default: autorename)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/nodes/deleted_nodes/actions/restore"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: deletedNodeIds, var: deleted_node_ids}, {name: keepShareLinks, var: keep_share_links}, {name: parentId, var: parent_id}, {name: resolutionStrategy, var: resolution_strategy}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, deleted_node_ids: $deleted_node_ids, keep_share_links: $keep_share_links, parent_id: $parent_id, resolution_strategy: $resolution_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request deleted node
#
# GET /v4/nodes/deleted_nodes/{deleted_node_id}
# Returns: record<accessedAt: string, classification: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, deletedAt: string, deletedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, id: int, isEncrypted: bool, name: string, notes: string, parentId: int, parentPath: string, referenceId: int, size: int, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: requestDeletedNode
export def "request-deleted-node" [
  deleted_node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/deleted_nodes/{deleted_node_id}"
    path_params: [{name: deleted_node_id, var: deleted_node_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    deleted_node_id: $deleted_node_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark or unmark a list of nodes (room, folder or file) as favorite
#
# PUT /v4/nodes/favorites
# operationId: updateFavorites
export def "update-favorites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-favorite: oneof<nothing, bool> # Sets the favorite attribute to true or false on each file in an array of nodes.
  object_ids: list<int> # List of ids
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/nodes/favorites"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: isFavorite, var: is_favorite, required: true}, {name: objectIds, var: object_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, is_favorite: $is_favorite, object_ids: $object_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a list of file’s metadata
#
# PUT /v4/nodes/files
# operationId: updateFiles
export def "update-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --classification: int # Classification ID: * `1` - public * `2` - internal * `3` - confidential * `4` - strictly confidential (format: int32)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  object_ids: list<int> # List of ids
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/nodes/files"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: classification, var: classification}, {name: expiration, var: expiration}, {name: objectIds, var: object_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, classification: $classification, expiration: $expiration, object_ids: $object_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set file keys for a list of users and files
#
# POST /v4/nodes/files/keys
# operationId: setUserFileKeys
export def "set-user-file-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of user file keys — item shape: {fileId: int, fileKey: record, userId: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/nodes/files/keys"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new file upload channel
#
# POST /v4/nodes/files/uploads
# Returns: record<token: string, uploadId: string, uploadUrl: string>
# operationId: createFileUploadChannel
export def "create-file-upload-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --classification: int@classification-completer # Classification ID: * `1` - public * `2` - internal * `3` - confidential * `4` - strictly confidential (default: classification from parent room) (format: int32)
  --direct-s3-upload: oneof<nothing, bool> # &#128640; Since v4.15.0 Upload direct to S3 (default: false)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  name: string # File name
  --notes: string # User notes Use empty string to remove.
  parent_id: int # Parent node ID (room or folder) (format: int64)
  --size: int # File size in byte (format: int64)
  --timestamp-creation: string # &#128640; Since v4.22.0 Time the node was created on external file system (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0 Time the content of a node was last modified on external file system (default: current server datetime in UTC format) (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/files/uploads"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: classification, var: classification}, {name: directS3Upload, var: direct_s3_upload}, {name: expiration, var: expiration}, {name: name, var: name}, {name: notes, var: notes}, {name: parentId, var: parent_id}, {name: size, var: size}, {name: timestampCreation, var: timestamp_creation}, {name: timestampModification, var: timestamp_modification}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, classification: $classification, direct_s3_upload: $direct_s3_upload, expiration: $expiration, name: $name, notes: $notes, parent_id: $parent_id, size: $size, timestamp_creation: $timestamp_creation, timestamp_modification: $timestamp_modification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel file upload
#
# DELETE /v4/nodes/files/uploads/{upload_id}
# operationId: cancelFileUpload
export def "cancel-file-upload" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/nodes/files/uploads/{upload_id}"
    path_params: [{name: upload_id, var: upload_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    upload_id: $upload_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request status of S3 file upload
#
# GET /v4/nodes/files/uploads/{upload_id}
# Returns: record<errorDetails: record<code: int, debugInfo: string, errorCode: int, message: string>, node: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, status: string>
# operationId: requestUploadStatusFiles
export def "request-upload-status-files" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/files/uploads/{upload_id}"
    path_params: [{name: upload_id, var: upload_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    upload_id: $upload_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file
#
# POST /v4/nodes/files/uploads/{upload_id}
# DEPRECATED
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# Returns: record<hash: string, size: int>
# operationId: uploadFileAsMultipart
@deprecated
export def "upload-file-as-multipart" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Content-Range e.g. `bytes 0-999/3980`
  --x-sds-auth-token: string # Authentication token
  file: string # File (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/files/uploads/{upload_id}"
    path_params: [{name: upload_id, var: upload_id}]
    header: [{name: Content-Range, var: content_range}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    upload_id: $upload_id, content_range: $content_range, x_sds_auth_token: $x_sds_auth_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete file upload
#
# PUT /v4/nodes/files/uploads/{upload_id}
# DEPRECATED
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: completeFileUpload
@deprecated
@deprecated --flag user-file-key-list
export def "complete-file-upload" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --file-key: record # File key information — shape: {iv: string, key: string, tag: string, version: string}
  --file-name: string # New file name to store with
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy: * `autorename` * `overwrite` * `fail` (default: autorename)
  --user-file-key-list: record # Mandatory for encrypted shares (DEPRECATED) — shape: {items?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/nodes/files/uploads/{upload_id}"
    path_params: [{name: upload_id, var: upload_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileKey, var: file_key}, {name: fileName, var: file_name}, {name: keepShareLinks, var: keep_share_links}, {name: resolutionStrategy, var: resolution_strategy}, {name: userFileKeyList, var: user_file_key_list}]}
    accept: ["application/json"]
    ok: [201, 202]
    auth: bearer
  } {
    upload_id: $upload_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, file_key: $file_key, file_name: $file_name, keep_share_links: $keep_share_links, resolution_strategy: $resolution_strategy, user_file_key_list: $user_file_key_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete S3 file upload
#
# PUT /v4/nodes/files/uploads/{upload_id}/s3
# operationId: completeS3FileUpload
export def "complete-s3-file-upload" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --file-key: record # File key information — shape: {iv: string, key: string, tag: string, version: string}
  --file-name: string # New file name to store with
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  parts: list # List of S3 file upload parts — item shape: {partEtag: string, partNumber: int}
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy: * `autorename` * `overwrite` * `fail` (default: autorename)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/nodes/files/uploads/{upload_id}/s3"
    path_params: [{name: upload_id, var: upload_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileKey, var: file_key}, {name: fileName, var: file_name}, {name: keepShareLinks, var: keep_share_links}, {name: parts, var: parts}, {name: resolutionStrategy, var: resolution_strategy}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    upload_id: $upload_id, x_sds_auth_token: $x_sds_auth_token, file_key: $file_key, file_name: $file_name, keep_share_links: $keep_share_links, parts: $parts, resolution_strategy: $resolution_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate presigned URLs for S3 file upload
#
# POST /v4/nodes/files/uploads/{upload_id}/s3_urls
# Returns: record<urls: table<partNumber: int, url: string>>
# operationId: generatePresignedUrlsFiles
export def "generate-presigned-urls-files" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  first_part_number: int # First part number of a range of requested presigned URLs (for S3 it is: `1`) (format: int32)
  last_part_number: int # Last part number of a range of requested presigned URLs (format: int32)
  size: int # `Content-Length` header size for each presigned URL (in bytes) *MUST* be >= 5 MB except the last part. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/files/uploads/{upload_id}/s3_urls"
    path_params: [{name: upload_id, var: upload_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: firstPartNumber, var: first_part_number}, {name: lastPartNumber, var: last_part_number}, {name: size, var: size}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    upload_id: $upload_id, x_sds_auth_token: $x_sds_auth_token, first_part_number: $first_part_number, last_part_number: $last_part_number, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of file versions
#
# GET /v4/nodes/files/versions/{reference_id}
# Returns: record<items: table<deleted: bool, id: int, name: string, parentId: int, referenceId: int>, range: record<limit: int, offset: int, total: int>>
# operationId: requestFileVersionList
export def "request-file-version-list" [
  reference_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/files/versions/{reference_id}"
    path_params: [{name: reference_id, var: reference_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    reference_id: $reference_id, offset: $offset, limit: $limit, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a file’s metadata
#
# PUT /v4/nodes/files/{file_id}
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: updateFile
export def "update-file" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --classification: int # Classification ID: * `1` - public * `2` - internal * `3` - confidential * `4` - strictly confidential (format: int32)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --name: string # File name
  --notes: string # User notes Use empty string to remove.
  --timestamp-creation: string # &#128640; Since v4.22.0 Time the node was created on external file system (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0 Time the content of a node was last modified on external file system (default: current server datetime in UTC format) (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/nodes/files/{file_id}"
    path_params: [{name: file_id, var: file_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: classification, var: classification}, {name: expiration, var: expiration}, {name: name, var: name}, {name: notes, var: notes}, {name: timestampCreation, var: timestamp_creation}, {name: timestampModification, var: timestamp_modification}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, classification: $classification, expiration: $expiration, name: $name, notes: $notes, timestamp_creation: $timestamp_creation, timestamp_modification: $timestamp_modification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request room rescue key
#
# GET /v4/nodes/files/{file_id}/data_room_file_key
# DEPRECATED
# Returns: record<iv: string, key: string, tag: string, version: string>
# operationId: requestRoomRescueKey
@deprecated
export def "request-room-rescue-key" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/files/{file_id}/data_room_file_key"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, version: $version, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request system rescue key
#
# GET /v4/nodes/files/{file_id}/data_space_file_key
# DEPRECATED
# Returns: record<iv: string, key: string, tag: string, version: string>
# operationId: requestSystemRescueKey
@deprecated
export def "request-system-rescue-key" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/files/{file_id}/data_space_file_key"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, version: $version, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate download URL
#
# POST /v4/nodes/files/{file_id}/downloads
# Returns: record<downloadUrl: string>
# operationId: generateDownloadUrl
export def "generate-download-url" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/nodes/files/{file_id}/downloads"
    path_params: [{name: file_id, var: file_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user's file key
#
# GET /v4/nodes/files/{file_id}/user_file_key
# Returns: record<iv: string, key: string, tag: string, version: string>
# operationId: requestUserFileKey
export def "request-user-file-key" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/files/{file_id}/user_file_key"
    path_params: [{name: file_id, var: file_id}]
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id, version: $version, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new folder
#
# POST /v4/nodes/folders
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: createFolder
export def "create-folder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --classification: int@classification-completer # &#128640; Since v4.30.0 Classification ID: * `1` - public * `2` - internal * `3` - confidential * `4` - strictly confidential Provided (or default) classification is taken from room when file gets uploaded without any classification. (format: int32)
  name: string # Name
  --notes: string # User notes Use empty string to remove.
  parent_id: int # Parent node ID (room or folder) (format: int64)
  --timestamp-creation: string # &#128640; Since v4.22.0 Time the node was created on external file system (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0 Time the content of a node was last modified on external file system (default: current server datetime in UTC format) (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/folders"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: classification, var: classification}, {name: name, var: name}, {name: notes, var: notes}, {name: parentId, var: parent_id}, {name: timestampCreation, var: timestamp_creation}, {name: timestampModification, var: timestamp_modification}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, classification: $classification, name: $name, notes: $notes, parent_id: $parent_id, timestamp_creation: $timestamp_creation, timestamp_modification: $timestamp_modification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates folder’s metadata
#
# PUT /v4/nodes/folders/{folder_id}
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: updateFolder
export def "update-folder" [
  folder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --classification: int@classification-completer # &#128640; Since v4.30.0 Classification ID: * `1` - public * `2` - internal * `3` - confidential * `4` - strictly confidential Provided (or default) classification is taken from room when file gets uploaded without any classification. (format: int32)
  --name: string # Folder name
  --notes: string # User notes Use empty string to remove.
  --timestamp-creation: string # &#128640; Since v4.22.0 Time the node was created on external file system (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0 Time the content of a node was last modified on external file system (default: current server datetime in UTC format) (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/nodes/folders/{folder_id}"
    path_params: [{name: folder_id, var: folder_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: classification, var: classification}, {name: name, var: name}, {name: notes, var: notes}, {name: timestampCreation, var: timestamp_creation}, {name: timestampModification, var: timestamp_modification}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, classification: $classification, name: $name, notes: $notes, timestamp_creation: $timestamp_creation, timestamp_modification: $timestamp_modification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request files without user's file key
#
# GET /v4/nodes/missingFileKeys
# Returns: record<files: table<fileKeyContainer: record, id: int>, items: table<fileId: int, userId: int>, range: record<limit: int, offset: int, total: int>, users: table<id: int, publicKeyContainer: record>>
# operationId: requestMissingFileKeys
export def "request-missing-file-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --room-id: int # Room ID (format: int64)
  --file-id: int # File ID (format: int64)
  --user-id: int # User ID (format: int64)
  --use-key: string@use-key-completer # Determines which key should be used (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/missingFileKeys"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: room_id, var: room_id}, {name: file_id, var: file_id}, {name: user_id, var: user_id}, {name: use_key, var: use_key}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, room_id: $room_id, file_id: $file_id, user_id: $user_id, use_key: $use_key, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new room
#
# POST /v4/nodes/rooms
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: createRoom
@deprecated --flag has-recycle-bin
export def "create-room" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --admin-group-ids: list<int> # List of group ids A room requires at least one admin (user or group)
  --admin-ids: list<int> # List of user ids A room requires at least one admin (user or group)
  --classification: int@classification-completer # Classification ID: * `1` - public * `2` - internal * `3` - confidential * `4` - strictly confidential Provided (or default) classification is taken from room when file gets uploaded without any classification. (format: int32, default: 2)
  --has-activities-log: oneof<nothing, bool> # Is activities log active (for rooms only) (default: true)
  --has-recycle-bin: oneof<nothing, bool> # &#128679; Deprecated since v4.10.0 Is recycle bin active (for rooms only) Recycle bin is always on (disabling is not possible). (DEPRECATED)
  --inherit-permissions: oneof<nothing, bool> # Inherit permissions from parent room (default: `false` if `parentId` is `0`; otherwise: `true`)
  name: string # Name
  --new-group-member-acceptance: string@new-group-member-acceptance-completer # Behaviour when new users are added to the group: * `autoallow` * `pending` Only relevant if `adminGroupIds` has items. (default: autoallow)
  --notes: string # User notes Use empty string to remove.
  --parent-id: int # Parent room ID or `null` (not 0) to create a top level room (format: int64)
  --quota: int # Quota in byte (format: int64)
  --recycle-bin-retention-period: int # Retention period for deleted nodes in days (format: int32)
  --timestamp-creation: string # &#128640; Since v4.22.0 Time the node was created on external file system (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0 Time the content of a node was last modified on external file system (default: current server datetime in UTC format) (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/rooms"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminGroupIds, var: admin_group_ids}, {name: adminIds, var: admin_ids}, {name: classification, var: classification}, {name: hasActivitiesLog, var: has_activities_log}, {name: hasRecycleBin, var: has_recycle_bin}, {name: inheritPermissions, var: inherit_permissions}, {name: name, var: name}, {name: newGroupMemberAcceptance, var: new_group_member_acceptance}, {name: notes, var: notes}, {name: parentId, var: parent_id}, {name: quota, var: quota}, {name: recycleBinRetentionPeriod, var: recycle_bin_retention_period}, {name: timestampCreation, var: timestamp_creation}, {name: timestampModification, var: timestamp_modification}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, admin_group_ids: $admin_group_ids, admin_ids: $admin_ids, classification: $classification, has_activities_log: $has_activities_log, has_recycle_bin: $has_recycle_bin, inherit_permissions: $inherit_permissions, name: $name, new_group_member_acceptance: $new_group_member_acceptance, notes: $notes, parent_id: $parent_id, quota: $quota, recycle_bin_retention_period: $recycle_bin_retention_period, timestamp_creation: $timestamp_creation, timestamp_modification: $timestamp_modification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user-room assignments per group
#
# GET /v4/nodes/rooms/pending
# Returns: record<items: table<groupInfo: record, pendingGroupData: record, pendingUserData: record, roomId: int, roomName: string, state: string, userInfo: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestPendingAssignments
export def "request-pending-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/pending"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Handle user-room assignments per group
#
# PUT /v4/nodes/rooms/pending
# operationId: changePendingAssignments
export def "change-pending-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of pending assignments — item shape: {groupId: int, roomId: int, roomName: string, state: "ACCEPTED"|"DENIED"|"WAITING", userId: int}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/pending"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates room’s metadata
#
# PUT /v4/nodes/rooms/{room_id}
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: updateRoom
export def "update-room" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --name: string # Name
  --notes: string # User notes Use empty string to remove.
  --quota: int # Quota in byte (format: int64)
  --timestamp-creation: string # &#128640; Since v4.22.0 Time the node was created on external file system (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0 Time the content of a node was last modified on external file system (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/{room_id}"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: notes, var: notes}, {name: quota, var: quota}, {name: timestampCreation, var: timestamp_creation}, {name: timestampModification, var: timestamp_modification}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, name: $name, notes: $notes, quota: $quota, timestamp_creation: $timestamp_creation, timestamp_modification: $timestamp_modification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure room
#
# PUT /v4/nodes/rooms/{room_id}/config
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: configureRoom
export def "configure-room" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --admin-group-ids: list<int> # List of group ids A room requires at least one admin (user or group)
  --admin-ids: list<int> # List of user ids A room requires at least one admin (user or group)
  --classification: int@classification-completer # Classification ID: * `1` - public * `2` - internal * `3` - confidential * `4` - strictly confidential Provided (or default) classification is taken from room when file gets uploaded without any classification. (format: int32, default: 2)
  --has-activities-log: oneof<nothing, bool> # Is activities log active (for rooms only) (default: true)
  --inherit-permissions: oneof<nothing, bool> # Inherit permissions from parent room (default: `false` if `parentId` is `0`; otherwise: `true`)
  --new-group-member-acceptance: string@new-group-member-acceptance-completer # Behaviour when new users are added to the group: * `autoallow` * `pending` Only relevant if `adminGroupIds` has items. (default: autoallow)
  --recycle-bin-retention-period: int # Retention period for deleted nodes in days (format: int32)
  --take-over-permissions: oneof<nothing, bool> # Take over existing permissions
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/{room_id}/config"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: adminGroupIds, var: admin_group_ids}, {name: adminIds, var: admin_ids}, {name: classification, var: classification}, {name: hasActivitiesLog, var: has_activities_log}, {name: inheritPermissions, var: inherit_permissions}, {name: newGroupMemberAcceptance, var: new_group_member_acceptance}, {name: recycleBinRetentionPeriod, var: recycle_bin_retention_period}, {name: takeOverPermissions, var: take_over_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, admin_group_ids: $admin_group_ids, admin_ids: $admin_ids, classification: $classification, has_activities_log: $has_activities_log, inherit_permissions: $inherit_permissions, new_group_member_acceptance: $new_group_member_acceptance, recycle_bin_retention_period: $recycle_bin_retention_period, take_over_permissions: $take_over_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Encrypt room
#
# PUT /v4/nodes/rooms/{room_id}/encrypt
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: encryptRoom
export def "encrypt-room" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --data-room-rescue-key: record # Key pair container — shape: {privateKeyContainer: record, publicKeyContainer: record}
  --is-encrypted: oneof<nothing, bool> # Encryption state
  --use-data-space-rescue-key: oneof<nothing, bool> # Use system emergency password (rescue key) for files in this room
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/{room_id}/encrypt"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataRoomRescueKey, var: data_room_rescue_key}, {name: isEncrypted, var: is_encrypted, required: true}, {name: useDataSpaceRescueKey, var: use_data_space_rescue_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, data_room_rescue_key: $data_room_rescue_key, is_encrypted: $is_encrypted, use_data_space_rescue_key: $use_data_space_rescue_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request events of a room
#
# GET /v4/nodes/rooms/{room_id}/events
# Returns: record<items: table<attribute1: string, attribute2: string, attribute3: string, authParentSource: string, authParentTarget: string, customerId: int, id: int, message: string, objectId1: int, objectId2: int, objectName1: string, objectName2: string, objectType1: int, objectType2: int, operationId: int, operationName: string, status: int, time: string, userClient: string, userId: int, userIp: string, userName: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestRoomActivitiesLogAsJson
export def "request-room-activities-log-as-json" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --date-start: string # Filter events from given date e.g. `2015-12-31T23:59:00`
  --date-end: string # Filter events until given date e.g. `2015-12-31T23:59:00`
  --type: int # Operation ID cf. `GET /eventlog/operations` (format: int32)
  --user-id: int # User ID (format: int64)
  --status: int # Operation status: * `0` - Success * `2` - Error (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/{room_id}/events"
    path_params: [{name: room_id, var: room_id}]
    query: [{name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}, {name: date_start, var: date_start}, {name: date_end, var: date_end}, {name: type, var: type}, {name: user_id, var: user_id}, {name: status, var: status}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, sort: $sort, offset: $offset, limit: $limit, date_start: $date_start, date_end: $date_end, type: $type, user_id: $user_id, status: $status, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke granted group(s) from room
#
# DELETE /v4/nodes/rooms/{room_id}/groups
# operationId: revokeRoomGroups
export def "revoke-room-groups" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of group IDs
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/nodes/rooms/{room_id}/groups"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request room granted group(s) or / and group(s) that can be granted
#
# GET /v4/nodes/rooms/{room_id}/groups
# Returns: record<items: table<id: int, isGranted: bool, name: string, newGroupMemberAcceptance: string, permissions: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestRoomGroups
export def "request-room-groups" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/{room_id}/groups"
    path_params: [{name: room_id, var: room_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or change room granted group(s)
#
# PUT /v4/nodes/rooms/{room_id}/groups
# operationId: updateRoomGroups
export def "update-room-groups" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of room-group mappings — item shape: {id: int, newGroupMemberAcceptance?: "autoallow"|"pending", permissions: record}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/{room_id}/groups"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add guest users to a room
#
# PUT /v4/nodes/rooms/{room_id}/guest_users
# operationId: addRoomGuestUsers
export def "add-room-guest-users" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  room_guest_invitations: list # List of room-user mappings — item shape: {email: string, firstName: string, lastName: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/{room_id}/guest_users"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: roomGuestInvitations, var: room_guest_invitations}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token, room_guest_invitations: $room_guest_invitations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove rooms's rescue key pair
#
# DELETE /v4/nodes/rooms/{room_id}/keypair
# operationId: removeRoomRescueKeyPair
export def "remove-room-rescue-key-pair" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/nodes/rooms/{room_id}/keypair"
    path_params: [{name: room_id, var: room_id}]
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, version: $version, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request room rescue key
#
# GET /v4/nodes/rooms/{room_id}/keypair
# Returns: record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>
# operationId: requestRoomRescueKeyPair
export def "request-room-rescue-key-pair" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/{room_id}/keypair"
    path_params: [{name: room_id, var: room_id}]
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, version: $version, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set room's rescue key pair
#
# POST /v4/nodes/rooms/{room_id}/keypair
# operationId: setRoomRescueKeyPair
export def "set-room-rescue-key-pair" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/nodes/rooms/{room_id}/keypair"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: privateKeyContainer, var: private_key_container}, {name: publicKeyContainer, var: public_key_container}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token, private_key_container: $private_key_container, public_key_container: $public_key_container
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request all room rescue key pairs
#
# GET /v4/nodes/rooms/{room_id}/keypairs
# Returns: table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>
# operationId: requestRoomRescueKeyPairs
export def "request-room-rescue-key-pairs" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/{room_id}/keypairs"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create key pair and preserve copy of old private key
#
# POST /v4/nodes/rooms/{room_id}/keypairs
# operationId: createAndPreserveRoomRescueKeyPair
export def "create-and-preserve-room-rescue-key-pair" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  previous_private_key: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/nodes/rooms/{room_id}/keypairs"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: previousPrivateKey, var: previous_private_key}, {name: privateKeyContainer, var: private_key_container}, {name: publicKeyContainer, var: public_key_container}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token, previous_private_key: $previous_private_key, private_key_container: $private_key_container, public_key_container: $public_key_container
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Room Policies
#
# GET /v4/nodes/rooms/{room_id}/policies
# Returns: record<defaultExpirationPeriod: int>
# operationId: requestRoomPolicies
export def "request-room-policies" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/{room_id}/policies"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set room policies
#
# PUT /v4/nodes/rooms/{room_id}/policies
# operationId: setRoomPolicies
export def "set-room-policies" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --default-expiration-period: int # Default policy room expiration period in seconds. All files in a room will have their expiration date set to this period after their respective upload. 0 means no default expiration policy is set. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/{room_id}/policies"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultExpirationPeriod, var: default_expiration_period}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token, default_expiration_period: $default_expiration_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of all assigned S3 tags to the room
#
# GET /v4/nodes/rooms/{room_id}/s3_tags
# Returns: record<items: table<id: int, isMandatory: bool, key: string, value: string>>
# operationId: requestRoomS3Tags
export def "request-room-s3-tags" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/{room_id}/s3_tags"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set S3 tags for a room
#
# POST /v4/nodes/rooms/{room_id}/s3_tags
# Returns: record<items: table<id: int, isMandatory: bool, key: string, value: string>>
# operationId: setRoomS3Tags
export def "set-room-s3-tags" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of S3 tag IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/rooms/{room_id}/s3_tags"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke granted user(s) from room
#
# DELETE /v4/nodes/rooms/{room_id}/users
# operationId: revokeRoomUsers
export def "revoke-room-users" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of user IDs
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/nodes/rooms/{room_id}/users"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request room granted user(s) or / and user(s) that can be granted
#
# GET /v4/nodes/rooms/{room_id}/users
# Returns: record<items: table<displayName: string, email: string, id: int, isGranted: bool, login: string, permissions: record, publicKeyContainer: record, userInfo: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestRoomUsers
export def "request-room-users" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/{room_id}/users"
    path_params: [{name: room_id, var: room_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or change room granted user(s)
#
# PUT /v4/nodes/rooms/{room_id}/users
# operationId: updateRoomUsers
export def "update-room-users" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of room-user mappings — item shape: {id: int, permissions: record}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/{room_id}/users"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    room_id: $room_id, x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of webhooks that are assigned or can be assigned to this room
#
# GET /v4/nodes/rooms/{room_id}/webhooks
# Returns: record<items: table<isAssigned: bool, webhook: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestListOfWebhooksForRoom
export def "request-list-of-webhooks-for-room" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/rooms/{room_id}/webhooks"
    path_params: [{name: room_id, var: room_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, offset: $offset, limit: $limit, filter: $filter, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign or unassign webhooks to room
#
# PUT /v4/nodes/rooms/{room_id}/webhooks
# Returns: record<items: table<isAssigned: bool, webhook: record>, range: record<limit: int, offset: int, total: int>>
# operationId: handleRoomWebhookAssignments
export def "handle-room-webhook-assignments" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  items: list # Assign a webhook to a room to use it for node actions within the room — item shape: {isAssigned: bool, webhookId: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/nodes/rooms/{room_id}/webhooks"
    path_params: [{name: room_id, var: room_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    room_id: $room_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search nodes
#
# GET /v4/nodes/search
# Returns: record<items: table<authParentId: int, branchVersion: int, children: list, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record, encryptionInfo: record, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: searchNodes
export def "search-nodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-string: string # Search string (required)
  --depth-level: int # * `0` - top level nodes only (default) * `-1` - full tree * `n` (any positive number) - include `n` levels starting from the current node (format: int32)
  --parent-id: int # Parent node ID. Only rooms and folders can be parents. Parent ID `0` or empty is the root node. (format: int64)
  --filter: string # Filter string
  --sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/search"
    query: [{name: search_string, var: search_string, required: true}, {name: depth_level, var: depth_level}, {name: parent_id, var: parent_id}, {name: filter, var: filter}, {name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search_string: $search_string, depth_level: $depth_level, parent_id: $parent_id, filter: $filter, sort: $sort, offset: $offset, limit: $limit, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate download URL for ZIP download
#
# POST /v4/nodes/zip
# Returns: record<downloadUrl: string>
# operationId: generateDownloadUrlForZipArchive
export def "generate-download-url-for-zip-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  node_ids: list<int> # List of node IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/zip"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: nodeIds, var: node_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, node_ids: $node_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download files / folders as ZIP archive
#
# POST /v4/nodes/zip/download
# operationId: downloadZipArchive
export def "download-zip-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  node_ids: list<int> # List of node IDs
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/nodes/zip/download"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: nodeIds, var: node_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, node_ids: $node_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove node
#
# DELETE /v4/nodes/{node_id}
# operationId: removeNode
export def "remove-node" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/nodes/{node_id}"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    node_id: $node_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request node
#
# GET /v4/nodes/{node_id}
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: requestNode
export def "request-node" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/{node_id}"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of node comments
#
# GET /v4/nodes/{node_id}/comments
# Returns: record<items: table<createdAt: string, createdBy: record, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestNodeComments
export def "request-node-comments" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --hide-deleted: oneof<nothing, bool> # Hide deleted comments (default: false)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/{node_id}/comments"
    path_params: [{name: node_id, var: node_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: hide_deleted, var: hide_deleted}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, offset: $offset, limit: $limit, hide_deleted: $hide_deleted, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create node comment
#
# POST /v4/nodes/{node_id}/comments
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: createNodeComment
export def "create-node-comment" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  text: string # Comment text
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/{node_id}/comments"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    node_id: $node_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copy node(s)
#
# POST /v4/nodes/{node_id}/copy_to
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: copyNodes
@deprecated --flag node-ids
export def "copy-nodes" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --items: list # List of nodes to be copied — item shape: {id: int, name?: string, timestampCreation?: string, timestampModification?: string}
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --node-ids: list<int> # &#128679; Deprecated since v4.5.0 Node IDs Please use `items` instead. (DEPRECATED)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy: * `autorename` * `overwrite` * `fail` (default: autorename)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/{node_id}/copy_to"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}, {name: keepShareLinks, var: keep_share_links}, {name: nodeIds, var: node_ids}, {name: resolutionStrategy, var: resolution_strategy}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    node_id: $node_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, items: $items, keep_share_links: $keep_share_links, node_ids: $node_ids, resolution_strategy: $resolution_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Empty recycle bin
#
# DELETE /v4/nodes/{node_id}/deleted_nodes
# operationId: emptyDeletedNodes
export def "empty-deleted-nodes" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/nodes/{node_id}/deleted_nodes"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    node_id: $node_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of deleted nodes
#
# GET /v4/nodes/{node_id}/deleted_nodes
# Returns: record<items: table<cntVersions: int, firstDeletedAt: string, lastDeletedAt: string, lastDeletedNodeId: int, name: string, parentId: int, parentPath: string, referenceId: int, timestampCreation: string, timestampModification: string, type: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestDeletedNodesSummary
export def "request-deleted-nodes-summary" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/{node_id}/deleted_nodes"
    path_params: [{name: node_id, var: node_id}]
    query: [{name: filter, var: filter}, {name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, filter: $filter, sort: $sort, offset: $offset, limit: $limit, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request deleted versions of nodes
#
# GET /v4/nodes/{node_id}/deleted_nodes/versions
# Returns: record<items: table<accessedAt: string, classification: int, createdAt: string, createdBy: record, deletedAt: string, deletedBy: record, expireAt: string, id: int, isEncrypted: bool, name: string, notes: string, parentId: int, parentPath: string, referenceId: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestDeletedNodeVersions
export def "request-deleted-node-versions" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Node type (required)
  --name: string # Node name (required)
  --sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/{node_id}/deleted_nodes/versions"
    path_params: [{name: node_id, var: node_id}]
    query: [{name: type, var: type, required: true}, {name: name, var: name, required: true}, {name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, type: $type, name: $name, sort: $sort, offset: $offset, limit: $limit, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unmark a node (room, folder or file) as favorite
#
# DELETE /v4/nodes/{node_id}/favorite
# operationId: removeFavorite
export def "remove-favorite" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/nodes/{node_id}/favorite"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    node_id: $node_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark a node (room, folder or file) as favorite
#
# POST /v4/nodes/{node_id}/favorite
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: addFavorite
export def "add-favorite" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/nodes/{node_id}/favorite"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    node_id: $node_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move node(s)
#
# POST /v4/nodes/{node_id}/move_to
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: moveNodes
@deprecated --flag node-ids
export def "move-nodes" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --items: list # List of nodes to be moved — item shape: {id: int, name?: string, timestampCreation?: string, timestampModification?: string}
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --node-ids: list<int> # &#128679; Deprecated since v4.5.0 Node IDs Please use `items` instead. (DEPRECATED)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy: * `autorename` * `overwrite` * `fail` (default: autorename)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/nodes/{node_id}/move_to"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}, {name: keepShareLinks, var: keep_share_links}, {name: nodeIds, var: node_ids}, {name: resolutionStrategy, var: resolution_strategy}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    node_id: $node_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, items: $items, keep_share_links: $keep_share_links, node_ids: $node_ids, resolution_strategy: $resolution_strategy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of parent nodes
#
# GET /v4/nodes/{node_id}/parents
# Returns: record<items: table<id: int, name: string, parentId: int, type: string>>
# operationId: requestNodeParents
export def "request-node-parents" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/nodes/{node_id}/parents"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    node_id: $node_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of customers
#
# GET /v4/provisioning/customers
# Returns: record<items: table<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>, range: record<limit: int, offset: int, total: int>>
# operationId: requestCustomers
export def "request-customers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --include-attributes: oneof<nothing, bool> # Include custom customer attributes.
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/provisioning/customers"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}, {name: include_attributes, var: include_attributes}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    offset: $offset, limit: $limit, filter: $filter, sort: $sort, include_attributes: $include_attributes, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create customer
#
# POST /v4/provisioning/customers
# Returns: record<activationCode: string, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, firstAdminUser: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: list<record>, email: string, firstName: string, gender: string, language: string, lastName: string, login: string, needsToChangePassword: bool, needsToChangeUserName: bool, notifyUser: bool, password: string, phone: string, receiverLanguage: string, title: string, userName: string>, id: int, isLocked: bool, lockStatus: bool, providerCustomerId: string, quotaMax: int, trialDays: int, userMax: int, webhooksMax: int>
# operationId: createCustomer
@deprecated --flag activation-code
@deprecated --flag lock-status
export def "create-customer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  --activation-code: string # &#128679; Deprecated since v4.8.0 Customer activation code string: * valid only for types `free` and `demo` * for `pay` customers it is empty (DEPRECATED)
  --company-name: string # Company name
  --customer-attributes: record # List of customer attributes — shape: {items: list}
  customer_contract_type: string@customer-contract-type-completer # Customer type
  first_admin_user: record # First administrator user — shape: {authData?: record, authMethods?: list, email?: string, firstName: string, gender?: string, language?: string, lastName: string, login?: string, needsToChangePassword?: bool, needsToChangeUserName?: bool, notifyUser?: bool, password?: string, phone?: string, receiverLanguage?: string, title?: string, userName?: string}
  --is-locked: oneof<nothing, bool> # Customer is locked: * `false` - unlocked * `true` - locked All users of this customer will be blocked and can not login anymore. (default: false)
  --lock-status: oneof<nothing, bool> # &#128679; Deprecated since v4.7.0 Customer lock status: * `false` - unlocked * `true` - locked Please use `isLocked` instead. All users of this customer will be blocked and can not login anymore. (DEPRECATED, default: false)
  --provider-customer-id: string # Provider customer ID
  quota_max: int # Maximal disc space which can be allocated by customer in bytes. -1 for unlimited (format: int64)
  --trial-days: int # Number of days left for trial period (relevant only for type `demo`) (not used) (format: int32)
  user_max: int # Maximal number of users (format: int32)
  --webhooks-max: int # &#128640; Since v4.19.0 Maximal number of webhooks (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/provisioning/customers"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: activationCode, var: activation_code}, {name: companyName, var: company_name}, {name: customerAttributes, var: customer_attributes}, {name: customerContractType, var: customer_contract_type}, {name: firstAdminUser, var: first_admin_user}, {name: isLocked, var: is_locked}, {name: lockStatus, var: lock_status}, {name: providerCustomerId, var: provider_customer_id}, {name: quotaMax, var: quota_max}, {name: trialDays, var: trial_days}, {name: userMax, var: user_max}, {name: webhooksMax, var: webhooks_max}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token, activation_code: $activation_code, company_name: $company_name, customer_attributes: $customer_attributes, customer_contract_type: $customer_contract_type, first_admin_user: $first_admin_user, is_locked: $is_locked, lock_status: $lock_status, provider_customer_id: $provider_customer_id, quota_max: $quota_max, trial_days: $trial_days, user_max: $user_max, webhooks_max: $webhooks_max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove customer
#
# DELETE /v4/provisioning/customers/{customer_id}
# operationId: removeCustomer
export def "remove-customer" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/provisioning/customers/{customer_id}"
    path_params: [{name: customer_id, var: customer_id}]
    header: [{name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    customer_id: $customer_id, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get customer
#
# GET /v4/provisioning/customers/{customer_id}
# Returns: record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>
# operationId: requestCustomer
export def "request-customer" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-attributes: oneof<nothing, bool> # Include custom customer attributes.
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/provisioning/customers/{customer_id}"
    path_params: [{name: customer_id, var: customer_id}]
    query: [{name: include_attributes, var: include_attributes}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    customer_id: $customer_id, include_attributes: $include_attributes, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update customer
#
# PUT /v4/provisioning/customers/{customer_id}
# Returns: record<activationCode: string, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lockStatus: bool, providerCustomerId: string, quotaMax: int, trialDays: int, updatedAt: string, userMax: int, webhooksMax: int>
# operationId: updateCustomer
@deprecated --flag lock-status
export def "update-customer" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  --company-name: string # Company name
  customer_contract_type: string@customer-contract-type-completer # Customer type
  --is-locked: oneof<nothing, bool> # Customer is locked: * `false` - unlocked * `true` - locked All users of this customer will be blocked and can not login anymore. (default: false)
  --lock-status: oneof<nothing, bool> # &#128679; Deprecated since v4.7.0 Customer lock status: * `false` - unlocked * `true` - locked Please use `isLocked` instead. All users of this customer will be blocked and can not login anymore. (DEPRECATED, default: false)
  --provider-customer-id: string # Provider customer ID
  --quota-max: int # Maximal disc space which can be allocated by customer in bytes. -1 for unlimited (format: int64)
  --user-max: int # Maximal number of users (format: int32)
  --webhooks-max: int # &#128640; Since v4.19.0 Maximal number of webhooks (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/provisioning/customers/{customer_id}"
    path_params: [{name: customer_id, var: customer_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: companyName, var: company_name}, {name: customerContractType, var: customer_contract_type}, {name: isLocked, var: is_locked}, {name: lockStatus, var: lock_status}, {name: providerCustomerId, var: provider_customer_id}, {name: quotaMax, var: quota_max}, {name: userMax, var: user_max}, {name: webhooksMax, var: webhooks_max}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    customer_id: $customer_id, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token, company_name: $company_name, customer_contract_type: $customer_contract_type, is_locked: $is_locked, lock_status: $lock_status, provider_customer_id: $provider_customer_id, quota_max: $quota_max, user_max: $user_max, webhooks_max: $webhooks_max
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request customer attributes
#
# GET /v4/provisioning/customers/{customer_id}/customerAttributes
# Returns: record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestCustomerAttributes
export def "request-customer-attributes" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-service-token: string # Service Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/provisioning/customers/{customer_id}/customerAttributes"
    path_params: [{name: customer_id, var: customer_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    customer_id: $customer_id, offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set customer attributes
#
# POST /v4/provisioning/customers/{customer_id}/customerAttributes
# DEPRECATED
# Returns: record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>
# operationId: setCustomerAttributes
@deprecated
export def "set-customer-attributes" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  items: list # List of customer attributes — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/provisioning/customers/{customer_id}/customerAttributes"
    path_params: [{name: customer_id, var: customer_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    customer_id: $customer_id, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or edit customer attributes
#
# PUT /v4/provisioning/customers/{customer_id}/customerAttributes
# Returns: record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>
# operationId: updateCustomerAttributes
export def "update-customer-attributes" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  items: list # List of customer attributes — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/provisioning/customers/{customer_id}/customerAttributes"
    path_params: [{name: customer_id, var: customer_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    customer_id: $customer_id, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove customer attribute
#
# DELETE /v4/provisioning/customers/{customer_id}/customerAttributes/{key}
# operationId: removeCustomerAttribute
export def "remove-customer-attribute" [
  customer_id: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/provisioning/customers/{customer_id}/customerAttributes/{key}"
    path_params: [{name: customer_id, var: customer_id}, {name: key, var: key}]
    header: [{name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    customer_id: $customer_id, key: $key, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of customer users
#
# GET /v4/provisioning/customers/{customer_id}/users
# Returns: record<items: table<avatarUuid: string, createdAt: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, title: string, userAttributes: record, userName: string, userRoles: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestCustomerUsers
export def "request-customer-users" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --include-attributes: oneof<nothing, bool> # Include custom user attributes.
  --include-roles: oneof<nothing, bool> # Include roles
  --include-manageable-rooms: oneof<nothing, bool> # Include hasManageableRooms (deprecated)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/provisioning/customers/{customer_id}/users"
    path_params: [{name: customer_id, var: customer_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}, {name: include_attributes, var: include_attributes}, {name: include_roles, var: include_roles}, {name: include_manageable_rooms, var: include_manageable_rooms}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    customer_id: $customer_id, offset: $offset, limit: $limit, filter: $filter, sort: $sort, include_attributes: $include_attributes, include_roles: $include_roles, include_manageable_rooms: $include_manageable_rooms, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of tenant webhooks
#
# GET /v4/provisioning/webhooks
# Returns: record<items: table<createdAt: string, createdBy: record, eventTypeNames: list, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record, url: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestListOfTenantWebhooks
export def "request-list-of-tenant-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/provisioning/webhooks"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create tenant webhook
#
# POST /v4/provisioning/webhooks
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>
# operationId: createTenantWebhook
export def "create-tenant-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  event_type_names: list<string> # List of names of event types
  --is-enabled: oneof<nothing, bool> # Is enabled
  name: string # Name
  --secret: string # Secret; used for event message signatures
  --trigger-example-event: oneof<nothing, bool> # If set to true, an example event is being created
  url: string # URL (must begin with the `HTTPS` scheme)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/provisioning/webhooks"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: eventTypeNames, var: event_type_names}, {name: isEnabled, var: is_enabled}, {name: name, var: name}, {name: secret, var: secret}, {name: triggerExampleEvent, var: trigger_example_event}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token, event_type_names: $event_type_names, is_enabled: $is_enabled, name: $name, secret: $secret, trigger_example_event: $trigger_example_event, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of event types
#
# GET /v4/provisioning/webhooks/event_types
# Returns: record<items: table<id: int, name: string, usableCustomerAdminWebhook: bool, usableNodeWebhook: bool, usablePushNotification: bool, usableTenantWebhook: bool>>
# operationId: requestListOfEventTypesForTenant
export def "request-list-of-event-types-for-tenant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/provisioning/webhooks/event_types"
    header: [{name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove tenant webhook
#
# DELETE /v4/provisioning/webhooks/{webhook_id}
# operationId: removeTenantWebhook
export def "remove-tenant-webhook" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/provisioning/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    header: [{name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    webhook_id: $webhook_id, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request tenant webhook
#
# GET /v4/provisioning/webhooks/{webhook_id}
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>
# operationId: requestTenantWebhook
export def "request-tenant-webhook" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/provisioning/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    webhook_id: $webhook_id, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update tenant webhook
#
# PUT /v4/provisioning/webhooks/{webhook_id}
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>
# operationId: updateTenantWebhook
export def "update-tenant-webhook" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  --event-type-names: list<string> # List of names of event types
  --is-enabled: oneof<nothing, bool> # Is enabled
  --name: string # Name
  --secret: string # Secret; used for event message signatures
  --trigger-example-event: oneof<nothing, bool> # If set to true, an example event is being created
  --url: string # URL (must begin with the `HTTPS` scheme)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/provisioning/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: eventTypeNames, var: event_type_names}, {name: isEnabled, var: is_enabled}, {name: name, var: name}, {name: secret, var: secret}, {name: triggerExampleEvent, var: trigger_example_event}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    webhook_id: $webhook_id, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token, event_type_names: $event_type_names, is_enabled: $is_enabled, name: $name, secret: $secret, trigger_example_event: $trigger_example_event, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset tenant webhook lifetime
#
# POST /v4/provisioning/webhooks/{webhook_id}/reset_lifetime
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>
# operationId: resetTenantWebhookLifetime
export def "reset-tenant-webhook-lifetime" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/provisioning/webhooks/{webhook_id}/reset_lifetime"
    path_params: [{name: webhook_id, var: webhook_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Service-Token, var: x_sds_service_token}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    webhook_id: $webhook_id, x_sds_date_format: $x_sds_date_format, x_sds_service_token: $x_sds_service_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request public Download Share information
#
# GET /v4/public/shares/downloads/{access_key}
# Returns: record<createdAt: string, creatorName: string, creatorUsername: string, expireAt: string, fileKey: record<iv: string, key: string, tag: string, version: string>, fileName: string, hasDownloadLimit: bool, isEncrypted: bool, isProtected: bool, limitReached: bool, mediaType: string, name: string, notes: string, privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, size: int>
# operationId: requestPublicDownloadShareInfo
export def "request-public-download-share-info" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/public/shares/downloads/{access_key}"
    path_params: [{name: access_key, var: access_key}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    access_key: $access_key, x_sds_date_format: $x_sds_date_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check public Download Share password
#
# HEAD /v4/public/shares/downloads/{access_key}
# Returns: record
# operationId: checkPublicDownloadSharePassword
export def "check-public-download-share-password" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # Download share password
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/v4/public/shares/downloads/{access_key}"
    path_params: [{name: access_key, var: access_key}]
    query: [{name: password, var: password}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    access_key: $access_key, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate download URL
#
# POST /v4/public/shares/downloads/{access_key}
# Returns: record<downloadUrl: string>
# operationId: generateDownloadUrlPublic
export def "generate-download-url-public" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # Password (only for password-protected shares)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/public/shares/downloads/{access_key}"
    path_params: [{name: access_key, var: access_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    access_key: $access_key, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download file with token
#
# GET /v4/public/shares/downloads/{access_key}/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: downloadFileViaTokenPublic
export def "download-file-via-token-public" [
  access_key: string
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --generic-mimetype: oneof<nothing, bool> # Always return `application/octet-stream` instead of specific mimetype
  --inline: oneof<nothing, bool> # Use Content-Disposition: `inline` instead of `attachment`
  --range: string # Range e.g. `bytes=0-999`
]: nothing -> any {
  http-request {
    method: get
    path: "/v4/public/shares/downloads/{access_key}/{token}"
    path_params: [{name: access_key, var: access_key}, {name: token, var: token_arg}]
    query: [{name: generic_mimetype, var: generic_mimetype}, {name: inline, var: inline}]
    header: [{name: Range, var: range}]
    accept: ["application/json"]
    ok: [200, 206]
    auth: none
  } {
    access_key: $access_key, token_arg: $token_arg, generic_mimetype: $generic_mimetype, inline: $inline, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download file with token
#
# HEAD /v4/public/shares/downloads/{access_key}/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# Returns: record
# operationId: downloadFileViaTokenPublic_1
export def "download-file-via-token-public-1" [
  access_key: string
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --generic-mimetype: oneof<nothing, bool> # Always return `application/octet-stream` instead of specific mimetype
  --inline: oneof<nothing, bool> # Use Content-Disposition: `inline` instead of `attachment`
  --range: string # Range e.g. `bytes=0-999`
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/v4/public/shares/downloads/{access_key}/{token}"
    path_params: [{name: access_key, var: access_key}, {name: token, var: token_arg}]
    query: [{name: generic_mimetype, var: generic_mimetype}, {name: inline, var: inline}]
    header: [{name: Range, var: range}]
    accept: ["application/json"]
    ok: [200, 206]
    auth: none
  } {
    access_key: $access_key, token_arg: $token_arg, generic_mimetype: $generic_mimetype, inline: $inline, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request public Upload Share information
#
# GET /v4/public/shares/uploads/{access_key}
# Returns: record<createdAt: string, creatorName: string, creatorUsername: string, expireAt: string, isEncrypted: bool, isProtected: bool, name: string, notes: string, remainingSize: int, remainingSlots: int, showUploadedFiles: bool, uploadedFiles: table<createdAt: string, hash: string, name: string, size: int>, userUserPublicKeyList: record<items: list<record>>>
# operationId: requestPublicUploadShareInfo
export def "request-public-upload-share-info" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-share-password: string # Upload share password. Should be base64-encoded. Plain X-Sds-Share-Passwords are *deprecated* and will be removed in the future
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/public/shares/uploads/{access_key}"
    path_params: [{name: access_key, var: access_key}]
    header: [{name: X-Sds-Share-Password, var: x_sds_share_password}, {name: X-Sds-Date-Format, var: x_sds_date_format}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    access_key: $access_key, x_sds_share_password: $x_sds_share_password, x_sds_date_format: $x_sds_date_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new file upload channel
#
# POST /v4/public/shares/uploads/{access_key}
# Returns: record<uploadId: string, uploadUrl: string>
# operationId: createShareUploadChannel
export def "create-share-upload-channel" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direct-s3-upload: oneof<nothing, bool> # &#128640; Since v4.15.0 Upload direct to S3 (default: false)
  name: string # File name
  --password: string # Password
  --size: int # File size in byte (format: int64)
  --timestamp-creation: string # &#128640; Since v4.22.0 Time the node was created on external file system (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0 Time the content of a node was last modified on external file system (default: current server datetime in UTC format) (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/public/shares/uploads/{access_key}"
    path_params: [{name: access_key, var: access_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: directS3Upload, var: direct_s3_upload}, {name: name, var: name}, {name: password, var: password}, {name: size, var: size}, {name: timestampCreation, var: timestamp_creation}, {name: timestampModification, var: timestamp_modification}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    access_key: $access_key, direct_s3_upload: $direct_s3_upload, name: $name, password: $password, size: $size, timestamp_creation: $timestamp_creation, timestamp_modification: $timestamp_modification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel file upload
#
# DELETE /v4/public/shares/uploads/{access_key}/{upload_id}
# operationId: cancelFileUploadViaShare
export def "cancel-file-upload-via-share" [
  access_key: string
  upload_id: string
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
    path: "/v4/public/shares/uploads/{access_key}/{upload_id}"
    path_params: [{name: access_key, var: access_key}, {name: upload_id, var: upload_id}]
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    access_key: $access_key, upload_id: $upload_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request status of S3 file upload
#
# GET /v4/public/shares/uploads/{access_key}/{upload_id}
# Returns: record<errorDetails: record<code: int, debugInfo: string, errorCode: int, message: string>, fileName: string, size: int, status: string>
# operationId: requestUploadStatusPublic
export def "request-upload-status-public" [
  access_key: string
  upload_id: string
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
    path: "/v4/public/shares/uploads/{access_key}/{upload_id}"
    path_params: [{name: access_key, var: access_key}, {name: upload_id, var: upload_id}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    access_key: $access_key, upload_id: $upload_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file
#
# POST /v4/public/shares/uploads/{access_key}/{upload_id}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# Returns: record<hash: string, size: int>
# operationId: uploadFileAsMultipartPublic_1
export def "upload-file-as-multipart-public-1" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Content-Range e.g. `bytes 0-999/3980`
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  file: string # File (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/public/shares/uploads/{access_key}/{upload_id}"
    path_params: [{name: access_key, var: access_key}, {name: upload_id, var: upload_id}]
    header: [{name: Content-Range, var: content_range}, {name: X-Sds-Date-Format, var: x_sds_date_format}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: none
  } {
    access_key: $access_key, upload_id: $upload_id, content_range: $content_range, x_sds_date_format: $x_sds_date_format, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete file upload
#
# PUT /v4/public/shares/uploads/{access_key}/{upload_id}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# Returns: record<createdAt: string, hash: string, name: string, size: int>
# operationId: completeFileUploadViaShare
export def "complete-file-upload-via-share" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --items: list # List of user file keys — item shape: {fileKey: record, userId: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/public/shares/uploads/{access_key}/{upload_id}"
    path_params: [{name: access_key, var: access_key}, {name: upload_id, var: upload_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [201, 202]
    auth: none
  } {
    access_key: $access_key, upload_id: $upload_id, x_sds_date_format: $x_sds_date_format, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete S3 file upload
#
# PUT /v4/public/shares/uploads/{access_key}/{upload_id}/s3
# operationId: completeS3FileUploadViaShare
export def "complete-s3-file-upload-via-share" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  parts: list # List of S3 file upload parts — item shape: {partEtag: string, partNumber: int}
  --user-file-key-list: list # List of user file keys — item shape: {fileKey: record, userId: int}
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/public/shares/uploads/{access_key}/{upload_id}/s3"
    path_params: [{name: access_key, var: access_key}, {name: upload_id, var: upload_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: parts, var: parts}, {name: userFileKeyList, var: user_file_key_list}]}
    accept: ["application/json"]
    ok: [202]
    auth: none
  } {
    access_key: $access_key, upload_id: $upload_id, parts: $parts, user_file_key_list: $user_file_key_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate presigned URLs for S3 file upload
#
# POST /v4/public/shares/uploads/{access_key}/{upload_id}/s3_urls
# Returns: record<urls: table<partNumber: int, url: string>>
# operationId: generatePresignedUrlsPublic
export def "generate-presigned-urls-public" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  first_part_number: int # First part number of a range of requested presigned URLs (for S3 it is: `1`) (format: int32)
  last_part_number: int # Last part number of a range of requested presigned URLs (format: int32)
  size: int # `Content-Length` header size for each presigned URL (in bytes) *MUST* be >= 5 MB except the last part. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/public/shares/uploads/{access_key}/{upload_id}/s3_urls"
    path_params: [{name: access_key, var: access_key}, {name: upload_id, var: upload_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}]
    body: {content_type: "application/json", kind: json, fields: [{name: firstPartNumber, var: first_part_number}, {name: lastPartNumber, var: last_part_number}, {name: size, var: size}]}
    accept: ["application/json"]
    ok: [201]
    auth: none
  } {
    access_key: $access_key, upload_id: $upload_id, x_sds_date_format: $x_sds_date_format, first_part_number: $first_part_number, last_part_number: $last_part_number, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request third-party software dependencies
#
# GET /v4/public/software/third_party_dependencies
# Returns: table<artifactId: string, description: string, groupId: string, id: string, licenses: list<string>, name: string, type: string, url: string, version: string>
# operationId: requestThirdPartyDependencies
export def "request-third-party-dependencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/public/software/third_party_dependencies"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request software version information
#
# GET /v4/public/software/version
# Returns: record<buildDate: string, isDracoonCloud: bool, restApiVersion: string, scmRevisionNumber: string, sdsServerVersion: string>
# operationId: requestSoftwareVersion
export def "request-software-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/public/software/version"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    x_sds_date_format: $x_sds_date_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request system information
#
# GET /v4/public/system/info
# Docs: https://tools.ietf.org/html/rfc5646 — Tags for Identifying Languages
# Returns: record<authMethods: table<isEnabled: bool, name: string, priority: int>, hideLoginInputFields: bool, languageDefault: string, s3EnforceDirectUpload: bool, s3Hosts: list<string>, useS3Storage: bool>
# operationId: requestSystemInfo
export def "request-system-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-enabled: oneof<nothing, bool> # Show only enabled authentication methods
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/public/system/info"
    query: [{name: is_enabled, var: is_enabled}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    is_enabled: $is_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Active Directory authentication information
#
# GET /v4/public/system/info/auth/ad
# Returns: record<items: table<alias: string, id: int, isGlobalAvailable: bool>>
# operationId: requestActiveDirectoryAuthInfo
export def "request-active-directory-auth-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-global-available: oneof<nothing, bool> # Show only global available items
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/public/system/info/auth/ad"
    query: [{name: is_global_available, var: is_global_available}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    is_global_available: $is_global_available
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request OpenID Connect provider authentication information
#
# GET /v4/public/system/info/auth/openid
# Returns: record<items: table<id: int, isGlobalAvailable: bool, issuer: string, mappingClaim: string, name: string, userManagementUrl: string>>
# operationId: requestOpenIdAuthInfo
export def "request-open-id-auth-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-global-available: oneof<nothing, bool> # Show only global available items
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/public/system/info/auth/openid"
    query: [{name: is_global_available, var: is_global_available}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    is_global_available: $is_global_available
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request system time
#
# GET /v4/public/time
# Returns: record<time: string>
# operationId: requestSystemTime
export def "request-system-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/public/time"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    x_sds_date_format: $x_sds_date_format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of subscription scopes
#
# GET /v4/resources/user/notifications/scopes
# Returns: record<items: table<id: int, name: string>>
# operationId: requestSubscriptionScopes
export def "request-subscription-scopes" [
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
    path: "/v4/resources/user/notifications/scopes"
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user avatar
#
# GET /v4/resources/users/{user_id}/avatar/{uuid}
# Returns: record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool>
# operationId: requestUserAvatar
export def "request-user-avatar" [
  user_id: int
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
    path: "/v4/resources/users/{user_id}/avatar/{uuid}"
    path_params: [{name: user_id, var: user_id}, {name: uuid, var: uuid}]
    accept: ["application/json"]
    ok: [200]
    auth: none
  } {
    user_id: $user_id, uuid: $uuid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request all roles with assigned rights
#
# GET /v4/roles
# Returns: record<items: table<description: string, id: int, items: list, name: string>>
# operationId: requestRoles
export def "request-roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/roles"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke granted role from group(s)
#
# DELETE /v4/roles/{role_id}/groups
# Returns: record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>>
# operationId: revokeRoleGroups
export def "revoke-role-groups" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of group IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/v4/roles/{role_id}/groups"
    path_params: [{name: role_id, var: role_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request groups with specific role
#
# GET /v4/roles/{role_id}/groups
# Returns: record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestRoleGroups
export def "request-role-groups" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/roles/{role_id}/groups"
    path_params: [{name: role_id, var: role_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id, offset: $offset, limit: $limit, filter: $filter, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign group(s) to the role
#
# POST /v4/roles/{role_id}/groups
# Returns: record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>>
# operationId: addRoleGroups
export def "add-role-groups" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of group IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/roles/{role_id}/groups"
    path_params: [{name: role_id, var: role_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke granted role from user(s)
#
# DELETE /v4/roles/{role_id}/users
# Returns: record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>>
# operationId: revokeRoleUsers
export def "revoke-role-users" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of user IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/v4/roles/{role_id}/users"
    path_params: [{name: role_id, var: role_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request users with specific role
#
# GET /v4/roles/{role_id}/users
# Returns: record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestRoleUsers
export def "request-role-users" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/roles/{role_id}/users"
    path_params: [{name: role_id, var: role_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id, offset: $offset, limit: $limit, filter: $filter, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign user(s) to the role
#
# POST /v4/roles/{role_id}/users
# Returns: record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>>
# operationId: addRoleUsers
export def "add-role-users" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list<int> # List of user IDs
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/roles/{role_id}/users"
    path_params: [{name: role_id, var: role_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    role_id: $role_id, x_sds_auth_token: $x_sds_auth_token, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request customer settings
#
# GET /v4/settings
# Returns: record<homeRoomParentId: int, homeRoomParentName: string, homeRoomQuota: int, homeRoomsActive: bool>
# operationId: requestSettings
export def "request-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/settings"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set customer settings
#
# PUT /v4/settings
# Returns: record<homeRoomParentId: int, homeRoomParentName: string, homeRoomQuota: int, homeRoomsActive: bool>
# operationId: setSettings
export def "set-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --home-room-parent-name: string # Homeroom Parent Name
  --home-room-quota: int # Homeroom Quota in bytes (format: int64)
  --home-rooms-active: oneof<nothing, bool> # Homerooms active
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/settings"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: homeRoomParentName, var: home_room_parent_name}, {name: homeRoomQuota, var: home_room_quota}, {name: homeRoomsActive, var: home_rooms_active}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, home_room_parent_name: $home_room_parent_name, home_room_quota: $home_room_quota, home_rooms_active: $home_rooms_active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove system rescue key pair
#
# DELETE /v4/settings/keypair
# operationId: removeSystemRescueKeyPair
export def "remove-system-rescue-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/settings/keypair"
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    version: $version, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request system rescue key pair
#
# GET /v4/settings/keypair
# Returns: record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>
# operationId: requestSystemRescueKeyPair
export def "request-system-rescue-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/settings/keypair"
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version: $version, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate client-side encryption for customer
#
# POST /v4/settings/keypair
# operationId: setSystemRescueKeyPair
export def "set-system-rescue-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/settings/keypair"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: privateKeyContainer, var: private_key_container}, {name: publicKeyContainer, var: public_key_container}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, private_key_container: $private_key_container, public_key_container: $public_key_container
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request all system rescue key pairs
#
# GET /v4/settings/keypairs
# Returns: table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>
# operationId: requestAllSystemRescueKeyPairs
export def "request-all-system-rescue-key-pairs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/settings/keypairs"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create system rescue key pair and preserve copy of old private key
#
# POST /v4/settings/keypairs
# operationId: createAndPreserveKeyPair
export def "create-and-preserve-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  previous_private_key: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/settings/keypairs"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: previousPrivateKey, var: previous_private_key}, {name: privateKeyContainer, var: private_key_container}, {name: publicKeyContainer, var: public_key_container}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, previous_private_key: $previous_private_key, private_key_container: $private_key_container, public_key_container: $public_key_container
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of notification channels
#
# GET /v4/settings/notifications/channels
# Returns: record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>>
# operationId: requestNotificationChannels
export def "request-notification-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/settings/notifications/channels"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Toggle notification channels
#
# PUT /v4/settings/notifications/channels
# Returns: record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>>
# operationId: toggleNotificationChannels
export def "toggle-notification-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  channel_id: int # Channel ID (format: int32)
  --is-enabled: oneof<nothing, bool> # Determines whether channel is enabled
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/settings/notifications/channels"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelId, var: channel_id}, {name: isEnabled, var: is_enabled, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, channel_id: $channel_id, is_enabled: $is_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of webhooks
#
# GET /v4/settings/webhooks
# Returns: record<items: table<createdAt: string, createdBy: record, eventTypeNames: list, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record, url: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestListOfWebhooks
export def "request-list-of-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/settings/webhooks"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create webhook
#
# POST /v4/settings/webhooks
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>
# operationId: createWebhook
export def "create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  event_type_names: list<string> # List of names of event types
  --is-enabled: oneof<nothing, bool> # Is enabled
  name: string # Name
  --secret: string # Secret; used for event message signatures
  --trigger-example-event: oneof<nothing, bool> # If set to true, an example event is being created
  url: string # URL (must begin with the `HTTPS` scheme)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/settings/webhooks"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: eventTypeNames, var: event_type_names}, {name: isEnabled, var: is_enabled}, {name: name, var: name}, {name: secret, var: secret}, {name: triggerExampleEvent, var: trigger_example_event}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, event_type_names: $event_type_names, is_enabled: $is_enabled, name: $name, secret: $secret, trigger_example_event: $trigger_example_event, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of event types
#
# GET /v4/settings/webhooks/event_types
# Returns: record<items: table<id: int, name: string, usableCustomerAdminWebhook: bool, usableNodeWebhook: bool, usablePushNotification: bool, usableTenantWebhook: bool>>
# operationId: requestListOfEventTypesForConfigManager
export def "request-list-of-event-types-for-config-manager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/settings/webhooks/event_types"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove webhook
#
# DELETE /v4/settings/webhooks/{webhook_id}
# operationId: removeWebhook
export def "remove-webhook" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/settings/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    webhook_id: $webhook_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request webhook
#
# GET /v4/settings/webhooks/{webhook_id}
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>
# operationId: requestWebhook
export def "request-webhook" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/settings/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update webhook
#
# PUT /v4/settings/webhooks/{webhook_id}
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>
# operationId: updateWebhook
export def "update-webhook" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --event-type-names: list<string> # List of names of event types
  --is-enabled: oneof<nothing, bool> # Is enabled
  --name: string # Name
  --secret: string # Secret; used for event message signatures
  --trigger-example-event: oneof<nothing, bool> # If set to true, an example event is being created
  --url: string # URL (must begin with the `HTTPS` scheme)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/settings/webhooks/{webhook_id}"
    path_params: [{name: webhook_id, var: webhook_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: eventTypeNames, var: event_type_names}, {name: isEnabled, var: is_enabled}, {name: name, var: name}, {name: secret, var: secret}, {name: triggerExampleEvent, var: trigger_example_event}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, event_type_names: $event_type_names, is_enabled: $is_enabled, name: $name, secret: $secret, trigger_example_event: $trigger_example_event, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset webhook lifetime
#
# POST /v4/settings/webhooks/{webhook_id}/reset_lifetime
# Returns: record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string>
# operationId: resetWebhookLifetime
export def "reset-webhook-lifetime" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/settings/webhooks/{webhook_id}/reset_lifetime"
    path_params: [{name: webhook_id, var: webhook_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_id: $webhook_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Download Shares
#
# DELETE /v4/shares/downloads
# operationId: deleteDownloadShares
export def "delete-download-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  share_ids: list<int> # List of share IDs
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/shares/downloads"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: shareIds, var: share_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, share_ids: $share_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of Download Shares
#
# GET /v4/shares/downloads
# Returns: record<items: table<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestDownloadShares
export def "request-download-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/shares/downloads"
    query: [{name: filter, var: filter}, {name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, sort: $sort, offset: $offset, limit: $limit, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new Download Share
#
# POST /v4/shares/downloads
# Returns: record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: createDownloadShare
@deprecated --flag creator-language
@deprecated --flag mail-body
@deprecated --flag mail-recipients
@deprecated --flag mail-subject
@deprecated --flag notify-creator
@deprecated --flag send-mail
@deprecated --flag send-sms
@deprecated --flag sms-recipients
export def "create-download-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --creator-language: string # &#128679; Deprecated since v4.20.0 Language tag for messages to creator (DEPRECATED)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --file-key: record # File key information — shape: {iv: string, key: string, tag: string, version: string}
  --internal-notes: string # &#128640; Since v4.11.0 Internal notes
  --key-pair: record # Key pair container — shape: {privateKeyContainer: record, publicKeyContainer: record}
  --mail-body: string # &#128679; Deprecated since v4.11.0 Notification email content (DEPRECATED)
  --mail-recipients: string # &#128679; Deprecated since v4.11.0 CSV string of recipient email addresses (DEPRECATED)
  --mail-subject: string # &#128679; Deprecated since v4.11.0 Notification email subject (DEPRECATED)
  --max-downloads: int # Max allowed downloads (format: int32)
  --name: string # Alias name (default: name of the shared node)
  node_id: int # Source node ID (format: int64)
  --notes: string # User notes
  --notify-creator: oneof<nothing, bool> # &#128679; Deprecated since v4.20.0 Notify creator on every download. (DEPRECATED, default: false)
  --password: string # Access password, not allowed for encrypted shares
  --receiver-language: string # Language tag for messages to receiver
  --send-mail: oneof<nothing, bool> # &#128679; Deprecated since v4.11.0 Notify recipients via email Please use `POST /shares/downloads/{share_id}/email` API instead. (DEPRECATED, default: false)
  --send-sms: oneof<nothing, bool> # &#128679; Deprecated since v4.11.0 Send share password via SMS Please use `textMessageRecipients` attribute instead. (DEPRECATED, default: false)
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name. (default: false)
  --show-creator-username: oneof<nothing, bool> # Show creator email address. (default: false)
  --sms-recipients: string # &#128679; Deprecated since v4.11.0 CSV string of recipient MSISDNs (DEPRECATED)
  --text-message-recipients: list<string> # &#128640; Since v4.11.0 List of recipient FQTNs E.123 / E.164 Format
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/shares/downloads"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: creatorLanguage, var: creator_language}, {name: expiration, var: expiration}, {name: fileKey, var: file_key}, {name: internalNotes, var: internal_notes}, {name: keyPair, var: key_pair}, {name: mailBody, var: mail_body}, {name: mailRecipients, var: mail_recipients}, {name: mailSubject, var: mail_subject}, {name: maxDownloads, var: max_downloads}, {name: name, var: name}, {name: nodeId, var: node_id}, {name: notes, var: notes}, {name: notifyCreator, var: notify_creator}, {name: password, var: password}, {name: receiverLanguage, var: receiver_language}, {name: sendMail, var: send_mail}, {name: sendSms, var: send_sms}, {name: showCreatorName, var: show_creator_name}, {name: showCreatorUsername, var: show_creator_username}, {name: smsRecipients, var: sms_recipients}, {name: textMessageRecipients, var: text_message_recipients}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, creator_language: $creator_language, expiration: $expiration, file_key: $file_key, internal_notes: $internal_notes, key_pair: $key_pair, mail_body: $mail_body, mail_recipients: $mail_recipients, mail_subject: $mail_subject, max_downloads: $max_downloads, name: $name, node_id: $node_id, notes: $notes, notify_creator: $notify_creator, password: $password, receiver_language: $receiver_language, send_mail: $send_mail, send_sms: $send_sms, show_creator_name: $show_creator_name, show_creator_username: $show_creator_username, sms_recipients: $sms_recipients, text_message_recipients: $text_message_recipients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a list of Download Shares
#
# PUT /v4/shares/downloads
# operationId: updateDownloadShares
export def "update-download-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --max-downloads: int # Max allowed downloads (format: int32)
  object_ids: list<int> # List of ids
  --reset-max-downloads: oneof<nothing, bool> # Set 'true' to reset 'maxDownloads' for Download Share.
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name.
  --show-creator-username: oneof<nothing, bool> # Show creator email address.
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/shares/downloads"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: expiration, var: expiration}, {name: maxDownloads, var: max_downloads}, {name: objectIds, var: object_ids}, {name: resetMaxDownloads, var: reset_max_downloads}, {name: showCreatorName, var: show_creator_name}, {name: showCreatorUsername, var: show_creator_username}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, expiration: $expiration, max_downloads: $max_downloads, object_ids: $object_ids, reset_max_downloads: $reset_max_downloads, show_creator_name: $show_creator_name, show_creator_username: $show_creator_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Download Share
#
# DELETE /v4/shares/downloads/{share_id}
# operationId: removeDownloadShare
export def "remove-download-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/shares/downloads/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    share_id: $share_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Download Share
#
# GET /v4/shares/downloads/{share_id}
# Returns: record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: requestDownloadShare
export def "request-download-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/shares/downloads/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    share_id: $share_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Download Share
#
# PUT /v4/shares/downloads/{share_id}
# Returns: record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: updateDownloadShare
@deprecated --flag notify-creator
export def "update-download-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --default-country: string # Country shorthand symbol (cf. ISO 3166-2)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --internal-notes: string # &#128640; Since v4.11.0 Internal notes
  --max-downloads: int # Max allowed downloads (format: int32)
  --name: string # Alias name
  --notes: string # User notes
  --notify-creator: oneof<nothing, bool> # &#128679; Deprecated since v4.20.0 Notify creator on every download. (DEPRECATED)
  --password: string # Access password, not allowed for encrypted shares
  --receiver-language: string # Language tag for messages to receiver
  --reset-max-downloads: oneof<nothing, bool> # Set 'true' to reset 'maxDownloads' for Download Share.
  --reset-password: oneof<nothing, bool> # Set 'true' to reset 'password' for Download Share.
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name.
  --show-creator-username: oneof<nothing, bool> # Show creator email address.
  --text-message-recipients: list<string> # List of recipient FQTNs E.123 / E.164 Format
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/shares/downloads/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultCountry, var: default_country}, {name: expiration, var: expiration}, {name: internalNotes, var: internal_notes}, {name: maxDownloads, var: max_downloads}, {name: name, var: name}, {name: notes, var: notes}, {name: notifyCreator, var: notify_creator}, {name: password, var: password}, {name: receiverLanguage, var: receiver_language}, {name: resetMaxDownloads, var: reset_max_downloads}, {name: resetPassword, var: reset_password}, {name: showCreatorName, var: show_creator_name}, {name: showCreatorUsername, var: show_creator_username}, {name: textMessageRecipients, var: text_message_recipients}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    share_id: $share_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, default_country: $default_country, expiration: $expiration, internal_notes: $internal_notes, max_downloads: $max_downloads, name: $name, notes: $notes, notify_creator: $notify_creator, password: $password, receiver_language: $receiver_language, reset_max_downloads: $reset_max_downloads, reset_password: $reset_password, show_creator_name: $show_creator_name, show_creator_username: $show_creator_username, text_message_recipients: $text_message_recipients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send an existing Download Share link via email
#
# POST /v4/shares/downloads/{share_id}/email
# operationId: sendDownloadShareLinkViaEmail
export def "send-download-share-link-via-email" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  body: string # Notification email content
  --receiver-language: string # Language tag for messages to receiver
  recipients: list<string> # List of recipient email addresses
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/shares/downloads/{share_id}/email"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: receiverLanguage, var: receiver_language}, {name: recipients, var: recipients}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    share_id: $share_id, x_sds_auth_token: $x_sds_auth_token, body: $body, receiver_language: $receiver_language, recipients: $recipients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Download Share via QR Code
#
# GET /v4/shares/downloads/{share_id}/qr
# Returns: record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: requestDownloadShareQr
export def "request-download-share-qr" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/shares/downloads/{share_id}/qr"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    share_id: $share_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Upload Shares
#
# DELETE /v4/shares/uploads
# operationId: deleteUploadShares
export def "delete-upload-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  share_ids: list<int> # List of share IDs
]: any -> any {
  $in | http-request {
    method: delete
    path: "/v4/shares/uploads"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: shareIds, var: share_ids}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, share_ids: $share_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of Upload Shares
#
# GET /v4/shares/uploads
# Returns: record<items: table<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestUploadShares
export def "request-upload-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/shares/uploads"
    query: [{name: filter, var: filter}, {name: sort, var: sort}, {name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, sort: $sort, offset: $offset, limit: $limit, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new Upload Share
#
# POST /v4/shares/uploads
# Returns: record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: createUploadShare
@deprecated --flag creator-language
@deprecated --flag mail-body
@deprecated --flag mail-recipients
@deprecated --flag mail-subject
@deprecated --flag notify-creator
@deprecated --flag send-mail
@deprecated --flag send-sms
@deprecated --flag sms-recipients
export def "create-upload-share" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --creator-language: string # &#128679; Deprecated since v4.20.0 Language tag for messages to creator (DEPRECATED)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --files-expiry-period: int # Number of days after which uploaded files expire (format: int32)
  --internal-notes: string # &#128640; Since v4.11.0 Internal notes
  --mail-body: string # &#128679; Deprecated since v4.11.0 Notification email content (DEPRECATED)
  --mail-recipients: string # &#128679; Deprecated since v4.11.0 CSV string of recipient email addresses (DEPRECATED)
  --mail-subject: string # &#128679; Deprecated since v4.11.0 Notification email subject (DEPRECATED)
  --max-size: int # Maximal total size of uploaded files (in bytes) (format: int64)
  --max-slots: int # Maximal amount of files to upload (format: int32)
  --name: string # Alias name (default: name of the shared node)
  --notes: string # User notes
  --notify-creator: oneof<nothing, bool> # &#128679; Deprecated since v4.20.0 Notify creator on every upload. (DEPRECATED, default: false)
  --password: string # Password
  --receiver-language: string # Language tag for messages to receiver
  --send-mail: oneof<nothing, bool> # &#128679; Deprecated since v4.11.0 Notify recipients via email Please use `POST /shares/uploads/{share_id}/email` API instead. (DEPRECATED, default: false)
  --send-sms: oneof<nothing, bool> # &#128679; Deprecated since v4.11.0 Send share password via SMS Please use `textMessageRecipients` attribute instead. (DEPRECATED, default: false)
  --show-creator-name: oneof<nothing, bool> # &#128640; Since v4.11.0 Show creator first and last name. (default: false)
  --show-creator-username: oneof<nothing, bool> # &#128640; Since v4.11.0 Show creator email address. (default: false)
  --show-uploaded-files: oneof<nothing, bool> # Allow display of already uploaded files (default: false)
  --sms-recipients: string # &#128679; Deprecated since v4.11.0 CSV string of recipient MSISDNs (DEPRECATED)
  target_id: int # Target room or folder ID (format: int64)
  --text-message-recipients: list<string> # &#128640; Since v4.11.0 List of recipient FQTNs E.123 / E.164 Format
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/shares/uploads"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: creatorLanguage, var: creator_language}, {name: expiration, var: expiration}, {name: filesExpiryPeriod, var: files_expiry_period}, {name: internalNotes, var: internal_notes}, {name: mailBody, var: mail_body}, {name: mailRecipients, var: mail_recipients}, {name: mailSubject, var: mail_subject}, {name: maxSize, var: max_size}, {name: maxSlots, var: max_slots}, {name: name, var: name}, {name: notes, var: notes}, {name: notifyCreator, var: notify_creator}, {name: password, var: password}, {name: receiverLanguage, var: receiver_language}, {name: sendMail, var: send_mail}, {name: sendSms, var: send_sms}, {name: showCreatorName, var: show_creator_name}, {name: showCreatorUsername, var: show_creator_username}, {name: showUploadedFiles, var: show_uploaded_files}, {name: smsRecipients, var: sms_recipients}, {name: targetId, var: target_id}, {name: textMessageRecipients, var: text_message_recipients}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, creator_language: $creator_language, expiration: $expiration, files_expiry_period: $files_expiry_period, internal_notes: $internal_notes, mail_body: $mail_body, mail_recipients: $mail_recipients, mail_subject: $mail_subject, max_size: $max_size, max_slots: $max_slots, name: $name, notes: $notes, notify_creator: $notify_creator, password: $password, receiver_language: $receiver_language, send_mail: $send_mail, send_sms: $send_sms, show_creator_name: $show_creator_name, show_creator_username: $show_creator_username, show_uploaded_files: $show_uploaded_files, sms_recipients: $sms_recipients, target_id: $target_id, text_message_recipients: $text_message_recipients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update List of Upload Shares
#
# PUT /v4/shares/uploads
# operationId: updateUploadShares
export def "update-upload-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --files-expiry-period: int # Number of days after which uploaded files expire (format: int32)
  --max-size: int # Maximal total size of uploaded files (in bytes) (format: int64)
  --max-slots: int # Maximal amount of files to upload (format: int32)
  object_ids: list<int> # List of ids
  --reset-files-expiry-period: oneof<nothing, bool> # Set 'true' to reset 'filesExpiryPeriod' for Upload Share
  --reset-max-size: oneof<nothing, bool> # Set 'true' to reset 'maxSize' for Upload Share
  --reset-max-slots: oneof<nothing, bool> # Set 'true' to reset 'maxSlots' for Upload Share
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name.
  --show-creator-username: oneof<nothing, bool> # Show creator email address.
  --show-uploaded-files: oneof<nothing, bool> # Allow display of already uploaded files
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/shares/uploads"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: expiration, var: expiration}, {name: filesExpiryPeriod, var: files_expiry_period}, {name: maxSize, var: max_size}, {name: maxSlots, var: max_slots}, {name: objectIds, var: object_ids}, {name: resetFilesExpiryPeriod, var: reset_files_expiry_period}, {name: resetMaxSize, var: reset_max_size}, {name: resetMaxSlots, var: reset_max_slots}, {name: showCreatorName, var: show_creator_name}, {name: showCreatorUsername, var: show_creator_username}, {name: showUploadedFiles, var: show_uploaded_files}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, expiration: $expiration, files_expiry_period: $files_expiry_period, max_size: $max_size, max_slots: $max_slots, object_ids: $object_ids, reset_files_expiry_period: $reset_files_expiry_period, reset_max_size: $reset_max_size, reset_max_slots: $reset_max_slots, show_creator_name: $show_creator_name, show_creator_username: $show_creator_username, show_uploaded_files: $show_uploaded_files
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Upload Share
#
# DELETE /v4/shares/uploads/{share_id}
# operationId: removeUploadShare
export def "remove-upload-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/shares/uploads/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    share_id: $share_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Upload Share
#
# GET /v4/shares/uploads/{share_id}
# Returns: record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: requestUploadShare
export def "request-upload-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/shares/uploads/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    share_id: $share_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Upload Share
#
# PUT /v4/shares/uploads/{share_id}
# Returns: record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: updateUploadShare
@deprecated --flag notify-creator
export def "update-upload-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --default-country: string # Country shorthand symbol (cf. ISO 3166-2)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --files-expiry-period: int # Number of days after which uploaded files expire (format: int32)
  --internal-notes: string # &#128640; Since v4.11.0 Internal notes
  --max-size: int # Maximal total size of uploaded files (in bytes) (format: int64)
  --max-slots: int # Maximal amount of files to upload (format: int32)
  --name: string # Alias name
  --notes: string # User notes
  --notify-creator: oneof<nothing, bool> # &#128679; Deprecated since v4.20.0 Notify creator on every upload. (DEPRECATED)
  --password: string # Password
  --receiver-language: string # Language tag for messages to receiver
  --reset-files-expiry-period: oneof<nothing, bool> # Set 'true' to reset 'filesExpiryPeriod' for Upload Share
  --reset-max-size: oneof<nothing, bool> # Set 'true' to reset 'maxSize' for Upload Share
  --reset-max-slots: oneof<nothing, bool> # Set 'true' to reset 'maxSlots' for Upload Share
  --reset-password: oneof<nothing, bool> # Set 'true' to reset 'password' for Upload Share.
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name.
  --show-creator-username: oneof<nothing, bool> # Show creator email address.
  --show-uploaded-files: oneof<nothing, bool> # Allow display of already uploaded files
  --text-message-recipients: list<string> # List of recipient FQTNs E.123 / E.164 Format
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/shares/uploads/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: defaultCountry, var: default_country}, {name: expiration, var: expiration}, {name: filesExpiryPeriod, var: files_expiry_period}, {name: internalNotes, var: internal_notes}, {name: maxSize, var: max_size}, {name: maxSlots, var: max_slots}, {name: name, var: name}, {name: notes, var: notes}, {name: notifyCreator, var: notify_creator}, {name: password, var: password}, {name: receiverLanguage, var: receiver_language}, {name: resetFilesExpiryPeriod, var: reset_files_expiry_period}, {name: resetMaxSize, var: reset_max_size}, {name: resetMaxSlots, var: reset_max_slots}, {name: resetPassword, var: reset_password}, {name: showCreatorName, var: show_creator_name}, {name: showCreatorUsername, var: show_creator_username}, {name: showUploadedFiles, var: show_uploaded_files}, {name: textMessageRecipients, var: text_message_recipients}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    share_id: $share_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, default_country: $default_country, expiration: $expiration, files_expiry_period: $files_expiry_period, internal_notes: $internal_notes, max_size: $max_size, max_slots: $max_slots, name: $name, notes: $notes, notify_creator: $notify_creator, password: $password, receiver_language: $receiver_language, reset_files_expiry_period: $reset_files_expiry_period, reset_max_size: $reset_max_size, reset_max_slots: $reset_max_slots, reset_password: $reset_password, show_creator_name: $show_creator_name, show_creator_username: $show_creator_username, show_uploaded_files: $show_uploaded_files, text_message_recipients: $text_message_recipients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send an existing Upload Share link via email
#
# POST /v4/shares/uploads/{share_id}/email
# operationId: sendUploadShareLinkViaEmail
export def "send-upload-share-link-via-email" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  body: string # Notification email content
  --receiver-language: string # Language tag for messages to receiver
  recipients: list<string> # List of recipient email addresses
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/shares/uploads/{share_id}/email"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: receiverLanguage, var: receiver_language}, {name: recipients, var: recipients}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    share_id: $share_id, x_sds_auth_token: $x_sds_auth_token, body: $body, receiver_language: $receiver_language, recipients: $recipients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Upload Share via QR Code
#
# GET /v4/shares/uploads/{share_id}/qr
# Returns: record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: requestUploadShareQr
export def "request-upload-share-qr" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/shares/uploads/{share_id}/qr"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    share_id: $share_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test Active Directory configuration
#
# POST /v4/system/config/actions/test/ad
# Returns: record<ldapUsersDomain: string, serverAdminName: string, serverAdminPassword: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool>
# operationId: testAdConfig
export def "test-ad-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ldap_users_domain: string # Search scope of Active Directory; only users below this node can log on.
  server_admin_name: string # Distinguished Name (DN) of Active Directory administrative account
  server_admin_password: string # Password of Active Directory administrative account
  server_ip: string # IPv4 or IPv6 address or host name
  server_port: int # Port (format: int32)
  --ssl-finger-print: string # SSL finger print of Active Directory server. Mandatory for LDAPS connections. Format: `Algorithm/Fingerprint`
  --use-ldaps: oneof<nothing, bool> # Determines whether LDAPS should be used instead of plain LDAP. (default: false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/system/config/actions/test/ad"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: ldapUsersDomain, var: ldap_users_domain}, {name: serverAdminName, var: server_admin_name}, {name: serverAdminPassword, var: server_admin_password}, {name: serverIp, var: server_ip}, {name: serverPort, var: server_port}, {name: sslFingerPrint, var: ssl_finger_print}, {name: useLdaps, var: use_ldaps}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, ldap_users_domain: $ldap_users_domain, server_admin_name: $server_admin_name, server_admin_password: $server_admin_password, server_ip: $server_ip, server_port: $server_port, ssl_finger_print: $ssl_finger_print, use_ldaps: $use_ldaps
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test RADIUS server availability
#
# POST /v4/system/config/actions/test/radius
# operationId: testRadiusConfig
export def "test-radius-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: post
    path: "/v4/system/config/actions/test/radius"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of Active Directory configurations
#
# GET /v4/system/config/auth/ads
# Returns: record<items: table<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>>
# operationId: requestAdConfigs
export def "request-ad-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/auth/ads"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Active Directory configuration
#
# POST /v4/system/config/auth/ads
# Returns: record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>
# operationId: createAdConfig
export def "create-ad-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --ad-export-group: string # If `userImport` is set to `true`, the user must be member of this Active Directory group to receive a newly created DRACOON account.
  alias: string # Unique name for an Active Directory configuration
  --create-home-folder: oneof<nothing, bool> # DEPRECATED, will be ignored Determines whether a room is created for each user that is created by automatic import (like a home folder). Room's name will equal the user's login name. (default: false)
  --home-folder-parent: int # DEPRECATED, will be ignored ID of the room in which the individual rooms for users will be created. (format: int64)
  ldap_users_domain: string # Search scope of Active Directory; only users below this node can log on.
  --sds-import-group: int # User group that is assigned to users who are created by automatic import. Reset with `0` (format: int64)
  server_admin_name: string # Distinguished Name (DN) of Active Directory administrative account
  server_admin_password: string # Password of Active Directory administrative account
  server_ip: string # IPv4 or IPv6 address or host name
  server_port: int # Port (format: int32)
  --ssl-finger-print: string # SSL finger print of Active Directory server. Mandatory for LDAPS connections. Format: `Algorithm/Fingerprint`
  --use-ldaps: oneof<nothing, bool> # Determines whether LDAPS should be used instead of plain LDAP. (default: false)
  user_filter: string # Name of Active Directory attribute that is used as login name.
  --user-import: oneof<nothing, bool> # Determines if a DRACOON account is automatically created for a new user who successfully logs on with his / her AD / IDP account. (default: false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/system/config/auth/ads"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: adExportGroup, var: ad_export_group}, {name: alias, var: alias}, {name: createHomeFolder, var: create_home_folder}, {name: homeFolderParent, var: home_folder_parent}, {name: ldapUsersDomain, var: ldap_users_domain}, {name: sdsImportGroup, var: sds_import_group}, {name: serverAdminName, var: server_admin_name}, {name: serverAdminPassword, var: server_admin_password}, {name: serverIp, var: server_ip}, {name: serverPort, var: server_port}, {name: sslFingerPrint, var: ssl_finger_print}, {name: useLdaps, var: use_ldaps}, {name: userFilter, var: user_filter}, {name: userImport, var: user_import}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, ad_export_group: $ad_export_group, alias: $alias, create_home_folder: $create_home_folder, home_folder_parent: $home_folder_parent, ldap_users_domain: $ldap_users_domain, sds_import_group: $sds_import_group, server_admin_name: $server_admin_name, server_admin_password: $server_admin_password, server_ip: $server_ip, server_port: $server_port, ssl_finger_print: $ssl_finger_print, use_ldaps: $use_ldaps, user_filter: $user_filter, user_import: $user_import
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Active Directory configuration
#
# DELETE /v4/system/config/auth/ads/{ad_id}
# operationId: removeAdConfig
export def "remove-ad-config" [
  ad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/system/config/auth/ads/{ad_id}"
    path_params: [{name: ad_id, var: ad_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    ad_id: $ad_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Active Directory configuration
#
# GET /v4/system/config/auth/ads/{ad_id}
# Returns: record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>
# operationId: requestAdConfig
export def "request-ad-config" [
  ad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/auth/ads/{ad_id}"
    path_params: [{name: ad_id, var: ad_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ad_id: $ad_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Active Directory configuration
#
# PUT /v4/system/config/auth/ads/{ad_id}
# Returns: record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>
# operationId: updateAdConfig
export def "update-ad-config" [
  ad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --ad-export-group: string # If `userImport` is set to `true`, the user must be member of this Active Directory group to receive a newly created DRACOON account.
  --alias: string # Unique name for an Active Directory configuration
  --create-home-folder: oneof<nothing, bool> # DEPRECATED, will be ignored Determines whether a room is created for each user that is created by automatic import (like a home folder). Room's name will equal the user's login name. (default: false)
  --home-folder-parent: int # DEPRECATED, will be ignored ID of the room in which the individual rooms for users will be created. (format: int64)
  --ldap-users-domain: string # Search scope of Active Directory; only users below this node can log on.
  --sds-import-group: int # User group that is assigned to users who are created by automatic import. Reset with `0` (format: int64)
  --server-admin-name: string # Distinguished Name (DN) of Active Directory administrative account
  --server-admin-password: string # Password of Active Directory administrative account
  --server-ip: string # IPv4 or IPv6 address or host name
  --server-port: int # Port (format: int32)
  --ssl-finger-print: string # SSL finger print of Active Directory server. Mandatory for LDAPS connections. Format: `Algorithm/Fingerprint`
  --use-ldaps: oneof<nothing, bool> # Determines whether LDAPS should be used instead of plain LDAP.
  --user-filter: string # Name of Active Directory attribute that is used as login name.
  --user-import: oneof<nothing, bool> # Determines if a DRACOON account is automatically created for a new user who successfully logs on with his / her AD / IDP account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/auth/ads/{ad_id}"
    path_params: [{name: ad_id, var: ad_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: adExportGroup, var: ad_export_group}, {name: alias, var: alias}, {name: createHomeFolder, var: create_home_folder}, {name: homeFolderParent, var: home_folder_parent}, {name: ldapUsersDomain, var: ldap_users_domain}, {name: sdsImportGroup, var: sds_import_group}, {name: serverAdminName, var: server_admin_name}, {name: serverAdminPassword, var: server_admin_password}, {name: serverIp, var: server_ip}, {name: serverPort, var: server_port}, {name: sslFingerPrint, var: ssl_finger_print}, {name: useLdaps, var: use_ldaps}, {name: userFilter, var: user_filter}, {name: userImport, var: user_import}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ad_id: $ad_id, x_sds_auth_token: $x_sds_auth_token, ad_export_group: $ad_export_group, alias: $alias, create_home_folder: $create_home_folder, home_folder_parent: $home_folder_parent, ldap_users_domain: $ldap_users_domain, sds_import_group: $sds_import_group, server_admin_name: $server_admin_name, server_admin_password: $server_admin_password, server_ip: $server_ip, server_port: $server_port, ssl_finger_print: $ssl_finger_print, use_ldaps: $use_ldaps, user_filter: $user_filter, user_import: $user_import
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of OpenID Connect IDP configurations
#
# GET /v4/system/config/auth/openid/idps
# Docs: http://openid.net/developers/specs — OpenID Specifications
# Returns: table<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool>
# operationId: requestOpenIdIdpConfigs
export def "request-open-id-idp-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/auth/openid/idps"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create OpenID Connect IDP configuration
#
# POST /v4/system/config/auth/openid/idps
# Docs: http://openid.net/developers/specs — OpenID Specifications
# Returns: record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool>
# operationId: createOpenIdIdpConfig
export def "create-open-id-idp-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  authorization_end_point_url: string # URL of the authorization endpoint
  client_id: string # ID of the OpenID client
  client_secret: string # Secret, which client uses at authentication.
  --fallback-mapping-claim: string # Name of the claim which is used for the user mapping fallback.
  --flow: string@flow-completer # &#128640; Since v4.11.0 Flow, which is used at authentication
  issuer: string # Issuer identifier of the IDP The value is a case sensitive URL.
  jwks_end_point_url: string # URL of the JWKS endpoint
  mapping_claim: string # Name of the claim which is used for the user mapping.
  name: string # Name of the IDP
  --pkce-challenge-method: string # PKCE code challenge method. cf. [RFC 7636](https://tools.ietf.org/html/rfc7636) (default: plain)
  --pkce-enabled: oneof<nothing, bool> # Determines whether PKCE is enabled. cf. [RFC 7636](https://tools.ietf.org/html/rfc7636) (default: false)
  redirect_uris: list<string> # URIs, to which a user is redirected after authorization.
  scopes: list<string> # List of requested scopes
  token_end_point_url: string # URL of the token endpoint
  --user-import-enabled: oneof<nothing, bool> # Determines if a DRACOON account is automatically created for a new user who successfully logs on with his / her AD / IDP account. (default: false)
  --user-import-group: int # User group that is assigned to users who are created by automatic import. Reset with `0` (format: int64)
  user_info_end_point_url: string # URL of the user info endpoint
  --user-info-source: string@user-info-source-completer # &#128640; Since v4.23.0 Source, which is used to get user information at the import or update of a user.
  --user-management-url: string # URL of the user management UI. Use empty string to remove.
  --user-update-enabled: oneof<nothing, bool> # Determines if the DRACOON account is updated with data from AD / IDP. For OpenID Connect, the scopes `email` and `profile` are needed. (default: false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/system/config/auth/openid/idps"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizationEndPointUrl, var: authorization_end_point_url}, {name: clientId, var: client_id}, {name: clientSecret, var: client_secret}, {name: fallbackMappingClaim, var: fallback_mapping_claim}, {name: flow, var: flow}, {name: issuer, var: issuer}, {name: jwksEndPointUrl, var: jwks_end_point_url}, {name: mappingClaim, var: mapping_claim}, {name: name, var: name}, {name: pkceChallengeMethod, var: pkce_challenge_method}, {name: pkceEnabled, var: pkce_enabled}, {name: redirectUris, var: redirect_uris}, {name: scopes, var: scopes}, {name: tokenEndPointUrl, var: token_end_point_url}, {name: userImportEnabled, var: user_import_enabled}, {name: userImportGroup, var: user_import_group}, {name: userInfoEndPointUrl, var: user_info_end_point_url}, {name: userInfoSource, var: user_info_source}, {name: userManagementUrl, var: user_management_url}, {name: userUpdateEnabled, var: user_update_enabled}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, authorization_end_point_url: $authorization_end_point_url, client_id: $client_id, client_secret: $client_secret, fallback_mapping_claim: $fallback_mapping_claim, flow: $flow, issuer: $issuer, jwks_end_point_url: $jwks_end_point_url, mapping_claim: $mapping_claim, name: $name, pkce_challenge_method: $pkce_challenge_method, pkce_enabled: $pkce_enabled, redirect_uris: $redirect_uris, scopes: $scopes, token_end_point_url: $token_end_point_url, user_import_enabled: $user_import_enabled, user_import_group: $user_import_group, user_info_end_point_url: $user_info_end_point_url, user_info_source: $user_info_source, user_management_url: $user_management_url, user_update_enabled: $user_update_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove OpenID Connect IDP configuration
#
# DELETE /v4/system/config/auth/openid/idps/{idp_id}
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: removeOpenIdIdpConfig
export def "remove-open-id-idp-config" [
  idp_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/system/config/auth/openid/idps/{idp_id}"
    path_params: [{name: idp_id, var: idp_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    idp_id: $idp_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request OpenID Connect IDP configuration
#
# GET /v4/system/config/auth/openid/idps/{idp_id}
# Docs: http://openid.net/developers/specs — OpenID Specifications
# Returns: record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool>
# operationId: requestOpenIdIdpConfig
export def "request-open-id-idp-config" [
  idp_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/auth/openid/idps/{idp_id}"
    path_params: [{name: idp_id, var: idp_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idp_id: $idp_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update OpenID Connect IDP configuration
#
# PUT /v4/system/config/auth/openid/idps/{idp_id}
# Docs: http://openid.net/developers/specs — OpenID Specifications
# Returns: record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool>
# operationId: updateOpenIdIdpConfig
export def "update-open-id-idp-config" [
  idp_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --authorization-end-point-url: string # URL of the authorization endpoint
  --client-id: string # ID of the OpenID client
  --client-secret: string # Secret, which client uses at authentication.
  --fallback-mapping-claim: string # Name of the claim which is used for the user mapping fallback.
  --flow: string@flow-completer # &#128640; Since v4.11.0 Flow, which is used at authentication
  --issuer: string # Issuer identifier of the IDP The value is a case sensitive URL.
  --jwks-end-point-url: string # URL of the JWKS endpoint
  --mapping-claim: string # Name of the claim which is used for the user mapping.
  --name: string # Name of the IDP
  --pkce-challenge-method: string # PKCE code challenge method. cf. [RFC 7636](https://tools.ietf.org/html/rfc7636)
  --pkce-enabled: oneof<nothing, bool> # Determines whether PKCE is enabled. cf. [RFC 7636](https://tools.ietf.org/html/rfc7636) (default: false)
  --redirect-uris: list<string> # URIs, to which a user is redirected after authorization.
  --reset-fallback-mapping-claim: oneof<nothing, bool> # Set `true` to reset `fallbackMappingClaim`.
  --scopes: list<string> # List of requested scopes Usually `openid` and the names of the requested claims.
  --token-end-point-url: string # URL of the token endpoint
  --user-import-enabled: oneof<nothing, bool> # Determines if a DRACOON account is automatically created for a new user who successfully logs on with his / her AD / IDP account. (default: false)
  --user-import-group: int # User group that is assigned to users who are created by automatic import. Reset with `0` (format: int64)
  --user-info-end-point-url: string # URL of the user info endpoint
  --user-info-source: string@user-info-source-completer # &#128640; Since v4.23.0 Source, which is used to get user information at the import or update of a user.
  --user-management-url: string # URL of the user management UI. Use empty string to remove.
  --user-update-enabled: oneof<nothing, bool> # Determines if the DRACOON account is updated with data from AD / IDP. For OpenID Connect, the scopes `email` and `profile` are needed. (default: false)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/auth/openid/idps/{idp_id}"
    path_params: [{name: idp_id, var: idp_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: authorizationEndPointUrl, var: authorization_end_point_url}, {name: clientId, var: client_id}, {name: clientSecret, var: client_secret}, {name: fallbackMappingClaim, var: fallback_mapping_claim}, {name: flow, var: flow}, {name: issuer, var: issuer}, {name: jwksEndPointUrl, var: jwks_end_point_url}, {name: mappingClaim, var: mapping_claim}, {name: name, var: name}, {name: pkceChallengeMethod, var: pkce_challenge_method}, {name: pkceEnabled, var: pkce_enabled}, {name: redirectUris, var: redirect_uris}, {name: resetFallbackMappingClaim, var: reset_fallback_mapping_claim}, {name: scopes, var: scopes}, {name: tokenEndPointUrl, var: token_end_point_url}, {name: userImportEnabled, var: user_import_enabled}, {name: userImportGroup, var: user_import_group}, {name: userInfoEndPointUrl, var: user_info_end_point_url}, {name: userInfoSource, var: user_info_source}, {name: userManagementUrl, var: user_management_url}, {name: userUpdateEnabled, var: user_update_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    idp_id: $idp_id, x_sds_auth_token: $x_sds_auth_token, authorization_end_point_url: $authorization_end_point_url, client_id: $client_id, client_secret: $client_secret, fallback_mapping_claim: $fallback_mapping_claim, flow: $flow, issuer: $issuer, jwks_end_point_url: $jwks_end_point_url, mapping_claim: $mapping_claim, name: $name, pkce_challenge_method: $pkce_challenge_method, pkce_enabled: $pkce_enabled, redirect_uris: $redirect_uris, reset_fallback_mapping_claim: $reset_fallback_mapping_claim, scopes: $scopes, token_end_point_url: $token_end_point_url, user_import_enabled: $user_import_enabled, user_import_group: $user_import_group, user_info_end_point_url: $user_info_end_point_url, user_info_source: $user_info_source, user_management_url: $user_management_url, user_update_enabled: $user_update_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove RADIUS configuration
#
# DELETE /v4/system/config/auth/radius
# operationId: removeRadiusConfig
export def "remove-radius-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/system/config/auth/radius"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request RADIUS configuration
#
# GET /v4/system/config/auth/radius
# Returns: record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string>
# operationId: requestRadiusConfig
export def "request-radius-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/auth/radius"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create RADIUS configuration
#
# POST /v4/system/config/auth/radius
# Returns: record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string>
# operationId: createRadiusConfig
export def "create-radius-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --failover-server: record # Failover server information — shape: {failoverEnabled: bool, failoverIpAddress: string, failoverPort: int}
  ip_address: string # RADIUS Server IP Address
  --otp-pin-first: oneof<nothing, bool> # Sequence order of concatenated PIN and one-time token (default: true)
  port: int # RADIUS Server Port (format: int32)
  shared_secret: string # Shared Secret to access the RADIUS server
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/system/config/auth/radius"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: failoverServer, var: failover_server}, {name: ipAddress, var: ip_address}, {name: otpPinFirst, var: otp_pin_first}, {name: port, var: port}, {name: sharedSecret, var: shared_secret}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, failover_server: $failover_server, ip_address: $ip_address, otp_pin_first: $otp_pin_first, port: $port, shared_secret: $shared_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update RADIUS configuration
#
# PUT /v4/system/config/auth/radius
# Returns: record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string>
# operationId: updateRadiusConfig
export def "update-radius-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --failover-server: record # Failover server information — shape: {failoverEnabled: bool, failoverIpAddress: string, failoverPort: int}
  --ip-address: string # RADIUS Server IP Address
  --otp-pin-first: oneof<nothing, bool> # Sequence order of concatenated PIN and one-time token (default: true)
  --port: int # RADIUS Server Port (format: int32)
  --shared-secret: string # Shared Secret to access the RADIUS server
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/auth/radius"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: failoverServer, var: failover_server}, {name: ipAddress, var: ip_address}, {name: otpPinFirst, var: otp_pin_first}, {name: port, var: port}, {name: sharedSecret, var: shared_secret}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, failover_server: $failover_server, ip_address: $ip_address, otp_pin_first: $otp_pin_first, port: $port, shared_secret: $shared_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of OAuth clients
#
# GET /v4/system/config/oauth/clients
# Returns: table<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int>
# operationId: requestOAuthClients
export def "request-o-auth-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/oauth/clients"
    query: [{name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create OAuth client
#
# POST /v4/system/config/oauth/clients
# Returns: record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int>
# operationId: createOAuthClient
export def "create-o-auth-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --access-token-validity: int # Validity of the access token in seconds. (format: int32)
  --approval-validity: int # &#128640; Since v4.22.0 Validity of the approval interval in seconds. (format: int32)
  --client-id: string # ID of the OAuth client
  client_name: string # Name, which is shown at the client configuration and authorization.
  --client-secret: string # Secret, which client uses at authentication.
  --client-type: string@client-type-completer # Determines whether client is a confidential or public client.
  grant_types: list<string>@grant-types-completer # Authorized grant types * `authorization_code` * `implicit` * `password` * `client_credentials` * `refresh_token` cf. [RFC 6749](https://tools.ietf.org/html/rfc6749)
  redirect_uris: list<string> # URIs, to which a user is redirected after authorization.
  --refresh-token-validity: int # Validity of the refresh token in seconds. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/system/config/oauth/clients"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessTokenValidity, var: access_token_validity}, {name: approvalValidity, var: approval_validity}, {name: clientId, var: client_id}, {name: clientName, var: client_name}, {name: clientSecret, var: client_secret}, {name: clientType, var: client_type}, {name: grantTypes, var: grant_types}, {name: redirectUris, var: redirect_uris}, {name: refreshTokenValidity, var: refresh_token_validity}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, access_token_validity: $access_token_validity, approval_validity: $approval_validity, client_id: $client_id, client_name: $client_name, client_secret: $client_secret, client_type: $client_type, grant_types: $grant_types, redirect_uris: $redirect_uris, refresh_token_validity: $refresh_token_validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove OAuth client
#
# DELETE /v4/system/config/oauth/clients/{client_id}
# operationId: removeOAuthClient
export def "remove-o-auth-client" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/system/config/oauth/clients/{client_id}"
    path_params: [{name: client_id, var: client_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    client_id: $client_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request OAuth client
#
# GET /v4/system/config/oauth/clients/{client_id}
# Returns: record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int>
# operationId: requestOAuthClient
export def "request-o-auth-client" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/oauth/clients/{client_id}"
    path_params: [{name: client_id, var: client_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update OAuth client
#
# PUT /v4/system/config/oauth/clients/{client_id}
# Returns: record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int>
# operationId: updateOAuthClient
export def "update-o-auth-client" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --access-token-validity: int # Validity of the access token in seconds. (format: int32)
  --approval-validity: int # &#128640; Since v4.22.0 Validity of the approval interval in seconds. (format: int32)
  --client-name: string # Name, which is shown at the client configuration and authorization.
  --client-secret: string # Secret, which client uses at authentication.
  --client-type: string@client-type-completer # Determines whether client is a confidential or public client.
  grant_types: list<string>@grant-types-completer # Authorized grant types * `authorization_code` * `implicit` * `password` * `client_credentials` * `refresh_token` cf. [RFC 6749](https://tools.ietf.org/html/rfc6749)
  --is-enabled: oneof<nothing, bool> # Determines whether client is enabled.
  --redirect-uris: list<string> # URIs, to which a user is redirected after authorization.
  --refresh-token-validity: int # Validity of the refresh token in seconds. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/oauth/clients/{client_id}"
    path_params: [{name: client_id, var: client_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessTokenValidity, var: access_token_validity}, {name: approvalValidity, var: approval_validity}, {name: clientName, var: client_name}, {name: clientSecret, var: client_secret}, {name: clientType, var: client_type}, {name: grantTypes, var: grant_types}, {name: isEnabled, var: is_enabled}, {name: redirectUris, var: redirect_uris}, {name: refreshTokenValidity, var: refresh_token_validity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, x_sds_auth_token: $x_sds_auth_token, access_token_validity: $access_token_validity, approval_validity: $approval_validity, client_name: $client_name, client_secret: $client_secret, client_type: $client_type, grant_types: $grant_types, is_enabled: $is_enabled, redirect_uris: $redirect_uris, refresh_token_validity: $refresh_token_validity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request classification policies
#
# GET /v4/system/config/policies/classifications
# Returns: record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>>
# operationId: requestClassificationPoliciesConfig
export def "request-classification-policies-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/policies/classifications"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change classification policies
#
# PUT /v4/system/config/policies/classifications
# Returns: record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>>
# operationId: changeClassificationPoliciesConfig
export def "change-classification-policies-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --share-classification-policies: record # Shares classification policies — shape: {classificationRequiresSharePassword?: "0"|"1"|"2"|"3"|"4"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/policies/classifications"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: shareClassificationPolicies, var: share_classification_policies}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, share_classification_policies: $share_classification_policies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request guest user policies
#
# GET /v4/system/config/policies/guest_users
# Returns: record<isInviteUsersEnabled: bool>
# operationId: requestGuestUsersPoliciesConfig
export def "request-guest-users-policies-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/policies/guest_users"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change guest user policies
#
# PUT /v4/system/config/policies/guest_users
# Returns: record<isInviteUsersEnabled: bool>
# operationId: changeGuestUsersPoliciesConfig
export def "change-guest-users-policies-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-invite-users-enabled: oneof<nothing, bool> # Determines whether the invite of users to rooms is enabled.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/policies/guest_users"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: isInviteUsersEnabled, var: is_invite_users_enabled, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, is_invite_users_enabled: $is_invite_users_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request MFA policies
#
# GET /v4/system/config/policies/mfa
# Returns: record<isMfaEnforced: bool>
# operationId: requestMfaPoliciesConfig
export def "request-mfa-policies-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/policies/mfa"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change MFA policies
#
# PUT /v4/system/config/policies/mfa
# Returns: record<isMfaEnforced: bool>
# operationId: changeMfaPoliciesConfig
export def "change-mfa-policies-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-mfa-enforced: oneof<nothing, bool> # Determines whether multi-factor authentication is enforced
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/policies/mfa"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: isMfaEnforced, var: is_mfa_enforced, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, is_mfa_enforced: $is_mfa_enforced
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request password policies
#
# GET /v4/system/config/policies/passwords
# Returns: record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>>
# operationId: requestPasswordPoliciesConfig
export def "request-password-policies-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/policies/passwords"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password policies
#
# PUT /v4/system/config/policies/passwords
# Returns: record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>>
# operationId: changePasswordPoliciesConfig
export def "change-password-policies-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --encryption-password-policies: record # Request model for updating encryption password policies — shape: {characterRules?: record, minLength?: int, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool}
  --login-password-policies: record # Request model for updating login password policies — shape: {characterRules?: record, enforceLoginPasswordChange?: bool, minLength?: int, numberOfArchivedPasswords?: int, passwordExpiration?: record, rejectDictionaryWords?: bool, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool, userLockout?: record}
  --shares-password-policies: record # Request model for updating shares password policies — shape: {characterRules?: record, minLength?: int, rejectDictionaryWords?: bool, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/policies/passwords"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: encryptionPasswordPolicies, var: encryption_password_policies}, {name: loginPasswordPolicies, var: login_password_policies}, {name: sharesPasswordPolicies, var: shares_password_policies}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, encryption_password_policies: $encryption_password_policies, login_password_policies: $login_password_policies, shares_password_policies: $shares_password_policies
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enforce login password change for all users
#
# POST /v4/system/config/policies/passwords/enforce_change
# operationId: enforceLoginPasswordChange
export def "enforce-login-password-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: post
    path: "/v4/system/config/policies/passwords/enforce_change"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request password policies for a certain password type
#
# GET /v4/system/config/policies/passwords/{password_type}
# Returns: record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>>
# operationId: requestPasswordPoliciesForPasswordType
export def "request-password-policies-for-password-type" [
  password_type: string@password-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/policies/passwords/{password_type}"
    path_params: [{name: password_type, var: password_type}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    password_type: $password_type, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request authentication settings
#
# GET /v4/system/config/settings/auth
# Returns: record<authMethods: table<isEnabled: bool, name: string, priority: int>>
# operationId: requestAuthConfig
export def "request-auth-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/settings/auth"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update authentication settings
#
# PUT /v4/system/config/settings/auth
# Returns: record<authMethods: table<isEnabled: bool, name: string, priority: int>>
# operationId: updateAuthConfig
export def "update-auth-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  auth_methods: list # List of authentication methods — item shape: {isEnabled: bool, name: string, priority: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/settings/auth"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: authMethods, var: auth_methods}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, auth_methods: $auth_methods
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request system defaults
#
# GET /v4/system/config/settings/defaults
# Docs: https://tools.ietf.org/html/rfc5646 — Tags for Identifying Languages
# Returns: record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int>
# operationId: requestSystemDefaults
export def "request-system-defaults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/settings/defaults"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update system defaults
#
# PUT /v4/system/config/settings/defaults
# Docs: https://tools.ietf.org/html/rfc5646 — Tags for Identifying Languages
# Returns: record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int>
# operationId: updateSystemDefaults
export def "update-system-defaults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --download-share-default-expiration-period: int # Default expiration period for Download Shares in days. (format: int32)
  --file-default-expiration-period: int # Default expiration period for all uploaded files in days. (format: int32)
  --language-default: string # Define which language should be default.
  --nonmember-viewer-default: oneof<nothing, bool> # &#128640; Since v4.12.0 Defines if new users get the role Non Member Viewer by default
  --upload-share-default-expiration-period: int # Default expiration period for Upload Shares in days. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/settings/defaults"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: downloadShareDefaultExpirationPeriod, var: download_share_default_expiration_period}, {name: fileDefaultExpirationPeriod, var: file_default_expiration_period}, {name: languageDefault, var: language_default}, {name: nonmemberViewerDefault, var: nonmember_viewer_default}, {name: uploadShareDefaultExpirationPeriod, var: upload_share_default_expiration_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, download_share_default_expiration_period: $download_share_default_expiration_period, file_default_expiration_period: $file_default_expiration_period, language_default: $language_default, nonmember_viewer_default: $nonmember_viewer_default, upload_share_default_expiration_period: $upload_share_default_expiration_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request eventlog settings
#
# GET /v4/system/config/settings/eventlog
# Returns: record<enabled: bool, logIpEnabled: bool, retentionPeriod: int>
# operationId: requestEventlogConfig
export def "request-eventlog-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/settings/eventlog"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update eventlog settings
#
# PUT /v4/system/config/settings/eventlog
# Returns: record<enabled: bool, logIpEnabled: bool, retentionPeriod: int>
# operationId: updateEventlogConfig
export def "update-eventlog-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --enabled: oneof<nothing, bool> # Is eventlog enabled?
  --log-ip-enabled: oneof<nothing, bool> # Determines whether user’s IP address is logged.
  --retention-period: int # Retention period (in days) of event log entries. After that period, all entries are deleted. Recommended value: 7 (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/settings/eventlog"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: logIpEnabled, var: log_ip_enabled}, {name: retentionPeriod, var: retention_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, enabled: $enabled, log_ip_enabled: $log_ip_enabled, retention_period: $retention_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request general settings
#
# GET /v4/system/config/settings/general
# Returns: record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, useS3Storage: bool, weakPasswordEnabled: bool>
# operationId: requestGeneralSettings
export def "request-general-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/settings/general"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update general settings
#
# PUT /v4/system/config/settings/general
# Returns: record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, useS3Storage: bool, weakPasswordEnabled: bool>
# operationId: updateGeneralSettings
@deprecated --flag hide-login-input-fields
@deprecated --flag media-server-enabled
@deprecated --flag weak-password-enabled
export def "update-general-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --auth-token-restrictions: record # Request model for updating auth token settings — shape: {accessTokenValidity?: int, overwriteEnabled: bool, refreshTokenValidity?: int}
  --crypto-enabled: oneof<nothing, bool> # Activation status of client-side encryption. Can only be enabled once; disabling is not possible.
  --email-notification-button-enabled: oneof<nothing, bool> # Enable email notification button
  --eula-enabled: oneof<nothing, bool> # Each user has to confirm the EULA at first login.
  --hide-login-input-fields: oneof<nothing, bool> # &#128679; Deprecated since v4.13.0 Defines if login fields should be hidden (DEPRECATED)
  --media-server-enabled: oneof<nothing, bool> # &#128679; Deprecated since v4.12.0 Determines if the media server is enabled (DEPRECATED)
  --s3-tags-enabled: oneof<nothing, bool> # &#128640; Since v4.9.0 Defines if S3 tags are enabled
  --share-password-sms-enabled: oneof<nothing, bool> # Allow sending of share passwords via SMS
  --weak-password-enabled: oneof<nothing, bool> # &#128679; Deprecated since v4.14.0 Allow weak password * A weak password has to fulfill the following criteria: * is at least 8 characters long * contains letters and numbers * A strong password has to fulfill the following criteria in addition: * contains at least one special character * contains upper and lower case characters Please use `PUT /system/config/policies/passwords` API to change configured password policies. (DEPRECATED)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/settings/general"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: authTokenRestrictions, var: auth_token_restrictions}, {name: cryptoEnabled, var: crypto_enabled}, {name: emailNotificationButtonEnabled, var: email_notification_button_enabled}, {name: eulaEnabled, var: eula_enabled}, {name: hideLoginInputFields, var: hide_login_input_fields}, {name: mediaServerEnabled, var: media_server_enabled}, {name: s3TagsEnabled, var: s3_tags_enabled}, {name: sharePasswordSmsEnabled, var: share_password_sms_enabled}, {name: weakPasswordEnabled, var: weak_password_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, auth_token_restrictions: $auth_token_restrictions, crypto_enabled: $crypto_enabled, email_notification_button_enabled: $email_notification_button_enabled, eula_enabled: $eula_enabled, hide_login_input_fields: $hide_login_input_fields, media_server_enabled: $media_server_enabled, s3_tags_enabled: $s3_tags_enabled, share_password_sms_enabled: $share_password_sms_enabled, weak_password_enabled: $weak_password_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request infrastructure properties
#
# GET /v4/system/config/settings/infrastructure
# Returns: record<isDracoonCloud: bool, mediaServerConfigEnabled: bool, s3DefaultRegion: string, s3EnforceDirectUpload: bool, smsConfigEnabled: bool, tenantUuid: string>
# operationId: requestInfrastructureProperties
export def "request-infrastructure-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/settings/infrastructure"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request syslog settings
#
# GET /v4/system/config/settings/syslog
# Returns: record<enabled: bool, host: string, logIpEnabled: bool, port: int, protocol: string>
# operationId: requestSyslogConfig
export def "request-syslog-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/settings/syslog"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update syslog settings
#
# PUT /v4/system/config/settings/syslog
# Returns: record<enabled: bool, host: string, logIpEnabled: bool, port: int, protocol: string>
# operationId: updateSyslogConfig
export def "update-syslog-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --enabled: oneof<nothing, bool> # Is syslog enabled?
  --host: string # Syslog server (IP or FQDN)
  --log-ip-enabled: oneof<nothing, bool> # Determines whether user’s IP address is logged.
  --port: int # Syslog server port (format: int32)
  --protocol: string@protocol-completer # Protocol to connect to syslog server
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/settings/syslog"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: host, var: host}, {name: logIpEnabled, var: log_ip_enabled}, {name: port, var: port}, {name: protocol, var: protocol}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, enabled: $enabled, host: $host, log_ip_enabled: $log_ip_enabled, port: $port, protocol: $protocol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request S3 storage configuration
#
# GET /v4/system/config/storage/s3
# Returns: record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool>
# operationId: request3Config
export def "request3-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/storage/s3"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create S3 storage configuration
#
# POST /v4/system/config/storage/s3
# Returns: record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool>
# operationId: createS3Config
@deprecated --flag bucket-name
@deprecated --flag endpoint-url
export def "create-s3-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  access_key: string # Access Key ID
  --bucket-name: string # &#128679; Deprecated since v4.24.0 S3 bucket name use `bucketUrl` instead (DEPRECATED)
  --bucket-url: string # S3 object storage bucket URL
  --endpoint-url: string # &#128679; Deprecated since v4.24.0 S3 object storage endpoint URL use `bucketUrl` instead (DEPRECATED)
  --region: string # S3 region
  secret_key: string # Secret Access Key
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/system/config/storage/s3"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessKey, var: access_key}, {name: bucketName, var: bucket_name}, {name: bucketUrl, var: bucket_url}, {name: endpointUrl, var: endpoint_url}, {name: region, var: region}, {name: secretKey, var: secret_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, access_key: $access_key, bucket_name: $bucket_name, bucket_url: $bucket_url, endpoint_url: $endpoint_url, region: $region, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update S3 storage configuration
#
# PUT /v4/system/config/storage/s3
# Returns: record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool>
# operationId: updateS3Config
@deprecated --flag bucket-name
@deprecated --flag endpoint-url
export def "update-s3-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --access-key: string # Access Key ID
  --bucket-name: string # &#128679; Deprecated since v4.24.0 S3 bucket name use `bucketUrl` instead (DEPRECATED)
  --bucket-url: string # S3 object storage bucket URL
  --endpoint-url: string # &#128679; Deprecated since v4.24.0 S3 object storage endpoint URL use `bucketUrl` instead (DEPRECATED)
  --region: string # S3 region
  --secret-key: string # Secret Access Key
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/system/config/storage/s3"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: accessKey, var: access_key}, {name: bucketName, var: bucket_name}, {name: bucketUrl, var: bucket_url}, {name: endpointUrl, var: endpoint_url}, {name: region, var: region}, {name: secretKey, var: secret_key}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, access_key: $access_key, bucket_name: $bucket_name, bucket_url: $bucket_url, endpoint_url: $endpoint_url, region: $region, secret_key: $secret_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of configured S3 tags
#
# GET /v4/system/config/storage/s3/tags
# Returns: record<items: table<id: int, isMandatory: bool, key: string, value: string>>
# operationId: requestS3TagList
export def "request-s3-tag-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/storage/s3/tags"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create S3 tag
#
# POST /v4/system/config/storage/s3/tags
# Returns: record<id: int, isMandatory: bool, key: string, value: string>
# operationId: createS3Tag
export def "create-s3-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-mandatory: oneof<nothing, bool> # Determines whether S3 is mandatory or not (default: false)
  key: string # S3 tag key
  value: string # S3 tag value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/system/config/storage/s3/tags"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: isMandatory, var: is_mandatory}, {name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, is_mandatory: $is_mandatory, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove S3 tag
#
# DELETE /v4/system/config/storage/s3/tags/{id}
# operationId: removeS3Tag
export def "remove-s3-tag" [
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
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/system/config/storage/s3/tags/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request S3 tag
#
# GET /v4/system/config/storage/s3/tags/{id}
# Returns: record<id: int, isMandatory: bool, key: string, value: string>
# operationId: requestS3Tag
export def "request-s3-tag" [
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
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/system/config/storage/s3/tags/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel file upload
#
# DELETE /v4/uploads/{token}
# operationId: cancelFileUploadByToken
export def "cancel-file-upload-by-token" [
  token_arg: string
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
    path: "/v4/uploads/{token}"
    path_params: [{name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [204]
    auth: none
  } {
    token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload file
#
# POST /v4/uploads/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# Returns: record<hash: string, size: int>
# operationId: uploadFileByTokenAsMultipart_1
export def "upload-file-by-token-as-multipart-1" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Content-Range e.g. `bytes 0-999/3980`
  file: string # File (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/uploads/{token}"
    path_params: [{name: token, var: token_arg}]
    header: [{name: Content-Range, var: content_range}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: none
  } {
    token_arg: $token_arg, content_range: $content_range, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete file upload
#
# PUT /v4/uploads/{token}
# Returns: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>
# operationId: completeFileUploadByToken
@deprecated --flag user-file-key-list
export def "complete-file-upload-by-token" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --file-key: record # File key information — shape: {iv: string, key: string, tag: string, version: string}
  --file-name: string # New file name to store with
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy: * `autorename` * `overwrite` * `fail` (default: autorename)
  --user-file-key-list: record # Mandatory for encrypted shares (DEPRECATED) — shape: {items?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/uploads/{token}"
    path_params: [{name: token, var: token_arg}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}]
    body: {content_type: "application/json", kind: json, fields: [{name: fileKey, var: file_key}, {name: fileName, var: file_name}, {name: keepShareLinks, var: keep_share_links}, {name: resolutionStrategy, var: resolution_strategy}, {name: userFileKeyList, var: user_file_key_list}]}
    accept: ["application/json"]
    ok: [201, 202]
    auth: none
  } {
    token_arg: $token_arg, x_sds_date_format: $x_sds_date_format, file_key: $file_key, file_name: $file_name, keep_share_links: $keep_share_links, resolution_strategy: $resolution_strategy, user_file_key_list: $user_file_key_list
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user account information
#
# GET /v4/user/account
# Returns: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, language: string, lastLoginFailAt: string, lastLoginFailIp: string, lastLoginSuccessAt: string, lastLoginSuccessIp: string, lastName: string, lockStatus: int, login: string, mustSetEmail: bool, needsToAcceptEULA: bool, needsToChangePassword: bool, needsToChangeUserName: bool, phone: string, title: string, userAttributes: record<items: list<record>>, userGroups: table<id: int, isMember: bool, name: string>, userName: string, userRoles: record<items: list<record>>>
# operationId: requestUserInfo
export def "request-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --more-info: oneof<nothing, bool> # Get more info for this user e.g. list of user groups
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/account"
    query: [{name: more_info, var: more_info}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    more_info: $more_info, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user account
#
# PUT /v4/user/account
# Returns: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, language: string, lastLoginFailAt: string, lastLoginFailIp: string, lastLoginSuccessAt: string, lastLoginSuccessIp: string, lastName: string, lockStatus: int, login: string, mustSetEmail: bool, needsToAcceptEULA: bool, needsToChangePassword: bool, needsToChangeUserName: bool, phone: string, title: string, userAttributes: record<items: list<record>>, userGroups: table<id: int, isMember: bool, name: string>, userName: string, userRoles: record<items: list<record>>>
# operationId: updateUserAccount
@deprecated --flag gender
@deprecated --flag login
@deprecated --flag title
export def "update-user-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --accept-eula: oneof<nothing, bool> # Accept EULA Present, if EULA is system global active. cf. `GET system/config/settings/general` - `eulaEnabled` If accepted can not be undone.
  --email: string # Email
  --first-name: string # User first name
  --gender: string # &#128679; Deprecated since v4.12.0 Gender Do NOT use `gender`! It will be ignored. (DEPRECATED, default: n)
  --language: string # &#128640; Since v4.20.0 IETF language tag
  --last-name: string # User last name
  --login: string # &#128679; Deprecated since v4.13.0 User login name (DEPRECATED)
  --phone: string # Phone number
  --title: string # &#128679; Deprecated since v4.18.0 Job title (DEPRECATED)
  --user-name: string # &#128640; Since v4.13.0 Username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/user/account"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptEULA, var: accept_eula}, {name: email, var: email}, {name: firstName, var: first_name}, {name: gender, var: gender}, {name: language, var: language}, {name: lastName, var: last_name}, {name: login, var: login}, {name: phone, var: phone}, {name: title, var: title}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, accept_eula: $accept_eula, email: $email, first_name: $first_name, gender: $gender, language: $language, last_name: $last_name, login: $login, phone: $phone, title: $title, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset avatar
#
# DELETE /v4/user/account/avatar
# Returns: record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool>
# operationId: resetAvatar
export def "reset-avatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v4/user/account/avatar"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request avatar
#
# GET /v4/user/account/avatar
# Returns: record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool>
# operationId: requestAvatar
export def "request-avatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/account/avatar"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change avatar
#
# POST /v4/user/account/avatar
# Returns: record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool>
# operationId: uploadAvatarAsMultipart
export def "upload-avatar-as-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  file: string # File (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/user/account/avatar"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request customer information for user
#
# GET /v4/user/account/customer
# Returns: record<accountsLimit: int, accountsUsed: int, cntGuestUser: int, cntInternalUser: int, customerEncryptionEnabled: bool, id: int, isProviderCustomer: bool, name: string, spaceLimit: int, spaceUsed: int>
# operationId: requestCustomerInfo
export def "request-customer-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/account/customer"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Activate client-side encryption for customer
#
# PUT /v4/user/account/customer
# DEPRECATED
# Returns: record<accountsLimit: int, accountsUsed: int, cntGuestUser: int, cntInternalUser: int, customerEncryptionEnabled: bool, id: int, isProviderCustomer: bool, name: string, spaceLimit: int, spaceUsed: int>
# operationId: enableCustomerEncryption
@deprecated
export def "enable-customer-encryption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  data_space_rescue_key: record # Key pair container — shape: {privateKeyContainer: record, publicKeyContainer: record}
  --enable-customer-encryption: oneof<nothing, bool> # Set `true` to enable encryption for this customer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/user/account/customer"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: dataSpaceRescueKey, var: data_space_rescue_key}, {name: enableCustomerEncryption, var: enable_customer_encryption, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, data_space_rescue_key: $data_space_rescue_key, enable_customer_encryption: $enable_customer_encryption
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request customer's key pair
#
# GET /v4/user/account/customer/keypair
# DEPRECATED
# Returns: record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>
# operationId: requestCustomerKeyPair
@deprecated
export def "request-customer-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/account/customer/keypair"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove user's key pair
#
# DELETE /v4/user/account/keypair
# operationId: removeUserKeyPair
export def "remove-user-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/account/keypair"
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    version: $version, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user's key pair
#
# GET /v4/user/account/keypair
# Returns: record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>
# operationId: requestUserKeyPair
export def "request-user-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/account/keypair"
    query: [{name: version, var: version}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    version: $version, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set user's key pair
#
# POST /v4/user/account/keypair
# operationId: setUserKeyPair
export def "set-user-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/user/account/keypair"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: privateKeyContainer, var: private_key_container}, {name: publicKeyContainer, var: public_key_container}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, private_key_container: $private_key_container, public_key_container: $public_key_container
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request all user key pairs
#
# GET /v4/user/account/keypairs
# Returns: table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>>
# operationId: requestUserKeyPairs
export def "request-user-key-pairs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/account/keypairs"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create key pair and preserve copy of old private key
#
# POST /v4/user/account/keypairs
# operationId: createAndPreserveUserKeyPair
export def "create-and-preserve-user-key-pair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  previous_private_key: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/user/account/keypairs"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: previousPrivateKey, var: previous_private_key}, {name: privateKeyContainer, var: private_key_container}, {name: publicKeyContainer, var: public_key_container}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, previous_private_key: $previous_private_key, private_key_container: $private_key_container, public_key_container: $public_key_container
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Using emergency-code
#
# DELETE /v4/user/account/mfa
# operationId: useEmergencyCode
export def "use-emergency-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emergency-code: string # required
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/account/mfa"
    query: [{name: emergency_code, var: emergency_code, required: true}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    emergency_code: $emergency_code, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request information about the user's mfa status
#
# GET /v4/user/account/mfa
# Returns: record<mfaEnforced: bool, mfaSetups: table<createdAt: string, id: int, mfaType: string, name: string>>
# operationId: getMfaStatusForUser
export def "get-mfa-status-for-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/account/mfa"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request information to setup TOTP as second authentication factor
#
# GET /v4/user/account/mfa/totp
# Returns: record<id: int, otpUri: string, qrCode: string, secret: string>
# operationId: getTotpSetupInformation
export def "get-totp-setup-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/account/mfa/totp"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Confirm second factor TOTP setup with a generated OTP
#
# POST /v4/user/account/mfa/totp
# operationId: confirmTotpSetup
export def "confirm-totp-setup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  id: int # ID (format: int64)
  otp: string # Generated valid OTP
]: any -> any {
  $in | http-request {
    method: post
    path: "/v4/user/account/mfa/totp"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: otp, var: otp}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, id: $id, otp: $otp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a MFA TOTP setup with generated OTP
#
# DELETE /v4/user/account/mfa/totp/{id}
# operationId: deleteMfaTotpSetup
export def "delete-mfa-totp-setup" [
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
  --valid-otp: string # required
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/account/mfa/totp/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: valid_otp, var: valid_otp, required: true}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, valid_otp: $valid_otp, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change user's password
#
# PUT /v4/user/account/password
# operationId: changeUserPassword
export def "change-user-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  new_password: string # New password
  old_password: string # Old password
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/user/account/password"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: newPassword, var: new_password}, {name: oldPassword, var: old_password}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, new_password: $new_password, old_password: $old_password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invalidate authentication token
#
# POST /v4/user/logout
# DEPRECATED
# operationId: logout
@deprecated
export def "logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --everywhere: oneof<nothing, bool> # Invalidate all tokens
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: post
    path: "/v4/user/logout"
    query: [{name: everywhere, var: everywhere}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    everywhere: $everywhere, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of notification configurations
#
# GET /v4/user/notifications/config
# Returns: record<items: table<channelIds: list, eventTypeName: string, id: int, scopeId: int>>
# operationId: requestListOfNotificationConfigs
export def "request-list-of-notification-configs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/notifications/config"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update notification configuration
#
# PUT /v4/user/notifications/config/{id}
# Returns: record<channelIds: list<int>, eventTypeName: string, id: int, scopeId: int>
# operationId: updateNotificationConfig
export def "update-notification-config" [
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
  --x-sds-auth-token: string # Authentication token
  channel_ids: list<int> # List of notification channel IDs. Leave empty to disable notifications.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/user/notifications/config/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelIds, var: channel_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, x_sds_auth_token: $x_sds_auth_token, channel_ids: $channel_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of OAuth client approvals
#
# GET /v4/user/oauth/approvals
# Returns: table<clientId: string, clientName: string, expiresAt: string>
# operationId: requestOAuthApprovals
export def "request-o-auth-approvals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/oauth/approvals"
    query: [{name: sort, var: sort}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove OAuth client approval
#
# DELETE /v4/user/oauth/approvals/{client_id}
# operationId: removeOAuthApproval
export def "remove-o-auth-approval" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/oauth/approvals/{client_id}"
    path_params: [{name: client_id, var: client_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    client_id: $client_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request list of OAuth client authorizations
#
# GET /v4/user/oauth/authorizations
# Returns: table<clientId: string, clientName: string, createdAt: string, expiresAt: string, id: int, isCurrentAuthorization: bool, isStandard: bool, usedAt: string, userAgentCategory: string, userAgentInfo: string, userAgentOs: string, userAgentType: string>
# operationId: requestOAuthAuthorizations
export def "request-o-auth-authorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/oauth/authorizations"
    query: [{name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, sort: $sort, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove all OAuth authorizations of a client
#
# DELETE /v4/user/oauth/authorizations/{client_id}
# operationId: removeOAuthAuthorizations
export def "remove-o-auth-authorizations" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/oauth/authorizations/{client_id}"
    path_params: [{name: client_id, var: client_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    client_id: $client_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a OAuth authorization
#
# DELETE /v4/user/oauth/authorizations/{client_id}/{authorization_id}
# operationId: removeOAuthAuthorization
export def "remove-o-auth-authorization" [
  client_id: string
  authorization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/oauth/authorizations/{client_id}/{authorization_id}"
    path_params: [{name: client_id, var: client_id}, {name: authorization_id, var: authorization_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    client_id: $client_id, authorization_id: $authorization_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# (authenticated) Ping
#
# GET /v4/user/ping
# Returns: string
# operationId: pingUser
export def "ping-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: get
    path: "/v4/user/ping"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user profile attributes
#
# GET /v4/user/profileAttributes
# Returns: record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestProfileAttributes
export def "request-profile-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/profileAttributes"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set user profile attributes
#
# POST /v4/user/profileAttributes
# DEPRECATED
# Returns: record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>
# operationId: setProfileAttributes
@deprecated
export def "set-profile-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/user/profileAttributes"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or edit user profile attributes
#
# PUT /v4/user/profileAttributes
# Returns: record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>
# operationId: updateProfileAttributes
export def "update-profile-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/user/profileAttributes"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove user profile attribute
#
# DELETE /v4/user/profileAttributes/{key}
# operationId: removeProfileAttribute
export def "remove-profile-attribute" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/profileAttributes/{key}"
    path_params: [{name: key, var: key}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    key: $key, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Download Share subscriptions
#
# GET /v4/user/subscriptions/download_shares
# Returns: record<items: table<authParentId: int, id: int>, range: record<limit: int, offset: int, total: int>>
# operationId: listDownloadShareSubscriptions
export def "list-download-share-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --offset: int # Range offset (format: int32)
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/subscriptions/download_shares"
    query: [{name: filter, var: filter}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, limit: $limit, offset: $offset, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe or Unsubscribe a List of Download Shares for notifications
#
# PUT /v4/user/subscriptions/download_shares
# operationId: subscribeDownloadShares
export def "subscribe-download-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-subscribed: oneof<nothing, bool> # Creates or deletes a subscription on each item in an array of objects.
  object_ids: list<int> # List of ids
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/user/subscriptions/download_shares"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: isSubscribed, var: is_subscribed, required: true}, {name: objectIds, var: object_ids}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, is_subscribed: $is_subscribed, object_ids: $object_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe Download Share from notifications
#
# DELETE /v4/user/subscriptions/download_shares/{share_id}
# operationId: unsubscribeDownloadShare
export def "unsubscribe-download-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/subscriptions/download_shares/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    share_id: $share_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe Download Share for notifications
#
# POST /v4/user/subscriptions/download_shares/{share_id}
# Returns: record<authParentId: int, id: int>
# operationId: subscribeDownloadShare
export def "subscribe-download-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/user/subscriptions/download_shares/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    share_id: $share_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List node subscriptions
#
# GET /v4/user/subscriptions/nodes
# Returns: record<items: table<authParentId: int, id: int, type: string>, range: record<limit: int, offset: int, total: int>>
# operationId: listNodeSubscriptions
export def "list-node-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --offset: int # Range offset (format: int32)
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/subscriptions/nodes"
    query: [{name: filter, var: filter}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, limit: $limit, offset: $offset, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe or Unsubscribe a List of nodes for notifications
#
# PUT /v4/user/subscriptions/nodes
# operationId: updateNodeSubscriptions
export def "update-node-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-subscribed: oneof<nothing, bool> # Creates or deletes a subscription on each item in an array of objects.
  object_ids: list<int> # List of ids
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/user/subscriptions/nodes"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: isSubscribed, var: is_subscribed, required: true}, {name: objectIds, var: object_ids}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, is_subscribed: $is_subscribed, object_ids: $object_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe node from notifications
#
# DELETE /v4/user/subscriptions/nodes/{node_id}
# operationId: unsubscribeNode
export def "unsubscribe-node" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/subscriptions/nodes/{node_id}"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    node_id: $node_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe node for notifications
#
# POST /v4/user/subscriptions/nodes/{node_id}
# Returns: record<authParentId: int, id: int, type: string>
# operationId: subscribeNode
export def "subscribe-node" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/user/subscriptions/nodes/{node_id}"
    path_params: [{name: node_id, var: node_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    node_id: $node_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Upload Share subscriptions
#
# GET /v4/user/subscriptions/upload_shares
# Returns: record<items: table<id: int, targetNodeId: int>, range: record<limit: int, offset: int, total: int>>
# operationId: listUploadShareSubscriptions
export def "list-upload-share-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --offset: int # Range offset (format: int32)
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/user/subscriptions/upload_shares"
    query: [{name: filter, var: filter}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, limit: $limit, offset: $offset, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe or Unsubscribe a List of Upload Shares for notifications
#
# PUT /v4/user/subscriptions/upload_shares
# operationId: subscribeUploadShares
export def "subscribe-upload-shares" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-subscribed: oneof<nothing, bool> # Creates or deletes a subscription on each item in an array of objects.
  object_ids: list<int> # List of ids
]: any -> any {
  $in | http-request {
    method: put
    path: "/v4/user/subscriptions/upload_shares"
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: isSubscribed, var: is_subscribed, required: true}, {name: objectIds, var: object_ids}]}
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    x_sds_auth_token: $x_sds_auth_token, is_subscribed: $is_subscribed, object_ids: $object_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe Upload Share from notifications
#
# DELETE /v4/user/subscriptions/upload_shares/{share_id}
# operationId: unsubscribeUploadShare
export def "unsubscribe-upload-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/user/subscriptions/upload_shares/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    share_id: $share_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe Upload Share for notifications
#
# POST /v4/user/subscriptions/upload_shares/{share_id}
# Returns: record<id: int, targetNodeId: int>
# operationId: subscribeUploadShare
export def "subscribe-upload-share" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/user/subscriptions/upload_shares/{share_id}"
    path_params: [{name: share_id, var: share_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    share_id: $share_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request users
#
# GET /v4/users
# Returns: record<items: table<avatarUuid: string, createdAt: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, title: string, userAttributes: record, userName: string, userRoles: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestUsers
export def "request-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --include-attributes: oneof<nothing, bool> # Include custom user attributes.
  --include-roles: oneof<nothing, bool> # Include roles
  --include-manageable-rooms: oneof<nothing, bool> # Include hasManageableRooms (deprecated)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/users"
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}, {name: include_attributes, var: include_attributes}, {name: include_roles, var: include_roles}, {name: include_manageable_rooms, var: include_manageable_rooms}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, limit: $limit, filter: $filter, sort: $sort, include_attributes: $include_attributes, include_roles: $include_roles, include_manageable_rooms: $include_manageable_rooms, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new user
#
# POST /v4/users
# Returns: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>
# operationId: createUser
@deprecated --flag auth-methods
@deprecated --flag gender
@deprecated --flag login
@deprecated --flag needs-to-change-password
@deprecated --flag password
@deprecated --flag title
export def "create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --auth-data: record # User Authentication Data — shape: {adConfigId?: int, login?: string, method: string, mustChangePassword?: bool, oidConfigId?: int, password?: string}
  --auth-methods: list # &#128679; Deprecated since v4.13.0 Authentication methods: * `sql` * `active_directory` * `radius` * `openid` use `authData` instead (DEPRECATED) — item shape: {authId: string, isEnabled: bool, options?: list}
  --email: string # Email
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  first_name: string # User first name
  --gender: string # &#128679; Deprecated since v4.12.0 Gender Do NOT use `gender`! It will be ignored. (DEPRECATED, default: n)
  --is-nonmember-viewer: oneof<nothing, bool> # &#128640; Since v4.12.0 Determines whether user has the role NONMEMBER_VIEWER
  last_name: string # User last name
  --login: string # &#128679; Deprecated since v4.13.0 User login name (DEPRECATED)
  --mfa-config: record # Multi-factor authentication configuration — shape: {mfaEnforced?: bool}
  --needs-to-change-password: oneof<nothing, bool> # &#128679; Deprecated since v4.13.0 Determines whether user has to change his / her initial password. use `authDate.mustChangePassword` instead (DEPRECATED)
  --notify-user: oneof<nothing, bool> # &#128640; Since v4.9.0 Notify user about his new account * default: `true` for `basic` auth type * default: `false` for `active_directory`, `openid` and `radius` auth types
  --password: string # &#128679; Deprecated since v4.13.0 An initial password may be preset use `authData` instead (DEPRECATED)
  --phone: string # Phone number
  --receiver-language: string # IETF language tag
  --title: string # &#128679; Deprecated since v4.18.0 Job title (DEPRECATED)
  --user-name: string # &#128640; Since v4.13.0 Username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/users"
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: authData, var: auth_data}, {name: authMethods, var: auth_methods}, {name: email, var: email}, {name: expiration, var: expiration}, {name: firstName, var: first_name}, {name: gender, var: gender}, {name: isNonmemberViewer, var: is_nonmember_viewer}, {name: lastName, var: last_name}, {name: login, var: login}, {name: mfaConfig, var: mfa_config}, {name: needsToChangePassword, var: needs_to_change_password}, {name: notifyUser, var: notify_user}, {name: password, var: password}, {name: phone, var: phone}, {name: receiverLanguage, var: receiver_language}, {name: title, var: title}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, auth_data: $auth_data, auth_methods: $auth_methods, email: $email, expiration: $expiration, first_name: $first_name, gender: $gender, is_nonmember_viewer: $is_nonmember_viewer, last_name: $last_name, login: $login, mfa_config: $mfa_config, needs_to_change_password: $needs_to_change_password, notify_user: $notify_user, password: $password, phone: $phone, receiver_language: $receiver_language, title: $title, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove user
#
# DELETE /v4/users/{user_id}
# operationId: removeUser
export def "remove-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user_id: $user_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user
#
# GET /v4/users/{user_id}
# Returns: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>
# operationId: requestUser
export def "request-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --effective-roles: oneof<nothing, bool> # Filter users with DIRECT or DIRECT **AND** EFFECTIVE roles. * `false`: DIRECT roles * `true`: DIRECT **AND** EFFECTIVE roles DIRECT means: e.g. user gets role **directly** granted from someone with _grant permission_ right. EFFECTIVE means: e.g. user gets role through **group membership**.
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: effective_roles, var: effective_roles}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, effective_roles: $effective_roles, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user's metadata
#
# PUT /v4/users/{user_id}
# Returns: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>
# operationId: updateUser
@deprecated --flag auth-methods
@deprecated --flag gender
@deprecated --flag lock-status
@deprecated --flag title
export def "update-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --auth-data: record # User Authentication Data Update Request — shape: {adConfigId?: int, login?: string, method?: string, oidConfigId?: int}
  --auth-methods: list # &#128679; Deprecated since v4.13.0 Authentication methods: * `sql` * `active_directory` * `radius` * `openid` use `authData` instead (DEPRECATED) — item shape: {authId: string, isEnabled: bool, options?: list}
  --email: string # Email
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --first-name: string # User first name
  --gender: string # &#128679; Deprecated since v4.12.0 Gender Do NOT use `gender`! It will be ignored. (DEPRECATED, default: n)
  --is-locked: oneof<nothing, bool> # User is locked: * `false` - unlocked * `true` - locked User is locked and can not login anymore. (default: false)
  --last-name: string # User last name
  --lock-status: int # &#128679; Deprecated since v4.7.0 User lock status: * `0` - locked * `1` - Web access allowed * `2` - Web and mobile access allowed Please use `isLocked` instead. (DEPRECATED, format: int32)
  --mfa-config: record # Multi-factor authentication configuration — shape: {mfaEnforced?: bool}
  --phone: string # Phone number
  --receiver-language: string # IETF language tag
  --title: string # &#128679; Deprecated since v4.18.0 Job title (DEPRECATED)
  --user-name: string # &#128640; Since v4.13.0 Username
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: authData, var: auth_data}, {name: authMethods, var: auth_methods}, {name: email, var: email}, {name: expiration, var: expiration}, {name: firstName, var: first_name}, {name: gender, var: gender}, {name: isLocked, var: is_locked}, {name: lastName, var: last_name}, {name: lockStatus, var: lock_status}, {name: mfaConfig, var: mfa_config}, {name: phone, var: phone}, {name: receiverLanguage, var: receiver_language}, {name: title, var: title}, {name: userName, var: user_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, auth_data: $auth_data, auth_methods: $auth_methods, email: $email, expiration: $expiration, first_name: $first_name, gender: $gender, is_locked: $is_locked, last_name: $last_name, lock_status: $lock_status, mfa_config: $mfa_config, phone: $phone, receiver_language: $receiver_language, title: $title, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request groups that user is a member of or / and can become a member
#
# GET /v4/users/{user_id}/groups
# Returns: record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestUserGroups
export def "request-user-groups" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/users/{user_id}/groups"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, offset: $offset, limit: $limit, filter: $filter, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request rooms where the user is last admin
#
# GET /v4/users/{user_id}/last_admin_rooms
# Returns: record<items: table<id: int, lastAdminInGroup: bool, lastAdminInGroupId: int, name: string, parentId: int, parentPath: string>>
# operationId: requestLastAdminRoomsUsers
export def "request-last-admin-rooms-users" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/users/{user_id}/last_admin_rooms"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request emergency MFA code
#
# POST /v4/users/{user_id}/mfa/emergency_code
# Returns: record<code: string>
# operationId: requestEmergencyMfaCode
export def "request-emergency-mfa-code" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v4/users/{user_id}/mfa/emergency_code"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request user's granted roles
#
# GET /v4/users/{user_id}/roles
# Returns: record<items: table<description: string, id: int, items: list, name: string>>
# operationId: requestUserRoles
export def "request-user-roles" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/users/{user_id}/roles"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request rooms granted to the user or / and rooms that can be granted
#
# GET /v4/users/{user_id}/rooms
# DEPRECATED
# Returns: record<items: table<children: list, cntDownloadShares: int, cntUploadShares: int, createdAt: string, createdBy: record, hasRecycleBin: bool, id: int, isEncrypted: bool, isFavorite: bool, isGranted: bool, name: string, parentId: int, permissions: record, quota: int, recycleBinRetentionPeriod: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>>
# operationId: requestUsersRooms
@deprecated
export def "request-users-rooms" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/users/{user_id}/rooms"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, offset: $offset, limit: $limit, filter: $filter, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request custom user attributes
#
# GET /v4/users/{user_id}/userAttributes
# Returns: record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>>
# operationId: requestUserAttributes
export def "request-user-attributes" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit. Maximum 500. For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v4/users/{user_id}/userAttributes"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}, {name: filter, var: filter}, {name: sort, var: sort}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, offset: $offset, limit: $limit, filter: $filter, sort: $sort, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set custom user attributes
#
# POST /v4/users/{user_id}/userAttributes
# DEPRECATED
# Returns: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>
# operationId: setUserAttributes
@deprecated
export def "set-user-attributes" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v4/users/{user_id}/userAttributes"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add or edit custom user attributes
#
# PUT /v4/users/{user_id}/userAttributes
# Returns: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>>
# operationId: updateUserAttributes
export def "update-user-attributes" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v4/users/{user_id}/userAttributes"
    path_params: [{name: user_id, var: user_id}]
    header: [{name: X-Sds-Date-Format, var: x_sds_date_format}, {name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, x_sds_date_format: $x_sds_date_format, x_sds_auth_token: $x_sds_auth_token, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove custom user attribute
#
# DELETE /v4/users/{user_id}/userAttributes/{key}
# operationId: removeUserAttribute
export def "remove-user-attribute" [
  user_id: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  http-request {
    method: delete
    path: "/v4/users/{user_id}/userAttributes/{key}"
    path_params: [{name: user_id, var: user_id}, {name: key, var: key}]
    header: [{name: X-Sds-Auth-Token, var: x_sds_auth_token}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    user_id: $user_id, key: $key, x_sds_auth_token: $x_sds_auth_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
