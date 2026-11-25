# Auto-generated client for PandaScore REST API for All Videogames v2.23.1
# Source: https://api.apis.guru/v2/specs/pandascore.co/2.23.1/openapi.json
# Auth: --token flag or $env.PANDASCORE_REST_API_FOR_ALL_VIDEOGAMES_TOKEN

const CLIENT = {
  base_url: "https://api.pandascore.co"
  token_env_var: "PANDASCORE_REST_API_FOR_ALL_VIDEOGAMES_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: query-token, in: query, header_name: token, prefix: ""}
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

def base-url-completer [] { ["https://api.pandascore.co"] }
def auth-scheme-completer [] { ["bearer" "query-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-additions: "list<any>"
    get-changes: "list<any>"
    get-deletions: "table<change_type: string, id: any, modified_at: string, object: record<deleted_at: string, reason: any, videogame_id: int>, type: string>"
    get-incidents: "list<any>"
    get-leagues: "table<id: int, image_url: string, modified_at: string, name: string, series: list<record>, slug: string, url: string, videogame: any>"
    get-leagues-league-id-or-slug: "record<id: int, image_url: string, modified_at: string, name: string, series: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, slug: string, url: string, videogame: any>"
    get-leagues-league-id-or-slug-matches: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-leagues-league-id-or-slug-matches-past: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-leagues-league-id-or-slug-matches-running: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-leagues-league-id-or-slug-matches-upcoming: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-leagues-league-id-or-slug-series: "table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>"
    get-leagues-league-id-or-slug-tournaments: "table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>"
    get-lives: "table<endpoints: list<record>, event: record<begin_at: string, end_at: string, game: string, id: int, is_active: bool, stream_url: string, tournament_id: int>, match: record<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list, id: int, league: record, league_id: int, live: record, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list, original_scheduled_at: string, rescheduled: bool, results: list, scheduled_at: string, serie: record, serie_id: int, slug: string, status: string, streams: record, streams_list: list, tournament: record, tournament_id: int, videogame: record, videogame_version: record, winner: record, winner_id: record>>"
    get-matches: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-matches-past: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-matches-running: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-matches-upcoming: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-matches-match-id-or-slug: "record<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: table<begin_at: string, complete: bool, detailed_stats: bool, end_at: string, finished: bool, forfeit: bool, id: any, length: int, match_id: int, position: int, status: string, video_url: string, winner: record, winner_type: string>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: table<opponent: any, type: string>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record<embed_url: string, raw_url: string>, official: record<embed_url: string, raw_url: string>, russian: record<embed_url: string, raw_url: string>>, streams_list: table<embed_url: string, language: string, main: bool, official: bool, raw_url: string>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-players: "table<birth_year: float, birthday: string, current_team: record<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, current_videogame: record, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>"
    get-players-player-id-or-slug: "record<birth_year: float, birthday: string, current_team: record<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, current_videogame: record, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>"
    get-players-player-id-or-slug-matches: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-series: "table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>"
    get-series-past: "table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>"
    get-series-running: "table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>"
    get-series-upcoming: "table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>"
    get-series-serie-id-or-slug: "record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: table<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>"
    get-series-serie-id-or-slug-matches: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-series-serie-id-or-slug-matches-past: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-series-serie-id-or-slug-matches-running: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-series-serie-id-or-slug-matches-upcoming: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-series-serie-id-or-slug-players: "table<birth_year: float, birthday: string, current_team: record<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, current_videogame: record, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>"
    get-series-serie-id-or-slug-tournaments: "table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>"
    get-teams: "table<acronym: string, current_videogame: record, id: int, image_url: string, location: string, modified_at: string, name: string, players: list<record>, slug: string>"
    get-teams-team-id-or-slug: "record<acronym: string, current_videogame: record, id: int, image_url: string, location: string, modified_at: string, name: string, players: table<birth_year: float, birthday: string, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>, slug: string>"
    get-teams-team-id-or-slug-leagues: "table<id: int, image_url: string, modified_at: string, name: string, series: list<record>, slug: string, url: string, videogame: any>"
    get-teams-team-id-or-slug-matches: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-teams-team-id-or-slug-series: "table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>"
    get-teams-team-id-or-slug-tournaments: "table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>"
    get-tournaments: "table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>"
    get-tournaments-past: "table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>"
    get-tournaments-running: "table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>"
    get-tournaments-upcoming: "table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>"
    get-tournaments-tournament-id-or-slug: "record<begin_at: string, end_at: string, expected_roster: table<players: list, team: record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, id: int, live: record, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, original_scheduled_at: string, rescheduled: bool, scheduled_at: string, slug: string, status: string, streams: record, streams_list: list, tournament_id: int, winner_id: record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: table<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, videogame: record, winner_id: record, winner_type: string>"
    get-tournaments-tournament-id-or-slug-brackets: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, previous_matches: list<record>, scheduled_at: string, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament_id: int, winner_id: record>"
    get-tournaments-tournament-id-or-slug-matches: "table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>"
    get-tournaments-tournament-id-or-slug-players: "table<birth_year: float, birthday: string, current_team: record<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, current_videogame: record, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>"
    get-tournaments-tournament-id-or-slug-standings: "list<any>"
    get-tournaments-tournament-id-or-slug-teams: "table<acronym: string, current_videogame: record, id: int, image_url: string, location: string, modified_at: string, name: string, players: list<record>, slug: string>"
    get-videogames: "list<any>"
    get-videogames-videogame-id-or-slug-leagues: "table<id: int, image_url: string, modified_at: string, name: string, series: list<record>, slug: string, url: string, videogame: any>"
    get-videogames-videogame-id-or-slug-series: "table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>"
    get-videogames-videogame-id-or-slug-tournaments: "table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>"
    get-videogames-videogame-id-or-slug-versions: "table<current: bool, name: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-additions" "get-changes" "get-deletions" "get-incidents" "get-leagues" "get-leagues-league-id-or-slug" "get-leagues-league-id-or-slug-matches" "get-leagues-league-id-or-slug-matches-past" "get-leagues-league-id-or-slug-matches-running" "get-leagues-league-id-or-slug-matches-upcoming" "get-leagues-league-id-or-slug-series" "get-leagues-league-id-or-slug-tournaments" "get-lives" "get-matches" "get-matches-past" "get-matches-running" "get-matches-upcoming" "get-matches-match-id-or-slug" "get-matches-match-id-or-slug-opponents" "get-players" "get-players-player-id-or-slug" "get-players-player-id-or-slug-matches" "get-series" "get-series-past" "get-series-running" "get-series-upcoming" "get-series-serie-id-or-slug" "get-series-serie-id-or-slug-matches" "get-series-serie-id-or-slug-matches-past" "get-series-serie-id-or-slug-matches-running" "get-series-serie-id-or-slug-matches-upcoming" "get-series-serie-id-or-slug-players" "get-series-serie-id-or-slug-tournaments" "get-teams" "get-teams-team-id-or-slug" "get-teams-team-id-or-slug-leagues" "get-teams-team-id-or-slug-matches" "get-teams-team-id-or-slug-series" "get-teams-team-id-or-slug-tournaments" "get-tournaments" "get-tournaments-past" "get-tournaments-running" "get-tournaments-upcoming" "get-tournaments-tournament-id-or-slug" "get-tournaments-tournament-id-or-slug-brackets" "get-tournaments-tournament-id-or-slug-matches" "get-tournaments-tournament-id-or-slug-players" "get-tournaments-tournament-id-or-slug-rosters" "get-tournaments-tournament-id-or-slug-standings" "get-tournaments-tournament-id-or-slug-teams" "get-videogames" "get-videogames-videogame-id-or-slug" "get-videogames-videogame-id-or-slug-leagues" "get-videogames-videogame-id-or-slug-series" "get-videogames-videogame-id-or-slug-tournaments" "get-videogames-videogame-id-or-slug-versions" "commands"] | sort) } | get name | first)
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

