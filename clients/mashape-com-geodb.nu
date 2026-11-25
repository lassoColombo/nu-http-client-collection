# Auto-generated client for GeoDB Cities API v1.0.0
# Source: https://api.apis.guru/v2/specs/mashape.com/geodb/1.0.0/swagger.json
# Auth: --token flag or $env.GEODB_CITIES_API_TOKEN

const CLIENT = {
  base_url: "https://wft-geo-db.p.rapidapi.com/v1"
  token_env_var: "GEODB_CITIES_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-rapidapi-key, in: header, header_name: x-rapidapi-key, prefix: ""}
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

def base-url-completer [] { ["https://wft-geo-db.p.rapidapi.com/v1"] }
def auth-scheme-completer [] { ["x-rapidapi-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    find-admin-divisions-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    get-admin-division-using-get: "record<errors: table<code: string, message: string>, data: record<country: string, countryCode: string, deleted: bool, elevationMeters: int, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, timezone: string, type: string, wikiDataId: string>>"
    find-cities-near-admin-division-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    find-divisions-near-admin-division-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    find-cities-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    get-city-using-get: "record<errors: table<code: string, message: string>, data: record<country: string, countryCode: string, deleted: bool, elevationMeters: int, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, timezone: string, type: string, wikiDataId: string>>"
    get-city-date-time-using-get: "record<errors: table<code: string, message: string>, data: string>"
    get-city-distance-using-get: "record<errors: table<code: string, message: string>, data: float>"
    get-city-located-in-using-get: "record<errors: table<code: string, message: string>, data: record<country: string, countryCode: string, deleted: bool, elevationMeters: int, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, timezone: string, type: string, wikiDataId: string>>"
    find-cities-near-city-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    get-city-time-using-get: "record<errors: table<code: string, message: string>, data: string>"
    get-countries-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<code: string, currencyCodes: list, name: string, wikiDataId: string>>"
    get-country-using-get: "record<errors: table<code: string, message: string>, data: record<callingCode: string, code: string, currencyCodes: list<string>, flagImageUri: string, name: string, numRegions: int, wikiDataId: string>>"
    get-regions-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<countryCode: string, fipsCode: string, isoCode: string, name: string, wikiDataId: string>>"
    get-region-using-get: "record<errors: table<code: string, message: string>, data: record<capital: string, countryCode: string, fipsCode: string, isoCode: string, name: string, numCities: int, wikiDataId: string>>"
    find-region-divisions-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    find-region-cities-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    find-cities-near-location-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    find-divisions-near-location-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>"
    get-currencies-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<code: string, countryCodes: list, symbol: string>>"
    get-languages-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<code: string, name: string>>"
    get-locales-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<code: string>>"
    get-timezones-using-get: "record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<id: string, name: string, rawUtcOffsetHours: int>>"
    get-time-zone-using-get: "record<errors: table<code: string, message: string>, id: string, name: string, rawUtcOffsetHours: int>"
    get-time-zone-date-time-using-get: "record<errors: table<code: string, message: string>, data: string>"
    get-time-zone-time-using-get: "record<errors: table<code: string, message: string>, data: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["find-admin-divisions-using-get" "get-admin-division-using-get" "find-cities-near-admin-division-using-get" "find-divisions-near-admin-division-using-get" "find-cities-using-get" "get-city-using-get" "get-city-date-time-using-get" "get-city-distance-using-get" "get-city-located-in-using-get" "find-cities-near-city-using-get" "get-city-time-using-get" "get-countries-using-get" "get-country-using-get" "get-regions-using-get" "get-region-using-get" "find-region-divisions-using-get" "find-region-cities-using-get" "find-cities-near-location-using-get" "find-divisions-near-location-using-get" "get-currencies-using-get" "get-languages-using-get" "get-locales-using-get" "get-timezones-using-get" "get-time-zone-using-get" "get-time-zone-date-time-using-get" "get-time-zone-time-using-get" "commands"] | sort) } | get name | first)
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

# Find administrative divisions
#
# GET /geo/adminDivisions
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findAdminDivisionsUsingGET
export def "find-admin-divisions-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: string # Only places near this location. Latitude/longitude in ISO-6709 format: ±DD.DDDD±DDD.DDDD
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/adminDivisions"
    query: [{name: location, var: location}, {name: radius, var: radius}, {name: distanceUnit, var: distance_unit}, {name: countryIds, var: country_ids}, {name: excludedCountryIds, var: excluded_country_ids}, {name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    location: $location, radius: $radius, distance_unit: $distance_unit, country_ids: $country_ids, excluded_country_ids: $excluded_country_ids, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get administrative division details
#
# GET /geo/adminDivisions/{divisionId}
# Returns: record<errors: table<code: string, message: string>, data: record<country: string, countryCode: string, deleted: bool, elevationMeters: int, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, timezone: string, type: string, wikiDataId: string>>
# operationId: getAdminDivisionUsingGET
export def "get-admin-division-using-get" [
  division_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/adminDivisions/{divisionId}"
    path_params: [{name: divisionId, var: division_id}]
    query: [{name: asciiMode, var: ascii_mode}, {name: languageCode, var: language_code}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    division_id: $division_id, ascii_mode: $ascii_mode, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find cities near division
#
# GET /geo/adminDivisions/{divisionId}/nearbyCities
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findCitiesNearAdminDivisionUsingGET
export def "find-cities-near-admin-division-using-get" [
  division_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/adminDivisions/{divisionId}/nearbyCities"
    path_params: [{name: divisionId, var: division_id}]
    query: [{name: radius, var: radius}, {name: distanceUnit, var: distance_unit}, {name: countryIds, var: country_ids}, {name: excludedCountryIds, var: excluded_country_ids}, {name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: types, var: types}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    division_id: $division_id, radius: $radius, distance_unit: $distance_unit, country_ids: $country_ids, excluded_country_ids: $excluded_country_ids, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, types: $types, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find divisions near division
#
# GET /geo/adminDivisions/{divisionId}/nearbyDivisions
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findDivisionsNearAdminDivisionUsingGET
export def "find-divisions-near-admin-division-using-get" [
  division_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/adminDivisions/{divisionId}/nearbyDivisions"
    path_params: [{name: divisionId, var: division_id}]
    query: [{name: radius, var: radius}, {name: distanceUnit, var: distance_unit}, {name: countryIds, var: country_ids}, {name: excludedCountryIds, var: excluded_country_ids}, {name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    division_id: $division_id, radius: $radius, distance_unit: $distance_unit, country_ids: $country_ids, excluded_country_ids: $excluded_country_ids, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find cities
#
# GET /geo/cities
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findCitiesUsingGET
export def "find-cities-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: string # Only places near this location. Latitude/longitude in ISO-6709 format: ±DD.DDDD±DDD.DDDD
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/cities"
    query: [{name: location, var: location}, {name: radius, var: radius}, {name: distanceUnit, var: distance_unit}, {name: countryIds, var: country_ids}, {name: excludedCountryIds, var: excluded_country_ids}, {name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: types, var: types}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    location: $location, radius: $radius, distance_unit: $distance_unit, country_ids: $country_ids, excluded_country_ids: $excluded_country_ids, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, types: $types, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get city details
#
# GET /geo/cities/{cityId}
# Returns: record<errors: table<code: string, message: string>, data: record<country: string, countryCode: string, deleted: bool, elevationMeters: int, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, timezone: string, type: string, wikiDataId: string>>
# operationId: getCityUsingGET
export def "get-city-using-get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/cities/{cityId}"
    path_params: [{name: cityId, var: city_id}]
    query: [{name: asciiMode, var: ascii_mode}, {name: languageCode, var: language_code}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    city_id: $city_id, ascii_mode: $ascii_mode, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get city date-time
#
# GET /geo/cities/{cityId}/dateTime
# Returns: record<errors: table<code: string, message: string>, data: string>
# operationId: getCityDateTimeUsingGET
export def "get-city-date-time-using-get" [
  city_id: string
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
    path: "/geo/cities/{cityId}/dateTime"
    path_params: [{name: cityId, var: city_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    city_id: $city_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get city distance
#
# GET /geo/cities/{cityId}/distance
# Returns: record<errors: table<code: string, message: string>, data: float>
# operationId: getCityDistanceUsingGET
export def "get-city-distance-using-get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --to-city-id: string # Distance to this city (required)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/cities/{cityId}/distance"
    path_params: [{name: cityId, var: city_id}]
    query: [{name: toCityId, var: to_city_id, required: true}, {name: distanceUnit, var: distance_unit}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    city_id: $city_id, to_city_id: $to_city_id, distance_unit: $distance_unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get city admin region
#
# GET /geo/cities/{cityId}/locatedIn
# Returns: record<errors: table<code: string, message: string>, data: record<country: string, countryCode: string, deleted: bool, elevationMeters: int, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, timezone: string, type: string, wikiDataId: string>>
# operationId: getCityLocatedInUsingGET
export def "get-city-located-in-using-get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/cities/{cityId}/locatedIn"
    path_params: [{name: cityId, var: city_id}]
    query: [{name: asciiMode, var: ascii_mode}, {name: languageCode, var: language_code}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    city_id: $city_id, ascii_mode: $ascii_mode, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find cities near city
#
# GET /geo/cities/{cityId}/nearbyCities
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findCitiesNearCityUsingGET
export def "find-cities-near-city-using-get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/cities/{cityId}/nearbyCities"
    path_params: [{name: cityId, var: city_id}]
    query: [{name: radius, var: radius}, {name: distanceUnit, var: distance_unit}, {name: countryIds, var: country_ids}, {name: excludedCountryIds, var: excluded_country_ids}, {name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: types, var: types}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    city_id: $city_id, radius: $radius, distance_unit: $distance_unit, country_ids: $country_ids, excluded_country_ids: $excluded_country_ids, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, types: $types, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get city time
#
# GET /geo/cities/{cityId}/time
# Returns: record<errors: table<code: string, message: string>, data: string>
# operationId: getCityTimeUsingGET
export def "get-city-time-using-get" [
  city_id: string
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
    path: "/geo/cities/{cityId}/time"
    path_params: [{name: cityId, var: city_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    city_id: $city_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find countries
#
# GET /geo/countries
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<code: string, currencyCodes: list, name: string, wikiDataId: string>>
# operationId: getCountriesUsingGET
export def "get-countries-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency-code: string # Only countries supporting this currency
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort countries. Format: ±SORT_FIELD where SORT_FIELD = code | name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/countries"
    query: [{name: currencyCode, var: currency_code}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    currency_code: $currency_code, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get country details
#
# GET /geo/countries/{countryId}
# Returns: record<errors: table<code: string, message: string>, data: record<callingCode: string, code: string, currencyCodes: list<string>, flagImageUri: string, name: string, numRegions: int, wikiDataId: string>>
# operationId: getCountryUsingGET
export def "get-country-using-get" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/countries/{countryId}"
    path_params: [{name: countryId, var: country_id}]
    query: [{name: asciiMode, var: ascii_mode}, {name: languageCode, var: language_code}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    country_id: $country_id, ascii_mode: $ascii_mode, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find country regions
#
# GET /geo/countries/{countryId}/regions
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<countryCode: string, fipsCode: string, isoCode: string, name: string, wikiDataId: string>>
# operationId: getRegionsUsingGET
export def "get-regions-using-get" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort regions. Format: ±SORT_FIELD where SORT_FIELD = fipsCode | isoCode | name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/countries/{countryId}/regions"
    path_params: [{name: countryId, var: country_id}]
    query: [{name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    country_id: $country_id, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get region details
#
# GET /geo/countries/{countryId}/regions/{regionCode}
# Returns: record<errors: table<code: string, message: string>, data: record<capital: string, countryCode: string, fipsCode: string, isoCode: string, name: string, numCities: int, wikiDataId: string>>
# operationId: getRegionUsingGET
export def "get-region-using-get" [
  country_id: string
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
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/countries/{countryId}/regions/{regionCode}"
    path_params: [{name: countryId, var: country_id}, {name: regionCode, var: region_code}]
    query: [{name: asciiMode, var: ascii_mode}, {name: languageCode, var: language_code}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    country_id: $country_id, region_code: $region_code, ascii_mode: $ascii_mode, language_code: $language_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find country region administrative divisions
#
# GET /geo/countries/{countryId}/regions/{regionCode}/adminDivisions
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findRegionDivisionsUsingGET
export def "find-region-divisions-using-get" [
  country_id: string
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
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort place results. 'Format: ±SORT_FIELD,±SORT_FIELD' where SORT_FIELD = elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/countries/{countryId}/regions/{regionCode}/adminDivisions"
    path_params: [{name: countryId, var: country_id}, {name: regionCode, var: region_code}]
    query: [{name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    country_id: $country_id, region_code: $region_code, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find country region cities
#
# GET /geo/countries/{countryId}/regions/{regionCode}/cities
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findRegionCitiesUsingGET
export def "find-region-cities-using-get" [
  country_id: string
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
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort place results. 'Format: ±SORT_FIELD,±SORT_FIELD' where SORT_FIELD = elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/countries/{countryId}/regions/{regionCode}/cities"
    path_params: [{name: countryId, var: country_id}, {name: regionCode, var: region_code}]
    query: [{name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: types, var: types}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    country_id: $country_id, region_code: $region_code, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, types: $types, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find cities near location
#
# GET /geo/locations/{locationId}/nearbyCities
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findCitiesNearLocationUsingGET
export def "find-cities-near-location-using-get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/locations/{locationId}/nearbyCities"
    path_params: [{name: locationId, var: location_id}]
    query: [{name: radius, var: radius}, {name: distanceUnit, var: distance_unit}, {name: countryIds, var: country_ids}, {name: excludedCountryIds, var: excluded_country_ids}, {name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: types, var: types}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    location_id: $location_id, radius: $radius, distance_unit: $distance_unit, country_ids: $country_ids, excluded_country_ids: $excluded_country_ids, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, types: $types, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find divisions near location
#
# GET /geo/locations/{locationId}/nearbyDivisions
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<country: string, countryCode: string, distance: float, id: int, latitude: float, longitude: float, name: string, population: int, region: string, regionCode: string, type: string, wikiDataId: string>>
# operationId: findDivisionsNearLocationUsingGET
export def "find-divisions-near-location-using-get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/geo/locations/{locationId}/nearbyDivisions"
    path_params: [{name: locationId, var: location_id}]
    query: [{name: radius, var: radius}, {name: distanceUnit, var: distance_unit}, {name: countryIds, var: country_ids}, {name: excludedCountryIds, var: excluded_country_ids}, {name: minPopulation, var: min_population}, {name: maxPopulation, var: max_population}, {name: namePrefix, var: name_prefix}, {name: namePrefixDefaultLangResults, var: name_prefix_default_lang_results}, {name: timeZoneIds, var: time_zone_ids}, {name: asciiMode, var: ascii_mode}, {name: hateoasMode, var: hateoas_mode}, {name: languageCode, var: language_code}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}, {name: includeDeleted, var: include_deleted}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    location_id: $location_id, radius: $radius, distance_unit: $distance_unit, country_ids: $country_ids, excluded_country_ids: $excluded_country_ids, min_population: $min_population, max_population: $max_population, name_prefix: $name_prefix, name_prefix_default_lang_results: $name_prefix_default_lang_results, time_zone_ids: $time_zone_ids, ascii_mode: $ascii_mode, hateoas_mode: $hateoas_mode, language_code: $language_code, limit: $limit, offset: $offset, sort: $sort, include_deleted: $include_deleted
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Find currencies
#
# GET /locale/currencies
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<code: string, countryCodes: list, symbol: string>>
# operationId: getCurrenciesUsingGET
export def "get-currencies-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # Currencies for this country id (required)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/currencies"
    query: [{name: countryId, var: country_id, required: true}, {name: hateoasMode, var: hateoas_mode}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    country_id: $country_id, hateoas_mode: $hateoas_mode, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get languages
#
# GET /locale/languages
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<code: string, name: string>>
# operationId: getLanguagesUsingGET
export def "get-languages-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/languages"
    query: [{name: hateoasMode, var: hateoas_mode}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    hateoas_mode: $hateoas_mode, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get locales
#
# GET /locale/locales
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<code: string>>
# operationId: getLocalesUsingGET
export def "get-locales-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/locales"
    query: [{name: hateoasMode, var: hateoas_mode}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    hateoas_mode: $hateoas_mode, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get time-zones
#
# GET /locale/timezones
# Returns: record<errors: table<code: string, message: string>, links: table<href: string, rel: string>, metadata: record<currentOffset: int, totalCount: int>, data: table<id: string, name: string, rawUtcOffsetHours: int>>
# operationId: getTimezonesUsingGET
export def "get-timezones-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/locale/timezones"
    query: [{name: hateoasMode, var: hateoas_mode}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    hateoas_mode: $hateoas_mode, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get time-zone
#
# GET /locale/timezones/{zoneId}
# Returns: record<errors: table<code: string, message: string>, id: string, name: string, rawUtcOffsetHours: int>
# operationId: getTimeZoneUsingGET
export def "get-time-zone-using-get" [
  zone_id: string
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
    path: "/locale/timezones/{zoneId}"
    path_params: [{name: zoneId, var: zone_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    zone_id: $zone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get time-zone date-time
#
# GET /locale/timezones/{zoneId}/dateTime
# Returns: record<errors: table<code: string, message: string>, data: string>
# operationId: getTimeZoneDateTimeUsingGET
export def "get-time-zone-date-time-using-get" [
  zone_id: string
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
    path: "/locale/timezones/{zoneId}/dateTime"
    path_params: [{name: zoneId, var: zone_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    zone_id: $zone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get time-zone time
#
# GET /locale/timezones/{zoneId}/time
# Returns: record<errors: table<code: string, message: string>, data: string>
# operationId: getTimeZoneTimeUsingGET
export def "get-time-zone-time-using-get" [
  zone_id: string
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
    path: "/locale/timezones/{zoneId}/time"
    path_params: [{name: zoneId, var: zone_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-rapidapi-key
  } {
    zone_id: $zone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
