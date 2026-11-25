# Auto-generated client for Spotify Web API v1.0.0
# Source: https://api.apis.guru/v2/specs/spotify.com/1.0.0/openapi.json
# Auth: --token flag or $env.SPOTIFY_WEB_API_TOKEN

const CLIENT = {
  base_url: "https://api.spotify.com/v1"
  token_env_var: "SPOTIFY_WEB_API_TOKEN"
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

def base-url-completer [] { ["https://api.spotify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["artist" "user"] }
def type-completer-1 [] { ["artist"] }
def type-completer-2 [] { ["artists" "tracks"] }
def include-external-completer [] { ["audio"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-multiple-albums: "record<albums: table<album_type: string, available_markets: list, copyrights: list, external_ids: record, external_urls: record, genres: list, href: string, id: string, images: list, label: string, name: string, popularity: int, release_date: string, release_date_precision: string, restrictions: record, total_tracks: int, type: string, uri: string, artists: list, tracks: record>>"
    get-an-album: "record<album_type: string, available_markets: list<string>, copyrights: table<text: string, type: string>, external_ids: record<ean: string, isrc: string, upc: string>, external_urls: record<spotify: string>, genres: list<string>, href: string, id: string, images: table<height: int, url: string, width: int>, label: string, name: string, popularity: int, release_date: string, release_date_precision: string, restrictions: record<reason: string>, total_tracks: int, type: string, uri: string, artists: table<external_urls: record, followers: record, genres: list, href: string, id: string, images: list, name: string, popularity: int, type: string, uri: string>, tracks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>"
    get-an-albums-tracks: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<artists: list, available_markets: list, disc_number: int, duration_ms: int, explicit: bool, external_urls: record, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, preview_url: string, restrictions: record, track_number: int, type: string, uri: string>>"
    get-multiple-artists: "record<artists: table<external_urls: record, followers: record, genres: list, href: string, id: string, images: list, name: string, popularity: int, type: string, uri: string>>"
    get-an-artist: "record<external_urls: record<spotify: string>, followers: record<href: string, total: int>, genres: list<string>, href: string, id: string, images: table<height: int, url: string, width: int>, name: string, popularity: int, type: string, uri: string>"
    get-an-artists-albums: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<album_type: string, available_markets: list, copyrights: list, external_ids: record, external_urls: record, genres: list, href: string, id: string, images: list, label: string, name: string, popularity: int, release_date: string, release_date_precision: string, restrictions: record, total_tracks: int, type: string, uri: string, album_group: string, artists: list>>"
    get-an-artists-related-artists: "record<artists: table<external_urls: record, followers: record, genres: list, href: string, id: string, images: list, name: string, popularity: int, type: string, uri: string>>"
    get-an-artists-top-tracks: "record<tracks: table<album: record, artists: list, available_markets: list, disc_number: int, duration_ms: int, explicit: bool, external_ids: record, external_urls: record, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, popularity: int, preview_url: string, restrictions: record, track_number: int, type: string, uri: string>>"
    get-audio-analysis: "record<bars: table<confidence: float, duration: float, start: float>, beats: table<confidence: float, duration: float, start: float>, meta: record<analysis_time: float, analyzer_version: string, detailed_status: string, input_process: string, platform: string, status_code: int, timestamp: int>, sections: table<confidence: float, duration: float, key: int, key_confidence: float, loudness: float, mode: float, mode_confidence: float, start: float, tempo: float, tempo_confidence: float, time_signature: int, time_signature_confidence: float>, segments: table<confidence: float, duration: float, loudness_end: float, loudness_max: float, loudness_max_time: float, loudness_start: float, pitches: list, start: float, timbre: list>, tatums: table<confidence: float, duration: float, start: float>, track: record<analysis_channels: int, analysis_sample_rate: int, code_version: float, codestring: string, duration: float, echoprint_version: float, echoprintstring: string, end_of_fade_in: float, key: int, key_confidence: float, loudness: float, mode: int, mode_confidence: float, num_samples: int, offset_seconds: int, rhythm_version: float, rhythmstring: string, sample_md5: string, start_of_fade_out: float, synch_version: float, synchstring: string, tempo: float, tempo_confidence: float, time_signature: int, time_signature_confidence: float, window_seconds: int>>"
    get-several-audio-features: "record<audio_features: table<acousticness: float, analysis_url: string, danceability: float, duration_ms: int, energy: float, id: string, instrumentalness: float, key: int, liveness: float, loudness: float, mode: int, speechiness: float, tempo: float, time_signature: int, track_href: string, type: string, uri: string, valence: float>>"
    get-audio-features: "record<acousticness: float, analysis_url: string, danceability: float, duration_ms: int, energy: float, id: string, instrumentalness: float, key: int, liveness: float, loudness: float, mode: int, speechiness: float, tempo: float, time_signature: int, track_href: string, type: string, uri: string, valence: float>"
    get-multiple-audiobooks: "record<audiobooks: table<authors: list, available_markets: list, copyrights: list, description: string, edition: string, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, languages: list, media_type: string, name: string, narrators: list, publisher: string, total_chapters: int, type: string, uri: string, chapters: record>>"
    get-an-audiobook: "record<authors: table<name: string>, available_markets: list<string>, copyrights: table<text: string, type: string>, description: string, edition: string, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: table<height: int, url: string, width: int>, languages: list<string>, media_type: string, name: string, narrators: table<name: string>, publisher: string, total_chapters: int, type: string, uri: string, chapters: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>"
    get-audiobook-chapters: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<audio_preview_url: string, available_markets: list, chapter_number: int, description: string, duration_ms: int, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_playable: bool, languages: list, name: string, release_date: string, release_date_precision: string, restrictions: record, resume_point: record, type: string, uri: string>>"
    get-categories: "record<categories: record<href: string, limit: int, next: string, offset: int, previous: string, total: int>>"
    get-a-category: "record<href: string, icons: table<height: int, url: string, width: int>, id: string, name: string>"
    get-a-categories-playlists: "record<message: string, playlists: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>"
    get-featured-playlists: "record<message: string, playlists: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>"
    get-new-releases: "record<albums: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>"
    get-several-chapters: "record<chapters: table<audio_preview_url: string, available_markets: list, chapter_number: int, description: string, duration_ms: int, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_playable: bool, languages: list, name: string, release_date: string, release_date_precision: string, restrictions: record, resume_point: record, type: string, uri: string, audiobook: record>>"
    get-a-chapter: "record<audio_preview_url: string, available_markets: list<string>, chapter_number: int, description: string, duration_ms: int, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: table<height: int, url: string, width: int>, is_playable: bool, languages: list<string>, name: string, release_date: string, release_date_precision: string, restrictions: record<reason: string>, resume_point: record<fully_played: bool, resume_position_ms: int>, type: string, uri: string, audiobook: record<authors: list<record>, available_markets: list<string>, copyrights: list<record>, description: string, edition: string, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: list<record>, languages: list<string>, media_type: string, name: string, narrators: list<record>, publisher: string, total_chapters: int, type: string, uri: string>>"
    get-multiple-episodes: "record<episodes: table<audio_preview_url: string, description: string, duration_ms: int, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_externally_hosted: bool, is_playable: bool, language: string, languages: list, name: string, release_date: string, release_date_precision: string, restrictions: record, resume_point: record, type: string, uri: string, show: record>>"
    get-an-episode: "record<audio_preview_url: string, description: string, duration_ms: int, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: table<height: int, url: string, width: int>, is_externally_hosted: bool, is_playable: bool, language: string, languages: list<string>, name: string, release_date: string, release_date_precision: string, restrictions: record<reason: string>, resume_point: record<fully_played: bool, resume_position_ms: int>, type: string, uri: string, show: record<available_markets: list<string>, copyrights: list<record>, description: string, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: list<record>, is_externally_hosted: bool, languages: list<string>, media_type: string, name: string, publisher: string, total_episodes: int, type: string, uri: string>>"
    get-available-markets: "record<markets: list<string>>"
    get-current-users-profile: "record<country: string, display_name: string, email: string, explicit_content: record<filter_enabled: bool, filter_locked: bool>, external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, images: table<height: int, url: string, width: int>, product: string, type: string, uri: string>"
    get-users-saved-albums: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, album: record>>"
    check-users-saved-albums: "list<bool>"
    get-users-saved-audiobooks: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<authors: list, available_markets: list, copyrights: list, description: string, edition: string, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, languages: list, media_type: string, name: string, narrators: list, publisher: string, total_chapters: int, type: string, uri: string>>"
    check-users-saved-audiobooks: "list<bool>"
    get-users-saved-episodes: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, episode: record>>"
    check-users-saved-episodes: "list<bool>"
    get-followed: "record<artists: record<cursors: record<after: string, before: string>, href: string, limit: int, next: string, total: int, items: list<record>>>"
    check-current-user-follows: "list<bool>"
    get-information-about-the-users-current-playback: "record<actions: record<interrupting_playback: bool, pausing: bool, resuming: bool, seeking: bool, skipping_next: bool, skipping_prev: bool, toggling_repeat_context: bool, toggling_repeat_track: bool, toggling_shuffle: bool, transferring_playback: bool>, context: record<external_urls: record<spotify: string>, href: string, type: string, uri: string>, currently_playing_type: string, device: record<id: string, is_active: bool, is_private_session: bool, is_restricted: bool, name: string, type: string, volume_percent: int>, is_playing: bool, item: any, progress_ms: int, repeat_state: string, shuffle_state: bool, timestamp: int>"
    get-the-users-currently-playing-track: "record<actions: record<interrupting_playback: bool, pausing: bool, resuming: bool, seeking: bool, skipping_next: bool, skipping_prev: bool, toggling_repeat_context: bool, toggling_repeat_track: bool, toggling_shuffle: bool, transferring_playback: bool>, context: record<external_urls: record<spotify: string>, href: string, type: string, uri: string>, currently_playing_type: string, device: record<id: string, is_active: bool, is_private_session: bool, is_restricted: bool, name: string, type: string, volume_percent: int>, is_playing: bool, item: any, progress_ms: int, repeat_state: string, shuffle_state: bool, timestamp: int>"
    get-a-users-available-devices: "record<devices: table<id: string, is_active: bool, is_private_session: bool, is_restricted: bool, name: string, type: string, volume_percent: int>>"
    get-queue: "record<currently_playing: any, queue: list<any>>"
    get-recently-played: "record<cursors: record<after: string, before: string>, href: string, limit: int, next: string, total: int, items: table<context: record, played_at: string, track: record>>"
    get-a-list-of-current-users-playlists: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<collaborative: bool, description: string, external_urls: record, href: string, id: string, images: list, name: string, owner: record, public: bool, snapshot_id: string, tracks: record, type: string, uri: string>>"
    get-users-saved-shows: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, show: record>>"
    check-users-saved-shows: "list<bool>"
    get-users-top-artists-and-tracks: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>"
    get-users-saved-tracks: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, track: record>>"
    check-users-saved-tracks: "list<bool>"
    get-playlist: "record<collaborative: bool, description: string, external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, images: table<height: int, url: string, width: int>, name: string, owner: record<external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, type: string, uri: string, display_name: string>, public: bool, snapshot_id: string, tracks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, type: string, uri: string>"
    check-if-user-follows-playlist: "list<bool>"
    get-playlist-cover: "table<height: int, url: string, width: int>"
    remove-tracks-playlist: "record<snapshot_id: string>"
    get-playlists-tracks: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, added_by: record, is_local: bool, track: any>>"
    add-tracks-to-playlist: "record<snapshot_id: string>"
    reorder-or-replace-playlists-tracks: "record<snapshot_id: string>"
    get-recommendations: "record<seeds: table<afterFilteringSize: int, afterRelinkingSize: int, href: string, id: string, initialPoolSize: int, type: string>, tracks: table<album: record, artists: list, available_markets: list, disc_number: int, duration_ms: int, explicit: bool, external_ids: record, external_urls: record, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, popularity: int, preview_url: string, restrictions: record, track_number: int, type: string, uri: string>>"
    get-recommendation-genres: "record<genres: list<string>>"
    search: "record<albums: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, artists: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, audiobooks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, episodes: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, playlists: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, shows: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, tracks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>"
    get-multiple-shows: "record<shows: table<available_markets: list, copyrights: list, description: string, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_externally_hosted: bool, languages: list, media_type: string, name: string, publisher: string, total_episodes: int, type: string, uri: string>>"
    get-a-show: "record<available_markets: list<string>, copyrights: table<text: string, type: string>, description: string, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: table<height: int, url: string, width: int>, is_externally_hosted: bool, languages: list<string>, media_type: string, name: string, publisher: string, total_episodes: int, type: string, uri: string, episodes: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>"
    get-a-shows-episodes: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<audio_preview_url: string, description: string, duration_ms: int, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_externally_hosted: bool, is_playable: bool, language: string, languages: list, name: string, release_date: string, release_date_precision: string, restrictions: record, resume_point: record, type: string, uri: string>>"
    get-several-tracks: "record<tracks: table<album: record, artists: list, available_markets: list, disc_number: int, duration_ms: int, explicit: bool, external_ids: record, external_urls: record, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, popularity: int, preview_url: string, restrictions: record, track_number: int, type: string, uri: string>>"
    get-track: "record<album: record<album_type: string, available_markets: list<string>, copyrights: list<record>, external_ids: record<ean: string, isrc: string, upc: string>, external_urls: record<spotify: string>, genres: list<string>, href: string, id: string, images: list<record>, label: string, name: string, popularity: int, release_date: string, release_date_precision: string, restrictions: record<reason: string>, total_tracks: int, type: string, uri: string, album_group: string, artists: list<record>>, artists: table<external_urls: record, followers: record, genres: list, href: string, id: string, images: list, name: string, popularity: int, type: string, uri: string>, available_markets: list<string>, disc_number: int, duration_ms: int, explicit: bool, external_ids: record<ean: string, isrc: string, upc: string>, external_urls: record<spotify: string>, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, popularity: int, preview_url: string, restrictions: record<reason: string>, track_number: int, type: string, uri: string>"
    get-users-profile: "record<display_name: string, external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, images: table<height: int, url: string, width: int>, type: string, uri: string>"
    get-list-users-playlists: "record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<collaborative: bool, description: string, external_urls: record, href: string, id: string, images: list, name: string, owner: record, public: bool, snapshot_id: string, tracks: record, type: string, uri: string>>"
    create-playlist: "record<collaborative: bool, description: string, external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, images: table<height: int, url: string, width: int>, name: string, owner: record<external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, type: string, uri: string, display_name: string>, public: bool, snapshot_id: string, tracks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, type: string, uri: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-multiple-albums" "get-an-album" "get-an-albums-tracks" "get-multiple-artists" "get-an-artist" "get-an-artists-albums" "get-an-artists-related-artists" "get-an-artists-top-tracks" "get-audio-analysis" "get-several-audio-features" "get-audio-features" "get-multiple-audiobooks" "get-an-audiobook" "get-audiobook-chapters" "get-categories" "get-a-category" "get-a-categories-playlists" "get-featured-playlists" "get-new-releases" "get-several-chapters" "get-a-chapter" "get-multiple-episodes" "get-an-episode" "get-available-markets" "get-current-users-profile" "remove-albums-user" "get-users-saved-albums" "save-albums-user" "check-users-saved-albums" "remove-audiobooks-user" "get-users-saved-audiobooks" "save-audiobooks-user" "check-users-saved-audiobooks" "remove-episodes-user" "get-users-saved-episodes" "save-episodes-user" "check-users-saved-episodes" "unfollow-artists-users" "get-followed" "follow-artists-users" "check-current-user-follows" "get-information-about-the-users-current-playback" "transfer-a-users-playback" "get-the-users-currently-playing-track" "get-a-users-available-devices" "skip-users-playback-to-next-track" "pause-a-users-playback" "start-a-users-playback" "skip-users-playback-to-previous-track" "get-queue" "add-to-queue" "get-recently-played" "set-repeat-mode-on-users-playback" "seek-to-position-in-currently-playing-track" "toggle-shuffle-for-users-playback" "set-volume-for-users-playback" "get-a-list-of-current-users-playlists" "remove-shows-user" "get-users-saved-shows" "save-shows-user" "check-users-saved-shows" "get-users-top-artists-and-tracks" "remove-tracks-user" "get-users-saved-tracks" "save-tracks-user" "check-users-saved-tracks" "get-playlist" "change-playlist-details" "unfollow-playlist" "follow-playlist" "check-if-user-follows-playlist" "get-playlist-cover" "upload-custom-playlist-cover" "remove-tracks-playlist" "get-playlists-tracks" "add-tracks-to-playlist" "reorder-or-replace-playlists-tracks" "get-recommendations" "get-recommendation-genres" "search" "get-multiple-shows" "get-a-show" "get-a-shows-episodes" "get-several-tracks" "get-track" "get-users-profile" "get-list-users-playlists" "create-playlist" "commands"] | sort) } | get name | first)
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

# Get Several Albums
#
# GET /albums
# Returns: record<albums: table<album_type: string, available_markets: list, copyrights: list, external_ids: record, external_urls: record, genres: list, href: string, id: string, images: list, label: string, name: string, popularity: int, release_date: string, release_date_precision: string, restrictions: record, total_tracks: int, type: string, uri: string, artists: list, tracks: record>>
# operationId: get-multiple-albums
export def "get-multiple-albums" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 382ObEPsp2rxGrnsizN5TX,1A2GTWGtFfWp7KSQTwWOyo,2noRn2Aes5aoNVsU6iWThc
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/albums"
    query: [{name: ids, var: ids, required: true}, {name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Album
#
# GET /albums/{id}
# Returns: record<album_type: string, available_markets: list<string>, copyrights: table<text: string, type: string>, external_ids: record<ean: string, isrc: string, upc: string>, external_urls: record<spotify: string>, genres: list<string>, href: string, id: string, images: table<height: int, url: string, width: int>, label: string, name: string, popularity: int, release_date: string, release_date_precision: string, restrictions: record<reason: string>, total_tracks: int, type: string, uri: string, artists: table<external_urls: record, followers: record, genres: list, href: string, id: string, images: list, name: string, popularity: int, type: string, uri: string>, tracks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>
# operationId: get-an-album
export def "get-an-album" [
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
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/albums/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Album Tracks
#
# GET /albums/{id}/tracks
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<artists: list, available_markets: list, disc_number: int, duration_ms: int, explicit: bool, external_urls: record, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, preview_url: string, restrictions: record, track_number: int, type: string, uri: string>>
# operationId: get-an-albums-tracks
export def "get-an-albums-tracks" [
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
  --market: string # e.g. ES
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/albums/{id}/tracks"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Several Artists
#
# GET /artists
# Returns: record<artists: table<external_urls: record, followers: record, genres: list, href: string, id: string, images: list, name: string, popularity: int, type: string, uri: string>>
# operationId: get-multiple-artists
export def "get-multiple-artists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 2CIMQHirSU0MQqyYHq0eOx,57dN52uHvrHOxijzpIgu3E,1vCWHaC5f2uS3yhpwWbIA6
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/artists"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Artist
#
# GET /artists/{id}
# Returns: record<external_urls: record<spotify: string>, followers: record<href: string, total: int>, genres: list<string>, href: string, id: string, images: table<height: int, url: string, width: int>, name: string, popularity: int, type: string, uri: string>
# operationId: get-an-artist
export def "get-an-artist" [
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
    path: "/artists/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Artist's Albums
#
# GET /artists/{id}/albums
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<album_type: string, available_markets: list, copyrights: list, external_ids: record, external_urls: record, genres: list, href: string, id: string, images: list, label: string, name: string, popularity: int, release_date: string, release_date_precision: string, restrictions: record, total_tracks: int, type: string, uri: string, album_group: string, artists: list>>
# operationId: get-an-artists-albums
export def "get-an-artists-albums" [
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
  --include-groups: string # e.g. single,appears_on
  --market: string # e.g. ES
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/artists/{id}/albums"
    path_params: [{name: id, var: id}]
    query: [{name: include_groups, var: include_groups}, {name: market, var: market}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include_groups: $include_groups, market: $market, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Artist's Related Artists
#
# GET /artists/{id}/related-artists
# Returns: record<artists: table<external_urls: record, followers: record, genres: list, href: string, id: string, images: list, name: string, popularity: int, type: string, uri: string>>
# operationId: get-an-artists-related-artists
export def "get-an-artists-related-artists" [
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
    path: "/artists/{id}/related-artists"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Artist's Top Tracks
#
# GET /artists/{id}/top-tracks
# Returns: record<tracks: table<album: record, artists: list, available_markets: list, disc_number: int, duration_ms: int, explicit: bool, external_ids: record, external_urls: record, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, popularity: int, preview_url: string, restrictions: record, track_number: int, type: string, uri: string>>
# operationId: get-an-artists-top-tracks
export def "get-an-artists-top-tracks" [
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
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/artists/{id}/top-tracks"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Track's Audio Analysis
#
# GET /audio-analysis/{id}
# Returns: record<bars: table<confidence: float, duration: float, start: float>, beats: table<confidence: float, duration: float, start: float>, meta: record<analysis_time: float, analyzer_version: string, detailed_status: string, input_process: string, platform: string, status_code: int, timestamp: int>, sections: table<confidence: float, duration: float, key: int, key_confidence: float, loudness: float, mode: float, mode_confidence: float, start: float, tempo: float, tempo_confidence: float, time_signature: int, time_signature_confidence: float>, segments: table<confidence: float, duration: float, loudness_end: float, loudness_max: float, loudness_max_time: float, loudness_start: float, pitches: list, start: float, timbre: list>, tatums: table<confidence: float, duration: float, start: float>, track: record<analysis_channels: int, analysis_sample_rate: int, code_version: float, codestring: string, duration: float, echoprint_version: float, echoprintstring: string, end_of_fade_in: float, key: int, key_confidence: float, loudness: float, mode: int, mode_confidence: float, num_samples: int, offset_seconds: int, rhythm_version: float, rhythmstring: string, sample_md5: string, start_of_fade_out: float, synch_version: float, synchstring: string, tempo: float, tempo_confidence: float, time_signature: int, time_signature_confidence: float, window_seconds: int>>
# operationId: get-audio-analysis
export def "get-audio-analysis" [
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
    path: "/audio-analysis/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tracks' Audio Features
#
# GET /audio-features
# Returns: record<audio_features: table<acousticness: float, analysis_url: string, danceability: float, duration_ms: int, energy: float, id: string, instrumentalness: float, key: int, liveness: float, loudness: float, mode: int, speechiness: float, tempo: float, time_signature: int, track_href: string, type: string, uri: string, valence: float>>
# operationId: get-several-audio-features
export def "get-several-audio-features" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 7ouMYWpwJ422jRcDASZB7P,4VqPOruhp5EdPBeR92t6lQ,2takcwOaAZWiXQijPHIx7B
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audio-features"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Track's Audio Features
#
# GET /audio-features/{id}
# Returns: record<acousticness: float, analysis_url: string, danceability: float, duration_ms: int, energy: float, id: string, instrumentalness: float, key: int, liveness: float, loudness: float, mode: int, speechiness: float, tempo: float, time_signature: int, track_href: string, type: string, uri: string, valence: float>
# operationId: get-audio-features
export def "get-audio-features" [
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
    path: "/audio-features/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Several Audiobooks
#
# GET /audiobooks
# Returns: record<audiobooks: table<authors: list, available_markets: list, copyrights: list, description: string, edition: string, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, languages: list, media_type: string, name: string, narrators: list, publisher: string, total_chapters: int, type: string, uri: string, chapters: record>>
# operationId: get-multiple-audiobooks
export def "get-multiple-audiobooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 18yVqkdbdRvS24c0Ilj2ci,1HGw3J3NxZO1TP1BTtVhpZ,7iHfbu1YPACw6oZPAFJtqe
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audiobooks"
    query: [{name: ids, var: ids, required: true}, {name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Audiobook
#
# GET /audiobooks/{id}
# Returns: record<authors: table<name: string>, available_markets: list<string>, copyrights: table<text: string, type: string>, description: string, edition: string, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: table<height: int, url: string, width: int>, languages: list<string>, media_type: string, name: string, narrators: table<name: string>, publisher: string, total_chapters: int, type: string, uri: string, chapters: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>
# operationId: get-an-audiobook
export def "get-an-audiobook" [
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
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audiobooks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Audiobook Chapters
#
# GET /audiobooks/{id}/chapters
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<audio_preview_url: string, available_markets: list, chapter_number: int, description: string, duration_ms: int, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_playable: bool, languages: list, name: string, release_date: string, release_date_precision: string, restrictions: record, resume_point: record, type: string, uri: string>>
# operationId: get-audiobook-chapters
export def "get-audiobook-chapters" [
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
  --market: string # e.g. ES
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/audiobooks/{id}/chapters"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Several Browse Categories
#
# GET /browse/categories
# Returns: record<categories: record<href: string, limit: int, next: string, offset: int, previous: string, total: int>>
# operationId: get-categories
export def "get-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # e.g. SE
  --locale: string # e.g. sv_SE
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browse/categories"
    query: [{name: country, var: country}, {name: locale, var: locale}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, locale: $locale, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Single Browse Category
#
# GET /browse/categories/{category_id}
# Returns: record<href: string, icons: table<height: int, url: string, width: int>, id: string, name: string>
# operationId: get-a-category
export def "get-a-category" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # e.g. SE
  --locale: string # e.g. sv_SE
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browse/categories/{category_id}"
    path_params: [{name: category_id, var: category_id}]
    query: [{name: country, var: country}, {name: locale, var: locale}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_id: $category_id, country: $country, locale: $locale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Category's Playlists
#
# GET /browse/categories/{category_id}/playlists
# Returns: record<message: string, playlists: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>
# operationId: get-a-categories-playlists
export def "get-a-categories-playlists" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # e.g. SE
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browse/categories/{category_id}/playlists"
    path_params: [{name: category_id, var: category_id}]
    query: [{name: country, var: country}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category_id: $category_id, country: $country, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Featured Playlists
#
# GET /browse/featured-playlists
# Returns: record<message: string, playlists: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>
# operationId: get-featured-playlists
export def "get-featured-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # e.g. SE
  --locale: string # e.g. sv_SE
  --timestamp: string # e.g. 2014-10-23T09:00:00
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browse/featured-playlists"
    query: [{name: country, var: country}, {name: locale, var: locale}, {name: timestamp, var: timestamp}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, locale: $locale, timestamp: $timestamp, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get New Releases
#
# GET /browse/new-releases
# Returns: record<albums: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>
# operationId: get-new-releases
export def "get-new-releases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # e.g. SE
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/browse/new-releases"
    query: [{name: country, var: country}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    country: $country, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Several Chapters
#
# GET /chapters
# Returns: record<chapters: table<audio_preview_url: string, available_markets: list, chapter_number: int, description: string, duration_ms: int, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_playable: bool, languages: list, name: string, release_date: string, release_date_precision: string, restrictions: record, resume_point: record, type: string, uri: string, audiobook: record>>
# operationId: get-several-chapters
export def "get-several-chapters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 0IsXVP0JmcB2adSE338GkK,3ZXb8FKZGU0EHALYX6uCzU,0D5wENdkdwbqlrHoaJ9g29
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chapters"
    query: [{name: ids, var: ids, required: true}, {name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a Chapter
#
# GET /chapters/{id}
# Returns: record<audio_preview_url: string, available_markets: list<string>, chapter_number: int, description: string, duration_ms: int, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: table<height: int, url: string, width: int>, is_playable: bool, languages: list<string>, name: string, release_date: string, release_date_precision: string, restrictions: record<reason: string>, resume_point: record<fully_played: bool, resume_position_ms: int>, type: string, uri: string, audiobook: record<authors: list<record>, available_markets: list<string>, copyrights: list<record>, description: string, edition: string, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: list<record>, languages: list<string>, media_type: string, name: string, narrators: list<record>, publisher: string, total_chapters: int, type: string, uri: string>>
# operationId: get-a-chapter
export def "get-a-chapter" [
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
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/chapters/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Several Episodes
#
# GET /episodes
# Returns: record<episodes: table<audio_preview_url: string, description: string, duration_ms: int, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_externally_hosted: bool, is_playable: bool, language: string, languages: list, name: string, release_date: string, release_date_precision: string, restrictions: record, resume_point: record, type: string, uri: string, show: record>>
# operationId: get-multiple-episodes
export def "get-multiple-episodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 77o6BIVlYM3msb4MMIL1jH,0Q86acNRm6V9GYx55SXKwf
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/episodes"
    query: [{name: ids, var: ids, required: true}, {name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Episode
#
# GET /episodes/{id}
# Returns: record<audio_preview_url: string, description: string, duration_ms: int, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: table<height: int, url: string, width: int>, is_externally_hosted: bool, is_playable: bool, language: string, languages: list<string>, name: string, release_date: string, release_date_precision: string, restrictions: record<reason: string>, resume_point: record<fully_played: bool, resume_position_ms: int>, type: string, uri: string, show: record<available_markets: list<string>, copyrights: list<record>, description: string, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: list<record>, is_externally_hosted: bool, languages: list<string>, media_type: string, name: string, publisher: string, total_episodes: int, type: string, uri: string>>
# operationId: get-an-episode
export def "get-an-episode" [
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
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/episodes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Available Markets
#
# GET /markets
# Returns: record<markets: list<string>>
# operationId: get-available-markets
export def "get-available-markets" [
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
    path: "/markets"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Current User's Profile
#
# GET /me
# Returns: record<country: string, display_name: string, email: string, explicit_content: record<filter_enabled: bool, filter_locked: bool>, external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, images: table<height: int, url: string, width: int>, product: string, type: string, uri: string>
# operationId: get-current-users-profile
export def "get-current-users-profile" [
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
    path: "/me"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Users' Saved Albums
#
# DELETE /me/albums
# operationId: remove-albums-user
export def "remove-albums-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 382ObEPsp2rxGrnsizN5TX,1A2GTWGtFfWp7KSQTwWOyo,2noRn2Aes5aoNVsU6iWThc
  --body-ids: list<string> # A JSON array of the [Spotify IDs](/documentation/web-api/#spotify-uris-and-ids). For example: `["4iV5W9uYEdYUVa79Axb7Rh", "1301WleyT98MSxVHPZCA6M"]`A maximum of 50 items can be specified in one request. _**Note**: if the `ids` parameter is present in the query string, any IDs listed here in the body will be ignored._ (spec name: ids)
]: any -> any {
  $in | http-request {
    method: delete
    path: "/me/albums"
    query: [{name: ids, var: ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: body_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, body_ids: $body_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User's Saved Albums
#
# GET /me/albums
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, album: record>>
# operationId: get-users-saved-albums
export def "get-users-saved-albums" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/albums"
    query: [{name: limit, var: limit}, {name: offset, var: offset}, {name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save Albums for Current User
#
# PUT /me/albums
# operationId: save-albums-user
export def "save-albums-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 382ObEPsp2rxGrnsizN5TX,1A2GTWGtFfWp7KSQTwWOyo,2noRn2Aes5aoNVsU6iWThc
  --body-ids: list<string> # A JSON array of the [Spotify IDs](/documentation/web-api/#spotify-uris-and-ids). For example: `["4iV5W9uYEdYUVa79Axb7Rh", "1301WleyT98MSxVHPZCA6M"]`A maximum of 50 items can be specified in one request. _**Note**: if the `ids` parameter is present in the query string, any IDs listed here in the body will be ignored._ (spec name: ids)
]: any -> any {
  $in | http-request {
    method: put
    path: "/me/albums"
    query: [{name: ids, var: ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: body_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, body_ids: $body_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check User's Saved Albums
#
# GET /me/albums/contains
# Returns: list<bool>
# operationId: check-users-saved-albums
export def "check-users-saved-albums" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 382ObEPsp2rxGrnsizN5TX,1A2GTWGtFfWp7KSQTwWOyo,2noRn2Aes5aoNVsU6iWThc
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/albums/contains"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove User's Saved Audiobooks
#
# DELETE /me/audiobooks
# operationId: remove-audiobooks-user
export def "remove-audiobooks-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 18yVqkdbdRvS24c0Ilj2ci,1HGw3J3NxZO1TP1BTtVhpZ,7iHfbu1YPACw6oZPAFJtqe
]: nothing -> any {
  http-request {
    method: delete
    path: "/me/audiobooks"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User's Saved Audiobooks
#
# GET /me/audiobooks
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<authors: list, available_markets: list, copyrights: list, description: string, edition: string, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, languages: list, media_type: string, name: string, narrators: list, publisher: string, total_chapters: int, type: string, uri: string>>
# operationId: get-users-saved-audiobooks
export def "get-users-saved-audiobooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/audiobooks"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save Audiobooks for Current User
#
# PUT /me/audiobooks
# operationId: save-audiobooks-user
export def "save-audiobooks-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 18yVqkdbdRvS24c0Ilj2ci,1HGw3J3NxZO1TP1BTtVhpZ,7iHfbu1YPACw6oZPAFJtqe
]: nothing -> any {
  http-request {
    method: put
    path: "/me/audiobooks"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check User's Saved Audiobooks
#
# GET /me/audiobooks/contains
# Returns: list<bool>
# operationId: check-users-saved-audiobooks
export def "check-users-saved-audiobooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 18yVqkdbdRvS24c0Ilj2ci,1HGw3J3NxZO1TP1BTtVhpZ,7iHfbu1YPACw6oZPAFJtqe
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/audiobooks/contains"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove User's Saved Episodes
#
# DELETE /me/episodes
# operationId: remove-episodes-user
export def "remove-episodes-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 7ouMYWpwJ422jRcDASZB7P,4VqPOruhp5EdPBeR92t6lQ,2takcwOaAZWiXQijPHIx7B
  --body-ids: list<string> # A JSON array of the [Spotify IDs](/documentation/web-api/#spotify-uris-and-ids). A maximum of 50 items can be specified in one request. _**Note**: if the `ids` parameter is present in the query string, any IDs listed here in the body will be ignored._ (spec name: ids)
]: any -> any {
  $in | http-request {
    method: delete
    path: "/me/episodes"
    query: [{name: ids, var: ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: body_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, body_ids: $body_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User's Saved Episodes
#
# GET /me/episodes
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, episode: record>>
# operationId: get-users-saved-episodes
export def "get-users-saved-episodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market: string # e.g. ES
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/episodes"
    query: [{name: market, var: market}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    market: $market, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save Episodes for Current User
#
# PUT /me/episodes
# operationId: save-episodes-user
export def "save-episodes-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 77o6BIVlYM3msb4MMIL1jH,0Q86acNRm6V9GYx55SXKwf
  --body-ids: list<string> # A JSON array of the [Spotify IDs](/documentation/web-api/#spotify-uris-and-ids). A maximum of 50 items can be specified in one request. _**Note**: if the `ids` parameter is present in the query string, any IDs listed here in the body will be ignored._ (spec name: ids)
]: any -> any {
  $in | http-request {
    method: put
    path: "/me/episodes"
    query: [{name: ids, var: ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: body_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, body_ids: $body_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check User's Saved Episodes
#
# GET /me/episodes/contains
# Returns: list<bool>
# operationId: check-users-saved-episodes
export def "check-users-saved-episodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 77o6BIVlYM3msb4MMIL1jH,0Q86acNRm6V9GYx55SXKwf
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/episodes/contains"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow Artists or Users
#
# DELETE /me/following
# operationId: unfollow-artists-users
export def "unfollow-artists-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # required, e.g. artist
  --ids: string # required, e.g. 2CIMQHirSU0MQqyYHq0eOx,57dN52uHvrHOxijzpIgu3E,1vCWHaC5f2uS3yhpwWbIA6
  --body-ids: list<string> # A JSON array of the artist or user [Spotify IDs](/documentation/web-api/#spotify-uris-and-ids). For example: `{ids:["74ASZWbe4lXaubB36ztrGX", "08td7MxkoHQkXnWAYD8d6Q"]}`. A maximum of 50 IDs can be sent in one request. _**Note**: if the `ids` parameter is present in the query string, any IDs listed here in the body will be ignored._ (spec name: ids)
]: any -> any {
  $in | http-request {
    method: delete
    path: "/me/following"
    query: [{name: type, var: type, required: true}, {name: ids, var: ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: body_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, ids: $ids, body_ids: $body_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Followed Artists
#
# GET /me/following
# Returns: record<artists: record<cursors: record<after: string, before: string>, href: string, limit: int, next: string, total: int, items: list<record>>>
# operationId: get-followed
export def "get-followed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # required, e.g. artist
  --after: string # e.g. 0I2XqVXqHScXjHhk6AYYRe
  --limit: int # default: 20, e.g. 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/following"
    query: [{name: type, var: type, required: true, default: artist}, {name: after, var: after}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, after: $after, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow Artists or Users
#
# PUT /me/following
# operationId: follow-artists-users
export def "follow-artists-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # required, e.g. artist
  --ids: string # required, e.g. 2CIMQHirSU0MQqyYHq0eOx,57dN52uHvrHOxijzpIgu3E,1vCWHaC5f2uS3yhpwWbIA6
  --body-ids: list<string> # A JSON array of the artist or user [Spotify IDs](/documentation/web-api/#spotify-uris-and-ids). For example: `{ids:["74ASZWbe4lXaubB36ztrGX", "08td7MxkoHQkXnWAYD8d6Q"]}`. A maximum of 50 IDs can be sent in one request. _**Note**: if the `ids` parameter is present in the query string, any IDs listed here in the body will be ignored._ (spec name: ids)
]: any -> any {
  $in | http-request {
    method: put
    path: "/me/following"
    query: [{name: type, var: type, required: true}, {name: ids, var: ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: body_ids, required: true}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    type: $type, ids: $ids, body_ids: $body_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check If User Follows Artists or Users
#
# GET /me/following/contains
# Returns: list<bool>
# operationId: check-current-user-follows
export def "check-current-user-follows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # required, e.g. artist
  --ids: string # required, e.g. 2CIMQHirSU0MQqyYHq0eOx,57dN52uHvrHOxijzpIgu3E,1vCWHaC5f2uS3yhpwWbIA6
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/following/contains"
    query: [{name: type, var: type, required: true}, {name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Playback State
#
# GET /me/player
# Returns: record<actions: record<interrupting_playback: bool, pausing: bool, resuming: bool, seeking: bool, skipping_next: bool, skipping_prev: bool, toggling_repeat_context: bool, toggling_repeat_track: bool, toggling_shuffle: bool, transferring_playback: bool>, context: record<external_urls: record<spotify: string>, href: string, type: string, uri: string>, currently_playing_type: string, device: record<id: string, is_active: bool, is_private_session: bool, is_restricted: bool, name: string, type: string, volume_percent: int>, is_playing: bool, item: any, progress_ms: int, repeat_state: string, shuffle_state: bool, timestamp: int>
# operationId: get-information-about-the-users-current-playback
export def "get-information-about-the-users-current-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market: string # e.g. ES
  --additional-types: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/player"
    query: [{name: market, var: market}, {name: additional_types, var: additional_types}]
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    market: $market, additional_types: $additional_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer Playback
#
# PUT /me/player
# operationId: transfer-a-users-playback
export def "transfer-a-users-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  device_ids: list<string> # A JSON array containing the ID of the device on which playback should be started/transferred.For example:`{device_ids:["74ASZWbe4lXaubB36ztrGX"]}`_**Note**: Although an array is accepted, only a single device_id is currently supported. Supplying more than one will return `400 Bad Request`_
  --play: oneof<nothing, bool> # **true**: ensure playback happens on new device.**false** or not provided: keep the current playback state.
]: any -> any {
  $in | http-request {
    method: put
    path: "/me/player"
    body: {content_type: "application/json", kind: json, fields: [{name: device_ids, var: device_ids}, {name: play, var: play}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    device_ids: $device_ids, play: $play
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Currently Playing Track
#
# GET /me/player/currently-playing
# Returns: record<actions: record<interrupting_playback: bool, pausing: bool, resuming: bool, seeking: bool, skipping_next: bool, skipping_prev: bool, toggling_repeat_context: bool, toggling_repeat_track: bool, toggling_shuffle: bool, transferring_playback: bool>, context: record<external_urls: record<spotify: string>, href: string, type: string, uri: string>, currently_playing_type: string, device: record<id: string, is_active: bool, is_private_session: bool, is_restricted: bool, name: string, type: string, volume_percent: int>, is_playing: bool, item: any, progress_ms: int, repeat_state: string, shuffle_state: bool, timestamp: int>
# operationId: get-the-users-currently-playing-track
export def "get-the-users-currently-playing-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market: string # e.g. ES
  --additional-types: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/player/currently-playing"
    query: [{name: market, var: market}, {name: additional_types, var: additional_types}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    market: $market, additional_types: $additional_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Available Devices
#
# GET /me/player/devices
# Returns: record<devices: table<id: string, is_active: bool, is_private_session: bool, is_restricted: bool, name: string, type: string, volume_percent: int>>
# operationId: get-a-users-available-devices
export def "get-a-users-available-devices" [
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
    path: "/me/player/devices"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Skip To Next
#
# POST /me/player/next
# operationId: skip-users-playback-to-next-track
export def "skip-users-playback-to-next-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
]: nothing -> any {
  http-request {
    method: post
    path: "/me/player/next"
    query: [{name: device_id, var: device_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Pause Playback
#
# PUT /me/player/pause
# operationId: pause-a-users-playback
export def "pause-a-users-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
]: nothing -> any {
  http-request {
    method: put
    path: "/me/player/pause"
    query: [{name: device_id, var: device_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start/Resume Playback
#
# PUT /me/player/play
# operationId: start-a-users-playback
export def "start-a-users-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
  --context-uri: string # Optional. Spotify URI of the context to play. Valid contexts are albums, artists & playlists. `{context_uri:"spotify:album:1Je1IMUlBXcx1Fz0WE7oPT"}`
  --offset: record # Optional. Indicates from where in the context playback should start. Only available when context_uri corresponds to an album or playlist object "position" is zero based and can’t be negative. Example: `"offset": {"position": 5}` "uri" is a string representing the uri of the item to start at. Example: `"offset": {"uri": "spotify:track:1301WleyT98MSxVHPZCA6M"}`
  --position-ms: int # integer
  --uris: list<string> # Optional. A JSON array of the Spotify track URIs to play. For example: `{"uris": ["spotify:track:4iV5W9uYEdYUVa79Axb7Rh", "spotify:track:1301WleyT98MSxVHPZCA6M"]}`
]: any -> any {
  $in | http-request {
    method: put
    path: "/me/player/play"
    query: [{name: device_id, var: device_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: context_uri, var: context_uri}, {name: offset, var: offset}, {name: position_ms, var: position_ms}, {name: uris, var: uris}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    device_id: $device_id, context_uri: $context_uri, offset: $offset, position_ms: $position_ms, uris: $uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Skip To Previous
#
# POST /me/player/previous
# operationId: skip-users-playback-to-previous-track
export def "skip-users-playback-to-previous-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
]: nothing -> any {
  http-request {
    method: post
    path: "/me/player/previous"
    query: [{name: device_id, var: device_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the User's Queue
#
# GET /me/player/queue
# Returns: record<currently_playing: any, queue: list<any>>
# operationId: get-queue
export def "get-queue" [
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
    path: "/me/player/queue"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Item to Playback Queue
#
# POST /me/player/queue
# operationId: add-to-queue
export def "add-to-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uri: string # required, e.g. spotify:track:4iV5W9uYEdYUVa79Axb7Rh
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
]: nothing -> any {
  http-request {
    method: post
    path: "/me/player/queue"
    query: [{name: uri, var: uri, required: true}, {name: device_id, var: device_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    uri: $uri, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Recently Played Tracks
#
# GET /me/player/recently-played
# Returns: record<cursors: record<after: string, before: string>, href: string, limit: int, next: string, total: int, items: table<context: record, played_at: string, track: record>>
# operationId: get-recently-played
export def "get-recently-played" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20, e.g. 10
  --after: int # e.g. 1484811043508
  --before: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/player/recently-played"
    query: [{name: limit, var: limit}, {name: after, var: after}, {name: before, var: before}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, after: $after, before: $before
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Repeat Mode
#
# PUT /me/player/repeat
# operationId: set-repeat-mode-on-users-playback
export def "set-repeat-mode-on-users-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # required, e.g. context
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
]: nothing -> any {
  http-request {
    method: put
    path: "/me/player/repeat"
    query: [{name: state, var: state, required: true}, {name: device_id, var: device_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    state: $state, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Seek To Position
#
# PUT /me/player/seek
# operationId: seek-to-position-in-currently-playing-track
export def "seek-to-position-in-currently-playing-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position-ms: int # required, e.g. 25000
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
]: nothing -> any {
  http-request {
    method: put
    path: "/me/player/seek"
    query: [{name: position_ms, var: position_ms, required: true}, {name: device_id, var: device_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    position_ms: $position_ms, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Toggle Playback Shuffle
#
# PUT /me/player/shuffle
# operationId: toggle-shuffle-for-users-playback
export def "toggle-shuffle-for-users-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: oneof<nothing, bool> # required, e.g. true
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
]: nothing -> any {
  http-request {
    method: put
    path: "/me/player/shuffle"
    query: [{name: state, var: state, required: true}, {name: device_id, var: device_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    state: $state, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Playback Volume
#
# PUT /me/player/volume
# operationId: set-volume-for-users-playback
export def "set-volume-for-users-playback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --volume-percent: int # required, e.g. 50
  --device-id: string # e.g. 0d1841b0976bae2a3a310dd74c0f3df354899bc8
]: nothing -> any {
  http-request {
    method: put
    path: "/me/player/volume"
    query: [{name: volume_percent, var: volume_percent, required: true}, {name: device_id, var: device_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    volume_percent: $volume_percent, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Current User's Playlists
#
# GET /me/playlists
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<collaborative: bool, description: string, external_urls: record, href: string, id: string, images: list, name: string, owner: record, public: bool, snapshot_id: string, tracks: record, type: string, uri: string>>
# operationId: get-a-list-of-current-users-playlists
export def "get-a-list-of-current-users-playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/playlists"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove User's Saved Shows
#
# DELETE /me/shows
# operationId: remove-shows-user
export def "remove-shows-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 5CfCWKI5pZ28U0uOzXkDHe,5as3aKmN2k11yfDDDSrvaZ
  --market: string # e.g. ES
]: nothing -> any {
  http-request {
    method: delete
    path: "/me/shows"
    query: [{name: ids, var: ids, required: true}, {name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User's Saved Shows
#
# GET /me/shows
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, show: record>>
# operationId: get-users-saved-shows
export def "get-users-saved-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/shows"
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save Shows for Current User
#
# PUT /me/shows
# operationId: save-shows-user
export def "save-shows-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 5CfCWKI5pZ28U0uOzXkDHe,5as3aKmN2k11yfDDDSrvaZ
]: nothing -> any {
  http-request {
    method: put
    path: "/me/shows"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check User's Saved Shows
#
# GET /me/shows/contains
# Returns: list<bool>
# operationId: check-users-saved-shows
export def "check-users-saved-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 5CfCWKI5pZ28U0uOzXkDHe,5as3aKmN2k11yfDDDSrvaZ
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/shows/contains"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User's Top Items
#
# GET /me/top/{type}
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>
# operationId: get-users-top-artists-and-tracks
export def "get-users-top-artists-and-tracks" [
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
  --time-range: string # default: medium_term, e.g. medium_term
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/top/{type}"
    path_params: [{name: type, var: type}]
    query: [{name: time_range, var: time_range}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, time_range: $time_range, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove User's Saved Tracks
#
# DELETE /me/tracks
# operationId: remove-tracks-user
export def "remove-tracks-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 7ouMYWpwJ422jRcDASZB7P,4VqPOruhp5EdPBeR92t6lQ,2takcwOaAZWiXQijPHIx7B
  --body-ids: list<string> # A JSON array of the [Spotify IDs](/documentation/web-api/#spotify-uris-and-ids). For example: `["4iV5W9uYEdYUVa79Axb7Rh", "1301WleyT98MSxVHPZCA6M"]`A maximum of 50 items can be specified in one request. _**Note**: if the `ids` parameter is present in the query string, any IDs listed here in the body will be ignored._ (spec name: ids)
]: any -> any {
  $in | http-request {
    method: delete
    path: "/me/tracks"
    query: [{name: ids, var: ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: body_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, body_ids: $body_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User's Saved Tracks
#
# GET /me/tracks
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, track: record>>
# operationId: get-users-saved-tracks
export def "get-users-saved-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market: string # e.g. ES
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/tracks"
    query: [{name: market, var: market}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    market: $market, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save Tracks for Current User
#
# PUT /me/tracks
# operationId: save-tracks-user
export def "save-tracks-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 7ouMYWpwJ422jRcDASZB7P,4VqPOruhp5EdPBeR92t6lQ,2takcwOaAZWiXQijPHIx7B
  --body-ids: list<string> # A JSON array of the [Spotify IDs](/documentation/web-api/#spotify-uris-and-ids). For example: `["4iV5W9uYEdYUVa79Axb7Rh", "1301WleyT98MSxVHPZCA6M"]`A maximum of 50 items can be specified in one request. _**Note**: if the `ids` parameter is present in the query string, any IDs listed here in the body will be ignored._ (spec name: ids)
]: any -> any {
  $in | http-request {
    method: put
    path: "/me/tracks"
    query: [{name: ids, var: ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ids, var: body_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids, body_ids: $body_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check User's Saved Tracks
#
# GET /me/tracks/contains
# Returns: list<bool>
# operationId: check-users-saved-tracks
export def "check-users-saved-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. 7ouMYWpwJ422jRcDASZB7P,4VqPOruhp5EdPBeR92t6lQ,2takcwOaAZWiXQijPHIx7B
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/me/tracks/contains"
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Playlist
#
# GET /playlists/{playlist_id}
# Returns: record<collaborative: bool, description: string, external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, images: table<height: int, url: string, width: int>, name: string, owner: record<external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, type: string, uri: string, display_name: string>, public: bool, snapshot_id: string, tracks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, type: string, uri: string>
# operationId: get-playlist
export def "get-playlist" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market: string # e.g. ES
  --fields: string # e.g. items(added_by.id,track(name,href,album(name,href)))
  --additional-types: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    query: [{name: market, var: market}, {name: fields, var: fields}, {name: additional_types, var: additional_types}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, market: $market, fields: $fields, additional_types: $additional_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change Playlist Details
#
# PUT /playlists/{playlist_id}
# operationId: change-playlist-details
export def "change-playlist-details" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collaborative: oneof<nothing, bool> # If `true`, the playlist will become collaborative and other users will be able to modify the playlist in their Spotify client. _**Note**: You can only set `collaborative` to `true` on non-public playlists._
  --description: string # Value for playlist description as displayed in Spotify Clients and in the Web API.
  --name: string # The new name for the playlist, for example `"My New Playlist Title"`
  --public: oneof<nothing, bool> # If `true` the playlist will be public, if `false` it will be private.
]: any -> any {
  $in | http-request {
    method: put
    path: "/playlists/{playlist_id}"
    path_params: [{name: playlist_id, var: playlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: collaborative, var: collaborative}, {name: description, var: description}, {name: name, var: name}, {name: public, var: public}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, collaborative: $collaborative, description: $description, name: $name, public: $public
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unfollow Playlist
#
# DELETE /playlists/{playlist_id}/followers
# operationId: unfollow-playlist
export def "unfollow-playlist" [
  playlist_id: string
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
    path: "/playlists/{playlist_id}/followers"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Follow Playlist
#
# PUT /playlists/{playlist_id}/followers
# operationId: follow-playlist
export def "follow-playlist" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --public: oneof<nothing, bool> # Defaults to `true`. If `true` the playlist will be included in user's public playlists, if `false` it will remain private.
]: any -> any {
  $in | http-request {
    method: put
    path: "/playlists/{playlist_id}/followers"
    path_params: [{name: playlist_id, var: playlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: public, var: public}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, public: $public
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Check if Users Follow Playlist
#
# GET /playlists/{playlist_id}/followers/contains
# Returns: list<bool>
# operationId: check-if-user-follows-playlist
export def "check-if-user-follows-playlist" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # required, e.g. jmperezperez,thelinmichael,wizzler
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/playlists/{playlist_id}/followers/contains"
    path_params: [{name: playlist_id, var: playlist_id}]
    query: [{name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Playlist Cover Image
#
# GET /playlists/{playlist_id}/images
# Returns: table<height: int, url: string, width: int>
# operationId: get-playlist-cover
export def "get-playlist-cover" [
  playlist_id: string
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
    path: "/playlists/{playlist_id}/images"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Custom Playlist Cover Image
#
# PUT /playlists/{playlist_id}/images
# operationId: upload-custom-playlist-cover
export def "upload-custom-playlist-cover" [
  playlist_id: string
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
    path: "/playlists/{playlist_id}/images"
    path_params: [{name: playlist_id, var: playlist_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove Playlist Items
#
# DELETE /playlists/{playlist_id}/tracks
# Returns: record<snapshot_id: string>
# operationId: remove-tracks-playlist
export def "remove-tracks-playlist" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-id: string # The playlist's snapshot ID against which you want to make the changes. The API will validate that the specified items exist and in the specified positions and make the changes, even if more recent changes have been made to the playlist.
  tracks: list # An array of objects containing [Spotify URIs](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) of the tracks or episodes to remove. For example: `{ "tracks": [{ "uri": "spotify:track:4iV5W9uYEdYUVa79Axb7Rh" },{ "uri": "spotify:track:1301WleyT98MSxVHPZCA6M" }] }`. A maximum of 100 objects can be sent at once. — item shape: {uri?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/playlists/{playlist_id}/tracks"
    path_params: [{name: playlist_id, var: playlist_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: snapshot_id, var: snapshot_id}, {name: tracks, var: tracks}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, snapshot_id: $snapshot_id, tracks: $tracks
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Playlist Items
#
# GET /playlists/{playlist_id}/tracks
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<added_at: string, added_by: record, is_local: bool, track: any>>
# operationId: get-playlists-tracks
export def "get-playlists-tracks" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market: string # e.g. ES
  --fields: string # e.g. items(added_by.id,track(name,href,album(name,href)))
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
  --additional-types: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/playlists/{playlist_id}/tracks"
    path_params: [{name: playlist_id, var: playlist_id}]
    query: [{name: market, var: market}, {name: fields, var: fields}, {name: limit, var: limit}, {name: offset, var: offset}, {name: additional_types, var: additional_types}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, market: $market, fields: $fields, limit: $limit, offset: $offset, additional_types: $additional_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Items to Playlist
#
# POST /playlists/{playlist_id}/tracks
# Returns: record<snapshot_id: string>
# operationId: add-tracks-to-playlist
export def "add-tracks-to-playlist" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: int # e.g. 0
  --uris: string # e.g. spotify:track:4iV5W9uYEdYUVa79Axb7Rh,spotify:track:1301WleyT98MSxVHPZCA6M
  --body-position: int # The position to insert the items, a zero-based index. For example, to insert the items in the first position: `position=0` ; to insert the items in the third position: `position=2`. If omitted, the items will be appended to the playlist. Items are added in the order they appear in the uris array. For example: `{"uris": ["spotify:track:4iV5W9uYEdYUVa79Axb7Rh","spotify:track:1301WleyT98MSxVHPZCA6M"], "position": 3}` (spec name: position)
  --body-uris: list<string> # A JSON array of the [Spotify URIs](/documentation/web-api/#spotify-uris-and-ids) to add. For example: `{"uris": ["spotify:track:4iV5W9uYEdYUVa79Axb7Rh","spotify:track:1301WleyT98MSxVHPZCA6M", "spotify:episode:512ojhOuo1ktJprKbVcKyQ"]}`A maximum of 100 items can be added in one request. _**Note**: if the `uris` parameter is present in the query string, any URIs listed here in the body will be ignored._ (spec name: uris)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/playlists/{playlist_id}/tracks"
    path_params: [{name: playlist_id, var: playlist_id}]
    query: [{name: position, var: position}, {name: uris, var: uris}]
    body: {content_type: "application/json", kind: json, fields: [{name: position, var: body_position}, {name: uris, var: body_uris}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    playlist_id: $playlist_id, position: $position, uris: $uris, body_position: $body_position, body_uris: $body_uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Playlist Items
#
# PUT /playlists/{playlist_id}/tracks
# Returns: record<snapshot_id: string>
# operationId: reorder-or-replace-playlists-tracks
export def "reorder-or-replace-playlists-tracks" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: string
  --insert-before: int # The position where the items should be inserted.To reorder the items to the end of the playlist, simply set _insert_before_ to the position after the last item.Examples:To reorder the first item to the last position in a playlist with 10 items, set _range_start_ to 0, and _insert_before_ to 10.To reorder the last item in a playlist with 10 items to the start of the playlist, set _range_start_ to 9, and _insert_before_ to 0.
  --range-length: int # The amount of items to be reordered. Defaults to 1 if not set.The range of items to be reordered begins from the _range_start_ position, and includes the _range_length_ subsequent items.Example:To move the items at index 9-10 to the start of the playlist, _range_start_ is set to 9, and _range_length_ is set to 2.
  --range-start: int # The position of the first item to be reordered.
  --snapshot-id: string # The playlist's snapshot ID against which you want to make the changes.
  --body-uris: list<string> # (spec name: uris)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/playlists/{playlist_id}/tracks"
    path_params: [{name: playlist_id, var: playlist_id}]
    query: [{name: uris, var: uris}]
    body: {content_type: "application/json", kind: json, fields: [{name: insert_before, var: insert_before}, {name: range_length, var: range_length}, {name: range_start, var: range_start}, {name: snapshot_id, var: snapshot_id}, {name: uris, var: body_uris}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playlist_id: $playlist_id, uris: $uris, insert_before: $insert_before, range_length: $range_length, range_start: $range_start, snapshot_id: $snapshot_id, body_uris: $body_uris
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Recommendations
#
# GET /recommendations
# Returns: record<seeds: table<afterFilteringSize: int, afterRelinkingSize: int, href: string, id: string, initialPoolSize: int, type: string>, tracks: table<album: record, artists: list, available_markets: list, disc_number: int, duration_ms: int, explicit: bool, external_ids: record, external_urls: record, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, popularity: int, preview_url: string, restrictions: record, track_number: int, type: string, uri: string>>
# operationId: get-recommendations
export def "get-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20, e.g. 10
  --market: string # e.g. ES
  --seed-artists: string # required, e.g. 4NHQUGzhtTLFvgF5SZesLK
  --seed-genres: string # required, e.g. classical,country
  --seed-tracks: string # required, e.g. 0c6xIDDpzE81m2q797ordA
  --min-acousticness: float
  --max-acousticness: float
  --target-acousticness: float
  --min-danceability: float
  --max-danceability: float
  --target-danceability: float
  --min-duration-ms: int
  --max-duration-ms: int
  --target-duration-ms: int
  --min-energy: float
  --max-energy: float
  --target-energy: float
  --min-instrumentalness: float
  --max-instrumentalness: float
  --target-instrumentalness: float
  --min-key: int
  --max-key: int
  --target-key: int
  --min-liveness: float
  --max-liveness: float
  --target-liveness: float
  --min-loudness: float
  --max-loudness: float
  --target-loudness: float
  --min-mode: int
  --max-mode: int
  --target-mode: int
  --min-popularity: int
  --max-popularity: int
  --target-popularity: int
  --min-speechiness: float
  --max-speechiness: float
  --target-speechiness: float
  --min-tempo: float
  --max-tempo: float
  --target-tempo: float
  --min-time-signature: int
  --max-time-signature: int
  --target-time-signature: int
  --min-valence: float
  --max-valence: float
  --target-valence: float
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recommendations"
    query: [{name: limit, var: limit}, {name: market, var: market}, {name: seed_artists, var: seed_artists, required: true}, {name: seed_genres, var: seed_genres, required: true}, {name: seed_tracks, var: seed_tracks, required: true}, {name: min_acousticness, var: min_acousticness}, {name: max_acousticness, var: max_acousticness}, {name: target_acousticness, var: target_acousticness}, {name: min_danceability, var: min_danceability}, {name: max_danceability, var: max_danceability}, {name: target_danceability, var: target_danceability}, {name: min_duration_ms, var: min_duration_ms}, {name: max_duration_ms, var: max_duration_ms}, {name: target_duration_ms, var: target_duration_ms}, {name: min_energy, var: min_energy}, {name: max_energy, var: max_energy}, {name: target_energy, var: target_energy}, {name: min_instrumentalness, var: min_instrumentalness}, {name: max_instrumentalness, var: max_instrumentalness}, {name: target_instrumentalness, var: target_instrumentalness}, {name: min_key, var: min_key}, {name: max_key, var: max_key}, {name: target_key, var: target_key}, {name: min_liveness, var: min_liveness}, {name: max_liveness, var: max_liveness}, {name: target_liveness, var: target_liveness}, {name: min_loudness, var: min_loudness}, {name: max_loudness, var: max_loudness}, {name: target_loudness, var: target_loudness}, {name: min_mode, var: min_mode}, {name: max_mode, var: max_mode}, {name: target_mode, var: target_mode}, {name: min_popularity, var: min_popularity}, {name: max_popularity, var: max_popularity}, {name: target_popularity, var: target_popularity}, {name: min_speechiness, var: min_speechiness}, {name: max_speechiness, var: max_speechiness}, {name: target_speechiness, var: target_speechiness}, {name: min_tempo, var: min_tempo}, {name: max_tempo, var: max_tempo}, {name: target_tempo, var: target_tempo}, {name: min_time_signature, var: min_time_signature}, {name: max_time_signature, var: max_time_signature}, {name: target_time_signature, var: target_time_signature}, {name: min_valence, var: min_valence}, {name: max_valence, var: max_valence}, {name: target_valence, var: target_valence}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    limit: $limit, market: $market, seed_artists: $seed_artists, seed_genres: $seed_genres, seed_tracks: $seed_tracks, min_acousticness: $min_acousticness, max_acousticness: $max_acousticness, target_acousticness: $target_acousticness, min_danceability: $min_danceability, max_danceability: $max_danceability, target_danceability: $target_danceability, min_duration_ms: $min_duration_ms, max_duration_ms: $max_duration_ms, target_duration_ms: $target_duration_ms, min_energy: $min_energy, max_energy: $max_energy, target_energy: $target_energy, min_instrumentalness: $min_instrumentalness, max_instrumentalness: $max_instrumentalness, target_instrumentalness: $target_instrumentalness, min_key: $min_key, max_key: $max_key, target_key: $target_key, min_liveness: $min_liveness, max_liveness: $max_liveness, target_liveness: $target_liveness, min_loudness: $min_loudness, max_loudness: $max_loudness, target_loudness: $target_loudness, min_mode: $min_mode, max_mode: $max_mode, target_mode: $target_mode, min_popularity: $min_popularity, max_popularity: $max_popularity, target_popularity: $target_popularity, min_speechiness: $min_speechiness, max_speechiness: $max_speechiness, target_speechiness: $target_speechiness, min_tempo: $min_tempo, max_tempo: $max_tempo, target_tempo: $target_tempo, min_time_signature: $min_time_signature, max_time_signature: $max_time_signature, target_time_signature: $target_time_signature, min_valence: $min_valence, max_valence: $max_valence, target_valence: $target_valence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Available Genre Seeds
#
# GET /recommendations/available-genre-seeds
# Returns: record<genres: list<string>>
# operationId: get-recommendation-genres
export def "get-recommendation-genres" [
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
    path: "/recommendations/available-genre-seeds"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for Item
#
# GET /search
# Returns: record<albums: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, artists: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, audiobooks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, episodes: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, playlists: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, shows: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, tracks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>
# operationId: search
export def "search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # required, e.g. remaster%20track:Doxy%20artist:Miles%20Davis
  --type: list<string> # required
  --market: string # e.g. ES
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
  --include-external: string@include-external-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search"
    query: [{name: q, var: q, required: true}, {name: type, var: type, style: csv, required: true}, {name: market, var: market}, {name: limit, var: limit}, {name: offset, var: offset}, {name: include_external, var: include_external}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, type: $type, market: $market, limit: $limit, offset: $offset, include_external: $include_external
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Several Shows
#
# GET /shows
# Returns: record<shows: table<available_markets: list, copyrights: list, description: string, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_externally_hosted: bool, languages: list, media_type: string, name: string, publisher: string, total_episodes: int, type: string, uri: string>>
# operationId: get-multiple-shows
export def "get-multiple-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market: string # e.g. ES
  --ids: string # required, e.g. 5CfCWKI5pZ28U0uOzXkDHe,5as3aKmN2k11yfDDDSrvaZ
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shows"
    query: [{name: market, var: market}, {name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    market: $market, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Show
#
# GET /shows/{id}
# Returns: record<available_markets: list<string>, copyrights: table<text: string, type: string>, description: string, explicit: bool, external_urls: record<spotify: string>, href: string, html_description: string, id: string, images: table<height: int, url: string, width: int>, is_externally_hosted: bool, languages: list<string>, media_type: string, name: string, publisher: string, total_episodes: int, type: string, uri: string, episodes: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>>
# operationId: get-a-show
export def "get-a-show" [
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
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shows/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Show Episodes
#
# GET /shows/{id}/episodes
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<audio_preview_url: string, description: string, duration_ms: int, explicit: bool, external_urls: record, href: string, html_description: string, id: string, images: list, is_externally_hosted: bool, is_playable: bool, language: string, languages: list, name: string, release_date: string, release_date_precision: string, restrictions: record, resume_point: record, type: string, uri: string>>
# operationId: get-a-shows-episodes
export def "get-a-shows-episodes" [
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
  --market: string # e.g. ES
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/shows/{id}/episodes"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Several Tracks
#
# GET /tracks
# Returns: record<tracks: table<album: record, artists: list, available_markets: list, disc_number: int, duration_ms: int, explicit: bool, external_ids: record, external_urls: record, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, popularity: int, preview_url: string, restrictions: record, track_number: int, type: string, uri: string>>
# operationId: get-several-tracks
export def "get-several-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market: string # e.g. ES
  --ids: string # required, e.g. 7ouMYWpwJ422jRcDASZB7P,4VqPOruhp5EdPBeR92t6lQ,2takcwOaAZWiXQijPHIx7B
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracks"
    query: [{name: market, var: market}, {name: ids, var: ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    market: $market, ids: $ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Track
#
# GET /tracks/{id}
# Returns: record<album: record<album_type: string, available_markets: list<string>, copyrights: list<record>, external_ids: record<ean: string, isrc: string, upc: string>, external_urls: record<spotify: string>, genres: list<string>, href: string, id: string, images: list<record>, label: string, name: string, popularity: int, release_date: string, release_date_precision: string, restrictions: record<reason: string>, total_tracks: int, type: string, uri: string, album_group: string, artists: list<record>>, artists: table<external_urls: record, followers: record, genres: list, href: string, id: string, images: list, name: string, popularity: int, type: string, uri: string>, available_markets: list<string>, disc_number: int, duration_ms: int, explicit: bool, external_ids: record<ean: string, isrc: string, upc: string>, external_urls: record<spotify: string>, href: string, id: string, is_local: bool, is_playable: bool, linked_from: record, name: string, popularity: int, preview_url: string, restrictions: record<reason: string>, track_number: int, type: string, uri: string>
# operationId: get-track
export def "get-track" [
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
  --market: string # e.g. ES
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tracks/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: market, var: market}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, market: $market
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User's Profile
#
# GET /users/{user_id}
# Returns: record<display_name: string, external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, images: table<height: int, url: string, width: int>, type: string, uri: string>
# operationId: get-users-profile
export def "get-users-profile" [
  user_id: string
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
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User's Playlists
#
# GET /users/{user_id}/playlists
# Returns: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: table<collaborative: bool, description: string, external_urls: record, href: string, id: string, images: list, name: string, owner: record, public: bool, snapshot_id: string, tracks: record, type: string, uri: string>>
# operationId: get-list-users-playlists
export def "get-list-users-playlists" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # default: 20, e.g. 10
  --offset: int # default: 0, e.g. 5
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/playlists"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Playlist
#
# POST /users/{user_id}/playlists
# Returns: record<collaborative: bool, description: string, external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, images: table<height: int, url: string, width: int>, name: string, owner: record<external_urls: record<spotify: string>, followers: record<href: string, total: int>, href: string, id: string, type: string, uri: string, display_name: string>, public: bool, snapshot_id: string, tracks: record<href: string, limit: int, next: string, offset: int, previous: string, total: int, items: list<record>>, type: string, uri: string>
# operationId: create-playlist
export def "create-playlist" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collaborative: oneof<nothing, bool> # Defaults to `false`. If `true` the playlist will be collaborative. _**Note**: to create a collaborative playlist you must also set `public` to `false`. To create collaborative playlists you must have granted `playlist-modify-private` and `playlist-modify-public` [scopes](/documentation/general/guides/authorization-guide/#list-of-scopes)._
  --description: string # value for playlist description as displayed in Spotify Clients and in the Web API.
  name: string # The name for the new playlist, for example `"Your Coolest Playlist"`. This name does not need to be unique; a user may have several playlists with the same name.
  --public: oneof<nothing, bool> # Defaults to `true`. If `true` the playlist will be public, if `false` it will be private. To be able to create private playlists, the user must have granted the `playlist-modify-private` [scope](/documentation/general/guides/authorization-guide/#list-of-scopes)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/playlists"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: collaborative, var: collaborative}, {name: description, var: description}, {name: name, var: name}, {name: public, var: public}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    user_id: $user_id, collaborative: $collaborative, description: $description, name: $name, public: $public
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
