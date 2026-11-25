# Auto-generated client for spoonacular API v1.1
# Source: https://api.apis.guru/v2/specs/spoonacular.com/1.1/openapi.json
# Auth: --token flag or $env.SPOONACULAR_API_TOKEN

const CLIENT = {
  base_url: "https://api.spoonacular.com"
  token_env_var: "SPOONACULAR_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-api-key, in: header, header_name: x-api-key, prefix: ""}
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

def base-url-completer [] { ["https://api.spoonacular.com"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def content-type-completer [] { ["application/json" "application/x-www-form-urlencoded" "multipart/form-data"] }
def language-completer [] { ["de" "en"] }
def add-menu-item-information-completer [] { ["false" "true"] }
def accept-completer [] { ["application/json" "media/*" "text/html"] }
def locale-completer [] { ["en_GB" "en_US"] }
def add-product-information-completer [] { ["false" "true"] }
def measure-completer [] { ["metric" "us"] }
def normalize-completer [] { ["false" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    talk-to-chatbot: "record<answerText: string, media: list<any>>"
    get-conversation-suggests: "record<suggests: record<_: list<record>>, words: list<any>>"
    search-custom-foods: "record<customFoods: table<id: int, imageUrl: string, price: float, servings: float, title: string>, number: int, offset: int, type: string>"
    detect-food-in-text: "record<annotations: table<annotation: string, image: string, tag: string>>"
    image-analysis-by-url: "record<category: record<name: string, probability: float>, nutrition: record<calories: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, carbs: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, fat: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, protein: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, recipesUsed: int>, recipes: table<id: int, imageType: string, title: string, url: string>>"
    image-classification-by-url: "record<category: string, probability: float>"
    autocomplete-ingredient-search: "table<aisle: string, id: int, image: string, name: string, possibleUnits: list<string>>"
    compute-glycemic-load: "record<ingredients: table<glycemicIndex: float, glycemicLoad: float, id: int, original: string>, totalGlycemicLoad: float>"
    map-ingredients-to-grocery-products: "table<ingredientImage: string, meta: list<string>, original: string, originalName: string, products: list<record>>"
    ingredient-search: "record<number: int, offset: int, results: table<id: int, image: string, name: string>, totalResults: int>"
    get-ingredient-substitutes: "record<ingredient: string, message: string, substitutes: list<string>>"
    compute-ingredient-amount: "record<amount: float, unit: string>"
    get-ingredient-information: "record<aisle: string, amount: float, categoryPath: list<string>, consistency: string, estimatedCost: record<unit: string, value: float>, id: int, image: string, meta: list<record>, name: string, nameClean: string, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>, properties: list<record>, weightPerServing: record<amount: float, unit: string>>, original: string, originalName: string, possibleUnits: list<string>, shoppingListUnits: list<string>, unit: string, unitLong: string, unitShort: string>"
    get-ingredient-substitutes-by-id: "record<ingredient: string, message: string, substitutes: list<string>>"
    get-a-random-food-joke: "record<text: string>"
    search-menu-items: "record<menuItems: table<id: int, image: string, imageType: string, restaurantChain: string, servings: record, title: string>, number: int, offset: int, totalMenuItems: int, type: string>"
    autocomplete-menu-item-search: "record<results: table<id: int, title: string>>"
    get-menu-item-information: "record<badges: list<string>, breadcrumbs: list<string>, generatedText: string, id: int, imageType: string, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, restaurantChain: string, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string>"
    menu-item-nutrition-label-widget: "string"
    menu-item-nutrition-label-image: "record"
    visualize-menu-item-nutrition-by-id: "string"
    menu-item-nutrition-by-id-image: "record"
    classify-grocery-product: "record<breadcrumbs: list<string>, category: string, cleanTitle: string, image: string, usdaCode: int>"
    classify-grocery-product-bulk: "table<breadcrumbs: list<string>, category: string, cleanTitle: string, image: string, usdaCode: int>"
    search-grocery-products: "record<number: int, offset: int, products: table<id: int, imageType: string, title: string>, totalProducts: int, type: string>"
    autocomplete-product-search: "record<results: table<id: int, title: string>>"
    search-grocery-products-by-upc: "record<badges: list<string>, breadcrumbs: list<string>, generatedText: string, id: int, imageType: string, importantBadges: list<string>, ingredientCount: int, ingredientList: string, ingredients: table<description: any, name: string, safety_level: any>, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string>"
    get-comparable-products: "record<comparableProducts: record<calories: list<record>, likes: list<record>, price: list<record>, protein: list<record>, spoonacularScore: list<record>, sugar: list<record>>>"
    get-product-information: "record<aisle: string, badges: list<string>, breadcrumbs: list<string>, generatedText: any, id: int, imageType: string, importantBadges: list<string>, ingredientCount: int, ingredientList: string, ingredients: table<description: any, name: string, safety_level: any>, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string>"
    product-nutrition-label-widget: "string"
    product-nutrition-label-image: "record"
    visualize-product-nutrition-by-id: "string"
    product-nutrition-by-id-image: "record"
    search-restaurants: "record<restaurants: table<_id: string, address: record, aggregated_rating_count: int, cuisines: list, delivery_enabled: bool, description: string, dollar_signs: int, food_photos: list, is_open: bool, local_hours: record, logo_photos: list, miles: float, name: string, offers_first_party_delivery: bool, offers_third_party_delivery: bool, phone_number: int, pickup_enabled: bool, store_photos: list, type: string, weighted_rating_value: float>>"
    search-all-food: "record<limit: int, offset: int, query: string, searchResults: table<name: string, results: list, totalResults: int>, totalResults: int>"
    search-site-content: "record<Articles: table<dataPoints: list, image: string, link: string, name: string>, \"Grocery Products\": table<dataPoints: list, image: string, link: string, name: string>, \"Menu Items\": table<dataPoints: list, image: string, link: string, name: string>, Recipes: table<dataPoints: list, image: string, link: string, name: string>>"
    get-random-food-trivia: "record<text: string>"
    search-food-videos: "record<totalResults: int, videos: table<length: int, rating: float, shortTitle: string, thumbnail: string, title: string, views: int, youTubeId: string>>"
    get-wine-description: "record<wineDescription: string>"
    get-dish-pairing-for-wine: "record<pairings: list<string>, text: string>"
    get-wine-pairing: "record<pairedWines: list<string>, pairingText: string, productMatches: table<averageRating: float, description: any, id: int, imageUrl: string, link: string, price: string, ratingCount: int, score: float, title: string>>"
    get-wine-recommendation: "record<recommendedWines: table<averageRating: float, description: string, id: int, imageUrl: string, link: string, price: string, ratingCount: int, score: float, title: string>, totalFound: int>"
    generate-meal-plan: "record<meals: table<id: int, imageType: string, readyInMinutes: int, servings: float, sourceUrl: string, title: string>, nutrients: record<calories: float, carbohydrates: float, fat: float, protein: float>>"
    clear-meal-plan-day: "record"
    add-to-meal-plan: "record"
    delete-from-meal-plan: "record"
    get-shopping-list: "record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float>"
    add-to-shopping-list: "record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float>"
    delete-from-shopping-list: "record"
    generate-shopping-list: "record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float>"
    get-meal-plan-templates: "record<templates: table<id: int, name: string>>"
    add-meal-plan-template: "record<items: table<day: int, position: int, slot: int, type: string, value: record>, name: string, publishAsPublic: bool>"
    delete-meal-plan-template: "record"
    get-meal-plan-template: "record<days: table<day: string, items: list, nutritionSummary: record, nutritionSummaryBreakfast: record, nutritionSummaryDinner: record, nutritionSummaryLunch: record>, id: int, name: string>"
    get-meal-plan-week: "record<days: table<date: float, day: string, items: list, nutritionSummary: record, nutritionSummaryBreakfast: record, nutritionSummaryDinner: record, nutritionSummaryLunch: record>>"
    analyze-recipe: "record"
    analyze-recipe-instructions: "record<equipment: table<id: float, name: string>, ingredients: table<id: float, name: string>, parsedInstructions: table<name: string, steps: list>>"
    autocomplete-recipe-search: "table<id: int, imageType: string, title: string>"
    search-recipes: "record<number: int, offset: int, results: table<calories: float, carbs: string, fat: string, id: int, image: string, imageType: string, protein: string, title: string>, totalResults: int>"
    convert-amounts: "record<answer: string, sourceAmount: float, sourceUnit: string, targetAmount: float, targetUnit: string>"
    classify-cuisine: "record<confidence: float, cuisine: string, cuisines: list<string>>"
    extract-recipe-from-website: "record<aggregateLikes: int, analyzedInstructions: list<record>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: table<aisle: string, amount: float, consitency: string, id: int, image: string, measures: record, meta: list, name: string, original: string, originalName: string, unit: string>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list<string>, pairingText: string, productMatches: list<record>>>"
    search-recipes-by-ingredients: "table<id: int, image: string, imageType: string, likes: int, missedIngredientCount: int, missedIngredients: list<record>, title: string, unusedIngredients: list<record>, usedIngredientCount: float, usedIngredients: list<record>>"
    search-recipes-by-nutrients: "table<calories: float, carbs: string, fat: string, id: int, image: string, imageType: string, protein: string, title: string>"
    guess-nutrition-by-dish-name: "record<calories: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, carbs: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, fat: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, protein: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, recipesUsed: int>"
    get-recipe-information-bulk: "table<aggregateLikes: int, analyzedInstructions: list<string>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: list<record>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list, pairingText: string, productMatches: list>>"
    parse-ingredients: "table<aisle: string, amount: float, consistency: string, estimatedCost: record<unit: string, value: float>, id: int, image: string, meta: list<string>, name: string, nameClean: string, nutrition: record<caloricBreakdown: record, flavonoids: list, nutrients: list, properties: list, weightPerServing: record>, original: string, originalName: string, possibleUnits: list<string>, unit: string, unitLong: string, unitShort: string>"
    analyze-a-recipe-search-query: "record<cuisines: list<string>, dishes: table<image: string, name: string>, ingredients: table<image: string, include: bool, name: string>, modifiers: list<string>>"
    quick-answer: "record<answer: string, image: string>"
    get-random-recipes: "record<recipes: table<aggregateLikes: float, analyzedInstructions: list, cheap: bool, creditsText: string, cuisines: list, dairyFree: bool, diets: list, dishTypes: list, extendedIngredients: list, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record>>"
    visualize-equipment: "string"
    visualize-ingredients: "string"
    visualize-recipe-nutrition: "string"
    visualize-price-breakdown: "string"
    create-recipe-card: "record<url: string>"
    visualize-recipe-taste: "string"
    get-analyzed-recipe-instructions: "record<equipment: table<id: int, name: string>, ingredients: table<id: int, name: string>, parsedInstructions: table<name: string, steps: list>>"
    create-recipe-card-get: "record"
    visualize-recipe-equipment-by-id: "string"
    get-recipe-equipment-by-id: "record<equipment: table<image: string, name: string>>"
    equipment-by-id-image: "record"
    get-recipe-information: "record<aggregateLikes: int, analyzedInstructions: list<record>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: table<aisle: string, amount: float, consitency: string, id: int, image: string, measures: record, meta: list, name: string, original: string, originalName: string, unit: string>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list<string>, pairingText: string, productMatches: list<record>>>"
    visualize-recipe-ingredients-by-id: "string"
    get-recipe-ingredients-by-id: "record<ingredients: table<amount: record, image: string, name: string>>"
    ingredients-by-id-image: "record"
    recipe-nutrition-label-widget: "string"
    recipe-nutrition-label-image: "record"
    visualize-recipe-nutrition-by-id: "string"
    get-recipe-nutrition-widget-by-id: "record<bad: table<amount: string, indented: bool, name: string, percentOfDailyNeeds: float>, calories: string, carbs: string, fat: string, good: table<amount: string, indented: bool, name: string, percentOfDailyNeeds: float>, protein: string>"
    recipe-nutrition-by-id-image: "record"
    visualize-recipe-price-breakdown-by-id: "string"
    get-recipe-price-breakdown-by-id: "record<ingredients: table<amount: record, image: string, name: string, price: float>, totalCost: float, totalCostPerServing: float>"
    price-breakdown-by-id-image: "record"
    get-similar-recipes: "table<id: int, imageType: string, readyInMinutes: int, servings: float, sourceUrl: string, title: string>"
    summarize-recipe: "record<id: int, summary: string, title: string>"
    visualize-recipe-taste-by-id: "string"
    get-recipe-taste-by-id: "record<bitterness: float, fattiness: float, saltiness: float, savoriness: float, sourness: float, spiciness: float, sweetness: float>"
    recipe-taste-by-id-image: "record"
    connect-user: "record<hash: string, username: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["talk-to-chatbot" "get-conversation-suggests" "search-custom-foods" "detect-food-in-text" "image-analysis-by-url" "image-classification-by-url" "autocomplete-ingredient-search" "compute-glycemic-load" "map-ingredients-to-grocery-products" "ingredient-search" "get-ingredient-substitutes" "compute-ingredient-amount" "get-ingredient-information" "get-ingredient-substitutes-by-id" "get-a-random-food-joke" "search-menu-items" "autocomplete-menu-item-search" "get-menu-item-information" "menu-item-nutrition-label-widget" "menu-item-nutrition-label-image" "visualize-menu-item-nutrition-by-id" "menu-item-nutrition-by-id-image" "classify-grocery-product" "classify-grocery-product-bulk" "search-grocery-products" "autocomplete-product-search" "search-grocery-products-by-upc" "get-comparable-products" "get-product-information" "product-nutrition-label-widget" "product-nutrition-label-image" "visualize-product-nutrition-by-id" "product-nutrition-by-id-image" "search-restaurants" "search-all-food" "search-site-content" "get-random-food-trivia" "search-food-videos" "get-wine-description" "get-dish-pairing-for-wine" "get-wine-pairing" "get-wine-recommendation" "generate-meal-plan" "clear-meal-plan-day" "add-to-meal-plan" "delete-from-meal-plan" "get-shopping-list" "add-to-shopping-list" "delete-from-shopping-list" "generate-shopping-list" "get-meal-plan-templates" "add-meal-plan-template" "delete-meal-plan-template" "get-meal-plan-template" "get-meal-plan-week" "analyze-recipe" "analyze-recipe-instructions" "autocomplete-recipe-search" "search-recipes" "convert-amounts" "classify-cuisine" "extract-recipe-from-website" "search-recipes-by-ingredients" "search-recipes-by-nutrients" "guess-nutrition-by-dish-name" "get-recipe-information-bulk" "parse-ingredients" "analyze-a-recipe-search-query" "quick-answer" "get-random-recipes" "visualize-equipment" "visualize-ingredients" "visualize-recipe-nutrition" "visualize-price-breakdown" "create-recipe-card" "visualize-recipe-taste" "get-analyzed-recipe-instructions" "create-recipe-card-get" "visualize-recipe-equipment-by-id" "get-recipe-equipment-by-id" "equipment-by-id-image" "get-recipe-information" "visualize-recipe-ingredients-by-id" "get-recipe-ingredients-by-id" "ingredients-by-id-image" "recipe-nutrition-label-widget" "recipe-nutrition-label-image" "visualize-recipe-nutrition-by-id" "get-recipe-nutrition-widget-by-id" "recipe-nutrition-by-id-image" "visualize-recipe-price-breakdown-by-id" "get-recipe-price-breakdown-by-id" "price-breakdown-by-id-image" "get-similar-recipes" "summarize-recipe" "visualize-recipe-taste-by-id" "get-recipe-taste-by-id" "recipe-taste-by-id-image" "connect-user" "commands"] | sort) } | get name | first)
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

# Talk to Chatbot
#
# GET /food/converse
# Docs: https://spoonacular.com/food-api/docs#Talk-to-Chatbot — Read entire docs
# Returns: record<answerText: string, media: list<any>>
# operationId: talkToChatbot
export def "talk-to-chatbot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # The request / question / answer from the user to the chatbot. (required, e.g. donut recipes)
  --context-id: string # An arbitrary globally unique id for your conversation. The conversation can contain states so you should pass your context id if you want the bot to be able to remember the conversation. (e.g. 342938)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/converse"
    query: [{name: text, var: text, required: true}, {name: contextId, var: context_id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    text: $text, context_id: $context_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Conversation Suggests
#
# GET /food/converse/suggest
# Docs: https://spoonacular.com/food-api/docs#Conversation-Suggests — Read entire docs
# Returns: record<suggests: record<_: list<record>>, words: list<any>>
# operationId: getConversationSuggests
export def "get-conversation-suggests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A (partial) query from the user. The endpoint will return if it matches topics it can talk about. (required, e.g. tell)
  --number: float # The number of suggestions to return (between 1 and 25). (e.g. 5)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/converse/suggest"
    query: [{name: query, var: query, required: true}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Custom Foods
#
# GET /food/customFoods/search
# Docs: https://spoonacular.com/food-api/docs#Search-Custom-Foods — Read entire docs
# Returns: record<customFoods: table<id: int, imageUrl: string, price: float, servings: float, title: string>, number: int, offset: int, type: string>
# operationId: searchCustomFoods
export def "search-custom-foods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --username: string # The username. (required, e.g. dsky)
  --hash: string # The private hash for the username. (required, e.g. 4b5v4398573406)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/customFoods/search"
    query: [{name: query, var: query}, {name: username, var: username, required: true}, {name: hash, var: hash, required: true}, {name: offset, var: offset}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, username: $username, hash: $hash, offset: $offset, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detect Food in Text
#
# POST /food/detect
# Docs: https://spoonacular.com/food-api/docs#Detect-Food-in-Text — Read entire docs
# Returns: record<annotations: table<annotation: string, image: string, tag: string>>
# operationId: detectFoodInText
export def "detect-food-in-text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/food/detect"
    header: [{name: Content-Type, var: content_type}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image Analysis by URL
#
# GET /food/images/analyze
# Docs: https://spoonacular.com/food-api/docs#Image-Analysis-by-URL — Read entire docs
# Returns: record<category: record<name: string, probability: float>, nutrition: record<calories: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, carbs: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, fat: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, protein: record<confidenceRange95Percent: record, standardDeviation: float, unit: string, value: float>, recipesUsed: int>, recipes: table<id: int, imageType: string, title: string, url: string>>
# operationId: imageAnalysisByURL
export def "image-analysis-by-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-url: string # The URL of the image to be analyzed. (required, e.g. https://spoonacular.com/recipeImages/635350-240x150.jpg)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/images/analyze"
    query: [{name: imageUrl, var: image_url, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    image_url: $image_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Image Classification by URL
#
# GET /food/images/classify
# Docs: https://spoonacular.com/food-api/docs#Image-Classification-by-URL — Read entire docs
# Returns: record<category: string, probability: float>
# operationId: imageClassificationByURL
export def "image-classification-by-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-url: string # The URL of the image to be classified. (required, e.g. https://spoonacular.com/recipeImages/635350-240x150.jpg)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/images/classify"
    query: [{name: imageUrl, var: image_url, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    image_url: $image_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Autocomplete Ingredient Search
#
# GET /food/ingredients/autocomplete
# Docs: https://spoonacular.com/food-api/docs#Autocomplete-Ingredient-Search — Read entire docs
# Returns: table<aisle: string, id: int, image: string, name: string, possibleUnits: list<string>>
# operationId: autocompleteIngredientSearch
export def "autocomplete-ingredient-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --meta-information: oneof<nothing, bool> # Whether to return more meta information about the ingredients. (e.g. false)
  --intolerances: string # A comma-separated list of intolerances. All recipes returned must not contain ingredients that are not suitable for people with the intolerances entered. See a full list of supported intolerances. (e.g. egg)
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/food/ingredients/autocomplete"
    query: [{name: query, var: query}, {name: number, var: number}, {name: metaInformation, var: meta_information}, {name: intolerances, var: intolerances}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, number: $number, meta_information: $meta_information, intolerances: $intolerances, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compute Glycemic Load
#
# POST /food/ingredients/glycemicLoad
# Docs: https://spoonacular.com/food-api/docs#Compute-Glycemic-Load — Read entire docs
# Returns: record<ingredients: table<glycemicIndex: float, glycemicLoad: float, id: int, original: string>, totalGlycemicLoad: float>
# operationId: computeGlycemicLoad
export def "compute-glycemic-load" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  ingredients: list<string>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/food/ingredients/glycemicLoad"
    query: [{name: language, var: language}]
    body: {content_type: "application/json", kind: json, fields: [{name: ingredients, var: ingredients}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    language: $language, ingredients: $ingredients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Map Ingredients to Grocery Products
#
# POST /food/ingredients/map
# Docs: https://spoonacular.com/food-api/docs#Map-Ingredients-to-Grocery-Products — Read entire docs
# Returns: table<ingredientImage: string, meta: list<string>, original: string, originalName: string, products: list<record>>
# operationId: mapIngredientsToGroceryProducts
export def "map-ingredients-to-grocery-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ingredients: list<string>
  servings: float
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/food/ingredients/map"
    body: {content_type: "application/json", kind: json, fields: [{name: ingredients, var: ingredients}, {name: servings, var: servings}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    ingredients: $ingredients, servings: $servings
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ingredient Search
#
# GET /food/ingredients/search
# Docs: https://spoonacular.com/food-api/docs#Ingredient-Search — Read entire docs
# Returns: record<number: int, offset: int, results: table<id: int, image: string, name: string>, totalResults: int>
# operationId: ingredientSearch
export def "ingredient-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --add-children: oneof<nothing, bool> # Whether to add children of found foods. (e.g. true)
  --min-protein-percent: float # The minimum percentage of protein the food must have (between 0 and 100). (e.g. 10)
  --max-protein-percent: float # The maximum percentage of protein the food can have (between 0 and 100). (e.g. 90)
  --min-fat-percent: float # The minimum percentage of fat the food must have (between 0 and 100). (e.g. 10)
  --max-fat-percent: float # The maximum percentage of fat the food can have (between 0 and 100). (e.g. 90)
  --min-carbs-percent: float # The minimum percentage of carbs the food must have (between 0 and 100). (e.g. 10)
  --max-carbs-percent: float # The maximum percentage of carbs the food can have (between 0 and 100). (e.g. 90)
  --meta-information: oneof<nothing, bool> # Whether to return more meta information about the ingredients. (e.g. false)
  --intolerances: string # A comma-separated list of intolerances. All recipes returned must not contain ingredients that are not suitable for people with the intolerances entered. See a full list of supported intolerances. (e.g. egg)
  --sort: string # The strategy to sort recipes by. See a full list of supported sorting options. (e.g. calories)
  --sort-direction: string # The direction in which to sort. Must be either 'asc' (ascending) or 'desc' (descending). (e.g. asc)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/ingredients/search"
    query: [{name: query, var: query}, {name: addChildren, var: add_children}, {name: minProteinPercent, var: min_protein_percent}, {name: maxProteinPercent, var: max_protein_percent}, {name: minFatPercent, var: min_fat_percent}, {name: maxFatPercent, var: max_fat_percent}, {name: minCarbsPercent, var: min_carbs_percent}, {name: maxCarbsPercent, var: max_carbs_percent}, {name: metaInformation, var: meta_information}, {name: intolerances, var: intolerances}, {name: sort, var: sort}, {name: sortDirection, var: sort_direction}, {name: offset, var: offset}, {name: number, var: number}, {name: language, var: language}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, add_children: $add_children, min_protein_percent: $min_protein_percent, max_protein_percent: $max_protein_percent, min_fat_percent: $min_fat_percent, max_fat_percent: $max_fat_percent, min_carbs_percent: $min_carbs_percent, max_carbs_percent: $max_carbs_percent, meta_information: $meta_information, intolerances: $intolerances, sort: $sort, sort_direction: $sort_direction, offset: $offset, number: $number, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Ingredient Substitutes
#
# GET /food/ingredients/substitutes
# Docs: https://spoonacular.com/food-api/docs#Get-Ingredient-Substitutes — Read entire docs
# Returns: record<ingredient: string, message: string, substitutes: list<string>>
# operationId: getIngredientSubstitutes
export def "get-ingredient-substitutes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ingredient-name: string # The name of the ingredient you want to replace. (required, e.g. butter)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/ingredients/substitutes"
    query: [{name: ingredientName, var: ingredient_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    ingredient_name: $ingredient_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compute Ingredient Amount
#
# GET /food/ingredients/{id}/amount
# Docs: https://spoonacular.com/food-api/docs#Compute-Ingredient-Amount — Read entire docs
# Returns: record<amount: float, unit: string>
# operationId: computeIngredientAmount
export def "compute-ingredient-amount" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nutrient: string # The target nutrient. See a list of supported nutrients. (required, e.g. protein)
  --target: float # The target number of the given nutrient. (required, e.g. 2)
  --unit: string # The target unit. (e.g. oz)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/ingredients/{id}/amount"
    path_params: [{name: id, var: id}]
    query: [{name: nutrient, var: nutrient, required: true}, {name: target, var: target, required: true}, {name: unit, var: unit}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, nutrient: $nutrient, target: $target, unit: $unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Ingredient Information
#
# GET /food/ingredients/{id}/information
# Docs: https://spoonacular.com/food-api/docs#Get-Ingredient-Information — Read entire docs
# Returns: record<aisle: string, amount: float, categoryPath: list<string>, consistency: string, estimatedCost: record<unit: string, value: float>, id: int, image: string, meta: list<record>, name: string, nameClean: string, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>, properties: list<record>, weightPerServing: record<amount: float, unit: string>>, original: string, originalName: string, possibleUnits: list<string>, shoppingListUnits: list<string>, unit: string, unitLong: string, unitShort: string>
# operationId: getIngredientInformation
export def "get-ingredient-information" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # The amount of this ingredient. (e.g. 150)
  --unit: string # The unit for the given amount. (e.g. grams)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/ingredients/{id}/information"
    path_params: [{name: id, var: id}]
    query: [{name: amount, var: amount}, {name: unit, var: unit}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, amount: $amount, unit: $unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Ingredient Substitutes by ID
#
# GET /food/ingredients/{id}/substitutes
# Docs: https://spoonacular.com/food-api/docs#Get-Ingredient-Substitutes-by-ID — Read entire docs
# Returns: record<ingredient: string, message: string, substitutes: list<string>>
# operationId: getIngredientSubstitutesByID
export def "get-ingredient-substitutes-by-id" [
  id: float
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
    path: "/food/ingredients/{id}/substitutes"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Random Food Joke
#
# GET /food/jokes/random
# Docs: https://spoonacular.com/food-api/docs#Random-Food-Joke — Read entire docs
# Returns: record<text: string>
# operationId: getARandomFoodJoke
export def "get-a-random-food-joke" [
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
    path: "/food/jokes/random"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Menu Items
#
# GET /food/menuItems/search
# Docs: https://spoonacular.com/food-api/docs#Search-Menu-Items — Read entire docs
# Returns: record<menuItems: table<id: int, image: string, imageType: string, restaurantChain: string, servings: record, title: string>, number: int, offset: int, totalMenuItems: int, type: string>
# operationId: searchMenuItems
export def "search-menu-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --min-calories: float # The minimum amount of calories the menu item must have. (e.g. 50)
  --max-calories: float # The maximum amount of calories the menu item can have. (e.g. 800)
  --min-carbs: float # The minimum amount of carbohydrates in grams the menu item must have. (e.g. 10)
  --max-carbs: float # The maximum amount of carbohydrates in grams the menu item can have. (e.g. 100)
  --min-protein: float # The minimum amount of protein in grams the menu item must have. (e.g. 10)
  --max-protein: float # The maximum amount of protein in grams the menu item can have. (e.g. 100)
  --min-fat: float # The minimum amount of fat in grams the menu item must have. (e.g. 1)
  --max-fat: float # The maximum amount of fat in grams the menu item can have. (e.g. 100)
  --add-menu-item-information: oneof<nothing, bool> # If set to true, you get more information about the menu items returned. (e.g. true)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/menuItems/search"
    query: [{name: query, var: query}, {name: minCalories, var: min_calories}, {name: maxCalories, var: max_calories}, {name: minCarbs, var: min_carbs}, {name: maxCarbs, var: max_carbs}, {name: minProtein, var: min_protein}, {name: maxProtein, var: max_protein}, {name: minFat, var: min_fat}, {name: maxFat, var: max_fat}, {name: addMenuItemInformation, var: add_menu_item_information}, {name: offset, var: offset}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, min_calories: $min_calories, max_calories: $max_calories, min_carbs: $min_carbs, max_carbs: $max_carbs, min_protein: $min_protein, max_protein: $max_protein, min_fat: $min_fat, max_fat: $max_fat, add_menu_item_information: $add_menu_item_information, offset: $offset, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Autocomplete Menu Item Search
#
# GET /food/menuItems/suggest
# Docs: https://spoonacular.com/food-api/docs#Autocomplete-Menu-Item-Search — Read entire docs
# Returns: record<results: table<id: int, title: string>>
# operationId: autocompleteMenuItemSearch
export def "autocomplete-menu-item-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (partial) search query. (required, e.g. chicke)
  --number: float # The number of results to return (between 1 and 25). (e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/menuItems/suggest"
    query: [{name: query, var: query, required: true}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Menu Item Information
#
# GET /food/menuItems/{id}
# Docs: https://spoonacular.com/food-api/docs#Get-Menu-Item-Information — Read entire docs
# Returns: record<badges: list<string>, breadcrumbs: list<string>, generatedText: string, id: int, imageType: string, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, restaurantChain: string, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string>
# operationId: getMenuItemInformation
export def "get-menu-item-information" [
  id: float
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
    path: "/food/menuItems/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Menu Item Nutrition Label Widget
#
# GET /food/menuItems/{id}/nutritionLabel
# Docs: https://spoonacular.com/food-api/docs#Menu-Item-Nutrition-Label-Widget — Read entire docs
# Returns: string
# operationId: menuItemNutritionLabelWidget
export def "menu-item-nutrition-label-widget" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  http-request {
    method: get
    path: "/food/menuItems/{id}/nutritionLabel"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}, {name: showOptionalNutrients, var: show_optional_nutrients}, {name: showZeroValues, var: show_zero_values}, {name: showIngredients, var: show_ingredients}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css, show_optional_nutrients: $show_optional_nutrients, show_zero_values: $show_zero_values, show_ingredients: $show_ingredients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Menu Item Nutrition Label Image
#
# GET /food/menuItems/{id}/nutritionLabel.png
# Docs: https://spoonacular.com/food-api/docs#Menu-Item-Nutrition-Label-Image — Read entire docs
# Returns: record
# operationId: menuItemNutritionLabelImage
export def "menu-item-nutrition-label-image" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/menuItems/{id}/nutritionLabel.png"
    path_params: [{name: id, var: id}]
    query: [{name: showOptionalNutrients, var: show_optional_nutrients}, {name: showZeroValues, var: show_zero_values}, {name: showIngredients, var: show_ingredients}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, show_optional_nutrients: $show_optional_nutrients, show_zero_values: $show_zero_values, show_ingredients: $show_ingredients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Menu Item Nutrition by ID Widget
#
# GET /food/menuItems/{id}/nutritionWidget
# Docs: https://spoonacular.com/food-api/docs#Menu-Item-Nutrition-by-ID-Widget — Read entire docs
# Returns: string
# operationId: visualizeMenuItemNutritionByID
export def "visualize-menu-item-nutrition-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/food/menuItems/{id}/nutritionWidget"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Menu Item Nutrition by ID Image
#
# GET /food/menuItems/{id}/nutritionWidget.png
# Docs: https://spoonacular.com/food-api/docs#Menu-Item-Nutrition-by-ID-Image — Read entire docs
# Returns: record
# operationId: menuItemNutritionByIDImage
export def "menu-item-nutrition-by-id-image" [
  id: float
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
    path: "/food/menuItems/{id}/nutritionWidget.png"
    path_params: [{name: id, var: id}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Classify Grocery Product
#
# POST /food/products/classify
# Docs: https://spoonacular.com/food-api/docs#Classify-Grocery-Product — Read entire docs
# Returns: record<breadcrumbs: list<string>, category: string, cleanTitle: string, image: string, usdaCode: int>
# operationId: classifyGroceryProduct
export def "classify-grocery-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string@locale-completer # The display name of the returned category, supported is en_US (for American English) and en_GB (for British English). (e.g. en_US)
  plu_code: string
  title: string
  upc: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/food/products/classify"
    query: [{name: locale, var: locale}]
    body: {content_type: "application/json", kind: json, fields: [{name: plu_code, var: plu_code}, {name: title, var: title}, {name: upc, var: upc}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    locale: $locale, plu_code: $plu_code, title: $title, upc: $upc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Classify Grocery Product Bulk
#
# POST /food/products/classifyBatch
# Docs: https://spoonacular.com/food-api/docs#Classify-Grocery-Product-Bulk — Read entire docs
# Returns: table<breadcrumbs: list<string>, category: string, cleanTitle: string, image: string, usdaCode: int>
# operationId: classifyGroceryProductBulk
export def "classify-grocery-product-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The display name of the returned category, supported is en_US (for American English) and en_GB (for British English). (e.g. en_US)
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/food/products/classifyBatch"
    query: [{name: locale, var: locale}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    locale: $locale, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Grocery Products
#
# GET /food/products/search
# Docs: https://spoonacular.com/food-api/docs#Search-Grocery-Products — Read entire docs
# Returns: record<number: int, offset: int, products: table<id: int, imageType: string, title: string>, totalProducts: int, type: string>
# operationId: searchGroceryProducts
export def "search-grocery-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --min-calories: float # The minimum amount of calories the product must have. (e.g. 50)
  --max-calories: float # The maximum amount of calories the product can have. (e.g. 800)
  --min-carbs: float # The minimum amount of carbohydrates in grams the product must have. (e.g. 10)
  --max-carbs: float # The maximum amount of carbohydrates in grams the product can have. (e.g. 100)
  --min-protein: float # The minimum amount of protein in grams the product must have. (e.g. 10)
  --max-protein: float # The maximum amount of protein in grams the product can have. (e.g. 100)
  --min-fat: float # The minimum amount of fat in grams the product must have. (e.g. 1)
  --max-fat: float # The maximum amount of fat in grams the product can have. (e.g. 100)
  --add-product-information: oneof<nothing, bool> # If set to true, you get more information about the products returned. (e.g. true)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/products/search"
    query: [{name: query, var: query}, {name: minCalories, var: min_calories}, {name: maxCalories, var: max_calories}, {name: minCarbs, var: min_carbs}, {name: maxCarbs, var: max_carbs}, {name: minProtein, var: min_protein}, {name: maxProtein, var: max_protein}, {name: minFat, var: min_fat}, {name: maxFat, var: max_fat}, {name: addProductInformation, var: add_product_information}, {name: offset, var: offset}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, min_calories: $min_calories, max_calories: $max_calories, min_carbs: $min_carbs, max_carbs: $max_carbs, min_protein: $min_protein, max_protein: $max_protein, min_fat: $min_fat, max_fat: $max_fat, add_product_information: $add_product_information, offset: $offset, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Autocomplete Product Search
#
# GET /food/products/suggest
# Docs: https://spoonacular.com/food-api/docs#Autocomplete-Product-Search — Read entire docs
# Returns: record<results: table<id: int, title: string>>
# operationId: autocompleteProductSearch
export def "autocomplete-product-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (partial) search query. (required, e.g. chicke)
  --number: int # The number of results to return (between 1 and 25). (e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/products/suggest"
    query: [{name: query, var: query, required: true}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Grocery Products by UPC
#
# GET /food/products/upc/{upc}
# Docs: https://spoonacular.com/food-api/docs#Search-Grocery-Products-by-UPC — Read entire docs
# Returns: record<badges: list<string>, breadcrumbs: list<string>, generatedText: string, id: int, imageType: string, importantBadges: list<string>, ingredientCount: int, ingredientList: string, ingredients: table<description: any, name: string, safety_level: any>, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string>
# operationId: searchGroceryProductsByUPC
export def "search-grocery-products-by-upc" [
  upc: float
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
    path: "/food/products/upc/{upc}"
    path_params: [{name: upc, var: upc}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    upc: $upc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Comparable Products
#
# GET /food/products/upc/{upc}/comparable
# Docs: https://spoonacular.com/food-api/docs#Get-Comparable-Products — Read entire docs
# Returns: record<comparableProducts: record<calories: list<record>, likes: list<record>, price: list<record>, protein: list<record>, spoonacularScore: list<record>, sugar: list<record>>>
# operationId: getComparableProducts
export def "get-comparable-products" [
  upc: float
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
    path: "/food/products/upc/{upc}/comparable"
    path_params: [{name: upc, var: upc}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    upc: $upc
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Product Information
#
# GET /food/products/{id}
# Docs: https://spoonacular.com/food-api/docs#Get-Product-Information — Read entire docs
# Returns: record<aisle: string, badges: list<string>, breadcrumbs: list<string>, generatedText: any, id: int, imageType: string, importantBadges: list<string>, ingredientCount: int, ingredientList: string, ingredients: table<description: any, name: string, safety_level: any>, likes: float, nutrition: record<caloricBreakdown: record<percentCarbs: float, percentFat: float, percentProtein: float>, nutrients: list<record>>, price: float, servings: record<number: float, size: float, unit: string>, spoonacularScore: float, title: string>
# operationId: getProductInformation
export def "get-product-information" [
  id: float
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
    path: "/food/products/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Product Nutrition Label Widget
#
# GET /food/products/{id}/nutritionLabel
# Docs: https://spoonacular.com/food-api/docs#Product-Nutrition-Label-Widget — Read entire docs
# Returns: string
# operationId: productNutritionLabelWidget
export def "product-nutrition-label-widget" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  http-request {
    method: get
    path: "/food/products/{id}/nutritionLabel"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}, {name: showOptionalNutrients, var: show_optional_nutrients}, {name: showZeroValues, var: show_zero_values}, {name: showIngredients, var: show_ingredients}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css, show_optional_nutrients: $show_optional_nutrients, show_zero_values: $show_zero_values, show_ingredients: $show_ingredients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Product Nutrition Label Image
#
# GET /food/products/{id}/nutritionLabel.png
# Docs: https://spoonacular.com/food-api/docs#Product-Nutrition-Label-Image — Read entire docs
# Returns: record
# operationId: productNutritionLabelImage
export def "product-nutrition-label-image" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/products/{id}/nutritionLabel.png"
    path_params: [{name: id, var: id}]
    query: [{name: showOptionalNutrients, var: show_optional_nutrients}, {name: showZeroValues, var: show_zero_values}, {name: showIngredients, var: show_ingredients}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, show_optional_nutrients: $show_optional_nutrients, show_zero_values: $show_zero_values, show_ingredients: $show_ingredients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Product Nutrition by ID Widget
#
# GET /food/products/{id}/nutritionWidget
# Docs: https://spoonacular.com/food-api/docs#Product-Nutrition-by-ID-Widget — Read entire docs
# Returns: string
# operationId: visualizeProductNutritionByID
export def "visualize-product-nutrition-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/food/products/{id}/nutritionWidget"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Product Nutrition by ID Image
#
# GET /food/products/{id}/nutritionWidget.png
# Docs: https://spoonacular.com/food-api/docs#Product-Nutrition-by-ID-Image — Read entire docs
# Returns: record
# operationId: productNutritionByIDImage
export def "product-nutrition-by-id-image" [
  id: float
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
    path: "/food/products/{id}/nutritionWidget.png"
    path_params: [{name: id, var: id}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Restaurants
#
# GET /food/restaurants/search
# Docs: https://spoonacular.com/food-api/docs#Search-Restaurants — Read entire docs
# Returns: record<restaurants: table<_id: string, address: record, aggregated_rating_count: int, cuisines: list, delivery_enabled: bool, description: string, dollar_signs: int, food_photos: list, is_open: bool, local_hours: record, logo_photos: list, miles: float, name: string, offers_first_party_delivery: bool, offers_third_party_delivery: bool, phone_number: int, pickup_enabled: bool, store_photos: list, type: string, weighted_rating_value: float>>
# operationId: searchRestaurants
export def "search-restaurants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The search query. (e.g. beach cafe)
  --lat: float # The latitude of the user's location. (e.g. 37.7786357)
  --lng: float # The longitude of the user's location.". (e.g. -122.3918135)
  --distance: float # The distance around the location in miles. (e.g. 2)
  --budget: float # The user's budget for a meal in USD. (e.g. 20)
  --cuisine: string # The cuisine of the restaurant. (e.g. italian)
  --min-rating: float # The minimum rating of the restaurant between 0 and 5. (e.g. 4.4)
  --is-open: oneof<nothing, bool> # Whether the restaurant must be open at the time of search. (e.g. true)
  --sort: string # How to sort the results, one of the following 'cheapest', 'fastest', 'rating', 'distance' or the default 'relevance'. (e.g. distance)
  --page: float # The page number of results. (e.g. 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/restaurants/search"
    query: [{name: query, var: query}, {name: lat, var: lat}, {name: lng, var: lng}, {name: distance, var: distance}, {name: budget, var: budget}, {name: cuisine, var: cuisine}, {name: min-rating, var: min_rating}, {name: is-open, var: is_open}, {name: sort, var: sort}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, lat: $lat, lng: $lng, distance: $distance, budget: $budget, cuisine: $cuisine, min_rating: $min_rating, is_open: $is_open, sort: $sort, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search All Food
#
# GET /food/search
# Docs: https://spoonacular.com/food-api/docs#Search-All-Food — Read entire docs
# Returns: record<limit: int, offset: int, query: string, searchResults: table<name: string, results: list, totalResults: int>, totalResults: int>
# operationId: searchAllFood
export def "search-all-food" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The search query. (required, e.g. apple)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/search"
    query: [{name: query, var: query, required: true}, {name: offset, var: offset}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, offset: $offset, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Site Content
#
# GET /food/site/search
# Docs: https://spoonacular.com/food-api/docs#Search-Site-Content — Read entire docs
# Returns: record<Articles: table<dataPoints: list, image: string, link: string, name: string>, "Grocery Products": table<dataPoints: list, image: string, link: string, name: string>, "Menu Items": table<dataPoints: list, image: string, link: string, name: string>, Recipes: table<dataPoints: list, image: string, link: string, name: string>>
# operationId: searchSiteContent
export def "search-site-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The query to search for. You can also use partial queries such as "spagh" to already find spaghetti recipes, articles, grocery products, and other content. (required, e.g. past)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/site/search"
    query: [{name: query, var: query, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Random Food Trivia
#
# GET /food/trivia/random
# Docs: https://spoonacular.com/food-api/docs#Random-Food-Trivia — Read entire docs
# Returns: record<text: string>
# operationId: getRandomFoodTrivia
export def "get-random-food-trivia" [
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
    path: "/food/trivia/random"
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Food Videos
#
# GET /food/videos/search
# Docs: https://spoonacular.com/food-api/docs#Search-Food-Videos — Read entire docs
# Returns: record<totalResults: int, videos: table<length: int, rating: float, shortTitle: string, thumbnail: string, title: string, views: int, youTubeId: string>>
# operationId: searchFoodVideos
export def "search-food-videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --type: string # The type of the recipes. See a full list of supported meal types. (e.g. main course)
  --cuisine: string # The cuisine(s) of the recipes. One or more, comma separated. See a full list of supported cuisines. (e.g. italian)
  --diet: string # The diet for which the recipes must be suitable. See a full list of supported diets. (e.g. vegetarian)
  --include-ingredients: string # A comma-separated list of ingredients that the recipes should contain. (e.g. tomato,cheese)
  --exclude-ingredients: string # A comma-separated list of ingredients or ingredient types that the recipes must not contain. (e.g. eggs)
  --min-length: float # Minimum video length in seconds. (e.g. 0)
  --max-length: float # Maximum video length in seconds. (e.g. 999)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/videos/search"
    query: [{name: query, var: query}, {name: type, var: type}, {name: cuisine, var: cuisine}, {name: diet, var: diet}, {name: includeIngredients, var: include_ingredients}, {name: excludeIngredients, var: exclude_ingredients}, {name: minLength, var: min_length}, {name: maxLength, var: max_length}, {name: offset, var: offset}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, type: $type, cuisine: $cuisine, diet: $diet, include_ingredients: $include_ingredients, exclude_ingredients: $exclude_ingredients, min_length: $min_length, max_length: $max_length, offset: $offset, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wine Description
#
# GET /food/wine/description
# Docs: https://spoonacular.com/food-api/docs#Wine-Description — Read entire docs
# Returns: record<wineDescription: string>
# operationId: getWineDescription
export def "get-wine-description" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wine: string # The name of the wine that should be paired, e.g. "merlot", "riesling", or "malbec". (required, e.g. merlot)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/wine/description"
    query: [{name: wine, var: wine, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    wine: $wine
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Dish Pairing for Wine
#
# GET /food/wine/dishes
# Docs: https://spoonacular.com/food-api/docs#Dish-Pairing-for-Wine — Read entire docs
# Returns: record<pairings: list<string>, text: string>
# operationId: getDishPairingForWine
export def "get-dish-pairing-for-wine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wine: string # The type of wine that should be paired, e.g. "merlot", "riesling", or "malbec". (required, e.g. malbec)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/wine/dishes"
    query: [{name: wine, var: wine, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    wine: $wine
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wine Pairing
#
# GET /food/wine/pairing
# Docs: https://spoonacular.com/food-api/docs#Wine-Pairing — Read entire docs
# Returns: record<pairedWines: list<string>, pairingText: string, productMatches: table<averageRating: float, description: any, id: int, imageUrl: string, link: string, price: string, ratingCount: int, score: float, title: string>>
# operationId: getWinePairing
export def "get-wine-pairing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --food: string # The food to get a pairing for. This can be a dish ("steak"), an ingredient ("salmon"), or a cuisine ("italian"). (required, e.g. steak)
  --max-price: float # The maximum price for the specific wine recommendation in USD. (e.g. 50)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/wine/pairing"
    query: [{name: food, var: food, required: true}, {name: maxPrice, var: max_price}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    food: $food, max_price: $max_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Wine Recommendation
#
# GET /food/wine/recommendation
# Docs: https://spoonacular.com/food-api/docs#Wine-Recommendation — Read entire docs
# Returns: record<recommendedWines: table<averageRating: float, description: string, id: int, imageUrl: string, link: string, price: string, ratingCount: int, score: float, title: string>, totalFound: int>
# operationId: getWineRecommendation
export def "get-wine-recommendation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wine: string # The type of wine to get a specific product recommendation for. (required, e.g. merlot)
  --max-price: float # The maximum price for the specific wine recommendation in USD. (e.g. 50)
  --min-rating: float # The minimum rating of the recommended wine between 0 and 1. For example, 0.8 equals 4 out of 5 stars. (e.g. 0.7)
  --number: float # The number of wine recommendations expected (between 1 and 100). (default: 10, e.g. 3)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/food/wine/recommendation"
    query: [{name: wine, var: wine, required: true}, {name: maxPrice, var: max_price}, {name: minRating, var: min_rating}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    wine: $wine, max_price: $max_price, min_rating: $min_rating, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Meal Plan
#
# GET /mealplanner/generate
# Docs: https://spoonacular.com/food-api/docs#Generate-Meal-Plan — Read entire docs
# Returns: record<meals: table<id: int, imageType: string, readyInMinutes: int, servings: float, sourceUrl: string, title: string>, nutrients: record<calories: float, carbohydrates: float, fat: float, protein: float>>
# operationId: generateMealPlan
export def "generate-meal-plan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-frame: string # Either for one "day" or an entire "week". (e.g. day)
  --target-calories: float # What is the caloric target for one day? The meal plan generator will try to get as close as possible to that goal. (e.g. 2000)
  --diet: string # Enter a diet that the meal plan has to adhere to. See a full list of supported diets. (e.g. vegetarian)
  --exclude: string # A comma-separated list of allergens or ingredients that must be excluded. (e.g. shellfish, olives)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mealplanner/generate"
    query: [{name: timeFrame, var: time_frame}, {name: targetCalories, var: target_calories}, {name: diet, var: diet}, {name: exclude, var: exclude}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    time_frame: $time_frame, target_calories: $target_calories, diet: $diet, exclude: $exclude
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Clear Meal Plan Day
#
# DELETE /mealplanner/{username}/day/{date}
# Docs: https://spoonacular.com/food-api/docs#Clear-Meal-Plan-Day — Read entire docs
# Returns: record
# operationId: clearMealPlanDay
export def "clear-meal-plan-day" [
  username: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
  --body-date: string # The date in the format yyyy-mm-dd. (e.g. 2020-06-01) (spec name: date)
  --body-hash: string # The private hash for the username. (e.g. 4b5v4398573406) (spec name: hash)
  --body-username: string # The username. (e.g. dsky) (spec name: username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/mealplanner/{username}/day/{date}"
    path_params: [{name: username, var: username}, {name: date, var: date}]
    query: [{name: hash, var: hash, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: date, var: body_date, required: true}, {name: hash, var: body_hash, required: true}, {name: username, var: body_username, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, date: $date, hash: $hash, body_date: $body_date, body_hash: $body_hash, body_username: $body_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add to Meal Plan
#
# POST /mealplanner/{username}/items
# Docs: https://spoonacular.com/food-api/docs#Add-to-Meal-Plan — Read entire docs
# Returns: record
# operationId: addToMealPlan
export def "add-to-meal-plan" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
  date: float
  position: int
  slot: int
  type: string
  value: record # shape: {ingredients: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/mealplanner/{username}/items"
    path_params: [{name: username, var: username}]
    query: [{name: hash, var: hash, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: date, var: date}, {name: position, var: position}, {name: slot, var: slot}, {name: type, var: type}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, hash: $hash, date: $date, position: $position, slot: $slot, type: $type, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete from Meal Plan
#
# DELETE /mealplanner/{username}/items/{id}
# Docs: https://spoonacular.com/food-api/docs#Delete-from-Meal-Plan — Read entire docs
# Returns: record
# operationId: deleteFromMealPlan
export def "delete-from-meal-plan" [
  username: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
  --body-hash: string # The private hash for the username. (e.g. 4b5v4398573406) (spec name: hash)
  --body-id: float # The shopping list item id. (e.g. 15678) (spec name: id)
  --body-username: string # The username. (e.g. dsky) (spec name: username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/mealplanner/{username}/items/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    query: [{name: hash, var: hash, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: hash, var: body_hash, required: true}, {name: id, var: body_id, required: true}, {name: username, var: body_username, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, id: $id, hash: $hash, body_hash: $body_hash, body_id: $body_id, body_username: $body_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Shopping List
#
# GET /mealplanner/{username}/shopping-list
# Docs: https://spoonacular.com/food-api/docs#Get-Shopping-List — Read entire docs
# Returns: record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float>
# operationId: getShoppingList
export def "get-shopping-list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mealplanner/{username}/shopping-list"
    path_params: [{name: username, var: username}]
    query: [{name: hash, var: hash, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, hash: $hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add to Shopping List
#
# POST /mealplanner/{username}/shopping-list/items
# Docs: https://spoonacular.com/food-api/docs#Add-to-Shopping-List — Read entire docs
# Returns: record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float>
# operationId: addToShoppingList
export def "add-to-shopping-list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
  aisle: string
  item: string
  --parse: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/mealplanner/{username}/shopping-list/items"
    path_params: [{name: username, var: username}]
    query: [{name: hash, var: hash, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: aisle, var: aisle}, {name: item, var: item}, {name: parse, var: parse, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, hash: $hash, aisle: $aisle, item: $item, parse: $parse
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete from Shopping List
#
# DELETE /mealplanner/{username}/shopping-list/items/{id}
# Docs: https://spoonacular.com/food-api/docs#Delete-from-Shopping-List — Read entire docs
# Returns: record
# operationId: deleteFromShoppingList
export def "delete-from-shopping-list" [
  username: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
  --body-hash: string # The private hash for the username. (e.g. 4b5v4398573406) (spec name: hash)
  --body-id: float # The shopping list item id. (e.g. 15678) (spec name: id)
  --body-username: string # The username. (e.g. dsky) (spec name: username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/mealplanner/{username}/shopping-list/items/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    query: [{name: hash, var: hash, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: hash, var: body_hash, required: true}, {name: id, var: body_id, required: true}, {name: username, var: body_username, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, id: $id, hash: $hash, body_hash: $body_hash, body_id: $body_id, body_username: $body_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Shopping List
#
# POST /mealplanner/{username}/shopping-list/{start-date}/{end-date}
# Docs: https://spoonacular.com/food-api/docs#Generate-Shopping-List — Read entire docs
# Returns: record<aisles: table<aisle: string, items: list>, cost: float, endDate: float, startDate: float>
# operationId: generateShoppingList
export def "generate-shopping-list" [
  username: string
  start_date: string
  end_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
  --body-end-date: string # The end date in the format yyyy-mm-dd. (e.g. 2020-06-07) (spec name: end-date)
  --body-hash: string # The private hash for the username. (e.g. 4b5v4398573406) (spec name: hash)
  --body-start-date: string # The start date in the format yyyy-mm-dd. (e.g. 2020-06-01) (spec name: start-date)
  --body-username: string # The username. (e.g. dsky) (spec name: username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/mealplanner/{username}/shopping-list/{start-date}/{end-date}"
    path_params: [{name: username, var: username}, {name: start-date, var: start_date}, {name: end-date, var: end_date}]
    query: [{name: hash, var: hash, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: end-date, var: body_end_date, required: true}, {name: hash, var: body_hash, required: true}, {name: start-date, var: body_start_date, required: true}, {name: username, var: body_username, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, start_date: $start_date, end_date: $end_date, hash: $hash, body_end_date: $body_end_date, body_hash: $body_hash, body_start_date: $body_start_date, body_username: $body_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Meal Plan Templates
#
# GET /mealplanner/{username}/templates
# Docs: https://spoonacular.com/food-api/docs#Get-Meal-Plan-Templates — Read entire docs
# Returns: record<templates: table<id: int, name: string>>
# operationId: getMealPlanTemplates
export def "get-meal-plan-templates" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mealplanner/{username}/templates"
    path_params: [{name: username, var: username}]
    query: [{name: hash, var: hash, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, hash: $hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Meal Plan Template
#
# POST /mealplanner/{username}/templates
# Docs: https://spoonacular.com/food-api/docs#Add-Meal-Plan-Template — Read entire docs
# Returns: record<items: table<day: int, position: int, slot: int, type: string, value: record>, name: string, publishAsPublic: bool>
# operationId: addMealPlanTemplate
export def "add-meal-plan-template" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required, e.g. 4b5v4398573406)
  --body-hash: string # The private hash for the username. (e.g. 4b5v4398573406) (spec name: hash)
  --body-username: string # The username. (e.g. dsky) (spec name: username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/mealplanner/{username}/templates"
    path_params: [{name: username, var: username}]
    query: [{name: hash, var: hash, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: hash, var: body_hash, required: true}, {name: username, var: body_username, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, hash: $hash, body_hash: $body_hash, body_username: $body_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Meal Plan Template
#
# DELETE /mealplanner/{username}/templates/{id}
# Docs: https://spoonacular.com/food-api/docs#Delete-Meal-Plan-Template — Read entire docs
# Returns: record
# operationId: deleteMealPlanTemplate
export def "delete-meal-plan-template" [
  username: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required, e.g. 4b5v4398573406)
  --body-hash: string # The private hash for the username. (e.g. 4b5v4398573406) (spec name: hash)
  --body-id: float # The shopping list item id. (e.g. 15678) (spec name: id)
  --body-username: string # The username. (e.g. dsky) (spec name: username)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/mealplanner/{username}/templates/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    query: [{name: hash, var: hash, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: hash, var: body_hash, required: true}, {name: id, var: body_id, required: true}, {name: username, var: body_username, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, id: $id, hash: $hash, body_hash: $body_hash, body_id: $body_id, body_username: $body_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Meal Plan Template
#
# GET /mealplanner/{username}/templates/{id}
# Docs: https://spoonacular.com/food-api/docs#Get-Meal-Plan-Template — Read entire docs
# Returns: record<days: table<day: string, items: list, nutritionSummary: record, nutritionSummaryBreakfast: record, nutritionSummaryDinner: record, nutritionSummaryLunch: record>, id: int, name: string>
# operationId: getMealPlanTemplate
export def "get-meal-plan-template" [
  username: string
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hash: string # The private hash for the username. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mealplanner/{username}/templates/{id}"
    path_params: [{name: username, var: username}, {name: id, var: id}]
    query: [{name: hash, var: hash, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, id: $id, hash: $hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Meal Plan Week
#
# GET /mealplanner/{username}/week/{start-date}
# Docs: https://spoonacular.com/food-api/docs#Get-Meal-Plan-Week — Read entire docs
# Returns: record<days: table<date: float, day: string, items: list, nutritionSummary: record, nutritionSummaryBreakfast: record, nutritionSummaryDinner: record, nutritionSummaryLunch: record>>
# operationId: getMealPlanWeek
export def "get-meal-plan-week" [
  username: string
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
  --hash: string # The private hash for the username. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mealplanner/{username}/week/{start-date}"
    path_params: [{name: username, var: username}, {name: start-date, var: start_date}]
    query: [{name: hash, var: hash, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    username: $username, start_date: $start_date, hash: $hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Analyze Recipe
#
# POST /recipes/analyze
# Docs: https://spoonacular.com/food-api/docs#Analyze-Recipe — Read entire docs
# Returns: record
# operationId: analyzeRecipe
export def "analyze-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The input language, either "en" or "de". (e.g. en)
  --include-nutrition: oneof<nothing, bool> # Whether nutrition data should be added to correctly parsed ingredients. (e.g. false)
  --include-taste: oneof<nothing, bool> # Whether taste data should be added to correctly parsed ingredients. (e.g. false)
  --ingredients: list<string>
  --instructions: string
  --servings: int
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipes/analyze"
    query: [{name: language, var: language}, {name: includeNutrition, var: include_nutrition}, {name: includeTaste, var: include_taste}]
    body: {content_type: "application/json", kind: json, fields: [{name: ingredients, var: ingredients}, {name: instructions, var: instructions}, {name: servings, var: servings}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    language: $language, include_nutrition: $include_nutrition, include_taste: $include_taste, ingredients: $ingredients, instructions: $instructions, servings: $servings, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Analyze Recipe Instructions
#
# POST /recipes/analyzeInstructions
# Docs: https://spoonacular.com/food-api/docs#Analyze-Recipe-Instructions — Read entire docs
# Returns: record<equipment: table<id: float, name: string>, ingredients: table<id: float, name: string>, parsedInstructions: table<name: string, steps: list>>
# operationId: analyzeRecipeInstructions
export def "analyze-recipe-instructions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipes/analyzeInstructions"
    header: [{name: Content-Type, var: content_type}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Autocomplete Recipe Search
#
# GET /recipes/autocomplete
# Docs: https://spoonacular.com/food-api/docs#Autocomplete-Recipe-Search — Read entire docs
# Returns: table<id: int, imageType: string, title: string>
# operationId: autocompleteRecipeSearch
export def "autocomplete-recipe-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/autocomplete"
    query: [{name: query, var: query}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Recipes
#
# GET /recipes/complexSearch
# Docs: https://spoonacular.com/food-api/docs#Search-Recipes — Read entire docs
# Returns: record<number: int, offset: int, results: table<calories: float, carbs: string, fat: string, id: int, image: string, imageType: string, protein: string, title: string>, totalResults: int>
# operationId: searchRecipes
export def "search-recipes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # The (natural language) search query. (e.g. burger)
  --cuisine: string # The cuisine(s) of the recipes. One or more, comma separated (will be interpreted as 'OR'). See a full list of supported cuisines. (e.g. italian)
  --exclude-cuisine: string # The cuisine(s) the recipes must not match. One or more, comma separated (will be interpreted as 'AND'). See a full list of supported cuisines. (e.g. greek)
  --diet: string # The diet for which the recipes must be suitable. See a full list of supported diets. (e.g. vegetarian)
  --intolerances: string # A comma-separated list of intolerances. All recipes returned must not contain ingredients that are not suitable for people with the intolerances entered. See a full list of supported intolerances. (e.g. gluten)
  --equipment: string # The equipment required. Multiple values will be interpreted as 'or'. For example, value could be "blender, frying pan, bowl". (e.g. pan)
  --include-ingredients: string # A comma-separated list of ingredients that should/must be used in the recipes. (e.g. tomato,cheese)
  --exclude-ingredients: string # A comma-separated list of ingredients or ingredient types that the recipes must not contain. (e.g. eggs)
  --type: string # The type of recipe. See a full list of supported meal types. (e.g. main course)
  --instructions-required: oneof<nothing, bool> # Whether the recipes must have instructions. (e.g. true)
  --fill-ingredients: oneof<nothing, bool> # Add information about the ingredients and whether they are used or missing in relation to the query. (e.g. false)
  --add-recipe-information: oneof<nothing, bool> # If set to true, you get more information about the recipes returned. (e.g. false)
  --add-recipe-nutrition: oneof<nothing, bool> # If set to true, you get nutritional information about each recipes returned. (e.g. false)
  --author: string # The username of the recipe author. (e.g. coffeebean)
  --tags: string # The tags (can be diets, meal types, cuisines, or intolerances) that the recipe must have.
  --recipe-box-id: float # The id of the recipe box to which the search should be limited to. (e.g. 2468)
  --title-match: string # Enter text that must be found in the title of the recipes. (e.g. Crock Pot)
  --max-ready-time: float # The maximum time in minutes it should take to prepare and cook the recipe. (e.g. 20)
  --ignore-pantry: oneof<nothing, bool> # Whether to ignore typical pantry items, such as water, salt, flour, etc. (default: false, e.g. false)
  --sort: string # The strategy to sort recipes by. See a full list of supported sorting options. (e.g. calories)
  --sort-direction: string # The direction in which to sort. Must be either 'asc' (ascending) or 'desc' (descending). (e.g. asc)
  --min-carbs: float # The minimum amount of carbohydrates in grams the recipe must have. (e.g. 10)
  --max-carbs: float # The maximum amount of carbohydrates in grams the recipe can have. (e.g. 100)
  --min-protein: float # The minimum amount of protein in grams the recipe must have. (e.g. 10)
  --max-protein: float # The maximum amount of protein in grams the recipe can have. (e.g. 100)
  --min-calories: float # The minimum amount of calories the recipe must have. (e.g. 50)
  --max-calories: float # The maximum amount of calories the recipe can have. (e.g. 800)
  --min-fat: float # The minimum amount of fat in grams the recipe must have. (e.g. 1)
  --max-fat: float # The maximum amount of fat in grams the recipe can have. (e.g. 100)
  --min-alcohol: float # The minimum amount of alcohol in grams the recipe must have. (e.g. 0)
  --max-alcohol: float # The maximum amount of alcohol in grams the recipe can have. (e.g. 100)
  --min-caffeine: float # The minimum amount of caffeine in milligrams the recipe must have. (e.g. 0)
  --max-caffeine: float # The maximum amount of caffeine in milligrams the recipe can have. (e.g. 100)
  --min-copper: float # The minimum amount of copper in milligrams the recipe must have. (e.g. 0)
  --max-copper: float # The maximum amount of copper in milligrams the recipe can have. (e.g. 100)
  --min-calcium: float # The minimum amount of calcium in milligrams the recipe must have. (e.g. 0)
  --max-calcium: float # The maximum amount of calcium in milligrams the recipe can have. (e.g. 100)
  --min-choline: float # The minimum amount of choline in milligrams the recipe must have. (e.g. 0)
  --max-choline: float # The maximum amount of choline in milligrams the recipe can have. (e.g. 100)
  --min-cholesterol: float # The minimum amount of cholesterol in milligrams the recipe must have. (e.g. 0)
  --max-cholesterol: float # The maximum amount of cholesterol in milligrams the recipe can have. (e.g. 100)
  --min-fluoride: float # The minimum amount of fluoride in milligrams the recipe must have. (e.g. 0)
  --max-fluoride: float # The maximum amount of fluoride in milligrams the recipe can have. (e.g. 100)
  --min-saturated-fat: float # The minimum amount of saturated fat in grams the recipe must have. (e.g. 0)
  --max-saturated-fat: float # The maximum amount of saturated fat in grams the recipe can have. (e.g. 100)
  --min-vitamin-a: float # The minimum amount of Vitamin A in IU the recipe must have. (e.g. 0)
  --max-vitamin-a: float # The maximum amount of Vitamin A in IU the recipe can have. (e.g. 100)
  --min-vitamin-c: float # The minimum amount of Vitamin C milligrams the recipe must have. (e.g. 0)
  --max-vitamin-c: float # The maximum amount of Vitamin C in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-d: float # The minimum amount of Vitamin D in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-d: float # The maximum amount of Vitamin D in micrograms the recipe can have. (e.g. 100)
  --min-vitamin-e: float # The minimum amount of Vitamin E in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-e: float # The maximum amount of Vitamin E in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-k: float # The minimum amount of Vitamin K in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-k: float # The maximum amount of Vitamin K in micrograms the recipe can have. (e.g. 100)
  --min-vitamin-b1: float # The minimum amount of Vitamin B1 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b1: float # The maximum amount of Vitamin B1 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b2: float # The minimum amount of Vitamin B2 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b2: float # The maximum amount of Vitamin B2 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b5: float # The minimum amount of Vitamin B5 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b5: float # The maximum amount of Vitamin B5 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b3: float # The minimum amount of Vitamin B3 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b3: float # The maximum amount of Vitamin B3 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b6: float # The minimum amount of Vitamin B6 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b6: float # The maximum amount of Vitamin B6 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b12: float # The minimum amount of Vitamin B12 in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-b12: float # The maximum amount of Vitamin B12 in micrograms the recipe can have. (e.g. 100)
  --min-fiber: float # The minimum amount of fiber in grams the recipe must have. (e.g. 0)
  --max-fiber: float # The maximum amount of fiber in grams the recipe can have. (e.g. 100)
  --min-folate: float # The minimum amount of folate in micrograms the recipe must have. (e.g. 0)
  --max-folate: float # The maximum amount of folate in micrograms the recipe can have. (e.g. 100)
  --min-folic-acid: float # The minimum amount of folic acid in micrograms the recipe must have. (e.g. 0)
  --max-folic-acid: float # The maximum amount of folic acid in micrograms the recipe can have. (e.g. 100)
  --min-iodine: float # The minimum amount of iodine in micrograms the recipe must have. (e.g. 0)
  --max-iodine: float # The maximum amount of iodine in micrograms the recipe can have. (e.g. 100)
  --min-iron: float # The minimum amount of iron in milligrams the recipe must have. (e.g. 0)
  --max-iron: float # The maximum amount of iron in milligrams the recipe can have. (e.g. 100)
  --min-magnesium: float # The minimum amount of magnesium in milligrams the recipe must have. (e.g. 0)
  --max-magnesium: float # The maximum amount of magnesium in milligrams the recipe can have. (e.g. 100)
  --min-manganese: float # The minimum amount of manganese in milligrams the recipe must have. (e.g. 0)
  --max-manganese: float # The maximum amount of manganese in milligrams the recipe can have. (e.g. 100)
  --min-phosphorus: float # The minimum amount of phosphorus in milligrams the recipe must have. (e.g. 0)
  --max-phosphorus: float # The maximum amount of phosphorus in milligrams the recipe can have. (e.g. 100)
  --min-potassium: float # The minimum amount of potassium in milligrams the recipe must have. (e.g. 0)
  --max-potassium: float # The maximum amount of potassium in milligrams the recipe can have. (e.g. 100)
  --min-selenium: float # The minimum amount of selenium in micrograms the recipe must have. (e.g. 0)
  --max-selenium: float # The maximum amount of selenium in micrograms the recipe can have. (e.g. 100)
  --min-sodium: float # The minimum amount of sodium in milligrams the recipe must have. (e.g. 0)
  --max-sodium: float # The maximum amount of sodium in milligrams the recipe can have. (e.g. 100)
  --min-sugar: float # The minimum amount of sugar in grams the recipe must have. (e.g. 0)
  --max-sugar: float # The maximum amount of sugar in grams the recipe can have. (e.g. 100)
  --min-zinc: float # The minimum amount of zinc in milligrams the recipe must have. (e.g. 0)
  --max-zinc: float # The maximum amount of zinc in milligrams the recipe can have. (e.g. 100)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/complexSearch"
    query: [{name: query, var: query}, {name: cuisine, var: cuisine}, {name: excludeCuisine, var: exclude_cuisine}, {name: diet, var: diet}, {name: intolerances, var: intolerances}, {name: equipment, var: equipment}, {name: includeIngredients, var: include_ingredients}, {name: excludeIngredients, var: exclude_ingredients}, {name: type, var: type}, {name: instructionsRequired, var: instructions_required}, {name: fillIngredients, var: fill_ingredients}, {name: addRecipeInformation, var: add_recipe_information}, {name: addRecipeNutrition, var: add_recipe_nutrition}, {name: author, var: author}, {name: tags, var: tags}, {name: recipeBoxId, var: recipe_box_id}, {name: titleMatch, var: title_match}, {name: maxReadyTime, var: max_ready_time}, {name: ignorePantry, var: ignore_pantry}, {name: sort, var: sort}, {name: sortDirection, var: sort_direction}, {name: minCarbs, var: min_carbs}, {name: maxCarbs, var: max_carbs}, {name: minProtein, var: min_protein}, {name: maxProtein, var: max_protein}, {name: minCalories, var: min_calories}, {name: maxCalories, var: max_calories}, {name: minFat, var: min_fat}, {name: maxFat, var: max_fat}, {name: minAlcohol, var: min_alcohol}, {name: maxAlcohol, var: max_alcohol}, {name: minCaffeine, var: min_caffeine}, {name: maxCaffeine, var: max_caffeine}, {name: minCopper, var: min_copper}, {name: maxCopper, var: max_copper}, {name: minCalcium, var: min_calcium}, {name: maxCalcium, var: max_calcium}, {name: minCholine, var: min_choline}, {name: maxCholine, var: max_choline}, {name: minCholesterol, var: min_cholesterol}, {name: maxCholesterol, var: max_cholesterol}, {name: minFluoride, var: min_fluoride}, {name: maxFluoride, var: max_fluoride}, {name: minSaturatedFat, var: min_saturated_fat}, {name: maxSaturatedFat, var: max_saturated_fat}, {name: minVitaminA, var: min_vitamin_a}, {name: maxVitaminA, var: max_vitamin_a}, {name: minVitaminC, var: min_vitamin_c}, {name: maxVitaminC, var: max_vitamin_c}, {name: minVitaminD, var: min_vitamin_d}, {name: maxVitaminD, var: max_vitamin_d}, {name: minVitaminE, var: min_vitamin_e}, {name: maxVitaminE, var: max_vitamin_e}, {name: minVitaminK, var: min_vitamin_k}, {name: maxVitaminK, var: max_vitamin_k}, {name: minVitaminB1, var: min_vitamin_b1}, {name: maxVitaminB1, var: max_vitamin_b1}, {name: minVitaminB2, var: min_vitamin_b2}, {name: maxVitaminB2, var: max_vitamin_b2}, {name: minVitaminB5, var: min_vitamin_b5}, {name: maxVitaminB5, var: max_vitamin_b5}, {name: minVitaminB3, var: min_vitamin_b3}, {name: maxVitaminB3, var: max_vitamin_b3}, {name: minVitaminB6, var: min_vitamin_b6}, {name: maxVitaminB6, var: max_vitamin_b6}, {name: minVitaminB12, var: min_vitamin_b12}, {name: maxVitaminB12, var: max_vitamin_b12}, {name: minFiber, var: min_fiber}, {name: maxFiber, var: max_fiber}, {name: minFolate, var: min_folate}, {name: maxFolate, var: max_folate}, {name: minFolicAcid, var: min_folic_acid}, {name: maxFolicAcid, var: max_folic_acid}, {name: minIodine, var: min_iodine}, {name: maxIodine, var: max_iodine}, {name: minIron, var: min_iron}, {name: maxIron, var: max_iron}, {name: minMagnesium, var: min_magnesium}, {name: maxMagnesium, var: max_magnesium}, {name: minManganese, var: min_manganese}, {name: maxManganese, var: max_manganese}, {name: minPhosphorus, var: min_phosphorus}, {name: maxPhosphorus, var: max_phosphorus}, {name: minPotassium, var: min_potassium}, {name: maxPotassium, var: max_potassium}, {name: minSelenium, var: min_selenium}, {name: maxSelenium, var: max_selenium}, {name: minSodium, var: min_sodium}, {name: maxSodium, var: max_sodium}, {name: minSugar, var: min_sugar}, {name: maxSugar, var: max_sugar}, {name: minZinc, var: min_zinc}, {name: maxZinc, var: max_zinc}, {name: offset, var: offset}, {name: number, var: number}, {name: limitLicense, var: limit_license}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    query: $query, cuisine: $cuisine, exclude_cuisine: $exclude_cuisine, diet: $diet, intolerances: $intolerances, equipment: $equipment, include_ingredients: $include_ingredients, exclude_ingredients: $exclude_ingredients, type: $type, instructions_required: $instructions_required, fill_ingredients: $fill_ingredients, add_recipe_information: $add_recipe_information, add_recipe_nutrition: $add_recipe_nutrition, author: $author, tags: $tags, recipe_box_id: $recipe_box_id, title_match: $title_match, max_ready_time: $max_ready_time, ignore_pantry: $ignore_pantry, sort: $sort, sort_direction: $sort_direction, min_carbs: $min_carbs, max_carbs: $max_carbs, min_protein: $min_protein, max_protein: $max_protein, min_calories: $min_calories, max_calories: $max_calories, min_fat: $min_fat, max_fat: $max_fat, min_alcohol: $min_alcohol, max_alcohol: $max_alcohol, min_caffeine: $min_caffeine, max_caffeine: $max_caffeine, min_copper: $min_copper, max_copper: $max_copper, min_calcium: $min_calcium, max_calcium: $max_calcium, min_choline: $min_choline, max_choline: $max_choline, min_cholesterol: $min_cholesterol, max_cholesterol: $max_cholesterol, min_fluoride: $min_fluoride, max_fluoride: $max_fluoride, min_saturated_fat: $min_saturated_fat, max_saturated_fat: $max_saturated_fat, min_vitamin_a: $min_vitamin_a, max_vitamin_a: $max_vitamin_a, min_vitamin_c: $min_vitamin_c, max_vitamin_c: $max_vitamin_c, min_vitamin_d: $min_vitamin_d, max_vitamin_d: $max_vitamin_d, min_vitamin_e: $min_vitamin_e, max_vitamin_e: $max_vitamin_e, min_vitamin_k: $min_vitamin_k, max_vitamin_k: $max_vitamin_k, min_vitamin_b1: $min_vitamin_b1, max_vitamin_b1: $max_vitamin_b1, min_vitamin_b2: $min_vitamin_b2, max_vitamin_b2: $max_vitamin_b2, min_vitamin_b5: $min_vitamin_b5, max_vitamin_b5: $max_vitamin_b5, min_vitamin_b3: $min_vitamin_b3, max_vitamin_b3: $max_vitamin_b3, min_vitamin_b6: $min_vitamin_b6, max_vitamin_b6: $max_vitamin_b6, min_vitamin_b12: $min_vitamin_b12, max_vitamin_b12: $max_vitamin_b12, min_fiber: $min_fiber, max_fiber: $max_fiber, min_folate: $min_folate, max_folate: $max_folate, min_folic_acid: $min_folic_acid, max_folic_acid: $max_folic_acid, min_iodine: $min_iodine, max_iodine: $max_iodine, min_iron: $min_iron, max_iron: $max_iron, min_magnesium: $min_magnesium, max_magnesium: $max_magnesium, min_manganese: $min_manganese, max_manganese: $max_manganese, min_phosphorus: $min_phosphorus, max_phosphorus: $max_phosphorus, min_potassium: $min_potassium, max_potassium: $max_potassium, min_selenium: $min_selenium, max_selenium: $max_selenium, min_sodium: $min_sodium, max_sodium: $max_sodium, min_sugar: $min_sugar, max_sugar: $max_sugar, min_zinc: $min_zinc, max_zinc: $max_zinc, offset: $offset, number: $number, limit_license: $limit_license
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Convert Amounts
#
# GET /recipes/convert
# Docs: https://spoonacular.com/food-api/docs#Convert-Amounts — Read entire docs
# Returns: record<answer: string, sourceAmount: float, sourceUnit: string, targetAmount: float, targetUnit: string>
# operationId: convertAmounts
export def "convert-amounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ingredient-name: string # The ingredient which you want to convert. (required, e.g. flour)
  --source-amount: float # The amount from which you want to convert, e.g. the 2.5 in "2.5 cups of flour to grams". (required, e.g. 2.5)
  --source-unit: string # The unit from which you want to convert, e.g. the grams in "2.5 cups of flour to grams". You can also use "piece", e.g. "3.4 oz tomatoes to piece" (required, e.g. cups)
  --target-unit: string # The unit to which you want to convert, e.g. the grams in "2.5 cups of flour to grams". You can also use "piece", e.g. "3.4 oz tomatoes to piece" (required, e.g. grams)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/convert"
    query: [{name: ingredientName, var: ingredient_name, required: true}, {name: sourceAmount, var: source_amount, required: true}, {name: sourceUnit, var: source_unit, required: true}, {name: targetUnit, var: target_unit, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    ingredient_name: $ingredient_name, source_amount: $source_amount, source_unit: $source_unit, target_unit: $target_unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Classify Cuisine
#
# POST /recipes/cuisine
# Docs: https://spoonacular.com/food-api/docs#Classify-Cuisine — Read entire docs
# Returns: record<confidence: float, cuisine: string, cuisines: list<string>>
# operationId: classifyCuisine
export def "classify-cuisine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipes/cuisine"
    header: [{name: Content-Type, var: content_type}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extract Recipe from Website
#
# GET /recipes/extract
# Docs: https://spoonacular.com/food-api/docs#Extract-Recipe-from-Website — Read entire docs
# Returns: record<aggregateLikes: int, analyzedInstructions: list<record>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: table<aisle: string, amount: float, consitency: string, id: int, image: string, measures: record, meta: list, name: string, original: string, originalName: string, unit: string>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list<string>, pairingText: string, productMatches: list<record>>>
# operationId: extractRecipeFromWebsite
export def "extract-recipe-from-website" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # The URL of the recipe page. (required, e.g. https://foodista.com/recipe/ZHK4KPB6/chocolate-crinkle-cookies)
  --force-extraction: oneof<nothing, bool> # If true, the extraction will be triggered whether we already know the recipe or not. Use this only if information is missing as this operation is slower. (e.g. true)
  --analyze: oneof<nothing, bool> # If true, the recipe will be analyzed and classified resolving in more data such as cuisines, dish types, and more. (e.g. false)
  --include-nutrition: oneof<nothing, bool> # Include nutrition data in the recipe information. Nutrition data is per serving. If you want the nutrition data for the entire recipe, just multiply by the number of servings. (default: false)
  --include-taste: oneof<nothing, bool> # Whether taste data should be added to correctly parsed ingredients. (default: false, e.g. false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/extract"
    query: [{name: url, var: url, required: true}, {name: forceExtraction, var: force_extraction}, {name: analyze, var: analyze}, {name: includeNutrition, var: include_nutrition}, {name: includeTaste, var: include_taste}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    url: $url, force_extraction: $force_extraction, analyze: $analyze, include_nutrition: $include_nutrition, include_taste: $include_taste
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Recipes by Ingredients
#
# GET /recipes/findByIngredients
# Docs: https://spoonacular.com/food-api/docs#Search-Recipes-by-Ingredients — Read entire docs
# Returns: table<id: int, image: string, imageType: string, likes: int, missedIngredientCount: int, missedIngredients: list<record>, title: string, unusedIngredients: list<record>, usedIngredientCount: float, usedIngredients: list<record>>
# operationId: searchRecipesByIngredients
export def "search-recipes-by-ingredients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ingredients: string # A comma-separated list of ingredients that the recipes should contain. (e.g. carrots,tomatoes)
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
  --ranking: float # Whether to maximize used ingredients (1) or minimize missing ingredients (2) first. (e.g. 1)
  --ignore-pantry: oneof<nothing, bool> # Whether to ignore typical pantry items, such as water, salt, flour, etc. (default: false, e.g. false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/findByIngredients"
    query: [{name: ingredients, var: ingredients}, {name: number, var: number}, {name: limitLicense, var: limit_license}, {name: ranking, var: ranking}, {name: ignorePantry, var: ignore_pantry}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    ingredients: $ingredients, number: $number, limit_license: $limit_license, ranking: $ranking, ignore_pantry: $ignore_pantry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search Recipes by Nutrients
#
# GET /recipes/findByNutrients
# Docs: https://spoonacular.com/food-api/docs#Search-Recipes-by-Nutrients — Read entire docs
# Returns: table<calories: float, carbs: string, fat: string, id: int, image: string, imageType: string, protein: string, title: string>
# operationId: searchRecipesByNutrients
export def "search-recipes-by-nutrients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-carbs: float # The minimum amount of carbohydrates in grams the recipe must have. (e.g. 10)
  --max-carbs: float # The maximum amount of carbohydrates in grams the recipe can have. (e.g. 100)
  --min-protein: float # The minimum amount of protein in grams the recipe must have. (e.g. 10)
  --max-protein: float # The maximum amount of protein in grams the recipe can have. (e.g. 100)
  --min-calories: float # The minimum amount of calories the recipe must have. (e.g. 50)
  --max-calories: float # The maximum amount of calories the recipe can have. (e.g. 800)
  --min-fat: float # The minimum amount of fat in grams the recipe must have. (e.g. 1)
  --max-fat: float # The maximum amount of fat in grams the recipe can have. (e.g. 100)
  --min-alcohol: float # The minimum amount of alcohol in grams the recipe must have. (e.g. 0)
  --max-alcohol: float # The maximum amount of alcohol in grams the recipe can have. (e.g. 100)
  --min-caffeine: float # The minimum amount of caffeine in milligrams the recipe must have. (e.g. 0)
  --max-caffeine: float # The maximum amount of caffeine in milligrams the recipe can have. (e.g. 100)
  --min-copper: float # The minimum amount of copper in milligrams the recipe must have. (e.g. 0)
  --max-copper: float # The maximum amount of copper in milligrams the recipe can have. (e.g. 100)
  --min-calcium: float # The minimum amount of calcium in milligrams the recipe must have. (e.g. 0)
  --max-calcium: float # The maximum amount of calcium in milligrams the recipe can have. (e.g. 100)
  --min-choline: float # The minimum amount of choline in milligrams the recipe must have. (e.g. 0)
  --max-choline: float # The maximum amount of choline in milligrams the recipe can have. (e.g. 100)
  --min-cholesterol: float # The minimum amount of cholesterol in milligrams the recipe must have. (e.g. 0)
  --max-cholesterol: float # The maximum amount of cholesterol in milligrams the recipe can have. (e.g. 100)
  --min-fluoride: float # The minimum amount of fluoride in milligrams the recipe must have. (e.g. 0)
  --max-fluoride: float # The maximum amount of fluoride in milligrams the recipe can have. (e.g. 100)
  --min-saturated-fat: float # The minimum amount of saturated fat in grams the recipe must have. (e.g. 0)
  --max-saturated-fat: float # The maximum amount of saturated fat in grams the recipe can have. (e.g. 100)
  --min-vitamin-a: float # The minimum amount of Vitamin A in IU the recipe must have. (e.g. 0)
  --max-vitamin-a: float # The maximum amount of Vitamin A in IU the recipe can have. (e.g. 100)
  --min-vitamin-c: float # The minimum amount of Vitamin C in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-c: float # The maximum amount of Vitamin C in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-d: float # The minimum amount of Vitamin D in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-d: float # The maximum amount of Vitamin D in micrograms the recipe can have. (e.g. 100)
  --min-vitamin-e: float # The minimum amount of Vitamin E in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-e: float # The maximum amount of Vitamin E in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-k: float # The minimum amount of Vitamin K in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-k: float # The maximum amount of Vitamin K in micrograms the recipe can have. (e.g. 100)
  --min-vitamin-b1: float # The minimum amount of Vitamin B1 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b1: float # The maximum amount of Vitamin B1 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b2: float # The minimum amount of Vitamin B2 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b2: float # The maximum amount of Vitamin B2 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b5: float # The minimum amount of Vitamin B5 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b5: float # The maximum amount of Vitamin B5 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b3: float # The minimum amount of Vitamin B3 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b3: float # The maximum amount of Vitamin B3 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b6: float # The minimum amount of Vitamin B6 in milligrams the recipe must have. (e.g. 0)
  --max-vitamin-b6: float # The maximum amount of Vitamin B6 in milligrams the recipe can have. (e.g. 100)
  --min-vitamin-b12: float # The minimum amount of Vitamin B12 in micrograms the recipe must have. (e.g. 0)
  --max-vitamin-b12: float # The maximum amount of Vitamin B12 in micrograms the recipe can have. (e.g. 100)
  --min-fiber: float # The minimum amount of fiber in grams the recipe must have. (e.g. 0)
  --max-fiber: float # The maximum amount of fiber in grams the recipe can have. (e.g. 100)
  --min-folate: float # The minimum amount of folate in micrograms the recipe must have. (e.g. 0)
  --max-folate: float # The maximum amount of folate in micrograms the recipe can have. (e.g. 100)
  --min-folic-acid: float # The minimum amount of folic acid in micrograms the recipe must have. (e.g. 0)
  --max-folic-acid: float # The maximum amount of folic acid in micrograms the recipe can have. (e.g. 100)
  --min-iodine: float # The minimum amount of iodine in micrograms the recipe must have. (e.g. 0)
  --max-iodine: float # The maximum amount of iodine in micrograms the recipe can have. (e.g. 100)
  --min-iron: float # The minimum amount of iron in milligrams the recipe must have. (e.g. 0)
  --max-iron: float # The maximum amount of iron in milligrams the recipe can have. (e.g. 100)
  --min-magnesium: float # The minimum amount of magnesium in milligrams the recipe must have. (e.g. 0)
  --max-magnesium: float # The maximum amount of magnesium in milligrams the recipe can have. (e.g. 100)
  --min-manganese: float # The minimum amount of manganese in milligrams the recipe must have. (e.g. 0)
  --max-manganese: float # The maximum amount of manganese in milligrams the recipe can have. (e.g. 100)
  --min-phosphorus: float # The minimum amount of phosphorus in milligrams the recipe must have. (e.g. 0)
  --max-phosphorus: float # The maximum amount of phosphorus in milligrams the recipe can have. (e.g. 100)
  --min-potassium: float # The minimum amount of potassium in milligrams the recipe must have. (e.g. 0)
  --max-potassium: float # The maximum amount of potassium in milligrams the recipe can have. (e.g. 100)
  --min-selenium: float # The minimum amount of selenium in micrograms the recipe must have. (e.g. 0)
  --max-selenium: float # The maximum amount of selenium in micrograms the recipe can have. (e.g. 100)
  --min-sodium: float # The minimum amount of sodium in milligrams the recipe must have. (e.g. 0)
  --max-sodium: float # The maximum amount of sodium in milligrams the recipe can have. (e.g. 100)
  --min-sugar: float # The minimum amount of sugar in grams the recipe must have. (e.g. 0)
  --max-sugar: float # The maximum amount of sugar in grams the recipe can have. (e.g. 100)
  --min-zinc: float # The minimum amount of zinc in milligrams the recipe must have. (e.g. 0)
  --max-zinc: float # The maximum amount of zinc in milligrams the recipe can have. (e.g. 100)
  --offset: int # The number of results to skip (between 0 and 900).
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --random: oneof<nothing, bool> # If true, every request will give you a random set of recipes within the requested limits. (e.g. false)
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/findByNutrients"
    query: [{name: minCarbs, var: min_carbs}, {name: maxCarbs, var: max_carbs}, {name: minProtein, var: min_protein}, {name: maxProtein, var: max_protein}, {name: minCalories, var: min_calories}, {name: maxCalories, var: max_calories}, {name: minFat, var: min_fat}, {name: maxFat, var: max_fat}, {name: minAlcohol, var: min_alcohol}, {name: maxAlcohol, var: max_alcohol}, {name: minCaffeine, var: min_caffeine}, {name: maxCaffeine, var: max_caffeine}, {name: minCopper, var: min_copper}, {name: maxCopper, var: max_copper}, {name: minCalcium, var: min_calcium}, {name: maxCalcium, var: max_calcium}, {name: minCholine, var: min_choline}, {name: maxCholine, var: max_choline}, {name: minCholesterol, var: min_cholesterol}, {name: maxCholesterol, var: max_cholesterol}, {name: minFluoride, var: min_fluoride}, {name: maxFluoride, var: max_fluoride}, {name: minSaturatedFat, var: min_saturated_fat}, {name: maxSaturatedFat, var: max_saturated_fat}, {name: minVitaminA, var: min_vitamin_a}, {name: maxVitaminA, var: max_vitamin_a}, {name: minVitaminC, var: min_vitamin_c}, {name: maxVitaminC, var: max_vitamin_c}, {name: minVitaminD, var: min_vitamin_d}, {name: maxVitaminD, var: max_vitamin_d}, {name: minVitaminE, var: min_vitamin_e}, {name: maxVitaminE, var: max_vitamin_e}, {name: minVitaminK, var: min_vitamin_k}, {name: maxVitaminK, var: max_vitamin_k}, {name: minVitaminB1, var: min_vitamin_b1}, {name: maxVitaminB1, var: max_vitamin_b1}, {name: minVitaminB2, var: min_vitamin_b2}, {name: maxVitaminB2, var: max_vitamin_b2}, {name: minVitaminB5, var: min_vitamin_b5}, {name: maxVitaminB5, var: max_vitamin_b5}, {name: minVitaminB3, var: min_vitamin_b3}, {name: maxVitaminB3, var: max_vitamin_b3}, {name: minVitaminB6, var: min_vitamin_b6}, {name: maxVitaminB6, var: max_vitamin_b6}, {name: minVitaminB12, var: min_vitamin_b12}, {name: maxVitaminB12, var: max_vitamin_b12}, {name: minFiber, var: min_fiber}, {name: maxFiber, var: max_fiber}, {name: minFolate, var: min_folate}, {name: maxFolate, var: max_folate}, {name: minFolicAcid, var: min_folic_acid}, {name: maxFolicAcid, var: max_folic_acid}, {name: minIodine, var: min_iodine}, {name: maxIodine, var: max_iodine}, {name: minIron, var: min_iron}, {name: maxIron, var: max_iron}, {name: minMagnesium, var: min_magnesium}, {name: maxMagnesium, var: max_magnesium}, {name: minManganese, var: min_manganese}, {name: maxManganese, var: max_manganese}, {name: minPhosphorus, var: min_phosphorus}, {name: maxPhosphorus, var: max_phosphorus}, {name: minPotassium, var: min_potassium}, {name: maxPotassium, var: max_potassium}, {name: minSelenium, var: min_selenium}, {name: maxSelenium, var: max_selenium}, {name: minSodium, var: min_sodium}, {name: maxSodium, var: max_sodium}, {name: minSugar, var: min_sugar}, {name: maxSugar, var: max_sugar}, {name: minZinc, var: min_zinc}, {name: maxZinc, var: max_zinc}, {name: offset, var: offset}, {name: number, var: number}, {name: random, var: random}, {name: limitLicense, var: limit_license}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    min_carbs: $min_carbs, max_carbs: $max_carbs, min_protein: $min_protein, max_protein: $max_protein, min_calories: $min_calories, max_calories: $max_calories, min_fat: $min_fat, max_fat: $max_fat, min_alcohol: $min_alcohol, max_alcohol: $max_alcohol, min_caffeine: $min_caffeine, max_caffeine: $max_caffeine, min_copper: $min_copper, max_copper: $max_copper, min_calcium: $min_calcium, max_calcium: $max_calcium, min_choline: $min_choline, max_choline: $max_choline, min_cholesterol: $min_cholesterol, max_cholesterol: $max_cholesterol, min_fluoride: $min_fluoride, max_fluoride: $max_fluoride, min_saturated_fat: $min_saturated_fat, max_saturated_fat: $max_saturated_fat, min_vitamin_a: $min_vitamin_a, max_vitamin_a: $max_vitamin_a, min_vitamin_c: $min_vitamin_c, max_vitamin_c: $max_vitamin_c, min_vitamin_d: $min_vitamin_d, max_vitamin_d: $max_vitamin_d, min_vitamin_e: $min_vitamin_e, max_vitamin_e: $max_vitamin_e, min_vitamin_k: $min_vitamin_k, max_vitamin_k: $max_vitamin_k, min_vitamin_b1: $min_vitamin_b1, max_vitamin_b1: $max_vitamin_b1, min_vitamin_b2: $min_vitamin_b2, max_vitamin_b2: $max_vitamin_b2, min_vitamin_b5: $min_vitamin_b5, max_vitamin_b5: $max_vitamin_b5, min_vitamin_b3: $min_vitamin_b3, max_vitamin_b3: $max_vitamin_b3, min_vitamin_b6: $min_vitamin_b6, max_vitamin_b6: $max_vitamin_b6, min_vitamin_b12: $min_vitamin_b12, max_vitamin_b12: $max_vitamin_b12, min_fiber: $min_fiber, max_fiber: $max_fiber, min_folate: $min_folate, max_folate: $max_folate, min_folic_acid: $min_folic_acid, max_folic_acid: $max_folic_acid, min_iodine: $min_iodine, max_iodine: $max_iodine, min_iron: $min_iron, max_iron: $max_iron, min_magnesium: $min_magnesium, max_magnesium: $max_magnesium, min_manganese: $min_manganese, max_manganese: $max_manganese, min_phosphorus: $min_phosphorus, max_phosphorus: $max_phosphorus, min_potassium: $min_potassium, max_potassium: $max_potassium, min_selenium: $min_selenium, max_selenium: $max_selenium, min_sodium: $min_sodium, max_sodium: $max_sodium, min_sugar: $min_sugar, max_sugar: $max_sugar, min_zinc: $min_zinc, max_zinc: $max_zinc, offset: $offset, number: $number, random: $random, limit_license: $limit_license
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Guess Nutrition by Dish Name
#
# GET /recipes/guessNutrition
# Docs: https://spoonacular.com/food-api/docs#Guess-Nutrition-by-Dish-Name — Read entire docs
# Returns: record<calories: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, carbs: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, fat: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, protein: record<confidenceRange95Percent: record<max: float, min: float>, standardDeviation: float, unit: string, value: float>, recipesUsed: int>
# operationId: guessNutritionByDishName
export def "guess-nutrition-by-dish-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the dish. (required, e.g. Spaghetti Aglio et Olio)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/guessNutrition"
    query: [{name: title, var: title, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Recipe Information Bulk
#
# GET /recipes/informationBulk
# Docs: https://spoonacular.com/food-api/docs#Get-Recipe-Information-Bulk — Read entire docs
# Returns: table<aggregateLikes: int, analyzedInstructions: list<string>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: list<record>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list, pairingText: string, productMatches: list>>
# operationId: getRecipeInformationBulk
export def "get-recipe-information-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # A comma-separated list of recipe ids. (required, e.g. 715538,716429)
  --include-nutrition: oneof<nothing, bool> # Include nutrition data in the recipe information. Nutrition data is per serving. If you want the nutrition data for the entire recipe, just multiply by the number of servings. (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/informationBulk"
    query: [{name: ids, var: ids, required: true}, {name: includeNutrition, var: include_nutrition}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    ids: $ids, include_nutrition: $include_nutrition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Parse Ingredients
#
# POST /recipes/parseIngredients
# Docs: https://spoonacular.com/food-api/docs#Parse-Ingredients — Read entire docs
# Returns: table<aisle: string, amount: float, consistency: string, estimatedCost: record<unit: string, value: float>, id: int, image: string, meta: list<string>, name: string, nameClean: string, nutrition: record<caloricBreakdown: record, flavonoids: list, nutrients: list, properties: list, weightPerServing: record>, original: string, originalName: string, possibleUnits: list<string>, unit: string, unitLong: string, unitShort: string>
# operationId: parseIngredients
export def "parse-ingredients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: string
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipes/parseIngredients"
    query: [{name: language, var: language}]
    header: [{name: Content-Type, var: content_type}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    language: $language, content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Analyze a Recipe Search Query
#
# GET /recipes/queries/analyze
# Docs: https://spoonacular.com/food-api/docs#Analyze-a-Recipe-Search-Query — Read entire docs
# Returns: record<cuisines: list<string>, dishes: table<image: string, name: string>, ingredients: table<image: string, include: bool, name: string>, modifiers: list<string>>
# operationId: analyzeARecipeSearchQuery
export def "analyze-a-recipe-search-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The recipe search query. (required, e.g. salmon with fusilli and no nuts)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/queries/analyze"
    query: [{name: q, var: q, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Quick Answer
#
# GET /recipes/quickAnswer
# Docs: https://spoonacular.com/food-api/docs#Quick-Answer — Read entire docs
# Returns: record<answer: string, image: string>
# operationId: quickAnswer
export def "quick-answer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The nutrition related question. (required, e.g. How much vitamin c is in 2 apples?)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/quickAnswer"
    query: [{name: q, var: q, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Random Recipes
#
# GET /recipes/random
# Docs: https://spoonacular.com/food-api/docs#Get-Random-Recipes — Read entire docs
# Returns: record<recipes: table<aggregateLikes: float, analyzedInstructions: list, cheap: bool, creditsText: string, cuisines: list, dairyFree: bool, diets: list, dishTypes: list, extendedIngredients: list, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record>>
# operationId: getRandomRecipes
export def "get-random-recipes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
  --tags: string # The tags (can be diets, meal types, cuisines, or intolerances) that the recipe must have.
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/random"
    query: [{name: limitLicense, var: limit_license}, {name: tags, var: tags}, {name: number, var: number}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    limit_license: $limit_license, tags: $tags, number: $number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equipment Widget
#
# POST /recipes/visualizeEquipment
# Docs: https://spoonacular.com/food-api/docs#Equipment-Widget — Read entire docs
# Returns: string
# operationId: visualizeEquipment
export def "visualize-equipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/recipes/visualizeEquipment"
    header: [{name: Content-Type, var: content_type}, {name: Accept, var: hdr_accept}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ingredients Widget
#
# POST /recipes/visualizeIngredients
# Docs: https://spoonacular.com/food-api/docs#Ingredients-Widget — Read entire docs
# Returns: string
# operationId: visualizeIngredients
export def "visualize-ingredients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/recipes/visualizeIngredients"
    query: [{name: language, var: language}]
    header: [{name: Content-Type, var: content_type}, {name: Accept, var: hdr_accept}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    language: $language, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recipe Nutrition Widget
#
# POST /recipes/visualizeNutrition
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-Widget — Read entire docs
# Returns: string
# operationId: visualizeRecipeNutrition
export def "visualize-recipe-nutrition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/recipes/visualizeNutrition"
    query: [{name: language, var: language}]
    header: [{name: Content-Type, var: content_type}, {name: Accept, var: hdr_accept}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    language: $language, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Price Breakdown Widget
#
# POST /recipes/visualizePriceEstimator
# Docs: https://spoonacular.com/food-api/docs#Price-Breakdown-Widget — Read entire docs
# Returns: string
# operationId: visualizePriceBreakdown
export def "visualize-price-breakdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/recipes/visualizePriceEstimator"
    query: [{name: language, var: language}]
    header: [{name: Content-Type, var: content_type}, {name: Accept, var: hdr_accept}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    language: $language, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Recipe Card
#
# POST /recipes/visualizeRecipe
# Docs: https://spoonacular.com/food-api/docs#Create-Recipe-Card — Read entire docs
# Returns: record<url: string>
# operationId: createRecipeCard
export def "create-recipe-card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipes/visualizeRecipe"
    header: [{name: Content-Type, var: content_type}]
    body: {content_type: "multipart/form-data", kind: multipart, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    content_type: $content_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recipe Taste Widget
#
# POST /recipes/visualizeTaste
# Docs: https://spoonacular.com/food-api/docs#Recipe-Taste-Widget — Read entire docs
# Returns: string
# operationId: visualizeRecipeTaste
export def "visualize-recipe-taste" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language of the input. Either 'en' or 'de'. (e.g. en)
  --normalize: oneof<nothing, bool> # Whether to normalize to the strongest taste.
  --rgb: string # Red, green, blue values for the chart color. (e.g. 75,192,192)
  --content-type: string@content-type-completer # The content type. (e.g. application/json)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json) (spec name: Accept)
  --body: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/recipes/visualizeTaste"
    query: [{name: language, var: language}, {name: normalize, var: normalize}, {name: rgb, var: rgb}]
    header: [{name: Content-Type, var: content_type}, {name: Accept, var: hdr_accept}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, accepts: scalar}
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    language: $language, normalize: $normalize, rgb: $rgb, content_type: $content_type, hdr_accept: $hdr_accept, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Analyzed Recipe Instructions
#
# GET /recipes/{id}/analyzedInstructions
# Docs: https://spoonacular.com/food-api/docs#Get-Analyzed-Recipe-Instructions — Read entire docs
# Returns: record<equipment: table<id: int, name: string>, ingredients: table<id: int, name: string>, parsedInstructions: table<name: string, steps: list>>
# operationId: getAnalyzedRecipeInstructions
export def "get-analyzed-recipe-instructions" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --step-breakdown: oneof<nothing, bool> # Whether to break down the recipe steps even more. (e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}/analyzedInstructions"
    path_params: [{name: id, var: id}]
    query: [{name: stepBreakdown, var: step_breakdown}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, step_breakdown: $step_breakdown
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Recipe Card
#
# GET /recipes/{id}/card
# Docs: https://spoonacular.com/food-api/docs#Create-Recipe-Card — Read entire docs
# Returns: record
# operationId: createRecipeCardGet
export def "create-recipe-card-get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mask: string # The mask to put over the recipe image ("ellipseMask", "diamondMask", "starMask", "heartMask", "potMask", "fishMask"). (e.g. ellipseMask)
  --background-image: string # The background image ("none","background1", or "background2"). (e.g. background1)
  --background-color: string # The background color for the recipe card as a hex-string. (e.g. ffffff)
  --font-color: string # The font color for the recipe card as a hex-string. (e.g. 333333)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}/card"
    path_params: [{name: id, var: id}]
    query: [{name: mask, var: mask}, {name: backgroundImage, var: background_image}, {name: backgroundColor, var: background_color}, {name: fontColor, var: font_color}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, mask: $mask, background_image: $background_image, background_color: $background_color, font_color: $font_color
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equipment by ID Widget
#
# GET /recipes/{id}/equipmentWidget
# Docs: https://spoonacular.com/food-api/docs#Equipment-by-ID-Widget — Read entire docs
# Returns: string
# operationId: visualizeRecipeEquipmentByID
export def "visualize-recipe-equipment-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
]: nothing -> any {
  http-request {
    method: get
    path: "/recipes/{id}/equipmentWidget"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equipment by ID
#
# GET /recipes/{id}/equipmentWidget.json
# Docs: https://spoonacular.com/food-api/docs#Equipment-by-ID — Read entire docs
# Returns: record<equipment: table<image: string, name: string>>
# operationId: getRecipeEquipmentByID
export def "get-recipe-equipment-by-id" [
  id: float
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
    path: "/recipes/{id}/equipmentWidget.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Equipment by ID Image
#
# GET /recipes/{id}/equipmentWidget.png
# Docs: https://spoonacular.com/food-api/docs#Equipment-by-ID-Image — Read entire docs
# Returns: record
# operationId: equipmentByIDImage
export def "equipment-by-id-image" [
  id: float
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
    path: "/recipes/{id}/equipmentWidget.png"
    path_params: [{name: id, var: id}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Recipe Information
#
# GET /recipes/{id}/information
# Docs: https://spoonacular.com/food-api/docs#Get-Recipe-Information — Read entire docs
# Returns: record<aggregateLikes: int, analyzedInstructions: list<record>, cheap: bool, creditsText: string, cuisines: list<string>, dairyFree: bool, diets: list<string>, dishTypes: list<string>, extendedIngredients: table<aisle: string, amount: float, consitency: string, id: int, image: string, measures: record, meta: list, name: string, original: string, originalName: string, unit: string>, gaps: string, glutenFree: bool, healthScore: float, id: int, image: string, imageType: string, instructions: string, ketogenic: bool, license: string, lowFodmap: bool, occasions: list<string>, pricePerServing: float, readyInMinutes: int, servings: float, sourceName: string, sourceUrl: string, spoonacularScore: float, spoonacularSourceUrl: string, summary: string, sustainable: bool, title: string, vegan: bool, vegetarian: bool, veryHealthy: bool, veryPopular: bool, weightWatcherSmartPoints: float, whole30: bool, winePairing: record<pairedWines: list<string>, pairingText: string, productMatches: list<record>>>
# operationId: getRecipeInformation
export def "get-recipe-information" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-nutrition: oneof<nothing, bool> # Include nutrition data in the recipe information. Nutrition data is per serving. If you want the nutrition data for the entire recipe, just multiply by the number of servings. (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}/information"
    path_params: [{name: id, var: id}]
    query: [{name: includeNutrition, var: include_nutrition}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, include_nutrition: $include_nutrition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ingredients by ID Widget
#
# GET /recipes/{id}/ingredientWidget
# Docs: https://spoonacular.com/food-api/docs#Ingredients-by-ID-Widget — Read entire docs
# Returns: string
# operationId: visualizeRecipeIngredientsByID
export def "visualize-recipe-ingredients-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --measure: string@measure-completer # Whether the the measures should be 'us' or 'metric'. (e.g. metric)
]: nothing -> any {
  http-request {
    method: get
    path: "/recipes/{id}/ingredientWidget"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}, {name: measure, var: measure}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css, measure: $measure
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ingredients by ID
#
# GET /recipes/{id}/ingredientWidget.json
# Docs: https://spoonacular.com/food-api/docs#Ingredients-by-ID — Read entire docs
# Returns: record<ingredients: table<amount: record, image: string, name: string>>
# operationId: getRecipeIngredientsByID
export def "get-recipe-ingredients-by-id" [
  id: float
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
    path: "/recipes/{id}/ingredientWidget.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ingredients by ID Image
#
# GET /recipes/{id}/ingredientWidget.png
# Docs: https://spoonacular.com/food-api/docs#Ingredients-by-ID-Image — Read entire docs
# Returns: record
# operationId: ingredientsByIDImage
export def "ingredients-by-id-image" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --measure: string@measure-completer # Whether the the measures should be 'us' or 'metric'. (e.g. metric)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}/ingredientWidget.png"
    path_params: [{name: id, var: id}]
    query: [{name: measure, var: measure}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, measure: $measure
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recipe Nutrition Label Widget
#
# GET /recipes/{id}/nutritionLabel
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-Label-Widget — Read entire docs
# Returns: string
# operationId: recipeNutritionLabelWidget
export def "recipe-nutrition-label-widget" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> any {
  http-request {
    method: get
    path: "/recipes/{id}/nutritionLabel"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}, {name: showOptionalNutrients, var: show_optional_nutrients}, {name: showZeroValues, var: show_zero_values}, {name: showIngredients, var: show_ingredients}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css, show_optional_nutrients: $show_optional_nutrients, show_zero_values: $show_zero_values, show_ingredients: $show_ingredients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recipe Nutrition Label Image
#
# GET /recipes/{id}/nutritionLabel.png
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-Label-Image — Read entire docs
# Returns: record
# operationId: recipeNutritionLabelImage
export def "recipe-nutrition-label-image" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-optional-nutrients: oneof<nothing, bool> # Whether to show optional nutrients. (e.g. false)
  --show-zero-values: oneof<nothing, bool> # Whether to show zero values. (e.g. false)
  --show-ingredients: oneof<nothing, bool> # Whether to show a list of ingredients. (e.g. false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}/nutritionLabel.png"
    path_params: [{name: id, var: id}]
    query: [{name: showOptionalNutrients, var: show_optional_nutrients}, {name: showZeroValues, var: show_zero_values}, {name: showIngredients, var: show_ingredients}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, show_optional_nutrients: $show_optional_nutrients, show_zero_values: $show_zero_values, show_ingredients: $show_ingredients
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recipe Nutrition by ID Widget
#
# GET /recipes/{id}/nutritionWidget
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-by-ID-Widget — Read entire docs
# Returns: string
# operationId: visualizeRecipeNutritionByID
export def "visualize-recipe-nutrition-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
  --hdr-accept: string@accept-completer # Accept header. (e.g. application/json) (spec name: Accept)
]: nothing -> any {
  http-request {
    method: get
    path: "/recipes/{id}/nutritionWidget"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Nutrition by ID
#
# GET /recipes/{id}/nutritionWidget.json
# Docs: https://spoonacular.com/food-api/docs#Nutrition-by-ID — Read entire docs
# Returns: record<bad: table<amount: string, indented: bool, name: string, percentOfDailyNeeds: float>, calories: string, carbs: string, fat: string, good: table<amount: string, indented: bool, name: string, percentOfDailyNeeds: float>, protein: string>
# operationId: getRecipeNutritionWidgetByID
export def "get-recipe-nutrition-widget-by-id" [
  id: float
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
    path: "/recipes/{id}/nutritionWidget.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recipe Nutrition by ID Image
#
# GET /recipes/{id}/nutritionWidget.png
# Docs: https://spoonacular.com/food-api/docs#Recipe-Nutrition-by-ID-Image — Read entire docs
# Returns: record
# operationId: recipeNutritionByIDImage
export def "recipe-nutrition-by-id-image" [
  id: float
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
    path: "/recipes/{id}/nutritionWidget.png"
    path_params: [{name: id, var: id}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Price Breakdown by ID Widget
#
# GET /recipes/{id}/priceBreakdownWidget
# Docs: https://spoonacular.com/food-api/docs#Price-Breakdown-by-ID-Widget — Read entire docs
# Returns: string
# operationId: visualizeRecipePriceBreakdownByID
export def "visualize-recipe-price-breakdown-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-css: oneof<nothing, bool> # Whether the default CSS should be added to the response. (default: true, e.g. false)
]: nothing -> any {
  http-request {
    method: get
    path: "/recipes/{id}/priceBreakdownWidget"
    path_params: [{name: id, var: id}]
    query: [{name: defaultCss, var: default_css}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, default_css: $default_css
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Price Breakdown by ID
#
# GET /recipes/{id}/priceBreakdownWidget.json
# Docs: https://spoonacular.com/food-api/docs#Price-Breakdown-by-ID — Read entire docs
# Returns: record<ingredients: table<amount: record, image: string, name: string, price: float>, totalCost: float, totalCostPerServing: float>
# operationId: getRecipePriceBreakdownByID
export def "get-recipe-price-breakdown-by-id" [
  id: float
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
    path: "/recipes/{id}/priceBreakdownWidget.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Price Breakdown by ID Image
#
# GET /recipes/{id}/priceBreakdownWidget.png
# Docs: https://spoonacular.com/food-api/docs#Price-Breakdown-by-ID-Image — Read entire docs
# Returns: record
# operationId: priceBreakdownByIDImage
export def "price-breakdown-by-id-image" [
  id: float
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
    path: "/recipes/{id}/priceBreakdownWidget.png"
    path_params: [{name: id, var: id}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Similar Recipes
#
# GET /recipes/{id}/similar
# Docs: https://spoonacular.com/food-api/docs#Get-Similar-Recipes — Read entire docs
# Returns: table<id: int, imageType: string, readyInMinutes: int, servings: float, sourceUrl: string, title: string>
# operationId: getSimilarRecipes
export def "get-similar-recipes" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # The maximum number of items to return (between 1 and 100). Defaults to 10. (default: 10, e.g. 10)
  --limit-license: oneof<nothing, bool> # Whether the recipes should have an open license that allows display with proper attribution. (default: true, e.g. true)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}/similar"
    path_params: [{name: id, var: id}]
    query: [{name: number, var: number}, {name: limitLicense, var: limit_license}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, number: $number, limit_license: $limit_license
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Summarize Recipe
#
# GET /recipes/{id}/summary
# Docs: https://spoonacular.com/food-api/docs#Summarize-Recipe — Read entire docs
# Returns: record<id: int, summary: string, title: string>
# operationId: summarizeRecipe
export def "summarize-recipe" [
  id: float
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
    path: "/recipes/{id}/summary"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recipe Taste by ID Widget
#
# GET /recipes/{id}/tasteWidget
# Docs: https://spoonacular.com/food-api/docs#Recipe-Taste-by-ID-Widget — Read entire docs
# Returns: string
# operationId: visualizeRecipeTasteByID
export def "visualize-recipe-taste-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --normalize: oneof<nothing, bool> # Whether to normalize to the strongest taste. (default: true, e.g. true)
  --rgb: string # Red, green, blue values for the chart color. (e.g. 75,192,192)
]: nothing -> any {
  http-request {
    method: get
    path: "/recipes/{id}/tasteWidget"
    path_params: [{name: id, var: id}]
    query: [{name: normalize, var: normalize}, {name: rgb, var: rgb}]
    accept: ["text/html"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, normalize: $normalize, rgb: $rgb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Taste by ID
#
# GET /recipes/{id}/tasteWidget.json
# Docs: https://spoonacular.com/food-api/docs#Taste-by-ID — Read entire docs
# Returns: record<bitterness: float, fattiness: float, saltiness: float, savoriness: float, sourness: float, spiciness: float, sweetness: float>
# operationId: getRecipeTasteByID
export def "get-recipe-taste-by-id" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --normalize: oneof<nothing, bool> # Normalize to the strongest taste. (default: true, e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}/tasteWidget.json"
    path_params: [{name: id, var: id}]
    query: [{name: normalize, var: normalize}]
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, normalize: $normalize
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recipe Taste by ID Image
#
# GET /recipes/{id}/tasteWidget.png
# Docs: https://spoonacular.com/food-api/docs#Recipe-Taste-by-ID-Image — Read entire docs
# Returns: record
# operationId: recipeTasteByIDImage
export def "recipe-taste-by-id-image" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --normalize: oneof<nothing, bool> # Normalize to the strongest taste. (e.g. false)
  --rgb: string # Red, green, blue values for the chart color. (e.g. 75,192,192)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}/tasteWidget.png"
    path_params: [{name: id, var: id}]
    query: [{name: normalize, var: normalize}, {name: rgb, var: rgb}]
    accept: ["image/png"]
    ok: [200]
    auth: x-api-key
  } {
    id: $id, normalize: $normalize, rgb: $rgb
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Connect User
#
# POST /users/connect
# Docs: https://spoonacular.com/food-api/docs#Connect-User — Read entire docs
# Returns: record<hash: string, username: string>
# operationId: connectUser
export def "connect-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
  first_name: string
  last_name: string
  username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/connect"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-api-key
  } {
    email: $email, first_name: $first_name, last_name: $last_name, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
