# Auto-generated client for GameSparks Game Details API v2
# Source: https://api.apis.guru/v2/specs/gamesparks.net/game-details/v2/openapi.json
# Auth: --token flag or $env.GAMESPARKS_GAME_DETAILS_API_TOKEN

const CLIENT = {
  base_url: "http://localhost//config2.gamesparks.net"
  token_env_var: "GAMESPARKS_GAME_DETAILS_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: accesstoken, in: header, header_name: accessToken, prefix: ""}
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: jwt, in: header, header_name: jwt, prefix: ""}
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

def base-url-completer [] { ["http://localhost//config2.gamesparks.net"] }
def auth-scheme-completer [] { ["accesstoken" "basic" "jwt" "basic-credentials"] }

# Completers for enum parameters
def stage-completer [] { ["LIVE" "PREVIEW"] }
def data-type-completer [] { ["activeDevices" "activeLocations" "activeUsers" "averageBandwidthPerUser" "averageDauOverMau" "averageJsExecutionTime" "averageRequestsPerUser" "averageResponseTime" "averageResponseTimePerType" "connectedUsers" "customAnalyticTotal" "customAnalyticUser" "scriptLogLevelsCount" "sessionAnalytic" "sessionAnalyticTotal" "storagePerUser" "timedAnalyticTotal"] }
def precision-completer [] { ["DAILY" "HOURLY" "MONTHLY"] }
def query-name-completer [] { ["activeUsersNow" "averageDailyActiveUsers" "averageSessionDuration" "dailyActiveUsers" "lastMonthlyActiveUsers" "monthlyActiveUsers"] }
def action-completer [] { ["publish" "start" "stop" "unpublish"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-region-options-using-get: "record<locked: bool, options: table<regionCode: string, regionName: string, selected: bool>>"
    get-analytics-data-using-get: "table<_id: string>"
    get-data-count-using-get: "record<result: string>"
    get-retention-using-get: "record<result: string>"
    get-billing-details: "record<building: string, city: string, companyName: string, country: string, email1: string, email2: string, email3: string, firstName1: string, firstName2: string, firstName3: string, lastName1: string, lastName2: string, lastName3: string, postcode: string, state: string, street: string, taxNumber: string>"
    put-billing-details: "record<building: string, city: string, companyName: string, country: string, email1: string, email2: string, email3: string, firstName1: string, firstName2: string, firstName3: string, lastName1: string, lastName2: string, lastName3: string, postcode: string, state: string, street: string, taxNumber: string>"
    get-game-summary-using-get: "record<logLevelData: list<record>, logLevelSummary: table<count: int, level: string>, message: string>"
    test-push-amazon-notifications-using-post: "record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>"
    test-push-apple-dev-notifications-using-post: "record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>"
    test-push-apple-prod-notifications-using-post: "record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>"
    test-push-google-notifications-using-post: "record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>"
    test-windows8-notifications-using-post: "record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>"
    test-windows-phone8-notifications-using-post: "record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>"
    test-viber-integration-notifications-using-post: "record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>"
    test-viber-production-notifications-using-post: "record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>"
    get-script-differences-using-get: "record<differences: table<bind: string, changeType: string, fileName: string, script1: string, script2: string, type: string>>"
    import-accept-using-post: "record<message: string>"
    import-zip-using-post: "record<differences: table<bind: string, changeType: string, fileName: string, script1: string, script2: string, type: string>>"
    get-script-versions-using-get-1: "record<scriptVersions: table<cloudCodeVersion: int, createdDate: string, description: string, id: string, live: bool>>"
    get-script-versions-using-get: "record<scriptVersions: table<cloudCodeVersion: int, createdDate: string, description: string, id: string, live: bool>>"
    get-segment-query-filters-using-get: "record<filters: table<key: string, name: string, options: list, type: string>>"
    get-segment-query-filters-config-using-get: "record<customFilters: table<key: string, name: string, options: list, type: string>, hiddenFilters: list<string>>"
    update-segment-query-filters-config-using-put: "record<customFilters: table<key: string, name: string, options: list, type: string>, hiddenFilters: list<string>>"
    get-segment-query-standard-filters-using-get: "record<filters: table<key: string, name: string, options: list, type: string>>"
    get-snapshots-using-get-1: "table<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>"
    create-snapshots-using-post: "record<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>"
    get-live-snapshot-id-using-get: "record<message: string>"
    get-snapshots-using-get: "table<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>"
    revert-to-snapshot-using-post: "record<message: string>"
    delete-snapshot-using-delete-1: "record<message: string>"
    get-snapshot-using-get: "record<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>"
    copy-snapshot-to-new-game-using-post: "record<targetGameApiKey: string>"
    copy-snapshot-to-existing-game-using-post-1: "record<targetGameApiKey: string>"
    unpublish-snapshot-using-post: "record<message: string>"
    get-test-harness-scenarios-using-get: "table<scenarioJson: record, scenarioName: string>"
    create-test-harness-scenario-using-post: "record<scenarioJson: record, scenarioName: string>"
    delete-test-harness-scenario-using-delete: "record<message: string>"
    get-test-harness-scenario-using-get: "record<scenarioJson: record, scenarioName: string>"
    update-test-harness-scenario-using-put: "record<scenarioJson: record, scenarioName: string>"
    get-games-endpoints-using-get: "record<liveElasticSearch: string, liveNosql: string, previewElasticSearch: string, previewNosql: string>"
    get-experiments-using-get: "table<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>"
    create-experiment-using-post: "record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>"
    delete-experiment-using-delete: "record<message: string>"
    get-experiment-using-get: "record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>"
    update-experiment-using-put: "record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>"
    do-action-experiment-using-post: "record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>"
    list-queries-using-get: "table<name: string, shortCode: string>"
    create-query-using-post: "record<esRules: string, name: string, qbRules: string, shortCode: string>"
    delete-query-using-delete: "record<message: string>"
    get-query-using-get: "record<esRules: string, name: string, qbRules: string, shortCode: string>"
    update-query-using-put: "record<esRules: string, name: string, qbRules: string, shortCode: string>"
    list-screens-using-get: "table<name: string, shortCode: string>"
    create-screen-using-post: "record<groups: list<string>, name: string, shortCode: string, template: string>"
    list-executable-screens-using-get: "table<name: string, shortCode: string>"
    delete-screen-using-delete: "record<message: string>"
    get-screen-using-get: "record<groups: list<string>, name: string, shortCode: string, template: string>"
    update-screen-using-put: "record<groups: list<string>, name: string, shortCode: string, template: string>"
    list-snapshots-using-get: "table<date: string, description: string, id: string, published: bool>"
    create-snapshot-using-post: "record<date: string, description: string, id: string, published: bool>"
    delete-snapshot-using-delete: "record<message: string>"
    copy-snapshot-to-existing-game-using-post: "record<message: string>"
    publish-snapshot-using-post: "record<message: string>"
    revert-snapshot-using-post: "record<message: string>"
    list-snippets-using-get: "table<name: string, shortCode: string>"
    create-snippet-using-post: "record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>"
    delete-snippet-using-delete: "record<message: string>"
    get-snippet-using-get: "record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>"
    update-snippet-using-put: "record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>"
    restore-deleted-game-using-post: "record<message: string>"
    set-game-region-using-post: "record<message: string>"
    get-game-region-options-using-get: "record<locked: bool, options: table<regionCode: string, regionName: string, selected: bool>>"
    list-using-get: "table<\"@id\": string, name: string>"
    list-deleted-using-get: "table<apiKey: string, name: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-region-options-using-get" "get-analytics-data-using-get" "get-data-count-using-get" "get-retention-using-get" "get-billing-details" "put-billing-details" "get-game-summary-using-get" "test-push-amazon-notifications-using-post" "test-push-apple-dev-notifications-using-post" "test-push-apple-prod-notifications-using-post" "test-push-google-notifications-using-post" "test-windows8-notifications-using-post" "test-windows-phone8-notifications-using-post" "test-viber-integration-notifications-using-post" "test-viber-production-notifications-using-post" "get-script-differences-using-get" "export-zip-using-get" "import-accept-using-post" "import-zip-using-post" "get-script-versions-using-get-1" "get-script-versions-using-get" "get-segment-query-filters-using-get" "get-segment-query-filters-config-using-get" "update-segment-query-filters-config-using-put" "get-segment-query-standard-filters-using-get" "get-snapshots-using-get-1" "create-snapshots-using-post" "get-live-snapshot-id-using-get" "get-snapshots-using-get" "revert-to-snapshot-using-post" "delete-snapshot-using-delete-1" "get-snapshot-using-get" "copy-snapshot-to-new-game-using-post" "copy-snapshot-to-existing-game-using-post-1" "publish-snapshot-using-post-1" "unpublish-snapshot-using-post" "get-test-harness-scenarios-using-get" "create-test-harness-scenario-using-post" "delete-test-harness-scenario-using-delete" "get-test-harness-scenario-using-get" "update-test-harness-scenario-using-put" "update-credential-secret-using-post" "get-games-endpoints-using-get" "get-experiments-using-get" "create-experiment-using-post" "delete-experiment-using-delete" "get-experiment-using-get" "update-experiment-using-put" "do-action-experiment-using-post" "list-queries-using-get" "create-query-using-post" "delete-query-using-delete" "get-query-using-get" "update-query-using-put" "list-screens-using-get" "create-screen-using-post" "list-executable-screens-using-get" "delete-screen-using-delete" "get-screen-using-get" "update-screen-using-put" "list-snapshots-using-get" "create-snapshot-using-post" "delete-snapshot-using-delete" "copy-snapshot-to-existing-game-using-post" "publish-snapshot-using-post" "revert-snapshot-using-post" "list-snippets-using-get" "create-snippet-using-post" "delete-snippet-using-delete" "get-snippet-using-get" "update-snippet-using-put" "restore-deleted-game-using-post" "set-game-region-using-post" "get-game-region-options-using-get" "list-using-get" "list-deleted-using-get" "commands"] | sort) } | get name | first)
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

