# Auto-generated client for Trakt API v1.0.0
# Source: https://api.apis.guru/v2/specs/trakt.tv/1.0.0/openapi.json
# Auth: --token flag or $env.TRAKT_API_TOKEN

const CLIENT = {
  base_url: "https://api.trakt.tv"
  token_env_var: "TRAKT_API_TOKEN"
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

def base-url-completer [] { ["https://api.trakt.tv"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["movies" "shows"] }
def comment-type-completer [] { ["all" "reviews" "shouts"] }
def type-completer-1 [] { ["all" "episodes" "lists" "movies" "seasons" "shows"] }
def sort-completer [] { ["likes" "newest" "oldest" "replies"] }
def type-completer-2 [] { ["episode" "movie" "person" "season" "show"] }
def period-completer [] { ["all" "daily" "monthly" "weekly" "yearly"] }
def sort-completer-1 [] { ["highest" "likes" "lowest" "newest" "oldest" "plays" "replies"] }
def type-completer-3 [] { ["all" "official" "personal" "recommendations" "watchlists"] }
def sort-completer-2 [] { ["added" "comments" "items" "likes" "popular" "updated"] }
def type-completer-4 [] { ["all" "official" "personal"] }
def ignore-collected-completer [] { ["false" "true"] }
def ignore-watchlisted-completer [] { ["false" "true"] }
def id-type-completer [] { ["imdb" "tmdb" "trakt" "tvdb"] }
def type-completer-5 [] { ["episode" "list" "movie" "person" "show"] }
def sort-completer-3 [] { ["highest" "likes" "lowest" "newest" "oldest" "plays" "replies" "watched"] }
def type-completer-6 [] { ["all" "official" "personal" "watchlists"] }
def type-completer-7 [] { ["episodes" "movies" "seasons" "shows"] }
def type-completer-8 [] { ["episodes" "movies"] }
def type-completer-9 [] { ["all" "episodes" "movies" "seasons" "shows"] }
def rating-completer [] { ["1" "10" "2" "3" "4" "5" "6" "7" "8" "9"] }
def sort-completer-4 [] { ["added" "rank" "released" "title"] }
def section-completer [] { ["calendar" "comments" "progress_collected" "progress_watched" "progress_watched_reset" "recommendations"] }
def type-completer-10 [] { ["movie" "season" "show" "user"] }
def section-completer-1 [] { ["calendar" "progress_collected" "progress_watched" "recommendations"] }
def section-completer-2 [] { ["calendar" "comments" "progress_collected" "progress_watched" "recommendations"] }
def section-completer-3 [] { ["calendars" "movies" "search" "shows"] }
def include-replies-completer [] { ["false" "only" "true"] }
def type-completer-11 [] { ["comments" "lists"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-calendars-all-dvd-start-date-days" "get-calendars-all-movies-start-date-days" "get-calendars-all-shows-new-start-date-days" "get-calendars-all-shows-premieres-start-date-days" "get-calendars-all-shows-start-date-days" "get-dvd-releases" "get-movies" "get-new-shows" "get-season-premieres" "get-shows" "get-certifications" "delete-any-active-checkins" "check-into-an-item" "post-a-comment" "get-recently-created-comments" "get-trending-comments" "get-recently-updated-comments" "delete-a-comment-or-reply" "get-a-comment-or-reply" "update-a-comment-or-reply" "get-the-attached-media-item" "remove-like-on-a-comment" "like-a-comment" "get-all-users-who-liked-a-comment" "get-replies-for-a-comment" "post-a-reply-for-a-comment" "get-countries" "get-genres" "get-languages" "get-popular-lists" "get-trending-lists" "get-list" "get-all-list-comments" "get-items-on-a-list" "get-all-users-who-liked-a-list" "get-the-most-anticipated-movies" "get-the-weekend-box-office" "get-the-most-collected-movies" "get-the-most-played-movies" "get-popular-movies" "get-the-most-recommended-movies" "get-trending-movies" "get-recently-updated-movie-trakt-i-ds" "get-recently-updated-movies" "get-the-most-watched-movies" "get-a-movie" "get-all-movie-aliases" "get-all-movie-comments" "get-lists-containing-this-movie" "get-all-people-for-a-movie" "get-movie-ratings" "get-related-movies" "get-all-movie-releases" "get-movie-stats" "get-movie-studios" "get-all-movie-translations" "get-users-watching-right-now" "get-networks" "authorize-application" "generate-new-device-codes" "poll-for-the-access-token" "revoke-an-access-token" "exchange-refresh-token-for-access-token" "get-recently-updated-people-trakt-i-ds" "get-recently-updated-people" "get-a-single-person" "get-lists-containing-this-person" "get-movie-credits" "get-show-credits" "get-movie-recommendations" "hide-a-movie-recommendation" "get-show-recommendations" "hide-a-show-recommendation" "pause-watching-in-a-media-center" "start-watching-in-a-media-center" "stop-or-finish-watching-in-a-media-center" "get-id-lookup-results" "get-text-query-results" "get-the-most-anticipated-shows" "get-the-most-collected-shows" "get-the-most-played-shows" "get-popular-shows" "get-the-most-recommended-shows" "get-trending-shows" "get-recently-updated-show-trakt-i-ds" "get-recently-updated-shows" "get-the-most-watched-shows" "get-a-single-show" "get-all-show-aliases" "get-all-show-certifications" "get-all-show-comments" "get-last-episode" "get-lists-containing-this-show" "get-next-episode" "get-all-people-for-a-show" "get-show-collection-progress" "get-show-watched-progress" "undo-reset-show-progress" "reset-show-progress" "get-show-ratings" "get-related-shows" "get-all-seasons-for-a-show" "get-single-season-for-a-show" "get-all-season-comments" "get-a-single-episode-for-a-show" "get-all-episode-comments" "get-lists-containing-this-episode" "get-all-people-for-an-episode" "get-episode-ratings" "get-episode-stats" "get-all-episode-translations" "get-shows-id-seasons-season-episodes-episode-watching" "get-lists-containing-this-season" "get-all-people-for-a-season" "get-season-ratings" "get-season-stats" "get-all-season-translations" "get-shows-id-seasons-season-watching" "get-show-stats" "get-show-studios" "get-all-show-translations" "get-shows-id-watching" "add-items-to-collection" "remove-items-from-collection" "get-collection" "add-items-to-watched-history" "remove-items-from-history" "get-watched-history" "get-last-activity" "remove-a-playback-item" "get-playback-progress" "add-new-ratings" "remove-ratings" "get-ratings" "add-items-to-personal-recommendations" "remove-items-from-personal-recommendations" "reorder-personally-recommended-items" "get-personal-recommendations" "get-watched" "add-items-to-watchlist" "remove-items-from-watchlist" "reorder-watchlist-items" "get-watchlist" "get-hidden-items" "add-hidden-items" "remove-hidden-items" "get-follow-requests" "get-pending-following-requests" "deny-follow-request" "approve-follow-request" "get-saved-filters" "retrieve-settings" "get-user-profile" "get-users-id-collection-type" "get-comments" "unfollow-this-user" "follow-this-user" "get-followers" "get-following" "get-friends" "get-users-id-history-type-item-id" "get-likes" "get-a-users-personal-lists" "create-personal-list" "get-all-lists-a-user-can-collaborate-on" "reorder-a-users-lists" "delete-a-users-personal-list" "get-personal-list" "update-personal-list" "get-users-id-lists-list-id-comments-sort" "add-items-to-personal-list" "remove-items-from-personal-list" "reorder-items-on-a-list" "get-items-on-a-personal-list" "remove-like-on-a-list" "like-a-list" "get-users-id-lists-list-id-likes" "get-users-id-ratings-type-rating" "get-users-id-recommendations-type-sort" "get-stats" "get-users-id-watched-type" "get-watching" "get-users-id-watchlist-type-sort" "commands"] | sort) } | get name | first)
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

# Get DVD releases
#
# GET /calendars/all/dvd/{start_date}/{days}
export def "get-calendars-all-dvd-start-date-days" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/all/dvd/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get movies
#
# GET /calendars/all/movies/{start_date}/{days}
export def "get-calendars-all-movies-start-date-days" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/all/movies/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get new shows
#
# GET /calendars/all/shows/new/{start_date}/{days}
export def "get-calendars-all-shows-new-start-date-days" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/all/shows/new/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get season premieres
#
# GET /calendars/all/shows/premieres/{start_date}/{days}
export def "get-calendars-all-shows-premieres-start-date-days" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/all/shows/premieres/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shows
#
# GET /calendars/all/shows/{start_date}/{days}
export def "get-calendars-all-shows-start-date-days" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/all/shows/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get DVD releases
#
# GET /calendars/my/dvd/{start_date}/{days}
# operationId: Get DVD releases
export def "get-dvd-releases" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/my/dvd/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get movies
#
# GET /calendars/my/movies/{start_date}/{days}
# operationId: Get movies
export def "get-movies" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/my/movies/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get new shows
#
# GET /calendars/my/shows/new/{start_date}/{days}
# operationId: Get new shows
export def "get-new-shows" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/my/shows/new/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get season premieres
#
# GET /calendars/my/shows/premieres/{start_date}/{days}
# operationId: Get season premieres
export def "get-season-premieres" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/my/shows/premieres/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get shows
#
# GET /calendars/my/shows/{start_date}/{days}
# operationId: Get shows
export def "get-shows" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/calendars/my/shows/{start_date}/{days}"
    path_params: [{name: start_date, var: start_date}, {name: days, var: days}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, days: $days, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get certifications
#
# GET /certifications/{type}
# operationId: Get certifications
export def "get-certifications" [
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/certifications/{type}"
    path_params: [{name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete any active checkins
#
# DELETE /checkin
# operationId: Delete any active checkins
export def "delete-any-active-checkins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/checkin"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check into an item
#
# POST /checkin
# operationId: Check into an item
export def "check-into-an-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --app-date: string
  --app-version: string
  --message: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --sharing: record # shape: {tumblr?: bool, twitter?: bool}
]: any -> any {
  $in | http-request {
    method: post
    path: "/checkin"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: app_date, var: app_date}, {name: app_version, var: app_version}, {name: message, var: message}, {name: movie, var: movie}, {name: sharing, var: sharing}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, app_date: $app_date, app_version: $app_version, message: $message, movie: $movie, sharing: $sharing
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post a comment
#
# POST /comments
# operationId: Post a comment
export def "post-a-comment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --comment: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --sharing: record # shape: {medium?: bool, tumblr?: bool, twitter?: bool}
  --spoiler: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/comments"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: movie, var: movie}, {name: sharing, var: sharing}, {name: spoiler, var: spoiler}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, comment: $comment, movie: $movie, sharing: $sharing, spoiler: $spoiler
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recently created comments
#
# GET /comments/recent/{comment_type}/{type}
# operationId: Get recently created comments
export def "get-recently-created-comments" [
  comment_type: string@comment-type-completer
  type: string@type-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-replies: string # include comment replies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/comments/recent/{comment_type}/{type}"
    path_params: [{name: comment_type, var: comment_type}, {name: type, var: type}]
    query: [{name: include_replies, var: include_replies}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_type: $comment_type, type: $type, include_replies: $include_replies, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trending comments
#
# GET /comments/trending/{comment_type}/{type}
# operationId: Get trending comments
export def "get-trending-comments" [
  comment_type: string@comment-type-completer
  type: string@type-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-replies: string # include comment replies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/comments/trending/{comment_type}/{type}"
    path_params: [{name: comment_type, var: comment_type}, {name: type, var: type}]
    query: [{name: include_replies, var: include_replies}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_type: $comment_type, type: $type, include_replies: $include_replies, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recently updated comments
#
# GET /comments/updates/{comment_type}/{type}
# operationId: Get recently updated comments
export def "get-recently-updated-comments" [
  comment_type: string@comment-type-completer
  type: string@type-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-replies: string # include comment replies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/comments/updates/{comment_type}/{type}"
    path_params: [{name: comment_type, var: comment_type}, {name: type, var: type}]
    query: [{name: include_replies, var: include_replies}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    comment_type: $comment_type, type: $type, include_replies: $include_replies, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a comment or reply
#
# DELETE /comments/{id}
# operationId: Delete a comment or reply
export def "delete-a-comment-or-reply" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/comments/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a comment or reply
#
# GET /comments/{id}
# operationId: Get a comment or reply
export def "get-a-comment-or-reply" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/comments/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a comment or reply
#
# PUT /comments/{id}
# operationId: Update a comment or reply
export def "update-a-comment-or-reply" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --comment: string
  --spoiler: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/comments/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: spoiler, var: spoiler}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, comment: $comment, spoiler: $spoiler
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the attached media item
#
# GET /comments/{id}/item
# operationId: Get the attached media item
export def "get-the-attached-media-item" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/comments/{id}/item"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove like on a comment
#
# DELETE /comments/{id}/like
# operationId: Remove like on a comment
export def "remove-like-on-a-comment" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/comments/{id}/like"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Like a comment
#
# POST /comments/{id}/like
# operationId: Like a comment
export def "like-a-comment" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: post
    path: "/comments/{id}/like"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users who liked a comment
#
# GET /comments/{id}/likes
# operationId: Get all users who liked a comment
export def "get-all-users-who-liked-a-comment" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/comments/{id}/likes"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get replies for a comment
#
# GET /comments/{id}/replies
# operationId: Get replies for a comment
export def "get-replies-for-a-comment" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/comments/{id}/replies"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post a reply for a comment
#
# POST /comments/{id}/replies
# operationId: Post a reply for a comment
export def "post-a-reply-for-a-comment" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --comment: string
  --spoiler: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: post
    path: "/comments/{id}/replies"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: comment, var: comment}, {name: spoiler, var: spoiler}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, comment: $comment, spoiler: $spoiler
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get countries
#
# GET /countries/{type}
# operationId: Get countries
export def "get-countries" [
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/countries/{type}"
    path_params: [{name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get genres
#
# GET /genres/{type}
# operationId: Get genres
export def "get-genres" [
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/genres/{type}"
    path_params: [{name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get languages
#
# GET /languages/{type}
# operationId: Get languages
export def "get-languages" [
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/languages/{type}"
    path_params: [{name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get popular lists
#
# GET /lists/popular
# operationId: Get popular lists
export def "get-popular-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/popular"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trending lists
#
# GET /lists/trending
# operationId: Get trending lists
export def "get-trending-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/trending"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list
#
# GET /lists/{id}
# operationId: Get list
export def "get-list" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all list comments
#
# GET /lists/{id}/comments/{sort}
# operationId: Get all list comments
export def "get-all-list-comments" [
  id: int
  sort: string@sort-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{id}/comments/{sort}"
    path_params: [{name: id, var: id}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get items on a list
#
# GET /lists/{id}/items/{type}
# operationId: Get items on a list
export def "get-items-on-a-list" [
  id: string
  type: string@type-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{id}/items/{type}"
    path_params: [{name: id, var: id}, {name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users who liked a list
#
# GET /lists/{id}/likes
# operationId: Get all users who liked a list
export def "get-all-users-who-liked-a-list" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{id}/likes"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most anticipated movies
#
# GET /movies/anticipated
# operationId: Get the most anticipated movies
export def "get-the-most-anticipated-movies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/anticipated"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the weekend box office
#
# GET /movies/boxoffice
# operationId: Get the weekend box office
export def "get-the-weekend-box-office" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/boxoffice"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most Collected movies
#
# GET /movies/collected/{period}
# operationId: Get the most Collected movies
export def "get-the-most-collected-movies" [
  period: string@period-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/collected/{period}"
    path_params: [{name: period, var: period}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most played movies
#
# GET /movies/played/{period}
# operationId: Get the most played movies
export def "get-the-most-played-movies" [
  period: string@period-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/played/{period}"
    path_params: [{name: period, var: period}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get popular movies
#
# GET /movies/popular
# operationId: Get popular movies
export def "get-popular-movies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/popular"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most recommended movies
#
# GET /movies/recommended/{period}
# operationId: Get the most recommended movies
export def "get-the-most-recommended-movies" [
  period: string@period-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/recommended/{period}"
    path_params: [{name: period, var: period}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trending movies
#
# GET /movies/trending
# operationId: Get trending movies
export def "get-trending-movies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/trending"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recently updated movie Trakt IDs
#
# GET /movies/updates/id/{start_date}
# operationId: Get recently updated movie Trakt IDs
export def "get-recently-updated-movie-trakt-i-ds" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/updates/id/{start_date}"
    path_params: [{name: start_date, var: start_date}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recently updated movies
#
# GET /movies/updates/{start_date}
# operationId: Get recently updated movies
export def "get-recently-updated-movies" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/updates/{start_date}"
    path_params: [{name: start_date, var: start_date}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most watched movies
#
# GET /movies/watched/{period}
# operationId: Get the most watched movies
export def "get-the-most-watched-movies" [
  period: string@period-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/watched/{period}"
    path_params: [{name: period, var: period}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a movie
#
# GET /movies/{id}
# operationId: Get a movie
export def "get-a-movie" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all movie aliases
#
# GET /movies/{id}/aliases
# operationId: Get all movie aliases
export def "get-all-movie-aliases" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/aliases"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all movie comments
#
# GET /movies/{id}/comments/{sort}
# operationId: Get all movie comments
export def "get-all-movie-comments" [
  id: string
  sort: string@sort-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/comments/{sort}"
    path_params: [{name: id, var: id}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lists containing this movie
#
# GET /movies/{id}/lists/{type}/{sort}
# operationId: Get lists containing this movie
export def "get-lists-containing-this-movie" [
  id: string
  type: string@type-completer-3
  sort: string@sort-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/lists/{type}/{sort}"
    path_params: [{name: id, var: id}, {name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all people for a movie
#
# GET /movies/{id}/people
# operationId: Get all people for a movie
export def "get-all-people-for-a-movie" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/people"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get movie ratings
#
# GET /movies/{id}/ratings
# operationId: Get movie ratings
export def "get-movie-ratings" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/ratings"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get related movies
#
# GET /movies/{id}/related
# operationId: Get related movies
export def "get-related-movies" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/related"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all movie releases
#
# GET /movies/{id}/releases/{country}
# operationId: Get all movie releases
export def "get-all-movie-releases" [
  id: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/releases/{country}"
    path_params: [{name: id, var: id}, {name: country, var: country}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, country: $country, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get movie stats
#
# GET /movies/{id}/stats
# operationId: Get movie stats
export def "get-movie-stats" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/stats"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get movie studios
#
# GET /movies/{id}/studios
# operationId: Get movie studios
export def "get-movie-studios" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/studios"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all movie translations
#
# GET /movies/{id}/translations/{language}
# operationId: Get all movie translations
export def "get-all-movie-translations" [
  id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/translations/{language}"
    path_params: [{name: id, var: id}, {name: language, var: language}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, language: $language, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users watching right now
#
# GET /movies/{id}/watching
# operationId: Get users watching right now
export def "get-users-watching-right-now" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/movies/{id}/watching"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get networks
#
# GET /networks
# operationId: Get networks
export def "get-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/networks"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authorize Application
#
# GET /oauth/authorize
# operationId: Authorize Application
export def "authorize-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # Must be set to code. (required, e.g. code)
  --client-id: string # Get this from your app settings. (required, e.g.  )
  --redirect-uri: string # URI specified in your app settings. (required, e.g.  )
  --state: string # State variable for CSRF purposes. (e.g.  )
]: nothing -> any {
  http-request {
    method: get
    path: "/oauth/authorize"
    query: [{name: response_type, var: response_type, required: true}, {name: client_id, var: client_id, required: true}, {name: redirect_uri, var: redirect_uri, required: true}, {name: state, var: state}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    response_type: $response_type, client_id: $client_id, redirect_uri: $redirect_uri, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate new device codes
#
# POST /oauth/device/code
# operationId: Generate new device codes
export def "generate-new-device-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/oauth/device/code"
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: client_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Poll for the access_token
#
# POST /oauth/device/token
# operationId: Poll for the access_token
export def "poll-for-the-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
  --code: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/oauth/device/token"
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: code, var: code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, code: $code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Revoke an access_token
#
# POST /oauth/revoke
# operationId: Revoke an access_token
export def "revoke-an-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
  --body-token: string # (spec name: token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/oauth/revoke"
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Exchange refresh_token for access_token
#
# POST /oauth/token
# operationId: Exchange refresh_token for access_token
export def "exchange-refresh-token-for-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
  --grant-type: string
  --redirect-uri: string
  --refresh-token: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/oauth/token"
    body: {content_type: "application/json", kind: json, fields: [{name: client_id, var: client_id}, {name: client_secret, var: client_secret}, {name: grant_type, var: grant_type}, {name: redirect_uri, var: redirect_uri}, {name: refresh_token, var: refresh_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, redirect_uri: $redirect_uri, refresh_token: $refresh_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recently updated people Trakt IDs
#
# GET /people/updates/id/{start_date}
# operationId: Get recently updated people Trakt IDs
export def "get-recently-updated-people-trakt-i-ds" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/people/updates/id/{start_date}"
    path_params: [{name: start_date, var: start_date}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recently updated people
#
# GET /people/updates/{start_date}
# operationId: Get recently updated people
export def "get-recently-updated-people" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/people/updates/{start_date}"
    path_params: [{name: start_date, var: start_date}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single person
#
# GET /people/{id}
# operationId: Get a single person
export def "get-a-single-person" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/people/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lists containing this person
#
# GET /people/{id}/lists/{type}/{sort}
# operationId: Get lists containing this person
export def "get-lists-containing-this-person" [
  id: string
  type: string@type-completer-4
  sort: string@sort-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/people/{id}/lists/{type}/{sort}"
    path_params: [{name: id, var: id}, {name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get movie credits
#
# GET /people/{id}/movies
# operationId: Get movie credits
export def "get-movie-credits" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/people/{id}/movies"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get show credits
#
# GET /people/{id}/shows
# operationId: Get show credits
export def "get-show-credits" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/people/{id}/shows"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get movie recommendations
#
# GET /recommendations/movies
# operationId: Get movie recommendations
export def "get-movie-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignore-collected: string@ignore-collected-completer # filter out collected movies (e.g. false)
  --ignore-watchlisted: string@ignore-watchlisted-completer # filter out watchlisted movies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/recommendations/movies"
    query: [{name: ignore_collected, var: ignore_collected}, {name: ignore_watchlisted, var: ignore_watchlisted}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ignore_collected: $ignore_collected, ignore_watchlisted: $ignore_watchlisted, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hide a movie recommendation
#
# DELETE /recommendations/movies/{id}
# operationId: Hide a movie recommendation
export def "hide-a-movie-recommendation" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/recommendations/movies/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get show recommendations
#
# GET /recommendations/shows
# operationId: Get show recommendations
export def "get-show-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignore-collected: string@ignore-collected-completer # filter out collected shows (e.g. false)
  --ignore-watchlisted: string@ignore-watchlisted-completer # filter out watchlisted movies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/recommendations/shows"
    query: [{name: ignore_collected, var: ignore_collected}, {name: ignore_watchlisted, var: ignore_watchlisted}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ignore_collected: $ignore_collected, ignore_watchlisted: $ignore_watchlisted, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Hide a show recommendation
#
# DELETE /recommendations/shows/{id}
# operationId: Hide a show recommendation
export def "hide-a-show-recommendation" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/recommendations/shows/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause watching in a media center
#
# POST /scrobble/pause
# operationId: Pause watching in a media center
export def "pause-watching-in-a-media-center" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --app-date: string
  --app-version: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --progress: float
]: any -> any {
  $in | http-request {
    method: post
    path: "/scrobble/pause"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: app_date, var: app_date}, {name: app_version, var: app_version}, {name: movie, var: movie}, {name: progress, var: progress}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, app_date: $app_date, app_version: $app_version, movie: $movie, progress: $progress
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start watching in a media center
#
# POST /scrobble/start
# operationId: Start watching in a media center
export def "start-watching-in-a-media-center" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --app-date: string
  --app-version: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --progress: float
]: any -> any {
  $in | http-request {
    method: post
    path: "/scrobble/start"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: app_date, var: app_date}, {name: app_version, var: app_version}, {name: movie, var: movie}, {name: progress, var: progress}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, app_date: $app_date, app_version: $app_version, movie: $movie, progress: $progress
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stop or finish watching in a media center
#
# POST /scrobble/stop
# operationId: Stop or finish watching in a media center
export def "stop-or-finish-watching-in-a-media-center" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --app-date: string
  --app-version: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --progress: float
]: any -> any {
  $in | http-request {
    method: post
    path: "/scrobble/stop"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: app_date, var: app_date}, {name: app_version, var: app_version}, {name: movie, var: movie}, {name: progress, var: progress}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, app_date: $app_date, app_version: $app_version, movie: $movie, progress: $progress
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ID lookup results
#
# GET /search/{id_type}/{id}
# operationId: Get ID lookup results
export def "get-id-lookup-results" [
  id_type: string@id-type-completer
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
  --type: string@type-completer-5 # Search type. (e.g. movie)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{id_type}/{id}"
    path_params: [{name: id_type, var: id_type}, {name: id, var: id}]
    query: [{name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id_type: $id_type, id: $id, type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get text query results
#
# GET /search/{type}
# operationId: Get text query results
export def "get-text-query-results" [
  type: string@type-completer-5
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search all text based fields. (required, e.g. tron)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/search/{type}"
    path_params: [{name: type, var: type}]
    query: [{name: query, var: query, required: true}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, query: $query, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most anticipated shows
#
# GET /shows/anticipated
# operationId: Get the most anticipated shows
export def "get-the-most-anticipated-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/anticipated"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most collected shows
#
# GET /shows/collected/{period}
# operationId: Get the most collected shows
export def "get-the-most-collected-shows" [
  period: string@period-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/collected/{period}"
    path_params: [{name: period, var: period}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most played shows
#
# GET /shows/played/{period}
# operationId: Get the most played shows
export def "get-the-most-played-shows" [
  period: string@period-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/played/{period}"
    path_params: [{name: period, var: period}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get popular shows
#
# GET /shows/popular
# operationId: Get popular shows
export def "get-popular-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/popular"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most recommended shows
#
# GET /shows/recommended/{period}
# operationId: Get the most recommended shows
export def "get-the-most-recommended-shows" [
  period: string@period-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/recommended/{period}"
    path_params: [{name: period, var: period}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get trending shows
#
# GET /shows/trending
# operationId: Get trending shows
export def "get-trending-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/trending"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recently updated show Trakt IDs
#
# GET /shows/updates/id/{start_date}
# operationId: Get recently updated show Trakt IDs
export def "get-recently-updated-show-trakt-i-ds" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/updates/id/{start_date}"
    path_params: [{name: start_date, var: start_date}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get recently updated shows
#
# GET /shows/updates/{start_date}
# operationId: Get recently updated shows
export def "get-recently-updated-shows" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/updates/{start_date}"
    path_params: [{name: start_date, var: start_date}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    start_date: $start_date, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the most watched shows
#
# GET /shows/watched/{period}
# operationId: Get the most watched shows
export def "get-the-most-watched-shows" [
  period: string@period-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/watched/{period}"
    path_params: [{name: period, var: period}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single show
#
# GET /shows/{id}
# operationId: Get a single show
export def "get-a-single-show" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all show aliases
#
# GET /shows/{id}/aliases
# operationId: Get all show aliases
export def "get-all-show-aliases" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/aliases"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all show certifications
#
# GET /shows/{id}/certifications
# operationId: Get all show certifications
export def "get-all-show-certifications" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/certifications"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all show comments
#
# GET /shows/{id}/comments/{sort}
# operationId: Get all show comments
export def "get-all-show-comments" [
  id: string
  sort: string@sort-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/comments/{sort}"
    path_params: [{name: id, var: id}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get last episode
#
# GET /shows/{id}/last_episode
# operationId: Get last episode
export def "get-last-episode" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/last_episode"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lists containing this show
#
# GET /shows/{id}/lists/{type}/{sort}
# operationId: Get lists containing this show
export def "get-lists-containing-this-show" [
  id: string
  type: string@type-completer-3
  sort: string@sort-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/lists/{type}/{sort}"
    path_params: [{name: id, var: id}, {name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get next episode
#
# GET /shows/{id}/next_episode
# operationId: Get next episode
export def "get-next-episode" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/next_episode"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all people for a show
#
# GET /shows/{id}/people
# operationId: Get all people for a show
export def "get-all-people-for-a-show" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/people"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get show collection progress
#
# GET /shows/{id}/progress/collection
# operationId: Get show collection progress
export def "get-show-collection-progress" [
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
  --hidden: string # include any hidden seasons (e.g. false)
  --specials: string # include specials as season 0 (e.g. false)
  --count-specials: string # count specials in the overall stats (only applies if specials are included) (e.g. true)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/progress/collection"
    path_params: [{name: id, var: id}]
    query: [{name: hidden, var: hidden}, {name: specials, var: specials}, {name: count_specials, var: count_specials}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, hidden: $hidden, specials: $specials, count_specials: $count_specials, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get show watched progress
#
# GET /shows/{id}/progress/watched
# operationId: Get show watched progress
export def "get-show-watched-progress" [
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
  --hidden: string # include any hidden seasons (e.g. false)
  --specials: string # include specials as season 0 (e.g. false)
  --count-specials: string # count specials in the overall stats (only applies if specials are included) (e.g. true)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/progress/watched"
    path_params: [{name: id, var: id}]
    query: [{name: hidden, var: hidden}, {name: specials, var: specials}, {name: count_specials, var: count_specials}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, hidden: $hidden, specials: $specials, count_specials: $count_specials, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Undo reset show progress
#
# DELETE /shows/{id}/progress/watched/reset
# operationId: Undo reset show progress
export def "undo-reset-show-progress" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/shows/{id}/progress/watched/reset"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset show progress
#
# POST /shows/{id}/progress/watched/reset
# operationId: Reset show progress
export def "reset-show-progress" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: post
    path: "/shows/{id}/progress/watched/reset"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get show ratings
#
# GET /shows/{id}/ratings
# operationId: Get show ratings
export def "get-show-ratings" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/ratings"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get related shows
#
# GET /shows/{id}/related
# operationId: Get related shows
export def "get-related-shows" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/related"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all seasons for a show
#
# GET /shows/{id}/seasons
# operationId: Get all seasons for a show
export def "get-all-seasons-for-a-show" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get single season for a show
#
# GET /shows/{id}/seasons/{season}
# operationId: Get single season for a show
export def "get-single-season-for-a-show" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --translations: string # include episode translations (e.g. es)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}"
    path_params: [{name: id, var: id}, {name: season, var: season}]
    query: [{name: translations, var: translations}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, translations: $translations, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all season comments
#
# GET /shows/{id}/seasons/{season}/comments/{sort}
# operationId: Get all season comments
export def "get-all-season-comments" [
  id: string
  season: int
  sort: string@sort-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/comments/{sort}"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single episode for a show
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}
# operationId: Get a single episode for a show
export def "get-a-single-episode-for-a-show" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/episodes/{episode}"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: episode, var: episode}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, episode: $episode, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all episode comments
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/comments/{sort}
# operationId: Get all episode comments
export def "get-all-episode-comments" [
  id: string
  season: int
  episode: int
  sort: string@sort-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/episodes/{episode}/comments/{sort}"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: episode, var: episode}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, episode: $episode, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lists containing this episode
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/lists/{type}/{sort}
# operationId: Get lists containing this episode
export def "get-lists-containing-this-episode" [
  id: string
  season: int
  episode: int
  type: string@type-completer-6
  sort: string@sort-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/episodes/{episode}/lists/{type}/{sort}"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: episode, var: episode}, {name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, episode: $episode, type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all people for an episode
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/people
# operationId: Get all people for an episode
export def "get-all-people-for-an-episode" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/episodes/{episode}/people"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: episode, var: episode}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, episode: $episode, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get episode ratings
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/ratings
# operationId: Get episode ratings
export def "get-episode-ratings" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/episodes/{episode}/ratings"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: episode, var: episode}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, episode: $episode, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get episode stats
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/stats
# operationId: Get episode stats
export def "get-episode-stats" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/episodes/{episode}/stats"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: episode, var: episode}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, episode: $episode, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all episode translations
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/translations/{language}
# operationId: Get all episode translations
export def "get-all-episode-translations" [
  id: string
  season: int
  episode: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/episodes/{episode}/translations/{language}"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: episode, var: episode}, {name: language, var: language}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, episode: $episode, language: $language, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users watching right now
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/watching
export def "get-shows-id-seasons-season-episodes-episode-watching" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/episodes/{episode}/watching"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: episode, var: episode}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, episode: $episode, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lists containing this season
#
# GET /shows/{id}/seasons/{season}/lists/{type}/{sort}
# operationId: Get lists containing this season
export def "get-lists-containing-this-season" [
  id: string
  season: int
  type: string@type-completer-6
  sort: string@sort-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/lists/{type}/{sort}"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all people for a season
#
# GET /shows/{id}/seasons/{season}/people
# operationId: Get all people for a season
export def "get-all-people-for-a-season" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/people"
    path_params: [{name: id, var: id}, {name: season, var: season}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get season ratings
#
# GET /shows/{id}/seasons/{season}/ratings
# operationId: Get season ratings
export def "get-season-ratings" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/ratings"
    path_params: [{name: id, var: id}, {name: season, var: season}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get season stats
#
# GET /shows/{id}/seasons/{season}/stats
# operationId: Get season stats
export def "get-season-stats" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/stats"
    path_params: [{name: id, var: id}, {name: season, var: season}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all season translations
#
# GET /shows/{id}/seasons/{season}/translations/{language}
# operationId: Get all season translations
export def "get-all-season-translations" [
  id: string
  season: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/translations/{language}"
    path_params: [{name: id, var: id}, {name: season, var: season}, {name: language, var: language}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, language: $language, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users watching right now
#
# GET /shows/{id}/seasons/{season}/watching
export def "get-shows-id-seasons-season-watching" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/seasons/{season}/watching"
    path_params: [{name: id, var: id}, {name: season, var: season}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, season: $season, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get show stats
#
# GET /shows/{id}/stats
# operationId: Get show stats
export def "get-show-stats" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/stats"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get show studios
#
# GET /shows/{id}/studios
# operationId: Get show studios
export def "get-show-studios" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/studios"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all show translations
#
# GET /shows/{id}/translations/{language}
# operationId: Get all show translations
export def "get-all-show-translations" [
  id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/translations/{language}"
    path_params: [{name: id, var: id}, {name: language, var: language}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, language: $language, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users watching right now
#
# GET /shows/{id}/watching
export def "get-shows-id-watching" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/shows/{id}/watching"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add items to collection
#
# POST /sync/collection
# operationId: Add items to collection
export def "add-items-to-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {audio?: string, audio_channels?: string, collected_at?: string, hdr?: string, ids: record, media_type?: string, resolution?: string, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/collection"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove items from collection
#
# POST /sync/collection/remove
# operationId: Remove items from collection
export def "remove-items-from-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/collection/remove"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get collection
#
# GET /sync/collection/{type}
# operationId: Get collection
export def "get-collection" [
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/sync/collection/{type}"
    path_params: [{name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add items to watched history
#
# POST /sync/history
# operationId: Add items to watched history
export def "add-items-to-watched-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record, watched_at?: string}
  --movies: list # item shape: {ids: record, title?: string, watched_at?: string, year?: float}
  --seasons: list # item shape: {ids?: record, watched_at?: string}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/history"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove items from history
#
# POST /sync/history/remove
# operationId: Remove items from history
export def "remove-items-from-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --ids: list<float>
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/history/remove"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: ids, var: ids}, {name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, ids: $ids, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watched history
#
# GET /sync/history/{type}/{id}
# operationId: Get watched history
export def "get-watched-history" [
  type: string@type-completer-7
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
  --start-at: string # Starting date. (e.g. 2016-06-01T00:00:00.000Z)
  --end-at: string # Ending date. (e.g. 2016-07-01T23:59:59.000Z)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/sync/history/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, start_at: $start_at, end_at: $end_at, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get last activity
#
# GET /sync/last_activities
# operationId: Get last activity
export def "get-last-activity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/sync/last_activities"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a playback item
#
# DELETE /sync/playback/{id}
# operationId: Remove a playback item
export def "remove-a-playback-item" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/sync/playback/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get playback progress
#
# GET /sync/playback/{type}
# operationId: Get playback progress
export def "get-playback-progress" [
  type: string@type-completer-8
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Starting date. (e.g. 2016-06-01T00:00:00.000Z)
  --end-at: string # Ending date. (e.g. 2016-07-01T23:59:59.000Z)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/sync/playback/{type}"
    path_params: [{name: type, var: type}]
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, start_at: $start_at, end_at: $end_at, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new ratings
#
# POST /sync/ratings
# operationId: Add new ratings
export def "add-new-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record, rating?: float}
  --movies: list # item shape: {ids: record, rated_at?: string, rating: float, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record, rating?: float}
  --shows: list # item shape: {ids: record, rating?: float, seasons: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/ratings"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove ratings
#
# POST /sync/ratings/remove
# operationId: Remove ratings
export def "remove-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/ratings/remove"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ratings
#
# GET /sync/ratings/{type}/{rating}
# operationId: Get ratings
export def "get-ratings" [
  type: string@type-completer-9
  rating: int@rating-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/sync/ratings/{type}/{rating}"
    path_params: [{name: type, var: type}, {name: rating, var: rating}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, rating: $rating, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add items to personal recommendations
#
# POST /sync/recommendations
# operationId: Add items to personal recommendations
export def "add-items-to-personal-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --movies: list # item shape: {ids: record, notes?: string, title?: string, year?: float}
  --shows: list # item shape: {ids: record, notes?: string, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/recommendations"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: movies, var: movies}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, movies: $movies, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove items from personal recommendations
#
# POST /sync/recommendations/remove
# operationId: Remove items from personal recommendations
export def "remove-items-from-personal-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --shows: list # item shape: {ids?: record, title?: string, year?: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/recommendations/remove"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: movies, var: movies}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, movies: $movies, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reorder personally recommended items
#
# POST /sync/recommendations/reorder
# operationId: Reorder personally recommended items
export def "reorder-personally-recommended-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --rank: list<float>
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/recommendations/reorder"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get personal recommendations
#
# GET /sync/recommendations/{type}/{sort}
# operationId: Get personal recommendations
export def "get-personal-recommendations" [
  type: string@type-completer
  sort: string@sort-completer-4
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/sync/recommendations/{type}/{sort}"
    path_params: [{name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watched
#
# GET /sync/watched/{type}
# operationId: Get watched
export def "get-watched" [
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/sync/watched/{type}"
    path_params: [{name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add items to watchlist
#
# POST /sync/watchlist
# operationId: Add items to watchlist
export def "add-items-to-watchlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, notes?: string, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, notes?: string, seasons: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/watchlist"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove items from watchlist
#
# POST /sync/watchlist/remove
# operationId: Remove items from watchlist
export def "remove-items-from-watchlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/watchlist/remove"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reorder watchlist items
#
# POST /sync/watchlist/reorder
# operationId: Reorder watchlist items
export def "reorder-watchlist-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --rank: list<float>
]: any -> any {
  $in | http-request {
    method: post
    path: "/sync/watchlist/reorder"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watchlist
#
# GET /sync/watchlist/{type}/{sort}
# operationId: Get watchlist
export def "get-watchlist" [
  type: string@type-completer-7
  sort: string@sort-completer-4
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/sync/watchlist/{type}/{sort}"
    path_params: [{name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get hidden items
#
# GET /users/hidden/{section}
# operationId: Get hidden items
export def "get-hidden-items" [
  section: string@section-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-10 # Narrow down by element type.
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/hidden/{section}"
    path_params: [{name: section, var: section}]
    query: [{name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    section: $section, type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add hidden items
#
# POST /users/hidden/{section}
# operationId: Add hidden items
export def "add-hidden-items" [
  section: string@section-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons?: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/hidden/{section}"
    path_params: [{name: section, var: section}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    section: $section, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove hidden items
#
# POST /users/hidden/{section}/remove
# operationId: Remove hidden items
export def "remove-hidden-items" [
  section: string@section-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons?: list, title: string, year: float}
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/hidden/{section}/remove"
    path_params: [{name: section, var: section}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: movies, var: movies}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    section: $section, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, movies: $movies, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get follow requests
#
# GET /users/requests
# operationId: Get follow requests
export def "get-follow-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/requests"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pending following requests
#
# GET /users/requests/following
# operationId: Get pending following requests
export def "get-pending-following-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/requests/following"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deny follow request
#
# DELETE /users/requests/{id}
# operationId: Deny follow request
export def "deny-follow-request" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/requests/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approve follow request
#
# POST /users/requests/{id}
# operationId: Approve follow request
export def "approve-follow-request" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: post
    path: "/users/requests/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get saved filters
#
# GET /users/saved_filters/{section}
# operationId: Get saved filters
export def "get-saved-filters" [
  section: string@section-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/saved_filters/{section}"
    path_params: [{name: section, var: section}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    section: $section, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve settings
#
# GET /users/settings
# operationId: Retrieve settings
export def "retrieve-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/settings"
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user profile
#
# GET /users/{id}
# operationId: Get user profile
export def "get-user-profile" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get collection
#
# GET /users/{id}/collection/{type}
export def "get-users-id-collection-type" [
  id: string
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/collection/{type}"
    path_params: [{name: id, var: id}, {name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get comments
#
# GET /users/{id}/comments/{comment_type}/{type}
# operationId: Get comments
export def "get-comments" [
  id: string
  comment_type: string@comment-type-completer
  type: string@type-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-replies: string@include-replies-completer # include comment replies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/comments/{comment_type}/{type}"
    path_params: [{name: id, var: id}, {name: comment_type, var: comment_type}, {name: type, var: type}]
    query: [{name: include_replies, var: include_replies}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, comment_type: $comment_type, type: $type, include_replies: $include_replies, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow this user
#
# DELETE /users/{id}/follow
# operationId: Unfollow this user
export def "unfollow-this-user" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{id}/follow"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow this user
#
# POST /users/{id}/follow
# operationId: Follow this user
export def "follow-this-user" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: post
    path: "/users/{id}/follow"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get followers
#
# GET /users/{id}/followers
# operationId: Get followers
export def "get-followers" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/followers"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get following
#
# GET /users/{id}/following
# operationId: Get following
export def "get-following" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/following"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get friends
#
# GET /users/{id}/friends
# operationId: Get friends
export def "get-friends" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/friends"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watched history
#
# GET /users/{id}/history/{type}/{item_id}
export def "get-users-id-history-type-item-id" [
  id: string
  type: string@type-completer-7
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Starting date. (e.g. 2016-06-01T00:00:00.000Z)
  --end-at: string # Ending date. (e.g. 2016-07-01T23:59:59.000Z)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/history/{type}/{item_id}"
    path_params: [{name: id, var: id}, {name: type, var: type}, {name: item_id, var: item_id}]
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, item_id: $item_id, start_at: $start_at, end_at: $end_at, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get likes
#
# GET /users/{id}/likes/{type}
# operationId: Get likes
export def "get-likes" [
  id: string
  type: string@type-completer-11
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/likes/{type}"
    path_params: [{name: id, var: id}, {name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's personal lists
#
# GET /users/{id}/lists
# operationId: Get a user's personal lists
export def "get-a-users-personal-lists" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/lists"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create personal list
#
# POST /users/{id}/lists
# operationId: Create personal list
export def "create-personal-list" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --allow-comments: oneof<nothing, bool>
  --description: string
  --display-numbers: oneof<nothing, bool>
  --name: string
  --privacy: string
  --sort-by: string
  --sort-how: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{id}/lists"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_comments, var: allow_comments}, {name: description, var: description}, {name: display_numbers, var: display_numbers}, {name: name, var: name}, {name: privacy, var: privacy}, {name: sort_by, var: sort_by}, {name: sort_how, var: sort_how}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, allow_comments: $allow_comments, description: $description, display_numbers: $display_numbers, name: $name, privacy: $privacy, sort_by: $sort_by, sort_how: $sort_how
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all lists a user can collaborate on
#
# GET /users/{id}/lists/collaborations
# operationId: Get all lists a user can collaborate on
export def "get-all-lists-a-user-can-collaborate-on" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/lists/collaborations"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reorder a user's lists
#
# POST /users/{id}/lists/reorder
# operationId: Reorder a user's lists
export def "reorder-a-users-lists" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --rank: list<float>
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{id}/lists/reorder"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user's personal list
#
# DELETE /users/{id}/lists/{list_id}
# operationId: Delete a user's personal list
export def "delete-a-users-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{id}/lists/{list_id}"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get personal list
#
# GET /users/{id}/lists/{list_id}
# operationId: Get personal list
export def "get-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/lists/{list_id}"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update personal list
#
# PUT /users/{id}/lists/{list_id}
# operationId: Update personal list
export def "update-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --display-numbers: oneof<nothing, bool>
  --name: string
  --privacy: string
  --sort-by: string
  --sort-how: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/{id}/lists/{list_id}"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: display_numbers, var: display_numbers}, {name: name, var: name}, {name: privacy, var: privacy}, {name: sort_by, var: sort_by}, {name: sort_how, var: sort_how}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, display_numbers: $display_numbers, name: $name, privacy: $privacy, sort_by: $sort_by, sort_how: $sort_how
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all list comments
#
# GET /users/{id}/lists/{list_id}/comments/{sort}
export def "get-users-id-lists-list-id-comments-sort" [
  id: string
  list_id: string
  sort: string@sort-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/lists/{list_id}/comments/{sort}"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add items to personal list
#
# POST /users/{id}/lists/{list_id}/items
# operationId: Add items to personal list
export def "add-items-to-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, notes?: string}
  --people: list # item shape: {ids?: record, name?: string}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, notes?: string, seasons: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{id}/lists/{list_id}/items"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: people, var: people}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, people: $people, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove items from personal list
#
# POST /users/{id}/lists/{list_id}/items/remove
# operationId: Remove items from personal list
export def "remove-items-from-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record}
  --people: list # item shape: {ids?: record, name?: string}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list}
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{id}/lists/{list_id}/items/remove"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: episodes, var: episodes}, {name: movies, var: movies}, {name: people, var: people}, {name: seasons, var: seasons}, {name: shows, var: shows}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, episodes: $episodes, movies: $movies, people: $people, seasons: $seasons, shows: $shows
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reorder items on a list
#
# POST /users/{id}/lists/{list_id}/items/reorder
# operationId: Reorder items on a list
export def "reorder-items-on-a-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --rank: list<float>
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/{id}/lists/{list_id}/items/reorder"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: rank, var: rank}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key, rank: $rank
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get items on a personal list
#
# GET /users/{id}/lists/{list_id}/items/{type}
# operationId: Get items on a personal list
export def "get-items-on-a-personal-list" [
  id: string
  list_id: string
  type: string@type-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/lists/{list_id}/items/{type}"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}, {name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id, type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove like on a list
#
# DELETE /users/{id}/lists/{list_id}/like
# operationId: Remove like on a list
export def "remove-like-on-a-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{id}/lists/{list_id}/like"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Like a list
#
# POST /users/{id}/lists/{list_id}/like
# operationId: Like a list
export def "like-a-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: post
    path: "/users/{id}/lists/{list_id}/like"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users who liked a list
#
# GET /users/{id}/lists/{list_id}/likes
export def "get-users-id-lists-list-id-likes" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/lists/{list_id}/likes"
    path_params: [{name: id, var: id}, {name: list_id, var: list_id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, list_id: $list_id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get ratings
#
# GET /users/{id}/ratings/{type}/{rating}
export def "get-users-id-ratings-type-rating" [
  id: string
  type: string@type-completer-9
  rating: int@rating-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/ratings/{type}/{rating}"
    path_params: [{name: id, var: id}, {name: type, var: type}, {name: rating, var: rating}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, rating: $rating, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get personal recommendations
#
# GET /users/{id}/recommendations/{type}/{sort}
export def "get-users-id-recommendations-type-sort" [
  id: string
  type: string@type-completer
  sort: string@sort-completer-4
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/recommendations/{type}/{sort}"
    path_params: [{name: id, var: id}, {name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get stats
#
# GET /users/{id}/stats
# operationId: Get stats
export def "get-stats" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/stats"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watched
#
# GET /users/{id}/watched/{type}
export def "get-users-id-watched-type" [
  id: string
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/watched/{type}"
    path_params: [{name: id, var: id}, {name: type, var: type}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watching
#
# GET /users/{id}/watching
# operationId: Get watching
export def "get-watching" [
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
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/watching"
    path_params: [{name: id, var: id}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    id: $id, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get watchlist
#
# GET /users/{id}/watchlist/{type}/{sort}
export def "get-users-id-watchlist-type-sort" [
  id: string
  type: string@type-completer-7
  sort: string@sort-completer-4
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{id}/watchlist/{type}/{sort}"
    path_params: [{name: id, var: id}, {name: type, var: type}, {name: sort, var: sort}]
    header: [{name: trakt-api-version, var: trakt_api_version}, {name: trakt-api-key, var: trakt_api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, type: $type, sort: $sort, trakt_api_version: $trakt_api_version, trakt_api_key: $trakt_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
