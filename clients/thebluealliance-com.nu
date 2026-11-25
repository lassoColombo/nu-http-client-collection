# Auto-generated client for The Blue Alliance API v3 v3.8.2
# Source: https://api.apis.guru/v2/specs/thebluealliance.com/3.8.2/openapi.json
# Auth: --token flag or $env.THE_BLUE_ALLIANCE_API_V3_TOKEN

const CLIENT = {
  base_url: "https://www.thebluealliance.com/api/v3"
  token_env_var: "THE_BLUE_ALLIANCE_API_V3_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-tba-auth-key, in: header, header_name: X-TBA-Auth-Key, prefix: ""}
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

def base-url-completer [] { ["https://www.thebluealliance.com/api/v3"] }
def auth-scheme-completer [] { ["x-tba-auth-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-district-events: "table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int>"
    get-district-events-keys: "list<string>"
    get-district-events-simple: "table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>"
    get-district-rankings: "table<event_points: list<record>, point_total: int, rank: int, rookie_bonus: int, team_key: string>"
    get-district-teams: "table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>"
    get-district-teams-keys: "list<string>"
    get-district-teams-simple: "table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>"
    get-districts-by-year: "table<abbreviation: string, display_name: string, key: string, year: int>"
    get-event: "record<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: table<channel: string, date: string, file: string, type: string>, website: string, week: int, year: int>"
    get-event-alliances: "table<backup: record<in: string, out: string>, declines: list<string>, name: string, picks: list<string>, status: record<current_level_record: record, level: string, playoff_average: float, record: record, status: string>>"
    get-event-awards: "table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int>"
    get-event-district-points: "record<points: record, tiebreakers: record>"
    get-event-insights: "record<playoff: record, qual: record>"
    get-event-matches: "table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string>"
    get-event-matches-keys: "list<string>"
    get-event-matches-simple: "table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string>"
    get-event-match-timeseries: "list<string>"
    get-event-op-rs: "record<ccwms: record, dprs: record, oprs: record>"
    get-event-predictions: "record"
    get-event-rankings: "record<extra_stats_info: table<name: string, precision: float>, rankings: table<dq: int, extra_stats: list, matches_played: int, qual_average: int, rank: int, record: record, sort_orders: list, team_key: string>, sort_order_info: table<name: string, precision: int>>"
    get-event-simple: "record<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>"
    get-event-teams: "table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>"
    get-event-teams-keys: "list<string>"
    get-event-teams-simple: "table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>"
    get-event-teams-statuses: "record"
    get-events-by-year: "table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int>"
    get-events-by-year-keys: "list<string>"
    get-events-by-year-simple: "table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>"
    get-match: "record<actual_time: int, alliances: record<blue: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>, red: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: table<key: string, type: string>, winning_alliance: string>"
    get-match-simple: "record<actual_time: int, alliances: record<blue: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>, red: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string>"
    get-match-timeseries: "list<record>"
    get-match-zebra: "record<alliances: record<blue: list<record>, red: list<record>>, key: string, times: list<float>>"
    get-status: "record<android: record<latest_app_version: int, min_app_version: int>, current_season: int, down_events: list<string>, ios: record<latest_app_version: int, min_app_version: int>, is_datafeed_down: bool, max_season: int>"
    get-team: "record<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>"
    get-team-awards: "table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int>"
    get-team-awards-by-year: "table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int>"
    get-team-districts: "table<abbreviation: string, display_name: string, key: string, year: int>"
    get-team-event-awards: "table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int>"
    get-team-event-matches: "table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string>"
    get-team-event-matches-keys: "list<string>"
    get-team-event-matches-simple: "table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string>"
    get-team-event-status: "record<alliance: record<backup: record<in: string, out: string>, name: string, number: int, pick: int>, alliance_status_str: string, last_match_key: string, next_match_key: string, overall_status_str: string, playoff: record<current_level_record: record<losses: int, ties: int, wins: int>, level: string, playoff_average: int, record: record<losses: int, ties: int, wins: int>, status: string>, playoff_status_str: string, qual: record<num_teams: int, ranking: record<dq: int, matches_played: int, qual_average: float, rank: int, record: record, sort_orders: list, team_key: string>, sort_order_info: list<record>, status: string>>"
    get-team-events: "table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int>"
    get-team-events-keys: "list<string>"
    get-team-events-simple: "table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>"
    get-team-events-by-year: "table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int>"
    get-team-events-by-year-keys: "list<string>"
    get-team-events-by-year-simple: "table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>"
    get-team-events-statuses-by-year: "record"
    get-team-matches-by-year: "table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string>"
    get-team-matches-by-year-keys: "list<string>"
    get-team-matches-by-year-simple: "table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string>"
    get-team-media-by-tag: "table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string>"
    get-team-media-by-tag-year: "table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string>"
    get-team-media-by-year: "table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string>"
    get-team-robots: "table<key: string, robot_name: string, team_key: string, year: int>"
    get-team-simple: "record<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>"
    get-team-social-media: "table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string>"
    get-team-years-participated: "list<int>"
    get-teams: "table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>"
    get-teams-keys: "list<string>"
    get-teams-simple: "table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>"
    get-teams-by-year: "table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>"
    get-teams-by-year-keys: "list<string>"
    get-teams-by-year-simple: "table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-district-events" "get-district-events-keys" "get-district-events-simple" "get-district-rankings" "get-district-teams" "get-district-teams-keys" "get-district-teams-simple" "get-districts-by-year" "get-event" "get-event-alliances" "get-event-awards" "get-event-district-points" "get-event-insights" "get-event-matches" "get-event-matches-keys" "get-event-matches-simple" "get-event-match-timeseries" "get-event-op-rs" "get-event-predictions" "get-event-rankings" "get-event-simple" "get-event-teams" "get-event-teams-keys" "get-event-teams-simple" "get-event-teams-statuses" "get-events-by-year" "get-events-by-year-keys" "get-events-by-year-simple" "get-match" "get-match-simple" "get-match-timeseries" "get-match-zebra" "get-status" "get-team" "get-team-awards" "get-team-awards-by-year" "get-team-districts" "get-team-event-awards" "get-team-event-matches" "get-team-event-matches-keys" "get-team-event-matches-simple" "get-team-event-status" "get-team-events" "get-team-events-keys" "get-team-events-simple" "get-team-events-by-year" "get-team-events-by-year-keys" "get-team-events-by-year-simple" "get-team-events-statuses-by-year" "get-team-matches-by-year" "get-team-matches-by-year-keys" "get-team-matches-by-year-simple" "get-team-media-by-tag" "get-team-media-by-tag-year" "get-team-media-by-year" "get-team-robots" "get-team-simple" "get-team-social-media" "get-team-years-participated" "get-teams" "get-teams-keys" "get-teams-simple" "get-teams-by-year" "get-teams-by-year-keys" "get-teams-by-year-simple" "commands"] | sort) } | get name | first)
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