# getRegionOptions
#
# GET /restv2/game/regions
# Returns: record<locked: bool, options: table<regionCode: string, regionName: string, selected: bool>>
# operationId: getRegionOptionsUsingGET
export def "get-region-options-using-get" [
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
    path: "/restv2/game/regions"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the results of executed query defined by the parameters passed in
#
# GET /restv2/game/{apiKey}/admin/analytics
# Returns: table<_id: string>
# operationId: getAnalyticsDataUsingGET
export def "get-analytics-data-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage (required)
  --data-type: string@data-type-completer # dataType (required)
  --precision: string@precision-completer # precision (required)
  --start-date: string # yyyy-MM-dd (required, format: date)
  --end-date: string # yyyy-MM-dd (required, format: date)
  --keys: string # the keys to select. For example "ReturningUsers", "NewUsers", etc
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/restv2/game/{apiKey}/admin/analytics"
    path_params: [{name: apiKey, var: api_key}]
    query: [{name: stage, var: stage, required: true}, {name: dataType, var: data_type, required: true}, {name: precision, var: precision, required: true}, {name: startDate, var: start_date, required: true}, {name: endDate, var: end_date, required: true}, {name: keys, var: keys}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, stage: $stage, data_type: $data_type, precision: $precision, start_date: $start_date, end_date: $end_date, keys: $keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the count of executed query
#
# GET /restv2/game/{apiKey}/admin/analytics/count
# Returns: record<result: string>
# operationId: getDataCountUsingGET
export def "get-data-count-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage (required)
  --query-name: string@query-name-completer # queryName (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restv2/game/{apiKey}/admin/analytics/count"
    path_params: [{name: apiKey, var: api_key}]
    query: [{name: stage, var: stage, required: true}, {name: queryName, var: query_name, required: true}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, stage: $stage, query_name: $query_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the percentage of user retention over the last 30 days
#
# GET /restv2/game/{apiKey}/admin/analytics/rollingRetention
# Returns: record<result: string>
# operationId: getRetentionUsingGET
export def "get-retention-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restv2/game/{apiKey}/admin/analytics/rollingRetention"
    path_params: [{name: apiKey, var: api_key}]
    query: [{name: stage, var: stage, required: true}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, stage: $stage
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the Billing Details
#
# GET /restv2/game/{apiKey}/admin/billingDetails
# Returns: record<building: string, city: string, companyName: string, country: string, email1: string, email2: string, email3: string, firstName1: string, firstName2: string, firstName3: string, lastName1: string, lastName2: string, lastName3: string, postcode: string, state: string, street: string, taxNumber: string>
# operationId: getBillingDetails
export def "get-billing-details" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/admin/billingDetails"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the Billing Details
#
# PUT /restv2/game/{apiKey}/admin/billingDetails
# Returns: record<building: string, city: string, companyName: string, country: string, email1: string, email2: string, email3: string, firstName1: string, firstName2: string, firstName3: string, lastName1: string, lastName2: string, lastName3: string, postcode: string, state: string, street: string, taxNumber: string>
# operationId: putBillingDetails
export def "put-billing-details" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  building: string
  city: string
  company_name: string
  country: string
  email1: string
  --email2: string
  --email3: string
  first_name1: string
  --first-name2: string
  --first-name3: string
  last_name1: string
  --last-name2: string
  --last-name3: string
  postcode: string
  --state: string
  street: string
  --tax-number: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restv2/game/{apiKey}/admin/billingDetails"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: building, var: building}, {name: city, var: city}, {name: companyName, var: company_name}, {name: country, var: country}, {name: email1, var: email1}, {name: email2, var: email2}, {name: email3, var: email3}, {name: firstName1, var: first_name1}, {name: firstName2, var: first_name2}, {name: firstName3, var: first_name3}, {name: lastName1, var: last_name1}, {name: lastName2, var: last_name2}, {name: lastName3, var: last_name3}, {name: postcode, var: postcode}, {name: state, var: state}, {name: street, var: street}, {name: taxNumber, var: tax_number}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, building: $building, city: $city, company_name: $company_name, country: $country, email1: $email1, email2: $email2, email3: $email3, first_name1: $first_name1, first_name2: $first_name2, first_name3: $first_name3, last_name1: $last_name1, last_name2: $last_name2, last_name3: $last_name3, postcode: $postcode, state: $state, street: $street, tax_number: $tax_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getGameSummary
#
# GET /restv2/game/{apiKey}/admin/notifications/summary
# Returns: record<logLevelData: list<record>, logLevelSummary: table<count: int, level: string>, message: string>
# operationId: getGameSummaryUsingGET
export def "get-game-summary-using-get" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage (required)
  --start-date: string # yyyy-MM-dd (required, format: date)
  --end-date: string # yyyy-MM-dd (required, format: date)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restv2/game/{apiKey}/admin/notifications/summary"
    path_params: [{name: apiKey, var: api_key}]
    query: [{name: stage, var: stage, required: true}, {name: startDate, var: start_date, required: true}, {name: endDate, var: end_date, required: true}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, stage: $stage, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# testPushAmazonNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/amazon
# Returns: record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>
# operationId: testPushAmazonNotificationsUsingPOST
export def "test-push-amazon-notifications-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/pushNotifications/test/amazon"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customJson, var: custom_json}, {name: messageId, var: message_id}, {name: pushId, var: push_id}, {name: subtitle, var: subtitle}, {name: summary, var: summary}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_json: $custom_json, message_id: $message_id, push_id: $push_id, subtitle: $subtitle, summary: $summary, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# testPushAppleDevNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/apple/development
# Returns: record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>
# operationId: testPushAppleDevNotificationsUsingPOST
export def "test-push-apple-dev-notifications-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/pushNotifications/test/apple/development"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customJson, var: custom_json}, {name: messageId, var: message_id}, {name: pushId, var: push_id}, {name: subtitle, var: subtitle}, {name: summary, var: summary}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_json: $custom_json, message_id: $message_id, push_id: $push_id, subtitle: $subtitle, summary: $summary, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# testPushAppleProdNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/apple/production
# Returns: record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>
# operationId: testPushAppleProdNotificationsUsingPOST
export def "test-push-apple-prod-notifications-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/pushNotifications/test/apple/production"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customJson, var: custom_json}, {name: messageId, var: message_id}, {name: pushId, var: push_id}, {name: subtitle, var: subtitle}, {name: summary, var: summary}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_json: $custom_json, message_id: $message_id, push_id: $push_id, subtitle: $subtitle, summary: $summary, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# testPushGoogleNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/google
# Returns: record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>
# operationId: testPushGoogleNotificationsUsingPOST
export def "test-push-google-notifications-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/pushNotifications/test/google"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customJson, var: custom_json}, {name: messageId, var: message_id}, {name: pushId, var: push_id}, {name: subtitle, var: subtitle}, {name: summary, var: summary}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_json: $custom_json, message_id: $message_id, push_id: $push_id, subtitle: $subtitle, summary: $summary, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# testWindows8Notifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windows8
# Returns: record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>
# operationId: testWindows8NotificationsUsingPOST
export def "test-windows8-notifications-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windows8"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customJson, var: custom_json}, {name: messageId, var: message_id}, {name: pushId, var: push_id}, {name: subtitle, var: subtitle}, {name: summary, var: summary}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_json: $custom_json, message_id: $message_id, push_id: $push_id, subtitle: $subtitle, summary: $summary, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# testWindowsPhone8Notifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windowsPhone8
# Returns: record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>
# operationId: testWindowsPhone8NotificationsUsingPOST
export def "test-windows-phone8-notifications-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windowsPhone8"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customJson, var: custom_json}, {name: messageId, var: message_id}, {name: pushId, var: push_id}, {name: subtitle, var: subtitle}, {name: summary, var: summary}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_json: $custom_json, message_id: $message_id, push_id: $push_id, subtitle: $subtitle, summary: $summary, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# testViberIntegrationNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/viber/integration
# Returns: record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>
# operationId: testViberIntegrationNotificationsUsingPOST
export def "test-viber-integration-notifications-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/pushNotifications/test/viber/integration"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customJson, var: custom_json}, {name: messageId, var: message_id}, {name: pushId, var: push_id}, {name: subtitle, var: subtitle}, {name: summary, var: summary}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_json: $custom_json, message_id: $message_id, push_id: $push_id, subtitle: $subtitle, summary: $summary, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# testViberProductionNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/viber/production
# Returns: record<summaries: table<error: bool, outgoingMessageParts: record, resultParts: record, title: string>>
# operationId: testViberProductionNotificationsUsingPOST
export def "test-viber-production-notifications-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-json: string
  --message-id: string
  --push-id: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/pushNotifications/test/viber/production"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customJson, var: custom_json}, {name: messageId, var: message_id}, {name: pushId, var: push_id}, {name: subtitle, var: subtitle}, {name: summary, var: summary}, {name: title, var: title}]}
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_json: $custom_json, message_id: $message_id, push_id: $push_id, subtitle: $subtitle, summary: $summary, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getScriptDifferences
#
# GET /restv2/game/{apiKey}/admin/scripts/differences/{snapshotId1}/{snapshotId2}
# Returns: record<differences: table<bind: string, changeType: string, fileName: string, script1: string, script2: string, type: string>>
# operationId: getScriptDifferencesUsingGET
export def "get-script-differences-using-get" [
  api_key: string
  snapshot_id1: string
  snapshot_id2: string
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
    path: "/restv2/game/{apiKey}/admin/scripts/differences/{snapshotId1}/{snapshotId2}"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId1, var: snapshot_id1}, {name: snapshotId2, var: snapshot_id2}]
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id1: $snapshot_id1, snapshot_id2: $snapshot_id2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# exportZip
#
# GET /restv2/game/{apiKey}/admin/scripts/export
# operationId: exportZipUsingGET
export def "export-zip-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/admin/scripts/export"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# importAccept
#
# POST /restv2/game/{apiKey}/admin/scripts/import/accept
# Returns: record<message: string>
# operationId: importAcceptUsingPOST
export def "import-accept-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-body: string # body (required) (spec name: body)
  file: string # file (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/scripts/import/accept"
    path_params: [{name: apiKey, var: api_key}]
    query: [{name: body, var: qp_body, required: true}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, qp_body: $qp_body, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# importZip
#
# POST /restv2/game/{apiKey}/admin/scripts/import/preview
# Returns: record<differences: table<bind: string, changeType: string, fileName: string, script1: string, script2: string, type: string>>
# operationId: importZipUsingPOST
export def "import-zip-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # file (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/scripts/import/preview"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getScriptVersions
#
# GET /restv2/game/{apiKey}/admin/scripts/versions
# Returns: record<scriptVersions: table<cloudCodeVersion: int, createdDate: string, description: string, id: string, live: bool>>
# operationId: getScriptVersionsUsingGET_1
export def "get-script-versions-using-get-1" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # pageSize (format: int32, default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restv2/game/{apiKey}/admin/scripts/versions"
    path_params: [{name: apiKey, var: api_key}]
    query: [{name: pageSize, var: page_size}]
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getScriptVersions
#
# GET /restv2/game/{apiKey}/admin/scripts/versions/{page}
# Returns: record<scriptVersions: table<cloudCodeVersion: int, createdDate: string, description: string, id: string, live: bool>>
# operationId: getScriptVersionsUsingGET
export def "get-script-versions-using-get" [
  api_key: string
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # pageSize (format: int32, default: 100)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restv2/game/{apiKey}/admin/scripts/versions/{page}"
    path_params: [{name: apiKey, var: api_key}, {name: page, var: page}]
    query: [{name: pageSize, var: page_size}]
    accept: ["*/*"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSegmentQueryFilters
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters
# Returns: record<filters: table<key: string, name: string, options: list, type: string>>
# operationId: getSegmentQueryFiltersUsingGET
export def "get-segment-query-filters-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/admin/segmentQueryFilters"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSegmentQueryFiltersConfig
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters/config
# Returns: record<customFilters: table<key: string, name: string, options: list, type: string>, hiddenFilters: list<string>>
# operationId: getSegmentQueryFiltersConfigUsingGET
export def "get-segment-query-filters-config-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/admin/segmentQueryFilters/config"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateSegmentQueryFiltersConfig
#
# PUT /restv2/game/{apiKey}/admin/segmentQueryFilters/config
# Returns: record<customFilters: table<key: string, name: string, options: list, type: string>, hiddenFilters: list<string>>
# operationId: updateSegmentQueryFiltersConfigUsingPUT
export def "update-segment-query-filters-config-using-put" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-filters: list # item shape: {key?: string, name?: string, options?: list, type?: string}
  --hidden-filters: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restv2/game/{apiKey}/admin/segmentQueryFilters/config"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: customFilters, var: custom_filters}, {name: hiddenFilters, var: hidden_filters}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, custom_filters: $custom_filters, hidden_filters: $hidden_filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSegmentQueryStandardFilters
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters/standardFilters
# Returns: record<filters: table<key: string, name: string, options: list, type: string>>
# operationId: getSegmentQueryStandardFiltersUsingGET
export def "get-segment-query-standard-filters-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/admin/segmentQueryFilters/standardFilters"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSnapshots
#
# GET /restv2/game/{apiKey}/admin/snapshots
# Returns: table<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>
# operationId: getSnapshotsUsingGET_1
export def "get-snapshots-using-get-1" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # pageSize (format: int32, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/restv2/game/{apiKey}/admin/snapshots"
    path_params: [{name: apiKey, var: api_key}]
    query: [{name: pageSize, var: page_size}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# createSnapshots
#
# POST /restv2/game/{apiKey}/admin/snapshots
# Returns: record<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>
# operationId: createSnapshotsUsingPOST
export def "create-snapshots-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/snapshots"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: accesstoken
  } {
    api_key: $api_key, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getLiveSnapshotId
#
# GET /restv2/game/{apiKey}/admin/snapshots/liveSnapshotId
# Returns: record<message: string>
# operationId: getLiveSnapshotIdUsingGET
export def "get-live-snapshot-id-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/admin/snapshots/liveSnapshotId"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSnapshots
#
# GET /restv2/game/{apiKey}/admin/snapshots/page/{page}
# Returns: table<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>
# operationId: getSnapshotsUsingGET
export def "get-snapshots-using-get" [
  api_key: string
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # pageSize (format: int32, default: 20)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/restv2/game/{apiKey}/admin/snapshots/page/{page}"
    path_params: [{name: apiKey, var: api_key}, {name: page, var: page}]
    query: [{name: pageSize, var: page_size}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, page: $page, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# revertToSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/revert/to/{snapshotId}
# Returns: record<message: string>
# operationId: revertToSnapshotUsingPOST
export def "revert-to-snapshot-using-post" [
  api_key: string
  snapshot_id: string
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
    path: "/restv2/game/{apiKey}/admin/snapshots/revert/to/{snapshotId}"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteSnapshot
#
# DELETE /restv2/game/{apiKey}/admin/snapshots/{snapshotId}
# Returns: record<message: string>
# operationId: deleteSnapshotUsingDELETE_1
export def "delete-snapshot-using-delete-1" [
  api_key: string
  snapshot_id: string
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
    method: delete
    path: "/restv2/game/{apiKey}/admin/snapshots/{snapshotId}"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSnapshot
#
# GET /restv2/game/{apiKey}/admin/snapshots/{snapshotId}
# Returns: record<created: string, createdBy: string, description: string, id: string, indexProgress: record, published: bool, status: string>
# operationId: getSnapshotUsingGET
export def "get-snapshot-using-get" [
  api_key: string
  snapshot_id: string
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
    path: "/restv2/game/{apiKey}/admin/snapshots/{snapshotId}"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# copySnapshotToNewGame
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy
# Returns: record<targetGameApiKey: string>
# operationId: copySnapshotToNewGameUsingPOST
export def "copy-snapshot-to-new-game-using-post" [
  api_key: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-game-config: oneof<nothing, bool> # includeGameConfig (default: true)
  --include-metadata: oneof<nothing, bool> # includeMetadata (default: true)
  --include-binaries: oneof<nothing, bool> # includeBinaries (default: true)
  --include-collaborators: oneof<nothing, bool> # includeCollaborators (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    query: [{name: includeGameConfig, var: include_game_config}, {name: includeMetadata, var: include_metadata}, {name: includeBinaries, var: include_binaries}, {name: includeCollaborators, var: include_collaborators}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id, include_game_config: $include_game_config, include_metadata: $include_metadata, include_binaries: $include_binaries, include_collaborators: $include_collaborators
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# copySnapshotToExistingGame
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy/to/{targetApiKey}
# Returns: record<targetGameApiKey: string>
# operationId: copySnapshotToExistingGameUsingPOST_1
export def "copy-snapshot-to-existing-game-using-post-1" [
  api_key: string
  snapshot_id: string
  target_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-game-config: oneof<nothing, bool> # includeGameConfig (default: true)
  --include-metadata: oneof<nothing, bool> # includeMetadata (default: true)
  --include-binaries: oneof<nothing, bool> # includeBinaries (default: true)
  --include-collaborators: oneof<nothing, bool> # includeCollaborators (default: true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy/to/{targetApiKey}"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}, {name: targetApiKey, var: target_api_key}]
    query: [{name: includeGameConfig, var: include_game_config}, {name: includeMetadata, var: include_metadata}, {name: includeBinaries, var: include_binaries}, {name: includeCollaborators, var: include_collaborators}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id, target_api_key: $target_api_key, include_game_config: $include_game_config, include_metadata: $include_metadata, include_binaries: $include_binaries, include_collaborators: $include_collaborators
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# publishSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/publish
# operationId: publishSnapshotUsingPOST_1
export def "publish-snapshot-using-post-1" [
  api_key: string
  snapshot_id: string
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
    method: post
    path: "/restv2/game/{apiKey}/admin/snapshots/{snapshotId}/publish"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# unpublishSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/unpublish
# Returns: record<message: string>
# operationId: unpublishSnapshotUsingPOST
export def "unpublish-snapshot-using-post" [
  api_key: string
  snapshot_id: string
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
    path: "/restv2/game/{apiKey}/admin/snapshots/{snapshotId}/unpublish"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTestHarnessScenarios
#
# GET /restv2/game/{apiKey}/admin/testHarness/scenarios
# Returns: table<scenarioJson: record, scenarioName: string>
# operationId: getTestHarnessScenariosUsingGET
export def "get-test-harness-scenarios-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/admin/testHarness/scenarios"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# createTestHarnessScenario
#
# POST /restv2/game/{apiKey}/admin/testHarness/scenarios
# Returns: record<scenarioJson: record, scenarioName: string>
# operationId: createTestHarnessScenarioUsingPOST
export def "create-test-harness-scenario-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scenario-json: record
  --scenario-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/admin/testHarness/scenarios"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: scenarioJson, var: scenario_json}, {name: scenarioName, var: scenario_name}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: accesstoken
  } {
    api_key: $api_key, scenario_json: $scenario_json, scenario_name: $scenario_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteTestHarnessScenario
#
# DELETE /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# Returns: record<message: string>
# operationId: deleteTestHarnessScenarioUsingDELETE
export def "delete-test-harness-scenario-using-delete" [
  api_key: string
  scenario_name: string
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
    method: delete
    path: "/restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}"
    path_params: [{name: apiKey, var: api_key}, {name: scenarioName, var: scenario_name}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, scenario_name: $scenario_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTestHarnessScenario
#
# GET /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# Returns: record<scenarioJson: record, scenarioName: string>
# operationId: getTestHarnessScenarioUsingGET
export def "get-test-harness-scenario-using-get" [
  api_key: string
  scenario_name: string
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
    path: "/restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}"
    path_params: [{name: apiKey, var: api_key}, {name: scenarioName, var: scenario_name}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, scenario_name: $scenario_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateTestHarnessScenario
#
# PUT /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# Returns: record<scenarioJson: record, scenarioName: string>
# operationId: updateTestHarnessScenarioUsingPUT
export def "update-test-harness-scenario-using-put" [
  api_key: string
  scenario_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scenario-json: record
  --body-scenario-name: string # (spec name: scenarioName)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}"
    path_params: [{name: apiKey, var: api_key}, {name: scenarioName, var: scenario_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: scenarioJson, var: scenario_json}, {name: scenarioName, var: body_scenario_name}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, scenario_name: $scenario_name, scenario_json: $scenario_json, body_scenario_name: $body_scenario_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resets the secret of a credential
#
# POST /restv2/game/{apiKey}/config/~credentials/{credentialName}/resetSecret
# operationId: updateCredentialSecretUsingPOST
export def "update-credential-secret-using-post" [
  api_key: string
  credential_name: string
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
    method: post
    path: "/restv2/game/{apiKey}/config/~credentials/{credentialName}/resetSecret"
    path_params: [{name: apiKey, var: api_key}, {name: credentialName, var: credential_name}]
    accept: ["application/json"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, credential_name: $credential_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getGamesEndpoints
#
# GET /restv2/game/{apiKey}/endpoints
# Returns: record<liveElasticSearch: string, liveNosql: string, previewElasticSearch: string, previewNosql: string>
# operationId: getGamesEndpointsUsingGET
export def "get-games-endpoints-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/endpoints"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getExperiments
#
# GET /restv2/game/{apiKey}/manage/experiments
# Returns: table<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>
# operationId: getExperimentsUsingGET
export def "get-experiments-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/manage/experiments"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# createExperiment
#
# POST /restv2/game/{apiKey}/manage/experiments
# Returns: record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>
# operationId: createExperimentUsingPOST
export def "create-experiment-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --changed-fields-and-initial-values: record
  --complete: oneof<nothing, bool>
  --config: record # shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
  --end-date: string # format: date-time
  --id: int # format: int64
  --measurements: string
  --measurements-es-query: string
  --name: string
  --percent-hash: string
  --published-stages: list<string>
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/manage/experiments"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: changedFieldsAndInitialValues, var: changed_fields_and_initial_values}, {name: complete, var: complete}, {name: config, var: config}, {name: endDate, var: end_date}, {name: id, var: id}, {name: measurements, var: measurements}, {name: measurementsEsQuery, var: measurements_es_query}, {name: name, var: name}, {name: percentHash, var: percent_hash}, {name: publishedStages, var: published_stages}, {name: startDate, var: start_date}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: accesstoken
  } {
    api_key: $api_key, active: $active, changed_fields_and_initial_values: $changed_fields_and_initial_values, complete: $complete, config: $config, end_date: $end_date, id: $id, measurements: $measurements, measurements_es_query: $measurements_es_query, name: $name, percent_hash: $percent_hash, published_stages: $published_stages, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteExperiment
#
# DELETE /restv2/game/{apiKey}/manage/experiments/{id}
# Returns: record<message: string>
# operationId: deleteExperimentUsingDELETE
export def "delete-experiment-using-delete" [
  api_key: string
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
    method: delete
    path: "/restv2/game/{apiKey}/manage/experiments/{id}"
    path_params: [{name: apiKey, var: api_key}, {name: id, var: id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getExperiment
#
# GET /restv2/game/{apiKey}/manage/experiments/{id}
# Returns: record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>
# operationId: getExperimentUsingGET
export def "get-experiment-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/manage/experiments/{id}"
    path_params: [{name: apiKey, var: api_key}, {name: id, var: id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateExperiment
#
# PUT /restv2/game/{apiKey}/manage/experiments/{id}
# Returns: record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>
# operationId: updateExperimentUsingPUT
export def "update-experiment-using-put" [
  api_key: string
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
  --active: oneof<nothing, bool>
  --changed-fields-and-initial-values: record
  --complete: oneof<nothing, bool>
  --config: record # shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
  --end-date: string # format: date-time
  --body-id: int # format: int64 (spec name: id)
  --measurements: string
  --measurements-es-query: string
  --name: string
  --percent-hash: string
  --published-stages: list<string>
  --start-date: string # format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restv2/game/{apiKey}/manage/experiments/{id}"
    path_params: [{name: apiKey, var: api_key}, {name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: changedFieldsAndInitialValues, var: changed_fields_and_initial_values}, {name: complete, var: complete}, {name: config, var: config}, {name: endDate, var: end_date}, {name: id, var: body_id}, {name: measurements, var: measurements}, {name: measurementsEsQuery, var: measurements_es_query}, {name: name, var: name}, {name: percentHash, var: percent_hash}, {name: publishedStages, var: published_stages}, {name: startDate, var: start_date}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, id: $id, active: $active, changed_fields_and_initial_values: $changed_fields_and_initial_values, complete: $complete, config: $config, end_date: $end_date, body_id: $body_id, measurements: $measurements, measurements_es_query: $measurements_es_query, name: $name, percent_hash: $percent_hash, published_stages: $published_stages, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# doActionExperiment
#
# POST /restv2/game/{apiKey}/manage/experiments/{id}/{action}
# Returns: record<active: bool, changedFieldsAndInitialValues: record, complete: bool, config: record<playerMongoQuery: string, playerQuery: string, variants: string>, endDate: string, id: int, measurements: string, measurementsEsQuery: string, name: string, percentHash: string, publishedStages: list<string>, startDate: string>
# operationId: doActionExperimentUsingPOST
export def "do-action-experiment-using-post" [
  api_key: string
  id: int
  action: string@action-completer
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
    path: "/restv2/game/{apiKey}/manage/experiments/{id}/{action}"
    path_params: [{name: apiKey, var: api_key}, {name: id, var: id}, {name: action, var: action}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, id: $id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# listQueries
#
# GET /restv2/game/{apiKey}/manage/queries
# Returns: table<name: string, shortCode: string>
# operationId: listQueriesUsingGET
export def "list-queries-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/manage/queries"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# createQuery
#
# POST /restv2/game/{apiKey}/manage/queries
# Returns: record<esRules: string, name: string, qbRules: string, shortCode: string>
# operationId: createQueryUsingPOST
export def "create-query-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --es-rules: string
  --name: string
  --qb-rules: string
  --short-code: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/manage/queries"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: esRules, var: es_rules}, {name: name, var: name}, {name: qbRules, var: qb_rules}, {name: shortCode, var: short_code}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, es_rules: $es_rules, name: $name, qb_rules: $qb_rules, short_code: $short_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteQuery
#
# DELETE /restv2/game/{apiKey}/manage/queries/{shortCode}
# Returns: record<message: string>
# operationId: deleteQueryUsingDELETE
export def "delete-query-using-delete" [
  api_key: string
  short_code: string
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
    method: delete
    path: "/restv2/game/{apiKey}/manage/queries/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getQuery
#
# GET /restv2/game/{apiKey}/manage/queries/{shortCode}
# Returns: record<esRules: string, name: string, qbRules: string, shortCode: string>
# operationId: getQueryUsingGET
export def "get-query-using-get" [
  api_key: string
  short_code: string
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
    path: "/restv2/game/{apiKey}/manage/queries/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateQuery
#
# PUT /restv2/game/{apiKey}/manage/queries/{shortCode}
# Returns: record<esRules: string, name: string, qbRules: string, shortCode: string>
# operationId: updateQueryUsingPUT
export def "update-query-using-put" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --es-rules: string
  --name: string
  --qb-rules: string
  --body-short-code: string # (spec name: shortCode)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restv2/game/{apiKey}/manage/queries/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: esRules, var: es_rules}, {name: name, var: name}, {name: qbRules, var: qb_rules}, {name: shortCode, var: body_short_code}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code, es_rules: $es_rules, name: $name, qb_rules: $qb_rules, body_short_code: $body_short_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# listScreens
#
# GET /restv2/game/{apiKey}/manage/screens
# Returns: table<name: string, shortCode: string>
# operationId: listScreensUsingGET
export def "list-screens-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/manage/screens"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# createScreen
#
# POST /restv2/game/{apiKey}/manage/screens
# Returns: record<groups: list<string>, name: string, shortCode: string, template: string>
# operationId: createScreenUsingPOST
export def "create-screen-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>
  --name: string
  --short-code: string
  --template: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/manage/screens"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: groups, var: groups}, {name: name, var: name}, {name: shortCode, var: short_code}, {name: template, var: template}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, groups: $groups, name: $name, short_code: $short_code, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# listExecutableScreens
#
# GET /restv2/game/{apiKey}/manage/screens/executable
# Returns: table<name: string, shortCode: string>
# operationId: listExecutableScreensUsingGET
export def "list-executable-screens-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/manage/screens/executable"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteScreen
#
# DELETE /restv2/game/{apiKey}/manage/screens/{shortCode}
# Returns: record<message: string>
# operationId: deleteScreenUsingDELETE
export def "delete-screen-using-delete" [
  api_key: string
  short_code: string
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
    method: delete
    path: "/restv2/game/{apiKey}/manage/screens/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getScreen
#
# GET /restv2/game/{apiKey}/manage/screens/{shortCode}
# Returns: record<groups: list<string>, name: string, shortCode: string, template: string>
# operationId: getScreenUsingGET
export def "get-screen-using-get" [
  api_key: string
  short_code: string
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
    path: "/restv2/game/{apiKey}/manage/screens/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateScreen
#
# PUT /restv2/game/{apiKey}/manage/screens/{shortCode}
# Returns: record<groups: list<string>, name: string, shortCode: string, template: string>
# operationId: updateScreenUsingPUT
export def "update-screen-using-put" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>
  --name: string
  --body-short-code: string # (spec name: shortCode)
  --template: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restv2/game/{apiKey}/manage/screens/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: groups, var: groups}, {name: name, var: name}, {name: shortCode, var: body_short_code}, {name: template, var: template}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code, groups: $groups, name: $name, body_short_code: $body_short_code, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# listSnapshots
#
# GET /restv2/game/{apiKey}/manage/snapshots
# Returns: table<date: string, description: string, id: string, published: bool>
# operationId: listSnapshotsUsingGET
export def "list-snapshots-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/manage/snapshots"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# createSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots
# Returns: record<date: string, description: string, id: string, published: bool>
# operationId: createSnapshotUsingPOST
export def "create-snapshot-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/manage/snapshots"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: accesstoken
  } {
    api_key: $api_key, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteSnapshot
#
# DELETE /restv2/game/{apiKey}/manage/snapshots/{snapshotId}
# Returns: record<message: string>
# operationId: deleteSnapshotUsingDELETE
export def "delete-snapshot-using-delete" [
  api_key: string
  snapshot_id: string
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
    method: delete
    path: "/restv2/game/{apiKey}/manage/snapshots/{snapshotId}"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200, 201]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# copySnapshotToExistingGame
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/copy/to/{targetApiKey}
# Returns: record<message: string>
# operationId: copySnapshotToExistingGameUsingPOST
export def "copy-snapshot-to-existing-game-using-post" [
  api_key: string
  snapshot_id: string
  target_api_key: string
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
    path: "/restv2/game/{apiKey}/manage/snapshots/{snapshotId}/copy/to/{targetApiKey}"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}, {name: targetApiKey, var: target_api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id, target_api_key: $target_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# publishSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/publish
# Returns: record<message: string>
# operationId: publishSnapshotUsingPOST
export def "publish-snapshot-using-post" [
  api_key: string
  snapshot_id: string
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
    path: "/restv2/game/{apiKey}/manage/snapshots/{snapshotId}/publish"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# revertSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/revert
# Returns: record<message: string>
# operationId: revertSnapshotUsingPOST
export def "revert-snapshot-using-post" [
  api_key: string
  snapshot_id: string
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
    path: "/restv2/game/{apiKey}/manage/snapshots/{snapshotId}/revert"
    path_params: [{name: apiKey, var: api_key}, {name: snapshotId, var: snapshot_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: accesstoken
  } {
    api_key: $api_key, snapshot_id: $snapshot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# listSnippets
#
# GET /restv2/game/{apiKey}/manage/snippets
# Returns: table<name: string, shortCode: string>
# operationId: listSnippetsUsingGET
export def "list-snippets-using-get" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/manage/snippets"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# createSnippet
#
# POST /restv2/game/{apiKey}/manage/snippets
# Returns: record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>
# operationId: createSnippetUsingPOST
export def "create-snippet-using-post" [
  api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>
  --name: string
  --script: string
  --script-data: string
  --short-code: string
  --template: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/restv2/game/{apiKey}/manage/snippets"
    path_params: [{name: apiKey, var: api_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: groups, var: groups}, {name: name, var: name}, {name: script, var: script}, {name: scriptData, var: script_data}, {name: shortCode, var: short_code}, {name: template, var: template}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, groups: $groups, name: $name, script: $script, script_data: $script_data, short_code: $short_code, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteSnippet
#
# DELETE /restv2/game/{apiKey}/manage/snippets/{shortCode}
# Returns: record<message: string>
# operationId: deleteSnippetUsingDELETE
export def "delete-snippet-using-delete" [
  api_key: string
  short_code: string
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
    method: delete
    path: "/restv2/game/{apiKey}/manage/snippets/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSnippet
#
# GET /restv2/game/{apiKey}/manage/snippets/{shortCode}
# Returns: record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>
# operationId: getSnippetUsingGET
export def "get-snippet-using-get" [
  api_key: string
  short_code: string
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
    path: "/restv2/game/{apiKey}/manage/snippets/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateSnippet
#
# PUT /restv2/game/{apiKey}/manage/snippets/{shortCode}
# Returns: record<groups: list<string>, name: string, script: string, scriptData: string, shortCode: string, template: string>
# operationId: updateSnippetUsingPUT
export def "update-snippet-using-put" [
  api_key: string
  short_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<string>
  --name: string
  --script: string
  --script-data: string
  --body-short-code: string # (spec name: shortCode)
  --template: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restv2/game/{apiKey}/manage/snippets/{shortCode}"
    path_params: [{name: apiKey, var: api_key}, {name: shortCode, var: short_code}]
    body: {content_type: "application/json", kind: json, fields: [{name: groups, var: groups}, {name: name, var: name}, {name: script, var: script}, {name: scriptData, var: script_data}, {name: shortCode, var: body_short_code}, {name: template, var: template}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key, short_code: $short_code, groups: $groups, name: $name, script: $script, script_data: $script_data, body_short_code: $body_short_code, template: $template
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# restoreDeletedGame
#
# POST /restv2/game/{apiKey}/restore
# Returns: record<message: string>
# operationId: restoreDeletedGameUsingPOST
export def "restore-deleted-game-using-post" [
  api_key: string
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
    path: "/restv2/game/{apiKey}/restore"
    path_params: [{name: apiKey, var: api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    api_key: $api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# setGameRegion
#
# POST /restv2/game/{gameApiKey}/region/{regionCode}
# Returns: record<message: string>
# operationId: setGameRegionUsingPOST
export def "set-game-region-using-post" [
  game_api_key: string
  region_code: string
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
    path: "/restv2/game/{gameApiKey}/region/{regionCode}"
    path_params: [{name: gameApiKey, var: game_api_key}, {name: regionCode, var: region_code}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    game_api_key: $game_api_key, region_code: $region_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getGameRegionOptions
#
# GET /restv2/game/{gameApiKey}/regions
# Returns: record<locked: bool, options: table<regionCode: string, regionName: string, selected: bool>>
# operationId: getGameRegionOptionsUsingGET
export def "get-game-region-options-using-get" [
  game_api_key: string
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
    path: "/restv2/game/{gameApiKey}/regions"
    path_params: [{name: gameApiKey, var: game_api_key}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    game_api_key: $game_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list
#
# GET /restv2/games
# Returns: table<"@id": string, name: string>
# operationId: listUsingGET
export def "list-using-get" [
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
    path: "/restv2/games"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# listDeleted
#
# GET /restv2/games/deleted
# Returns: table<apiKey: string, name: string>
# operationId: listDeletedUsingGET
export def "list-deleted-using-get" [
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
    path: "/restv2/games/deleted"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: accesstoken
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