# List additions
#
# GET /additions
# Returns: list<any>
# operationId: get_additions
export def "get-additions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
  --type: list # Filter by result type(s)
  --since: string # Filter out older results (format: date-time)
  --videogame: list # Filter by videogame(s)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/additions"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: type, var: type, style: multi}, {name: since, var: since}, {name: videogame, var: videogame, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, type: $type, since: $since, videogame: $videogame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List changes
#
# GET /changes
# Returns: list<any>
# operationId: get_changes
export def "get-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
  --type: list # Filter by result type(s)
  --since: string # Filter out older results (format: date-time)
  --videogame: list # Filter by videogame(s)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/changes"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: type, var: type, style: multi}, {name: since, var: since}, {name: videogame, var: videogame, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, type: $type, since: $since, videogame: $videogame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List deletions
#
# GET /deletions
# Returns: table<change_type: string, id: any, modified_at: string, object: record<deleted_at: string, reason: any, videogame_id: int>, type: string>
# operationId: get_deletions
export def "get-deletions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
  --type: list # Filter by result type(s)
  --since: string # Filter out older results (format: date-time)
  --videogame: list # Filter by videogame(s)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/deletions"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: type, var: type, style: multi}, {name: since, var: since}, {name: videogame, var: videogame, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, type: $type, since: $since, videogame: $videogame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List changes, additions and deletions