# Gets a list of events in the given district.
#
# GET /district/{district_key}/events
# Returns: table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int>
# operationId: getDistrictEvents
export def "get-district-events" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/district/{district_key}/events"
    path_params: [{name: district_key, var: district_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    district_key: $district_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of event keys for events in the given district.
#
# GET /district/{district_key}/events/keys
# Returns: list<string>
# operationId: getDistrictEventsKeys
export def "get-district-events-keys" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/district/{district_key}/events/keys"
    path_params: [{name: district_key, var: district_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    district_key: $district_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of events in the given district.
#
# GET /district/{district_key}/events/simple
# Returns: table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>
# operationId: getDistrictEventsSimple
export def "get-district-events-simple" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/district/{district_key}/events/simple"
    path_params: [{name: district_key, var: district_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    district_key: $district_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of team district rankings for the given district.
#
# GET /district/{district_key}/rankings
# Returns: table<event_points: list<record>, point_total: int, rank: int, rookie_bonus: int, team_key: string>
# operationId: getDistrictRankings
export def "get-district-rankings" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/district/{district_key}/rankings"
    path_params: [{name: district_key, var: district_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    district_key: $district_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of `Team` objects that competed in events in the given district.
#
# GET /district/{district_key}/teams
# Returns: table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>
# operationId: getDistrictTeams
export def "get-district-teams" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/district/{district_key}/teams"
    path_params: [{name: district_key, var: district_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    district_key: $district_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of `Team` objects that competed in events in the given district.
#
# GET /district/{district_key}/teams/keys
# Returns: list<string>
# operationId: getDistrictTeamsKeys
export def "get-district-teams-keys" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/district/{district_key}/teams/keys"
    path_params: [{name: district_key, var: district_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    district_key: $district_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of `Team` objects that competed in events in the given district.
#
# GET /district/{district_key}/teams/simple
# Returns: table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>
# operationId: getDistrictTeamsSimple
export def "get-district-teams-simple" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/district/{district_key}/teams/simple"
    path_params: [{name: district_key, var: district_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    district_key: $district_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of districts and their corresponding district key, for the given year.
#
# GET /districts/{year}
# Returns: table<abbreviation: string, display_name: string, key: string, year: int>
# operationId: getDistrictsByYear
export def "get-districts-by-year" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/districts/{year}"
    path_params: [{name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Event.
#
# GET /event/{event_key}
# Returns: record<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: table<channel: string, date: string, file: string, type: string>, website: string, week: int, year: int>
# operationId: getEvent
export def "get-event" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of Elimination Alliances for the given Event.
#
# GET /event/{event_key}/alliances
# Returns: table<backup: record<in: string, out: string>, declines: list<string>, name: string, picks: list<string>, status: record<current_level_record: record, level: string, playoff_average: float, record: record, status: string>>
# operationId: getEventAlliances
export def "get-event-alliances" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/alliances"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of awards from the given event.
#
# GET /event/{event_key}/awards
# Returns: table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int>
# operationId: getEventAwards
export def "get-event-awards" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/awards"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of team rankings for the Event.
#
# GET /event/{event_key}/district_points
# Returns: record<points: record, tiebreakers: record>
# operationId: getEventDistrictPoints
export def "get-event-district-points" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/district_points"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a set of Event-specific insights for the given Event.
#
# GET /event/{event_key}/insights
# Returns: record<playoff: record, qual: record>
# operationId: getEventInsights
export def "get-event-insights" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/insights"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of matches for the given event.
#
# GET /event/{event_key}/matches
# Returns: table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string>
# operationId: getEventMatches
export def "get-event-matches" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/matches"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of match keys for the given event.
#
# GET /event/{event_key}/matches/keys
# Returns: list<string>
# operationId: getEventMatchesKeys
export def "get-event-matches-keys" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/matches/keys"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of matches for the given event.
#
# GET /event/{event_key}/matches/simple
# Returns: table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string>
# operationId: getEventMatchesSimple
export def "get-event-matches-simple" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/matches/simple"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an array of Match Keys for the given event key that have timeseries data. Returns an empty array if no matches have timeseries data. *WARNING:* This is *not* official data, and is subject to a significant possibility of error, or missing data. Do not rely on this data for any purpose. In fact, pretend we made it up. *WARNING:* This endpoint and corresponding data models are under *active development* and may change at any time, including in breaking ways.
#
# GET /event/{event_key}/matches/timeseries
# Returns: list<string>
# operationId: getEventMatchTimeseries
export def "get-event-match-timeseries" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/matches/timeseries"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a set of Event OPRs (including OPR, DPR, and CCWM) for the given Event.
#
# GET /event/{event_key}/oprs
# Returns: record<ccwms: record, dprs: record, oprs: record>
# operationId: getEventOPRs
export def "get-event-op-rs" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/oprs"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information on TBA-generated predictions for the given Event. Contains year-specific information. *WARNING* This endpoint is currently under development and may change at any time.
#
# GET /event/{event_key}/predictions
# Returns: record
# operationId: getEventPredictions
export def "get-event-predictions" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/predictions"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of team rankings for the Event.
#
# GET /event/{event_key}/rankings
# Returns: record<extra_stats_info: table<name: string, precision: float>, rankings: table<dq: int, extra_stats: list, matches_played: int, qual_average: int, rank: int, record: record, sort_orders: list, team_key: string>, sort_order_info: table<name: string, precision: int>>
# operationId: getEventRankings
export def "get-event-rankings" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/rankings"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form Event.
#
# GET /event/{event_key}/simple
# Returns: record<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>
# operationId: getEventSimple
export def "get-event-simple" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/simple"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of `Team` objects that competed in the given event.
#
# GET /event/{event_key}/teams
# Returns: table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>
# operationId: getEventTeams
export def "get-event-teams" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/teams"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of `Team` keys that competed in the given event.
#
# GET /event/{event_key}/teams/keys
# Returns: list<string>
# operationId: getEventTeamsKeys
export def "get-event-teams-keys" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/teams/keys"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of `Team` objects that competed in the given event.
#
# GET /event/{event_key}/teams/simple
# Returns: table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>
# operationId: getEventTeamsSimple
export def "get-event-teams-simple" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/teams/simple"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a key-value list of the event statuses for teams competing at the given event.
#
# GET /event/{event_key}/teams/statuses
# Returns: record
# operationId: getEventTeamsStatuses
export def "get-event-teams-statuses" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/event/{event_key}/teams/statuses"
    path_params: [{name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of events in the given year.
#
# GET /events/{year}
# Returns: table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int>
# operationId: getEventsByYear
export def "get-events-by-year" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{year}"
    path_params: [{name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of event keys in the given year.
#
# GET /events/{year}/keys
# Returns: list<string>
# operationId: getEventsByYearKeys
export def "get-events-by-year-keys" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{year}/keys"
    path_params: [{name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of events in the given year.
#
# GET /events/{year}/simple
# Returns: table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>
# operationId: getEventsByYearSimple
export def "get-events-by-year-simple" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events/{year}/simple"
    path_params: [{name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a `Match` object for the given match key.
#
# GET /match/{match_key}
# Returns: record<actual_time: int, alliances: record<blue: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>, red: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: table<key: string, type: string>, winning_alliance: string>
# operationId: getMatch
export def "get-match" [
  match_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/match/{match_key}"
    path_params: [{name: match_key, var: match_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    match_key: $match_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form `Match` object for the given match key.
#
# GET /match/{match_key}/simple
# Returns: record<actual_time: int, alliances: record<blue: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>, red: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string>
# operationId: getMatchSimple
export def "get-match-simple" [
  match_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/match/{match_key}/simple"
    path_params: [{name: match_key, var: match_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    match_key: $match_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an array of game-specific Match Timeseries objects for the given match key or an empty array if not available. *WARNING:* This is *not* official data, and is subject to a significant possibility of error, or missing data. Do not rely on this data for any purpose. In fact, pretend we made it up. *WARNING:* This endpoint and corresponding data models are under *active development* and may change at any time, including in breaking ways.
#
# GET /match/{match_key}/timeseries
# Returns: list<record>
# operationId: getMatchTimeseries
export def "get-match-timeseries" [
  match_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/match/{match_key}/timeseries"
    path_params: [{name: match_key, var: match_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    match_key: $match_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets Zebra MotionWorks data for a Match for the given match key.
#
# GET /match/{match_key}/zebra_motionworks
# Returns: record<alliances: record<blue: list<record>, red: list<record>>, key: string, times: list<float>>
# operationId: getMatchZebra
export def "get-match-zebra" [
  match_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/match/{match_key}/zebra_motionworks"
    path_params: [{name: match_key, var: match_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    match_key: $match_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns API status, and TBA status information.
#
# GET /status
# Returns: record<android: record<latest_app_version: int, min_app_version: int>, current_season: int, down_events: list<string>, ios: record<latest_app_version: int, min_app_version: int>, is_datafeed_down: bool, max_season: int>
# operationId: getStatus
export def "get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/status"
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a `Team` object for the team referenced by the given key.
#
# GET /team/{team_key}
# Returns: record<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>
# operationId: getTeam
export def "get-team" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of awards the given team has won.
#
# GET /team/{team_key}/awards
# Returns: table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int>
# operationId: getTeamAwards
export def "get-team-awards" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/awards"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of awards the given team has won in a given year.
#
# GET /team/{team_key}/awards/{year}
# Returns: table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int>
# operationId: getTeamAwardsByYear
export def "get-team-awards-by-year" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/awards/{year}"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an array of districts representing each year the team was in a district. Will return an empty array if the team was never in a district.
#
# GET /team/{team_key}/districts
# Returns: table<abbreviation: string, display_name: string, key: string, year: int>
# operationId: getTeamDistricts
export def "get-team-districts" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/districts"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of awards the given team won at the given event.
#
# GET /team/{team_key}/event/{event_key}/awards
# Returns: table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int>
# operationId: getTeamEventAwards
export def "get-team-event-awards" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/event/{event_key}/awards"
    path_params: [{name: team_key, var: team_key}, {name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of matches for the given team and event.
#
# GET /team/{team_key}/event/{event_key}/matches
# Returns: table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string>
# operationId: getTeamEventMatches
export def "get-team-event-matches" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/event/{event_key}/matches"
    path_params: [{name: team_key, var: team_key}, {name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of match keys for matches for the given team and event.
#
# GET /team/{team_key}/event/{event_key}/matches/keys
# Returns: list<string>
# operationId: getTeamEventMatchesKeys
export def "get-team-event-matches-keys" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/event/{event_key}/matches/keys"
    path_params: [{name: team_key, var: team_key}, {name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of matches for the given team and event.
#
# GET /team/{team_key}/event/{event_key}/matches/simple
# Returns: table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string>
# operationId: getTeamEventMatchesSimple
export def "get-team-event-matches-simple" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/event/{event_key}/matches/simple"
    path_params: [{name: team_key, var: team_key}, {name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the competition rank and status of the team at the given event.
#
# GET /team/{team_key}/event/{event_key}/status
# Returns: record<alliance: record<backup: record<in: string, out: string>, name: string, number: int, pick: int>, alliance_status_str: string, last_match_key: string, next_match_key: string, overall_status_str: string, playoff: record<current_level_record: record<losses: int, ties: int, wins: int>, level: string, playoff_average: int, record: record<losses: int, ties: int, wins: int>, status: string>, playoff_status_str: string, qual: record<num_teams: int, ranking: record<dq: int, matches_played: int, qual_average: float, rank: int, record: record, sort_orders: list, team_key: string>, sort_order_info: list<record>, status: string>>
# operationId: getTeamEventStatus
export def "get-team-event-status" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/event/{event_key}/status"
    path_params: [{name: team_key, var: team_key}, {name: event_key, var: event_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, event_key: $event_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of all events this team has competed at.
#
# GET /team/{team_key}/events
# Returns: table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int>
# operationId: getTeamEvents
export def "get-team-events" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/events"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the event keys for all events this team has competed at.
#
# GET /team/{team_key}/events/keys
# Returns: list<string>
# operationId: getTeamEventsKeys
export def "get-team-events-keys" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/events/keys"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of all events this team has competed at.
#
# GET /team/{team_key}/events/simple
# Returns: table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>
# operationId: getTeamEventsSimple
export def "get-team-events-simple" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/events/simple"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of events this team has competed at in the given year.
#
# GET /team/{team_key}/events/{year}
# Returns: table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int>
# operationId: getTeamEventsByYear
export def "get-team-events-by-year" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/events/{year}"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of the event keys for events this team has competed at in the given year.
#
# GET /team/{team_key}/events/{year}/keys
# Returns: list<string>
# operationId: getTeamEventsByYearKeys
export def "get-team-events-by-year-keys" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/events/{year}/keys"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of events this team has competed at in the given year.
#
# GET /team/{team_key}/events/{year}/simple
# Returns: table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int>
# operationId: getTeamEventsByYearSimple
export def "get-team-events-by-year-simple" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/events/{year}/simple"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a key-value list of the event statuses for events this team has competed at in the given year.
#
# GET /team/{team_key}/events/{year}/statuses
# Returns: record
# operationId: getTeamEventsStatusesByYear
export def "get-team-events-statuses-by-year" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/events/{year}/statuses"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of matches for the given team and year.
#
# GET /team/{team_key}/matches/{year}
# Returns: table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string>
# operationId: getTeamMatchesByYear
export def "get-team-matches-by-year" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/matches/{year}"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of match keys for matches for the given team and year.
#
# GET /team/{team_key}/matches/{year}/keys
# Returns: list<string>
# operationId: getTeamMatchesByYearKeys
export def "get-team-matches-by-year-keys" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/matches/{year}/keys"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a short-form list of matches for the given team and year.
#
# GET /team/{team_key}/matches/{year}/simple
# Returns: table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string>
# operationId: getTeamMatchesByYearSimple
export def "get-team-matches-by-year-simple" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/matches/{year}/simple"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of Media (videos / pictures) for the given team and tag.
#
# GET /team/{team_key}/media/tag/{media_tag}
# Returns: table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string>
# operationId: getTeamMediaByTag
export def "get-team-media-by-tag" [
  team_key: string
  media_tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/media/tag/{media_tag}"
    path_params: [{name: team_key, var: team_key}, {name: media_tag, var: media_tag}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, media_tag: $media_tag, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of Media (videos / pictures) for the given team, tag and year.
#
# GET /team/{team_key}/media/tag/{media_tag}/{year}
# Returns: table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string>
# operationId: getTeamMediaByTagYear
export def "get-team-media-by-tag-year" [
  team_key: string
  media_tag: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/media/tag/{media_tag}/{year}"
    path_params: [{name: team_key, var: team_key}, {name: media_tag, var: media_tag}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, media_tag: $media_tag, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of Media (videos / pictures) for the given team and year.
#
# GET /team/{team_key}/media/{year}
# Returns: table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string>
# operationId: getTeamMediaByYear
export def "get-team-media-by-year" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/media/{year}"
    path_params: [{name: team_key, var: team_key}, {name: year, var: year}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, year: $year, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of year and robot name pairs for each year that a robot name was provided. Will return an empty array if the team has never named a robot.
#
# GET /team/{team_key}/robots
# Returns: table<key: string, robot_name: string, team_key: string, year: int>
# operationId: getTeamRobots
export def "get-team-robots" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/robots"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a `Team_Simple` object for the team referenced by the given key.
#
# GET /team/{team_key}/simple
# Returns: record<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>
# operationId: getTeamSimple
export def "get-team-simple" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/simple"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of Media (social media) for the given team.
#
# GET /team/{team_key}/social_media
# Returns: table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string>
# operationId: getTeamSocialMedia
export def "get-team-social-media" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/social_media"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of years in which the team participated in at least one competition.
#
# GET /team/{team_key}/years_participated
# Returns: list<int>
# operationId: getTeamYearsParticipated
export def "get-team-years-participated" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/team/{team_key}/years_participated"
    path_params: [{name: team_key, var: team_key}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    team_key: $team_key, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of `Team` objects, paginated in groups of 500.
#
# GET /teams/{page_num}
# Returns: table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>
# operationId: getTeams
export def "get-teams" [
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{page_num}"
    path_params: [{name: page_num, var: page_num}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    page_num: $page_num, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of Team keys, paginated in groups of 500. (Note, each page will not have 500 teams, but will include the teams within that range of 500.)
#
# GET /teams/{page_num}/keys
# Returns: list<string>
# operationId: getTeamsKeys
export def "get-teams-keys" [
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{page_num}/keys"
    path_params: [{name: page_num, var: page_num}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    page_num: $page_num, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of short form `Team_Simple` objects, paginated in groups of 500.
#
# GET /teams/{page_num}/simple
# Returns: table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>
# operationId: getTeamsSimple
export def "get-teams-simple" [
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{page_num}/simple"
    path_params: [{name: page_num, var: page_num}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    page_num: $page_num, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of `Team` objects that competed in the given year, paginated in groups of 500.
#
# GET /teams/{year}/{page_num}
# Returns: table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string>
# operationId: getTeamsByYear
export def "get-teams-by-year" [
  year: int
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{year}/{page_num}"
    path_params: [{name: year, var: year}, {name: page_num, var: page_num}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    year: $year, page_num: $page_num, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list Team Keys that competed in the given year, paginated in groups of 500.
#
# GET /teams/{year}/{page_num}/keys
# Returns: list<string>
# operationId: getTeamsByYearKeys
export def "get-teams-by-year-keys" [
  year: int
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{year}/{page_num}/keys"
    path_params: [{name: year, var: year}, {name: page_num, var: page_num}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    year: $year, page_num: $page_num, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of short form `Team_Simple` objects that competed in the given year, paginated in groups of 500.
#
# GET /teams/{year}/{page_num}/simple
# Returns: table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int>
# operationId: getTeamsByYearSimple
export def "get-teams-by-year-simple" [
  year: int
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{year}/{page_num}/simple"
    path_params: [{name: year, var: year}, {name: page_num, var: page_num}]
    header: [{name: If-None-Match, var: if_none_match}]
    accept: ["application/json"]
    ok: [200, 304]
    auth: x-tba-auth-key
  } {
    year: $year, page_num: $page_num, if_none_match: $if_none_match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