#
# GET /incidents
# Returns: list<any>
# operationId: get_incidents
export def "get-incidents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
  --type: list # Filter by result type(s)
  --since: string # Filter out older results (format: date-time)
  --videogame: list # Filter by videogame(s)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/incidents"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: type, var: type, style: multi}, {name: since, var: since}, {name: videogame, var: videogame, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, type: $type, since: $since, videogame: $videogame
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List leagues
#
# GET /leagues
# Returns: table<id: int, image_url: string, modified_at: string, name: string, series: list<record>, slug: string, url: string, videogame: any>
# operationId: get_leagues
export def "get-leagues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: record # Options to search results (e.g. {name: Contenders})
  --sort: list # Options to sort results (e.g. [name, -modified_at])
  --range: record # Options to select results within ranges (e.g. {modified_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --filter: record # Options to filter results. String fields are case sensitive
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/leagues"
    query: [{name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: filter, var: filter, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, sort: $sort, range: $range, filter: $filter, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a league
#
# GET /leagues/{league_id_or_slug}
# Returns: record<id: int, image_url: string, modified_at: string, name: string, series: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, slug: string, url: string, videogame: any>
# operationId: get_leagues_leagueIdOrSlug
export def "get-leagues-league-id-or-slug" [
  league_id_or_slug: string
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
    path: "/leagues/{league_id_or_slug}"
    path_params: [{name: league_id_or_slug, var: league_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    league_id_or_slug: $league_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get matches for a league
#
# GET /leagues/{league_id_or_slug}/matches
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_leagues_leagueIdOrSlug_matches
export def "get-leagues-league-id-or-slug-matches" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/leagues/{league_id_or_slug}/matches"
    path_params: [{name: league_id_or_slug, var: league_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    league_id_or_slug: $league_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get past matches for league
#
# GET /leagues/{league_id_or_slug}/matches/past
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_leagues_leagueIdOrSlug_matches_past
export def "get-leagues-league-id-or-slug-matches-past" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/leagues/{league_id_or_slug}/matches/past"
    path_params: [{name: league_id_or_slug, var: league_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    league_id_or_slug: $league_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get running matches for league
#
# GET /leagues/{league_id_or_slug}/matches/running
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_leagues_leagueIdOrSlug_matches_running
export def "get-leagues-league-id-or-slug-matches-running" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/leagues/{league_id_or_slug}/matches/running"
    path_params: [{name: league_id_or_slug, var: league_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    league_id_or_slug: $league_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get upcoming matches for league
#
# GET /leagues/{league_id_or_slug}/matches/upcoming
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_leagues_leagueIdOrSlug_matches_upcoming
export def "get-leagues-league-id-or-slug-matches-upcoming" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/leagues/{league_id_or_slug}/matches/upcoming"
    path_params: [{name: league_id_or_slug, var: league_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    league_id_or_slug: $league_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List series of a league
#
# GET /leagues/{league_id_or_slug}/series
# Returns: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>
# operationId: get_leagues_leagueIdOrSlug_series
export def "get-leagues-league-id-or-slug-series" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/leagues/{league_id_or_slug}/series"
    path_params: [{name: league_id_or_slug, var: league_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    league_id_or_slug: $league_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tournaments for a league
#
# GET /leagues/{league_id_or_slug}/tournaments
# Returns: table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_leagues_leagueIdOrSlug_tournaments
export def "get-leagues-league-id-or-slug-tournaments" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/leagues/{league_id_or_slug}/tournaments"
    path_params: [{name: league_id_or_slug, var: league_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    league_id_or_slug: $league_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List lives matches
#
# GET /lives
# Returns: table<endpoints: list<record>, event: record<begin_at: string, end_at: string, game: string, id: int, is_active: bool, stream_url: string, tournament_id: int>, match: record<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list, id: int, league: record, league_id: int, live: record, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list, original_scheduled_at: string, rescheduled: bool, results: list, scheduled_at: string, serie: record, serie_id: int, slug: string, status: string, streams: record, streams_list: list, tournament: record, tournament_id: int, videogame: record, videogame_version: record, winner: record, winner_id: record>>
# operationId: get_lives
export def "get-lives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/lives"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List matches
#
# GET /matches
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_matches
export def "get-matches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/matches"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get past matches
#
# GET /matches/past
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_matches_past
export def "get-matches-past" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/matches/past"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get running matches
#
# GET /matches/running
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_matches_running
export def "get-matches-running" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/matches/running"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get upcoming matches
#
# GET /matches/upcoming
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_matches_upcoming
export def "get-matches-upcoming" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/matches/upcoming"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a match
#
# GET /matches/{match_id_or_slug}
# Returns: record<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: table<begin_at: string, complete: bool, detailed_stats: bool, end_at: string, finished: bool, forfeit: bool, id: any, length: int, match_id: int, position: int, status: string, video_url: string, winner: record, winner_type: string>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: table<opponent: any, type: string>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record<embed_url: string, raw_url: string>, official: record<embed_url: string, raw_url: string>, russian: record<embed_url: string, raw_url: string>>, streams_list: table<embed_url: string, language: string, main: bool, official: bool, raw_url: string>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_matches_matchIdOrSlug
export def "get-matches-match-id-or-slug" [
  match_id_or_slug: string
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
    path: "/matches/{match_id_or_slug}"
    path_params: [{name: match_id_or_slug, var: match_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    match_id_or_slug: $match_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get match's opponents
#
# GET /matches/{match_id_or_slug}/opponents
# operationId: get_matches_matchIdOrSlug_opponents
export def "get-matches-match-id-or-slug-opponents" [
  match_id_or_slug: string
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
    path: "/matches/{match_id_or_slug}/opponents"
    path_params: [{name: match_id_or_slug, var: match_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    match_id_or_slug: $match_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List players
#
# GET /players
# Returns: table<birth_year: float, birthday: string, current_team: record<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, current_videogame: record, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>
# operationId: get_players
export def "get-players" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {hometown: France})
  --search: record # Options to search results (e.g. {role: tank})
  --sort: list # Options to sort results (e.g. [last_name])
  --range: record # Options to select results within ranges (e.g. {name: [f, i]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/players"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a player
#
# GET /players/{player_id_or_slug}
# Returns: record<birth_year: float, birthday: string, current_team: record<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, current_videogame: record, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>
# operationId: get_players_playerIdOrSlug
export def "get-players-player-id-or-slug" [
  player_id_or_slug: string
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
    path: "/players/{player_id_or_slug}"
    path_params: [{name: player_id_or_slug, var: player_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    player_id_or_slug: $player_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get matches for a player
#
# GET /players/{player_id_or_slug}/matches
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_players_playerIdOrSlug_matches
export def "get-players-player-id-or-slug-matches" [
  player_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/players/{player_id_or_slug}/matches"
    path_params: [{name: player_id_or_slug, var: player_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    player_id_or_slug: $player_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List series
#
# GET /series
# Returns: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>
# operationId: get_series
export def "get-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get past series
#
# GET /series/past
# Returns: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>
# operationId: get_series_past
export def "get-series-past" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/past"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get running series
#
# GET /series/running
# Returns: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>
# operationId: get_series_running
export def "get-series-running" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/running"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get upcoming series
#
# GET /series/upcoming
# Returns: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>
# operationId: get_series_upcoming
export def "get-series-upcoming" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/upcoming"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a serie
#
# GET /series/{serie_id_or_slug}
# Returns: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: table<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>
# operationId: get_series_serieIdOrSlug
export def "get-series-serie-id-or-slug" [
  serie_id_or_slug: string
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
    path: "/series/{serie_id_or_slug}"
    path_params: [{name: serie_id_or_slug, var: serie_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    serie_id_or_slug: $serie_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get matches for a serie
#
# GET /series/{serie_id_or_slug}/matches
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_series_serieIdOrSlug_matches
export def "get-series-serie-id-or-slug-matches" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/{serie_id_or_slug}/matches"
    path_params: [{name: serie_id_or_slug, var: serie_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    serie_id_or_slug: $serie_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get past matches for serie
#
# GET /series/{serie_id_or_slug}/matches/past
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_series_serieIdOrSlug_matches_past
export def "get-series-serie-id-or-slug-matches-past" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/{serie_id_or_slug}/matches/past"
    path_params: [{name: serie_id_or_slug, var: serie_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    serie_id_or_slug: $serie_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get running matches for serie
#
# GET /series/{serie_id_or_slug}/matches/running
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_series_serieIdOrSlug_matches_running
export def "get-series-serie-id-or-slug-matches-running" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/{serie_id_or_slug}/matches/running"
    path_params: [{name: serie_id_or_slug, var: serie_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    serie_id_or_slug: $serie_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get upcoming matches for serie
#
# GET /series/{serie_id_or_slug}/matches/upcoming
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_series_serieIdOrSlug_matches_upcoming
export def "get-series-serie-id-or-slug-matches-upcoming" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/{serie_id_or_slug}/matches/upcoming"
    path_params: [{name: serie_id_or_slug, var: serie_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    serie_id_or_slug: $serie_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get players for a serie
#
# GET /series/{serie_id_or_slug}/players
# Returns: table<birth_year: float, birthday: string, current_team: record<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, current_videogame: record, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>
# operationId: get_series_serieIdOrSlug_players
export def "get-series-serie-id-or-slug-players" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {hometown: France})
  --search: record # Options to search results (e.g. {role: tank})
  --sort: list # Options to sort results (e.g. [last_name])
  --range: record # Options to select results within ranges (e.g. {name: [f, i]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/{serie_id_or_slug}/players"
    path_params: [{name: serie_id_or_slug, var: serie_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    serie_id_or_slug: $serie_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tournaments for a serie
#
# GET /series/{serie_id_or_slug}/tournaments
# Returns: table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_series_serieIdOrSlug_tournaments
export def "get-series-serie-id-or-slug-tournaments" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/series/{serie_id_or_slug}/tournaments"
    path_params: [{name: serie_id_or_slug, var: serie_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    serie_id_or_slug: $serie_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List teams
#
# GET /teams
# Returns: table<acronym: string, current_videogame: record, id: int, image_url: string, location: string, modified_at: string, name: string, players: list<record>, slug: string>
# operationId: get_teams
export def "get-teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {acronym: RNG})
  --search: record # Options to search results (e.g. {name: vitality})
  --sort: list # Options to sort results (e.g. [name])
  --range: record # Options to select results within ranges (e.g. {name: [vitality, vultur]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a team
#
# GET /teams/{team_id_or_slug}
# Returns: record<acronym: string, current_videogame: record, id: int, image_url: string, location: string, modified_at: string, name: string, players: table<birth_year: float, birthday: string, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>, slug: string>
# operationId: get_teams_teamIdOrSlug
export def "get-teams-team-id-or-slug" [
  team_id_or_slug: string
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
    path: "/teams/{team_id_or_slug}"
    path_params: [{name: team_id_or_slug, var: team_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id_or_slug: $team_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get leagues for a team
#
# GET /teams/{team_id_or_slug}/leagues
# Returns: table<id: int, image_url: string, modified_at: string, name: string, series: list<record>, slug: string, url: string, videogame: any>
# operationId: get_teams_teamIdOrSlug_leagues
export def "get-teams-team-id-or-slug-leagues" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: record # Options to search results (e.g. {name: Contenders})
  --sort: list # Options to sort results (e.g. [name, -modified_at])
  --range: record # Options to select results within ranges (e.g. {modified_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --filter: record # Options to filter results. String fields are case sensitive
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_id_or_slug}/leagues"
    path_params: [{name: team_id_or_slug, var: team_id_or_slug}]
    query: [{name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: filter, var: filter, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id_or_slug: $team_id_or_slug, search: $search, sort: $sort, range: $range, filter: $filter, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get matches for team
#
# GET /teams/{team_id_or_slug}/matches
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_teams_teamIdOrSlug_matches
export def "get-teams-team-id-or-slug-matches" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_id_or_slug}/matches"
    path_params: [{name: team_id_or_slug, var: team_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id_or_slug: $team_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get series for a team
#
# GET /teams/{team_id_or_slug}/series
# Returns: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>
# operationId: get_teams_teamIdOrSlug_series
export def "get-teams-team-id-or-slug-series" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_id_or_slug}/series"
    path_params: [{name: team_id_or_slug, var: team_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id_or_slug: $team_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tournaments for a team
#
# GET /teams/{team_id_or_slug}/tournaments
# Returns: table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_teams_teamIdOrSlug_tournaments
export def "get-teams-team-id-or-slug-tournaments" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_id_or_slug}/tournaments"
    path_params: [{name: team_id_or_slug, var: team_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_id_or_slug: $team_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tournaments
#
# GET /tournaments
# Returns: table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_tournaments
export def "get-tournaments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get past tournaments
#
# GET /tournaments/past
# Returns: table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_tournaments_past
export def "get-tournaments-past" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments/past"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get running tournaments
#
# GET /tournaments/running
# Returns: table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_tournaments_running
export def "get-tournaments-running" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments/running"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get upcoming tournaments
#
# GET /tournaments/upcoming
# Returns: table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_tournaments_upcoming
export def "get-tournaments-upcoming" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments/upcoming"
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a tournament
#
# GET /tournaments/{tournament_id_or_slug}
# Returns: record<begin_at: string, end_at: string, expected_roster: table<players: list, team: record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, id: int, live: record, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, original_scheduled_at: string, rescheduled: bool, scheduled_at: string, slug: string, status: string, streams: record, streams_list: list, tournament_id: int, winner_id: record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: table<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_tournaments_tournamentIdOrSlug
export def "get-tournaments-tournament-id-or-slug" [
  tournament_id_or_slug: string
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
    path: "/tournaments/{tournament_id_or_slug}"
    path_params: [{name: tournament_id_or_slug, var: tournament_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tournament_id_or_slug: $tournament_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a tournament's brackets
#
# GET /tournaments/{tournament_id_or_slug}/brackets
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, previous_matches: list<record>, scheduled_at: string, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament_id: int, winner_id: record>
# operationId: get_tournaments_tournamentIdOrSlug_brackets
export def "get-tournaments-tournament-id-or-slug-brackets" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive
  --range: record # Options to select results within ranges
  --sort: list # Options to sort results
  --search: record # Options to search results
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments/{tournament_id_or_slug}/brackets"
    path_params: [{name: tournament_id_or_slug, var: tournament_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: range, var: range, style: deepObject}, {name: sort, var: sort, style: multi}, {name: search, var: search, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tournament_id_or_slug: $tournament_id_or_slug, filter: $filter, range: $range, sort: $sort, search: $search, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get matches for tournament
#
# GET /tournaments/{tournament_id_or_slug}/matches
# Returns: table<begin_at: string, detailed_stats: bool, draw: bool, end_at: string, forfeit: bool, game_advantage: record, games: list<record>, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live: record<opens_at: string, supported: bool, url: string>, live_embed_url: string, match_type: string, modified_at: string, name: string, number_of_games: int, official_stream_url: string, opponents: list<record>, original_scheduled_at: string, rescheduled: bool, results: list<any>, scheduled_at: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, status: string, streams: record<english: record, official: record, russian: record>, streams_list: list<record>, tournament: record<begin_at: string, end_at: string, id: int, league_id: int, live_supported: bool, modified_at: string, name: string, prizepool: string, serie_id: int, slug: string, winner_id: record, winner_type: string>, tournament_id: int, videogame: record, videogame_version: record<current: bool, name: string>, winner: record, winner_id: record>
# operationId: get_tournaments_tournamentIdOrSlug_matches
export def "get-tournaments-tournament-id-or-slug-matches" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments/{tournament_id_or_slug}/matches"
    path_params: [{name: tournament_id_or_slug, var: tournament_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tournament_id_or_slug: $tournament_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get players for a tournament
#
# GET /tournaments/{tournament_id_or_slug}/players
# Returns: table<birth_year: float, birthday: string, current_team: record<acronym: string, id: int, image_url: string, location: string, modified_at: string, name: string, slug: string>, current_videogame: record, first_name: string, hometown: string, id: int, image_url: string, last_name: string, name: string, nationality: string, role: string, slug: string>
# operationId: get_tournaments_tournamentIdOrSlug_players
export def "get-tournaments-tournament-id-or-slug-players" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {hometown: France})
  --search: record # Options to search results (e.g. {role: tank})
  --sort: list # Options to sort results (e.g. [last_name])
  --range: record # Options to select results within ranges (e.g. {name: [f, i]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments/{tournament_id_or_slug}/players"
    path_params: [{name: tournament_id_or_slug, var: tournament_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tournament_id_or_slug: $tournament_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get rosters for a tournament
#
# GET /tournaments/{tournament_id_or_slug}/rosters
# operationId: get_tournaments_tournamentIdOrSlug_rosters
export def "get-tournaments-tournament-id-or-slug-rosters" [
  tournament_id_or_slug: string
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
    path: "/tournaments/{tournament_id_or_slug}/rosters"
    path_params: [{name: tournament_id_or_slug, var: tournament_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tournament_id_or_slug: $tournament_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tournament standings
#
# GET /tournaments/{tournament_id_or_slug}/standings
# Returns: list<any>
# operationId: get_tournaments_tournamentIdOrSlug_standings
export def "get-tournaments-tournament-id-or-slug-standings" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments/{tournament_id_or_slug}/standings"
    path_params: [{name: tournament_id_or_slug, var: tournament_id_or_slug}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tournament_id_or_slug: $tournament_id_or_slug, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get teams for a tournament
#
# GET /tournaments/{tournament_id_or_slug}/teams
# Returns: table<acronym: string, current_videogame: record, id: int, image_url: string, location: string, modified_at: string, name: string, players: list<record>, slug: string>
# operationId: get_tournaments_tournamentIdOrSlug_teams
export def "get-tournaments-tournament-id-or-slug-teams" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {acronym: RNG})
  --search: record # Options to search results (e.g. {name: vitality})
  --sort: list # Options to sort results (e.g. [name])
  --range: record # Options to select results within ranges (e.g. {name: [vitality, vultur]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/tournaments/{tournament_id_or_slug}/teams"
    path_params: [{name: tournament_id_or_slug, var: tournament_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tournament_id_or_slug: $tournament_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videogames
#
# GET /videogames
# Returns: list<any>
# operationId: get_videogames
export def "get-videogames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videogames"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a videogame
#
# GET /videogames/{videogame_id_or_slug}
# operationId: get_videogames_videogameIdOrSlug
export def "get-videogames-videogame-id-or-slug" [
  videogame_id_or_slug: string
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
    path: "/videogames/{videogame_id_or_slug}"
    path_params: [{name: videogame_id_or_slug, var: videogame_id_or_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    videogame_id_or_slug: $videogame_id_or_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /videogames/{videogame_id_or_slug}/leagues
#
# Returns: table<id: int, image_url: string, modified_at: string, name: string, series: list<record>, slug: string, url: string, videogame: any>
# operationId: get_videogames_videogameIdOrSlug_leagues
export def "get-videogames-videogame-id-or-slug-leagues" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: record # Options to search results (e.g. {name: Contenders})
  --sort: list # Options to sort results (e.g. [name, -modified_at])
  --range: record # Options to select results within ranges (e.g. {modified_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --filter: record # Options to filter results. String fields are case sensitive
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videogames/{videogame_id_or_slug}/leagues"
    path_params: [{name: videogame_id_or_slug, var: videogame_id_or_slug}]
    query: [{name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: filter, var: filter, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    videogame_id_or_slug: $videogame_id_or_slug, search: $search, sort: $sort, range: $range, filter: $filter, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List series for a videogame
#
# GET /videogames/{videogame_id_or_slug}/series
# Returns: table<begin_at: string, description: string, end_at: string, full_name: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, tournaments: list<record>, videogame: record, videogame_title: record<id: int, name: string, videogame_id: int>, winner_id: record, winner_type: string, year: int>
# operationId: get_videogames_videogameIdOrSlug_series
export def "get-videogames-videogame-id-or-slug-series" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videogames/{videogame_id_or_slug}/series"
    path_params: [{name: videogame_id_or_slug, var: videogame_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: search, var: search, style: deepObject}, {name: sort, var: sort, style: multi}, {name: range, var: range, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    videogame_id_or_slug: $videogame_id_or_slug, filter: $filter, search: $search, sort: $sort, range: $range, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tournaments for a videogame
#
# GET /videogames/{videogame_id_or_slug}/tournaments
# Returns: table<begin_at: string, end_at: string, id: int, league: record<id: int, image_url: string, modified_at: string, name: string, slug: string, url: string>, league_id: int, live_supported: bool, matches: list<record>, modified_at: string, name: string, prizepool: string, serie: record<begin_at: string, description: string, end_at: string, full_name: string, id: int, league_id: int, modified_at: string, name: string, season: string, slug: string, tier: string, winner_id: record, winner_type: string, year: int>, serie_id: int, slug: string, teams: list<record>, videogame: record, winner_id: record, winner_type: string>
# operationId: get_videogames_videogameIdOrSlug_tournaments
export def "get-videogames-videogame-id-or-slug-tournaments" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive
  --range: record # Options to select results within ranges
  --sort: list # Options to sort results
  --search: record # Options to search results
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videogames/{videogame_id_or_slug}/tournaments"
    path_params: [{name: videogame_id_or_slug, var: videogame_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: range, var: range, style: deepObject}, {name: sort, var: sort, style: multi}, {name: search, var: search, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    videogame_id_or_slug: $videogame_id_or_slug, filter: $filter, range: $range, sort: $sort, search: $search, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List videogame versions
#
# GET /videogames/{videogame_id_or_slug}/versions
# Returns: table<current: bool, name: string>
# operationId: get_videogames_videogameIdOrSlug_versions
export def "get-videogames-videogame-id-or-slug-versions" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive
  --range: record # Options to select results within ranges
  --sort: list # Options to sort results
  --search: record # Options to search results
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/videogames/{videogame_id_or_slug}/versions"
    path_params: [{name: videogame_id_or_slug, var: videogame_id_or_slug}]
    query: [{name: filter, var: filter, style: deepObject}, {name: range, var: range, style: deepObject}, {name: sort, var: sort, style: multi}, {name: search, var: search, style: deepObject}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    videogame_id_or_slug: $videogame_id_or_slug, filter: $filter, range: $range, sort: $sort, search: $search, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
