# Auto-generated client for 1,000,000+ Recipe and Grocery List API (v2) vpartner
# Source: https://api.apis.guru/v2/specs/bigoven.com/partner/openapi.json
# Auth: --token flag or $env.1_000_000_RECIPE_AND_GROCERY_LIST_API_V2_TOKEN

const CLIENT = {
  base_url: "https://api2.bigoven.com"
  token_env_var: "1_000_000_RECIPE_AND_GROCERY_LIST_API_V2_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-bigoven-api-key, in: header, header_name: X-BigOven-API-Key, prefix: ""}
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
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

def base-url-completer [] { ["https://api2.bigoven.com"] }
def auth-scheme-completer [] { ["x-bigoven-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    collection-get-collection: "record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string>"
    collection-get-collection-meta: "record<Description: string, ID: int, IsFiltered: bool, IsSponsored: bool, MobileUrl: string, PRO: bool, PhotoUrl: string, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, Title: string, Token: string, WebUrl: string>"
    collection-collections: "table<Description: string, ID: int, IsFiltered: bool, IsSponsored: bool, MobileUrl: string, PRO: bool, PhotoUrl: string, Results: list<record>, Title: string, Token: string, WebUrl: string>"
    grocery-list-delete: "record"
    grocery-list-get: "record<Items: table<BigOvenObject: string, CreationDate: string, Department: string, DisplayQuantity: string, GUID: string, IsChecked: bool, ItemID: int, LastModified: string, LocalStatus: string, Name: string, Notes: string, RecipeID: int, ThirdPartyURL: string>, LastModified: string, Recipes: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, VersionGuid: string>"
    grocery-list-grocery-list-remove-marked-items: "record<Items: table<BigOvenObject: string, CreationDate: string, Department: string, DisplayQuantity: string, GUID: string, IsChecked: bool, ItemID: int, LastModified: string, LocalStatus: string, Name: string, Notes: string, RecipeID: int, ThirdPartyURL: string>, LastModified: string, Recipes: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, VersionGuid: string>"
    grocery-list-department: "table<dept: string, item: string>"
    post-grocerylist-item: "record<DateAdded: string, Dept: string, GUID: string, HTMLItemName: string, IsChecked: bool, ItemName: string, LastModified: string, ListID: int, MealPlanID: int, MealPlanObjectType: int, Notes: string, PendingAddition: bool, RecipeID: int, ShoppingListLineID: int, Store: string, TextAmt: string, ThirdPartyHost: string, ThirdPartyTitle: string, ThirdPartyURL: string>"
    grocery-list-delete-item-by-guid: "record"
    grocery-list-grocery-list-item-guid: "record"
    grocery-list-post: "record<DateAdded: string, Dept: string, GUID: string, HTMLItemName: string, IsChecked: bool, ItemName: string, LastModified: string, ListID: int, MealPlanID: int, MealPlanObjectType: int, Notes: string, PendingAddition: bool, RecipeID: int, ShoppingListLineID: int, Store: string, TextAmt: string, ThirdPartyHost: string, ThirdPartyTitle: string, ThirdPartyURL: string>"
    grocery-list-add-recipe: "record"
    grocery-list-post-grocery-list-sync: "record"
    images-upload-user-avatar: "record"
    me-index: "record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>"
    me-put-me: "record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>"
    me-put-me-personal: "record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>"
    me-put-me-preferences: "record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>"
    me-get-options: "record<EatingStyle: record<Options: list<record>>>"
    put-me-profile: "record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>"
    me-skinny: "record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>"
    recipe-post: "record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>"
    recipe-put: "record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>"
    recipe-auto-complete: "list<string>"
    recipe-auto-complete-all-recipes: "table<ImageURL: string, QualityScore: int, RecipeID: int, Servings: float, Title: string>"
    recipe-auto-complete-my-recipes: "table<ImageURL: string, QualityScore: int, RecipeID: int, Servings: float, Title: string>"
    recipe-categories: "table<Category: string, DefaultActiveMinutes: int, DefaultTotalMinutes: int, ID: int, ParentID: int, PrimaryImage: string, ShortDescription: string>"
    recipe-get-active-recipe: "record<Data: record, Message: string, StatusCode: int>"
    recipe-get-step: "string"
    recipe-get-step-number: "record<Data: record, Message: string, StatusCode: int>"
    images-get-pending-by-user: "record<ResultCount: int, Results: table<Caption: string, CreationDate: string, ImageID: int, IsPrimary: bool, MaxImageSquare: int, PhotoUrl: string, Poster: record>>"
    recipe-get-steps: "record<Data: record, Message: string, StatusCode: int>"
    review-delete-reply: "record"
    review-put-reply: "record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>"
    get-recipe-review-review-id: "record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>"
    review-put: "record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>"
    review-get-replies: "table<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>"
    review-post-reply: "record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>"
    recipe-get-recipe-with-steps: "record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>"
    recipe-delete: "record"
    recipe-get: "record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>"
    recipe-zap-recipe: "record"
    recipe-feedback: "record"
    images-upload-recipe-image: "record"
    images-get: "table<Caption: string, CreationDate: string, ImageID: int, ImageSquares: list<int>, ImageURL: string, ImageURL120: string, ImageURL128: string, ImageURL200: string, ImageURL256: string, ImageURL48: string, ImageURL64: string, IsPrimary: bool, MaxImageSquare: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>>"
    note-post: "record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>"
    note-delete: "record"
    note-get: "record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>"
    note-put: "record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>"
    note-get-notes: "record<ResultCount: int, Results: table<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>>"
    images-get-recipe-photos: "record<ResultCount: int, Results: table<Caption: string, CreationDate: string, ImageID: int, IsPrimary: bool, MaxImageSquare: int, PhotoUrl: string, Poster: record>>"
    recipe-related: "record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string>"
    get-recipe-recipe-id-review: "record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>"
    review-post: "record"
    review-delete: "record"
    review-get: "record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>"
    review-put-legacy: "record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>"
    review-get-reviews: "table<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>"
    images-get-scan-images: "table<Caption: string, CreationDate: string, ImageID: int, ImageSquares: list<int>, ImageURL: string, ImageURL120: string, ImageURL128: string, ImageURL200: string, ImageURL256: string, ImageURL48: string, ImageURL64: string, IsPrimary: bool, MaxImageSquare: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>>"
    recipe-recipe-search: "record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string>"
    recipe-get-random-recipe: "record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>"
    recipe-raves: "table<RecipeInfo: record<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, Review: record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record, Replies: list, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>>"
    recipe-recent-views: "table<date: string, recipeInfo: record<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>>"
    recipe-recipe-search-random: "record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string>"
    recipe-get-v2: "record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, Videos: table<InsertedOn: string, IsPrimaryVideo: bool, MediaId: string, VidId: int>, WebURL: string, YieldNumber: float, YieldUnit: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["collection-get-collection" "collection-get-collection-meta" "collection-collections" "grocery-list-delete" "grocery-list-get" "grocery-list-grocery-list-remove-marked-items" "grocery-list-department" "post-grocerylist-item" "grocery-list-delete-item-by-guid" "grocery-list-grocery-list-item-guid" "grocery-list-post" "grocery-list-add-recipe" "grocery-list-post-grocery-list-sync" "images-upload-user-avatar" "me-index" "me-put-me" "me-put-me-personal" "me-put-me-preferences" "me-get-options" "put-me-profile" "me-skinny" "recipe-post" "recipe-put" "recipe-auto-complete" "recipe-auto-complete-all-recipes" "recipe-auto-complete-my-recipes" "recipe-categories" "recipe-get-active-recipe" "recipe-get-step" "recipe-get-step-number" "images-get-pending-by-user" "recipe-get-steps" "review-delete-reply" "review-put-reply" "get-recipe-review-review-id" "review-put" "review-get-replies" "review-post-reply" "recipe-scan" "recipe-get-recipe-with-steps" "recipe-delete" "recipe-get" "recipe-zap-recipe" "recipe-feedback" "images-upload-recipe-image" "images-get" "note-post" "note-delete" "note-get" "note-put" "note-get-notes" "images-get-recipe-photos" "recipe-related" "get-recipe-recipe-id-review" "review-post" "review-delete" "review-get" "review-put-legacy" "review-get-reviews" "images-get-scan-images" "recipe-recipe-search" "recipe-get-random-recipe" "recipe-raves" "recipe-recent-views" "recipe-recipe-search-random" "recipe-get-v2" "commands"] | sort) } | get name | first)
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

# Gets a recipe collection. A recipe collection is a curated set of recipes.
#
# GET /collection/{id}
# Returns: record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string>
# operationId: Collection_GetCollection
export def "collection-get-collection" [
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
  --accept: string@accept-completer # Response content type
  --rpp: int # results per page (format: int32)
  --pg: int # page number (starting with 1) (format: int32)
  --test: oneof<nothing, bool>
  --session-for-logging: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collection/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: rpp, var: rpp}, {name: pg, var: pg}, {name: test, var: test}, {name: sessionForLogging, var: session_for_logging}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    id: $id, rpp: $rpp, pg: $pg, test: $test, session_for_logging: $session_for_logging
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a recipe collection metadata. A recipe collection is a curated set of recipes.
#
# GET /collection/{id}/meta
# Returns: record<Description: string, ID: int, IsFiltered: bool, IsSponsored: bool, MobileUrl: string, PRO: bool, PhotoUrl: string, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, Title: string, Token: string, WebUrl: string>
# operationId: Collection_GetCollectionMeta
export def "collection-get-collection-meta" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/collection/{id}/meta"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the list of current, seasonal recipe collections. From here, you can use the /collection/{id} endpoint to retrieve the recipes in those collections.
#
# GET /collections
# Returns: table<Description: string, ID: int, IsFiltered: bool, IsSponsored: bool, MobileUrl: string, PRO: bool, PhotoUrl: string, Results: list<record>, Title: string, Token: string, WebUrl: string>
# operationId: Collection_Collections
export def "collection-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --test: string
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/collections"
    query: [{name: test, var: test}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    test: $test
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete all the items on a grocery list; faster operation than a sync with deleted items.
#
# DELETE /grocerylist
# Returns: record
# operationId: GroceryList_Delete
export def "grocery-list-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/grocerylist"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the user's grocery list. User is determined by Basic Authentication.
#
# GET /grocerylist
# Returns: record<Items: table<BigOvenObject: string, CreationDate: string, Department: string, DisplayQuantity: string, GUID: string, IsChecked: bool, ItemID: int, LastModified: string, LocalStatus: string, Name: string, Notes: string, RecipeID: int, ThirdPartyURL: string>, LastModified: string, Recipes: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, VersionGuid: string>
# operationId: GroceryList_Get
export def "grocery-list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/grocerylist"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Clears the checked lines.
#
# POST /grocerylist/clearcheckedlines
# Returns: record<Items: table<BigOvenObject: string, CreationDate: string, Department: string, DisplayQuantity: string, GUID: string, IsChecked: bool, ItemID: int, LastModified: string, LocalStatus: string, Name: string, Notes: string, RecipeID: int, ThirdPartyURL: string>, LastModified: string, Recipes: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, VersionGuid: string>
# operationId: GroceryList_GroceryListRemoveMarkedItems
export def "grocery-list-grocery-list-remove-marked-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/grocerylist/clearcheckedlines"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Departmentalize a list of strings -- used for ad-hoc grocery list item addition
#
# POST /grocerylist/department
# Returns: table<dept: string, item: string>
# operationId: GroceryList_Department
export def "grocery-list-department" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --items: string # Gets or sets the items.
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/grocerylist/department"
    body: {content_type: "application/json", kind: json, fields: [{name: items, var: items}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a single line item to the grocery list
#
# POST /grocerylist/item
# Returns: record<DateAdded: string, Dept: string, GUID: string, HTMLItemName: string, IsChecked: bool, ItemName: string, LastModified: string, ListID: int, MealPlanID: int, MealPlanObjectType: int, Notes: string, PendingAddition: bool, RecipeID: int, ShoppingListLineID: int, Store: string, TextAmt: string, ThirdPartyHost: string, ThirdPartyTitle: string, ThirdPartyURL: string>
export def "post-grocerylist-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --department: string # Gets or sets the department.
  --name: string # Gets or sets the name.
  --notes: string # Gets or sets the notes.
  --quantity: string # Gets or sets the quantity.
  --unit: string # Gets or sets the unit.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/grocerylist/item"
    body: {content_type: "application/json", kind: json, fields: [{name: department, var: department}, {name: name, var: name}, {name: notes, var: notes}, {name: quantity, var: quantity}, {name: unit, var: unit}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    department: $department, name: $name, notes: $notes, quantity: $quantity, unit: $unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# /grocerylist/item/{guid} DELETE will delete this item assuming you own it.
#
# DELETE /grocerylist/item/{guid}
# Returns: record
# operationId: GroceryList_DeleteItemByGuid
export def "grocery-list-delete-item-by-guid" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/grocerylist/item/{guid}"
    path_params: [{name: guid, var: guid}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    guid: $guid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a grocery item by GUID
#
# PUT /grocerylist/item/{guid}
# Returns: record
# operationId: GroceryList_GroceryListItemGuid
export def "grocery-list-grocery-list-item-guid" [
  guid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --department: string # Gets or sets the department.
  --body-guid: string # Gets or sets the unique identifier. (spec name: guid)
  --ischecked: oneof<nothing, bool> # Gets or sets the ischecked.
  --name: string # Gets or sets the name.
  --notes: string # Gets or sets the notes.
  --quantity: string # Gets or sets the quantity.
  --unit: string # Gets or sets the unit.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/grocerylist/item/{guid}"
    path_params: [{name: guid, var: guid}]
    body: {content_type: "application/json", kind: json, fields: [{name: department, var: department}, {name: guid, var: body_guid}, {name: ischecked, var: ischecked}, {name: name, var: name}, {name: notes, var: notes}, {name: quantity, var: quantity}, {name: unit, var: unit}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    guid: $guid, department: $department, body_guid: $body_guid, ischecked: $ischecked, name: $name, notes: $notes, quantity: $quantity, unit: $unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a single line item to the grocery list
#
# POST /grocerylist/line
# Returns: record<DateAdded: string, Dept: string, GUID: string, HTMLItemName: string, IsChecked: bool, ItemName: string, LastModified: string, ListID: int, MealPlanID: int, MealPlanObjectType: int, Notes: string, PendingAddition: bool, RecipeID: int, ShoppingListLineID: int, Store: string, TextAmt: string, ThirdPartyHost: string, ThirdPartyTitle: string, ThirdPartyURL: string>
# operationId: GroceryList_Post
export def "grocery-list-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --text: string # Gets or sets the text.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/grocerylist/line"
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a Recipe to the grocery list. In the request data, pass in recipeId, scale (scale=1.0 says to keep the recipe the same size as originally posted), markAsPending (true/false) to indicate that the lines in the recipe should be marked in a "pending" (unconfirmed by user) state.
#
# POST /grocerylist/recipe
# Returns: record
# operationId: GroceryList_AddRecipe
export def "grocery-list-add-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --mark-as-pending: oneof<nothing, bool> # Gets or sets the mark as pending.
  --recipe-id: int # Gets or sets the recipe identifier. (format: int32)
  --scale: float # Gets or sets the scale. (format: double)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/grocerylist/recipe"
    body: {content_type: "application/json", kind: json, fields: [{name: markAsPending, var: mark_as_pending}, {name: recipeId, var: recipe_id}, {name: scale, var: scale}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    mark_as_pending: $mark_as_pending, recipe_id: $recipe_id, scale: $scale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Synchronize the grocery list. Call this with a POST to /grocerylist/sync
#
# POST /grocerylist/sync
# Returns: record
# operationId: GroceryList_PostGroceryListSync
export def "grocery-list-post-grocery-list-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --list: record # shape: {Items?: list, LastModified?: string, Recipes?: list, VersionGuid?: string}
  --since: string # Gets or sets the since.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/grocerylist/sync"
    body: {content_type: "application/json", kind: json, fields: [{name: list, var: list}, {name: since, var: since}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    list: $list, since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST: /image/avatar Testing with Postman (validated 11/20/2015): 1) Remove the Content-Type header; add authentication information 2) On the request, click Body and choose "form-data", then add a line item with "key" column set to "file" and on the right, change the type of the input from Text to File. Browse and choose a JPG.
#
# POST /image/avatar
# Returns: record
# operationId: Images_UploadUserAvatar
export def "images-upload-user-avatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/image/avatar"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Indexes this instance.
#
# GET /me
# Returns: record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>
# operationId: Me_Index
export def "me-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Puts me.
#
# PUT /me
# Returns: record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>
# operationId: Me_PutMe
export def "me-put-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accounting: record # shape: {CreditBalance?: int, MemberSince?: string, PremiumExpiryDate?: string, UserLevel?: string}
  --bo-auth-token: string # The user-specific authentication token
  --last-change-log-id: string # Last change log
  --personal: record # Personal level info -- email, location, etc. — shape: {Email?: string, Location?: record}
  --preferences: record # shape: {EatingStyle?: string}
  --profile: record # shape: {AboutMe?: string, BackgroundUrl?: string, Counts?: record, FirstName?: string, FullName?: string, HomeUrl?: string, LastName?: string, PhotoUrl?: string, UserID?: int, UserName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/me"
    body: {content_type: "application/json", kind: json, fields: [{name: Accounting, var: accounting}, {name: BOAuthToken, var: bo_auth_token}, {name: LastChangeLogID, var: last_change_log_id}, {name: Personal, var: personal}, {name: Preferences, var: preferences}, {name: Profile, var: profile}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    accounting: $accounting, bo_auth_token: $bo_auth_token, last_change_log_id: $last_change_log_id, personal: $personal, preferences: $preferences, profile: $profile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Puts me personal.
#
# PUT /me/personal
# Returns: record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>
# operationId: Me_PutMePersonal
export def "me-put-me-personal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string
  --location: record # shape: {City?: string, Country?: string, DMA?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/me/personal"
    body: {content_type: "application/json", kind: json, fields: [{name: Email, var: email}, {name: Location, var: location}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    email: $email, location: $location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Puts me preferences.
#
# PUT /me/preferences
# Returns: record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>
# operationId: Me_PutMePreferences
export def "me-put-me-preferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --eating-style: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/me/preferences"
    body: {content_type: "application/json", kind: json, fields: [{name: EatingStyle, var: eating_style}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    eating_style: $eating_style
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the options.
#
# GET /me/preferences/options
# Returns: record<EatingStyle: record<Options: list<record>>>
# operationId: Me_GetOptions
export def "me-get-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/preferences/options"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Puts me.
#
# PUT /me/profile
# Returns: record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>
export def "put-me-profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --about-me: string
  --background-url: string
  --counts: record # shape: {AddedCount?: int, FollowersCount?: int, FollowingCount?: int, PrivateRecipeCount?: int, PublicRecipeCount?: int, TotalRecipes?: int}
  --first-name: string
  --full-name: string
  --home-url: string
  --last-name: string
  --photo-url: string
  --user-id: int # format: int64
  --user-name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/me/profile"
    body: {content_type: "application/json", kind: json, fields: [{name: AboutMe, var: about_me}, {name: BackgroundUrl, var: background_url}, {name: Counts, var: counts}, {name: FirstName, var: first_name}, {name: FullName, var: full_name}, {name: HomeUrl, var: home_url}, {name: LastName, var: last_name}, {name: PhotoUrl, var: photo_url}, {name: UserID, var: user_id}, {name: UserName, var: user_name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    about_me: $about_me, background_url: $background_url, counts: $counts, first_name: $first_name, full_name: $full_name, home_url: $home_url, last_name: $last_name, photo_url: $photo_url, user_id: $user_id, user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Skinnies this instance.
#
# GET /me/skinny
# Returns: record<Accounting: record<CreditBalance: int, MemberSince: string, PremiumExpiryDate: string, UserLevel: string>, BOAuthToken: string, LastChangeLogID: string, Personal: record<Email: string, Location: record<City: string, Country: string, DMA: int>>, Preferences: record<EatingStyle: string>, Profile: record<AboutMe: string, BackgroundUrl: string, Counts: record<AddedCount: int, FollowersCount: int, FollowingCount: int, PrivateRecipeCount: int, PublicRecipeCount: int, TotalRecipes: int>, FirstName: string, FullName: string, HomeUrl: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>>
# operationId: Me_Skinny
export def "me-skinny" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/me/skinny"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a new recipe
#
# POST /recipe
# Returns: record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>
# operationId: Recipe_Post
export def "recipe-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # format: int32
  --ad-tags: string
  --admin-boost: int # format: int32
  --all-categories-text: string
  --bookmark-image-url: string
  --bookmark-site-logo: string
  --bookmark-url: string
  --category: string
  --collection: string
  --collection-id: int # format: int32
  --creation-date: string # format: date-time
  --cuisine: string
  --description: string
  --favorite-count: int # format: int32
  --hero-photo-url: string
  --image-squares: list<int>
  --image-url: string
  --ingredients: list # item shape: {DisplayIndex?: int, DisplayQuantity?: string, HTMLName?: string, IngredientID?: int, IngredientInfo?: record, IsHeading?: bool, IsLinked?: bool, MetricDisplayQuantity?: string, MetricQuantity?: float, MetricUnit?: string, Name?: string, PreparationNotes?: string, Quantity?: float, Unit?: string}
  --ingredients-text-block: string
  --instructions: string
  --is-bookmark: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --is-recipe-scan: oneof<nothing, bool>
  --is-sponsored: oneof<nothing, bool>
  --last-modified: string # format: date-time
  --max-image-square: int # format: int32
  --medal-count: int # format: int32
  --menu-count: int # format: int32
  --microcategory: string
  --notes-count: int # format: int32
  --nutrition-info: record # shape: {CaloriesFromFat?: float, Cholesterol?: float, CholesterolPct?: float, DietaryFiber?: float, DietaryFiberPct?: float, MonoFat?: float, PolyFat?: float, Potassium?: float, PotassiumPct?: float, Protein?: float, ProteinPct?: float, SatFat?: float, SatFatPct?: float, SingularYieldUnit?: string, Sodium?: float, SodiumPct?: float, Sugar?: float, TotalCalories?: float, TotalCarbs?: float, TotalCarbsPct?: float, TotalFat?: float, TotalFatPct?: float, TransFat?: float}
  --poster: record # shape: {FirstName?: string, ImageUrl48?: string, IsKitchenHelper?: bool, IsPremium?: bool, IsUsingRecurly?: bool, LastName?: string, MemberSince?: string, PhotoUrl?: string, PremiumExpiryDate?: string, UserID?: int, UserName?: string}
  --primary-ingredient: string
  --recipe-id: int # format: int32
  --review-count: int # format: int32
  --star-rating: float # format: double
  --subcategory: string
  --title: string
  --total-minutes: int # format: int32
  --variant-of-recipe-id: int # format: int32
  --verified-by-class: string
  --verified-date-time: string # format: date-time
  --web-url: string
  --yield-number: float # format: double
  --yield-unit: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipe"
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveMinutes, var: active_minutes}, {name: AdTags, var: ad_tags}, {name: AdminBoost, var: admin_boost}, {name: AllCategoriesText, var: all_categories_text}, {name: BookmarkImageURL, var: bookmark_image_url}, {name: BookmarkSiteLogo, var: bookmark_site_logo}, {name: BookmarkURL, var: bookmark_url}, {name: Category, var: category}, {name: Collection, var: collection}, {name: CollectionID, var: collection_id}, {name: CreationDate, var: creation_date}, {name: Cuisine, var: cuisine}, {name: Description, var: description}, {name: FavoriteCount, var: favorite_count}, {name: HeroPhotoUrl, var: hero_photo_url}, {name: ImageSquares, var: image_squares}, {name: ImageURL, var: image_url}, {name: Ingredients, var: ingredients}, {name: IngredientsTextBlock, var: ingredients_text_block}, {name: Instructions, var: instructions}, {name: IsBookmark, var: is_bookmark}, {name: IsPrivate, var: is_private}, {name: IsRecipeScan, var: is_recipe_scan}, {name: IsSponsored, var: is_sponsored}, {name: LastModified, var: last_modified}, {name: MaxImageSquare, var: max_image_square}, {name: MedalCount, var: medal_count}, {name: MenuCount, var: menu_count}, {name: Microcategory, var: microcategory}, {name: NotesCount, var: notes_count}, {name: NutritionInfo, var: nutrition_info}, {name: Poster, var: poster}, {name: PrimaryIngredient, var: primary_ingredient}, {name: RecipeID, var: recipe_id}, {name: ReviewCount, var: review_count}, {name: StarRating, var: star_rating}, {name: Subcategory, var: subcategory}, {name: Title, var: title}, {name: TotalMinutes, var: total_minutes}, {name: VariantOfRecipeID, var: variant_of_recipe_id}, {name: VerifiedByClass, var: verified_by_class}, {name: VerifiedDateTime, var: verified_date_time}, {name: WebURL, var: web_url}, {name: YieldNumber, var: yield_number}, {name: YieldUnit, var: yield_unit}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    active_minutes: $active_minutes, ad_tags: $ad_tags, admin_boost: $admin_boost, all_categories_text: $all_categories_text, bookmark_image_url: $bookmark_image_url, bookmark_site_logo: $bookmark_site_logo, bookmark_url: $bookmark_url, category: $category, collection: $collection, collection_id: $collection_id, creation_date: $creation_date, cuisine: $cuisine, description: $description, favorite_count: $favorite_count, hero_photo_url: $hero_photo_url, image_squares: $image_squares, image_url: $image_url, ingredients: $ingredients, ingredients_text_block: $ingredients_text_block, instructions: $instructions, is_bookmark: $is_bookmark, is_private: $is_private, is_recipe_scan: $is_recipe_scan, is_sponsored: $is_sponsored, last_modified: $last_modified, max_image_square: $max_image_square, medal_count: $medal_count, menu_count: $menu_count, microcategory: $microcategory, notes_count: $notes_count, nutrition_info: $nutrition_info, poster: $poster, primary_ingredient: $primary_ingredient, recipe_id: $recipe_id, review_count: $review_count, star_rating: $star_rating, subcategory: $subcategory, title: $title, total_minutes: $total_minutes, variant_of_recipe_id: $variant_of_recipe_id, verified_by_class: $verified_by_class, verified_date_time: $verified_date_time, web_url: $web_url, yield_number: $yield_number, yield_unit: $yield_unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a recipe
#
# PUT /recipe
# Returns: record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>
# operationId: Recipe_Put
export def "recipe-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # format: int32
  --ad-tags: string
  --admin-boost: int # format: int32
  --all-categories-text: string
  --bookmark-image-url: string
  --bookmark-site-logo: string
  --bookmark-url: string
  --category: string
  --collection: string
  --collection-id: int # format: int32
  --creation-date: string # format: date-time
  --cuisine: string
  --description: string
  --favorite-count: int # format: int32
  --hero-photo-url: string
  --image-squares: list<int>
  --image-url: string
  --ingredients: list # item shape: {DisplayIndex?: int, DisplayQuantity?: string, HTMLName?: string, IngredientID?: int, IngredientInfo?: record, IsHeading?: bool, IsLinked?: bool, MetricDisplayQuantity?: string, MetricQuantity?: float, MetricUnit?: string, Name?: string, PreparationNotes?: string, Quantity?: float, Unit?: string}
  --ingredients-text-block: string
  --instructions: string
  --is-bookmark: oneof<nothing, bool>
  --is-private: oneof<nothing, bool>
  --is-recipe-scan: oneof<nothing, bool>
  --is-sponsored: oneof<nothing, bool>
  --last-modified: string # format: date-time
  --max-image-square: int # format: int32
  --medal-count: int # format: int32
  --menu-count: int # format: int32
  --microcategory: string
  --notes-count: int # format: int32
  --nutrition-info: record # shape: {CaloriesFromFat?: float, Cholesterol?: float, CholesterolPct?: float, DietaryFiber?: float, DietaryFiberPct?: float, MonoFat?: float, PolyFat?: float, Potassium?: float, PotassiumPct?: float, Protein?: float, ProteinPct?: float, SatFat?: float, SatFatPct?: float, SingularYieldUnit?: string, Sodium?: float, SodiumPct?: float, Sugar?: float, TotalCalories?: float, TotalCarbs?: float, TotalCarbsPct?: float, TotalFat?: float, TotalFatPct?: float, TransFat?: float}
  --poster: record # shape: {FirstName?: string, ImageUrl48?: string, IsKitchenHelper?: bool, IsPremium?: bool, IsUsingRecurly?: bool, LastName?: string, MemberSince?: string, PhotoUrl?: string, PremiumExpiryDate?: string, UserID?: int, UserName?: string}
  --primary-ingredient: string
  --recipe-id: int # format: int32
  --review-count: int # format: int32
  --star-rating: float # format: double
  --subcategory: string
  --title: string
  --total-minutes: int # format: int32
  --variant-of-recipe-id: int # format: int32
  --verified-by-class: string
  --verified-date-time: string # format: date-time
  --web-url: string
  --yield-number: float # format: double
  --yield-unit: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/recipe"
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveMinutes, var: active_minutes}, {name: AdTags, var: ad_tags}, {name: AdminBoost, var: admin_boost}, {name: AllCategoriesText, var: all_categories_text}, {name: BookmarkImageURL, var: bookmark_image_url}, {name: BookmarkSiteLogo, var: bookmark_site_logo}, {name: BookmarkURL, var: bookmark_url}, {name: Category, var: category}, {name: Collection, var: collection}, {name: CollectionID, var: collection_id}, {name: CreationDate, var: creation_date}, {name: Cuisine, var: cuisine}, {name: Description, var: description}, {name: FavoriteCount, var: favorite_count}, {name: HeroPhotoUrl, var: hero_photo_url}, {name: ImageSquares, var: image_squares}, {name: ImageURL, var: image_url}, {name: Ingredients, var: ingredients}, {name: IngredientsTextBlock, var: ingredients_text_block}, {name: Instructions, var: instructions}, {name: IsBookmark, var: is_bookmark}, {name: IsPrivate, var: is_private}, {name: IsRecipeScan, var: is_recipe_scan}, {name: IsSponsored, var: is_sponsored}, {name: LastModified, var: last_modified}, {name: MaxImageSquare, var: max_image_square}, {name: MedalCount, var: medal_count}, {name: MenuCount, var: menu_count}, {name: Microcategory, var: microcategory}, {name: NotesCount, var: notes_count}, {name: NutritionInfo, var: nutrition_info}, {name: Poster, var: poster}, {name: PrimaryIngredient, var: primary_ingredient}, {name: RecipeID, var: recipe_id}, {name: ReviewCount, var: review_count}, {name: StarRating, var: star_rating}, {name: Subcategory, var: subcategory}, {name: Title, var: title}, {name: TotalMinutes, var: total_minutes}, {name: VariantOfRecipeID, var: variant_of_recipe_id}, {name: VerifiedByClass, var: verified_by_class}, {name: VerifiedDateTime, var: verified_date_time}, {name: WebURL, var: web_url}, {name: YieldNumber, var: yield_number}, {name: YieldUnit, var: yield_unit}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    active_minutes: $active_minutes, ad_tags: $ad_tags, admin_boost: $admin_boost, all_categories_text: $all_categories_text, bookmark_image_url: $bookmark_image_url, bookmark_site_logo: $bookmark_site_logo, bookmark_url: $bookmark_url, category: $category, collection: $collection, collection_id: $collection_id, creation_date: $creation_date, cuisine: $cuisine, description: $description, favorite_count: $favorite_count, hero_photo_url: $hero_photo_url, image_squares: $image_squares, image_url: $image_url, ingredients: $ingredients, ingredients_text_block: $ingredients_text_block, instructions: $instructions, is_bookmark: $is_bookmark, is_private: $is_private, is_recipe_scan: $is_recipe_scan, is_sponsored: $is_sponsored, last_modified: $last_modified, max_image_square: $max_image_square, medal_count: $medal_count, menu_count: $menu_count, microcategory: $microcategory, notes_count: $notes_count, nutrition_info: $nutrition_info, poster: $poster, primary_ingredient: $primary_ingredient, recipe_id: $recipe_id, review_count: $review_count, star_rating: $star_rating, subcategory: $subcategory, title: $title, total_minutes: $total_minutes, variant_of_recipe_id: $variant_of_recipe_id, verified_by_class: $verified_by_class, verified_date_time: $verified_date_time, web_url: $web_url, yield_number: $yield_number, yield_unit: $yield_unit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Given a query, return recipe titles starting with query. Query must be at least 3 chars in length.
#
# GET /recipe/autocomplete
# Returns: list<string>
# operationId: Recipe_AutoComplete
export def "recipe-auto-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # required
  --limit: int # format: int32
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/autocomplete"
    query: [{name: query, var: query, required: true}, {name: limit, var: limit}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    query: $query, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Automatics the complete all recipes.
#
# GET /recipe/autocomplete/all
# Returns: table<ImageURL: string, QualityScore: int, RecipeID: int, Servings: float, Title: string>
# operationId: Recipe_AutoCompleteAllRecipes
export def "recipe-auto-complete-all-recipes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The query. (required)
  --limit: int # The limit. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/autocomplete/all"
    query: [{name: query, var: query, required: true}, {name: limit, var: limit, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    query: $query, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Automatics the complete my recipes.
#
# GET /recipe/autocomplete/mine
# Returns: table<ImageURL: string, QualityScore: int, RecipeID: int, Servings: float, Title: string>
# operationId: Recipe_AutoCompleteMyRecipes
export def "recipe-auto-complete-my-recipes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The query. (required)
  --limit: int # The limit. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/autocomplete/mine"
    query: [{name: query, var: query, required: true}, {name: limit, var: limit, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    query: $query, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of recipe categories (the ID field can be used for include_cat in search parameters)
#
# GET /recipe/categories
# Returns: table<Category: string, DefaultActiveMinutes: int, DefaultTotalMinutes: int, ID: int, ParentID: int, PrimaryImage: string, ShortDescription: string>
# operationId: Recipe_Categories
export def "recipe-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/categories"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns last active recipe for the user
#
# GET /recipe/get/active/recipe
# Returns: record<Data: record, Message: string, StatusCode: int>
# operationId: Recipe_GetActiveRecipe
export def "recipe-get-active-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-name: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/get/active/recipe"
    query: [{name: userName, var: user_name, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    user_name: $user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets recipe single step as text
#
# POST /recipe/get/saved/step
# Returns: string
# operationId: Recipe_GetStep
export def "recipe-get-step" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-name: string # required
  --recipe-id: int # required, format: int32
  --step-id: int # required, format: int32
]: nothing -> any {
  http-request {
    method: post
    path: "/recipe/get/saved/step"
    query: [{name: userName, var: user_name, required: true}, {name: recipeId, var: recipe_id, required: true}, {name: stepId, var: step_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    user_name: $user_name, recipe_id: $recipe_id, step_id: $step_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns stored step number and number of steps in recipe
#
# POST /recipe/get/step/number
# Returns: record<Data: record, Message: string, StatusCode: int>
# operationId: Recipe_GetStepNumber
export def "recipe-get-step-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-name: string # required
  --recipe-id: int # required, format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/recipe/get/step/number"
    query: [{name: userName, var: user_name, required: true}, {name: recipeId, var: recipe_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    user_name: $user_name, recipe_id: $recipe_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the pending by user.
#
# GET /recipe/photos/pending
# Returns: record<ResultCount: int, Results: table<Caption: string, CreationDate: string, ImageID: int, IsPrimary: bool, MaxImageSquare: int, PhotoUrl: string, Poster: record>>
# operationId: Images_GetPendingByUser
export def "images-get-pending-by-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/photos/pending"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Stores recipe step number and returns saved step data
#
# POST /recipe/post/step
# Returns: record<Data: record, Message: string, StatusCode: int>
# operationId: Recipe_GetSteps
export def "recipe-get-steps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-name: string # required
  --recipe-id: int # required, format: int32
  --step-id: int # required, format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/recipe/post/step"
    query: [{name: userName, var: user_name, required: true}, {name: recipeId, var: recipe_id, required: true}, {name: stepId, var: step_id, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    user_name: $user_name, recipe_id: $recipe_id, step_id: $step_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE a reply to a given review. Authenticated user must be the one who originally posted the reply.
#
# DELETE /recipe/review/replies/{replyId}
# Returns: record
# operationId: Review_DeleteReply
export def "review-delete-reply" [
  reply_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/recipe/review/replies/{replyId}"
    path_params: [{name: replyId, var: reply_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    reply_id: $reply_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update (PUT) a reply to a given review. Authenticated user must be the original one that posted the reply.
#
# PUT /recipe/review/replies/{replyId}
# Returns: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>
# operationId: Review_PutReply
export def "review-put-reply" [
  reply_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # The comment. If mentioning any user(s) (optional), include them as @username in the text body. Do not use @ symbol for anything but mentioning @usernames.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/recipe/review/replies/{replyId}"
    path_params: [{name: replyId, var: reply_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Comment, var: comment}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    reply_id: $reply_id, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a given review by string-style ID. This will return a payload with FeaturedReply, ReplyCount. Recommended display is to list top-level reviews with one featured reply underneath. Currently, the FeaturedReply is the most recent one for that rating.
#
# GET /recipe/review/{reviewId}
# Returns: record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>
export def "get-recipe-review-review-id" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/review/{reviewId}"
    path_params: [{name: reviewId, var: review_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    review_id: $review_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update a given top-level review.
#
# PUT /recipe/review/{reviewId}
# Returns: record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>
# operationId: Review_Put
export def "review-put" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # How many minutes of ACTIVE time (i.e., actively working on the recipe, not waiting for rising, baking, etc.) did it demand of the cook? Optional. (format: int32)
  --comment: string # The notes
  --make-again: string # "yes" or "no"
  --star-rating: int # 1, 2, 3, 4, or 5 (format: int32)
  --total-minutes: int # How long, start to finish, in minutes (integer) did it take? Optional. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/recipe/review/{reviewId}"
    path_params: [{name: reviewId, var: review_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveMinutes, var: active_minutes}, {name: Comment, var: comment}, {name: MakeAgain, var: make_again}, {name: StarRating, var: star_rating}, {name: TotalMinutes, var: total_minutes}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    review_id: $review_id, active_minutes: $active_minutes, comment: $comment, make_again: $make_again, star_rating: $star_rating, total_minutes: $total_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a paged list of replies for a given review.
#
# GET /recipe/review/{reviewId}/replies
# Returns: table<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>
# operationId: Review_GetReplies
export def "review-get-replies" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # the page (int), starting with 1 (format: int32)
  --rpp: int # results per page (int) (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/review/{reviewId}/replies"
    path_params: [{name: reviewId, var: review_id}]
    query: [{name: pg, var: pg}, {name: rpp, var: rpp}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    review_id: $review_id, pg: $pg, rpp: $rpp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST a reply to a given review. The date will be set by server. Note that replies no longer have star ratings, only top-level reviews do.
#
# POST /recipe/review/{reviewId}/replies
# Returns: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>
# operationId: Review_PostReply
export def "review-post-reply" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # The comment. If mentioning any user(s) (optional), include them as @username in the text body. Do not use @ symbol for anything but mentioning @usernames.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipe/review/{reviewId}/replies"
    path_params: [{name: reviewId, var: review_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Comment, var: comment}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    review_id: $review_id, comment: $comment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST an image as a new RecipeScan request 1) Fetch the filename -- DONE 2) Copy it to the pics/scan folder - ENSURE NO NAMING COLLISIONS -- DONE 3) Create 120 thumbnail size in pics/scan/120 -- DONE 4) Insert the CloudTasks record 5) Create the HIT 6) Update the CloudTasks record with the HIT ID 7) Email the requesing user 8) Call out to www.bigoven.com to fetch the image and re-create the thumbnail
#
# POST /recipe/scan
# operationId: Recipe_Scan
export def "recipe-scan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --test: oneof<nothing, bool>
  --devicetype: string
  --lat: float # format: double
  --lng: float # format: double
]: nothing -> any {
  http-request {
    method: post
    path: "/recipe/scan"
    query: [{name: test, var: test}, {name: devicetype, var: devicetype}, {name: lat, var: lat}, {name: lng, var: lng}]
    accept: ["application/json"]
    ok: []
    auth: x-bigoven-api-key
  } {
    test: $test, devicetype: $devicetype, lat: $lat, lng: $lng
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return full Recipe detail with steps. Returns 403 if the recipe is owned by someone else.
#
# GET /recipe/steps/{id}
# Returns: record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>
# operationId: Recipe_GetRecipeWithSteps
export def "recipe-get-recipe-with-steps" [
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
  --accept: string@accept-completer # Response content type
  --prefetch: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/steps/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: prefetch, var: prefetch}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    id: $id, prefetch: $prefetch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a Recipe (you must be authenticated as an owner of the recipe)
#
# DELETE /recipe/{id}
# Returns: record
# operationId: Recipe_Delete
export def "recipe-delete" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/recipe/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Return full Recipe detail. Returns 403 if the recipe is owned by someone else.
#
# GET /recipe/{id}
# Returns: record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>
# operationId: Recipe_Get
export def "recipe-get" [
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
  --accept: string@accept-completer # Response content type
  --prefetch: oneof<nothing, bool> # The prefetch.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: prefetch, var: prefetch}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    id: $id, prefetch: $prefetch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Zaps the recipe.
#
# GET /recipe/{id}/zap
# Returns: record
# operationId: Recipe_ZapRecipe
export def "recipe-zap-recipe" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{id}/zap"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Feedback on a Recipe -- for internal BigOven editors
#
# POST /recipe/{recipeId}/feedback
# Returns: record
# operationId: Recipe_Feedback
export def "recipe-feedback" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --feedback: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipe/{recipeId}/feedback"
    path_params: [{name: recipeId, var: recipe_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: feedback, var: feedback}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, feedback: $feedback
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST: /recipe/{recipeId}/image?lat=42&lng=21&caption=this%20is%20my%20caption Note that caption, lng and lat are all optional, but must go on the request URI as params because this endpoint needs a multipart/mime content header and will not parse JSON in the body along with it. Testing with Postman (validated 11/20/2015): 1) Remove the Content-Type header; add authentication information 2) On the request, click Body and choose "form-data", then add a line item with "key" column set to "file" and on the right, change the type of the input from Text to File. Browse and choose a JPG.
#
# POST /recipe/{recipeId}/image
# Returns: record
# operationId: Images_UploadRecipeImage
export def "images-upload-recipe-image" [
  recipe_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --caption: string
  --lat: float # format: double
  --lng: float # format: double
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/recipe/{recipeId}/image"
    path_params: [{name: recipeId, var: recipe_id}]
    query: [{name: caption, var: caption}, {name: lat, var: lat}, {name: lng, var: lng}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, caption: $caption, lat: $lat, lng: $lng
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all the images for a recipe. DEPRECATED. Please use /recipe/{recipeId}/photos.
#
# GET /recipe/{recipeId}/images
# Returns: table<Caption: string, CreationDate: string, ImageID: int, ImageSquares: list<int>, ImageURL: string, ImageURL120: string, ImageURL128: string, ImageURL200: string, ImageURL256: string, ImageURL48: string, ImageURL64: string, IsPrimary: bool, MaxImageSquare: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>>
# operationId: Images_Get
export def "images-get" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/images"
    path_params: [{name: recipeId, var: recipe_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# HTTP POST a new note into the system.
#
# POST /recipe/{recipeId}/note
# Returns: record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>
# operationId: Note_Post
export def "note-post" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # Gets or sets the creation date. (format: date-time)
  --date: string # Gets or sets the date. (format: date-time)
  --date-dt: string # Gets or sets the date dt.
  --guid: string # Gets or sets the unique identifier.
  --id: int # Gets or sets the identifier. (format: int32)
  --notes: string # Gets or sets the notes.
  --people: string # Gets or sets the people.
  --body-recipe-id: int # Gets or sets the recipe identifier. (format: int32) (spec name: RecipeID)
  --user-id: int # Gets or sets the user identifier. (format: int32)
  --variations: string # Gets or sets the variations.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipe/{recipeId}/note"
    path_params: [{name: recipeId, var: recipe_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreationDate, var: creation_date}, {name: Date, var: date}, {name: DateDT, var: date_dt}, {name: GUID, var: guid}, {name: ID, var: id}, {name: Notes, var: notes}, {name: People, var: people}, {name: RecipeID, var: body_recipe_id}, {name: UserID, var: user_id}, {name: Variations, var: variations}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, creation_date: $creation_date, date: $date, date_dt: $date_dt, guid: $guid, id: $id, notes: $notes, people: $people, body_recipe_id: $body_recipe_id, user_id: $user_id, variations: $variations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a review do a DELETE Http request of /note/{ID}
#
# DELETE /recipe/{recipeId}/note/{noteId}
# Returns: record
# operationId: Note_Delete
export def "note-delete" [
  recipe_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/recipe/{recipeId}/note/{noteId}"
    path_params: [{name: recipeId, var: recipe_id}, {name: noteId, var: note_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a given note. Make sure you're passing authentication information in the header for the user who owns the note.
#
# GET /recipe/{recipeId}/note/{noteId}
# Returns: record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>
# operationId: Note_Get
export def "note-get" [
  recipe_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/note/{noteId}"
    path_params: [{name: recipeId, var: recipe_id}, {name: noteId, var: note_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# HTTP PUT (update) a Recipe note (RecipeNote).
#
# PUT /recipe/{recipeId}/note/{noteId}
# Returns: record<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>
# operationId: Note_Put
export def "note-put" [
  recipe_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # Gets or sets the creation date. (format: date-time)
  --date: string # Gets or sets the date. (format: date-time)
  --date-dt: string # Gets or sets the date dt.
  --guid: string # Gets or sets the unique identifier.
  --id: int # Gets or sets the identifier. (format: int32)
  --notes: string # Gets or sets the notes.
  --people: string # Gets or sets the people.
  --body-recipe-id: int # Gets or sets the recipe identifier. (format: int32) (spec name: RecipeID)
  --user-id: int # Gets or sets the user identifier. (format: int32)
  --variations: string # Gets or sets the variations.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/recipe/{recipeId}/note/{noteId}"
    path_params: [{name: recipeId, var: recipe_id}, {name: noteId, var: note_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: CreationDate, var: creation_date}, {name: Date, var: date}, {name: DateDT, var: date_dt}, {name: GUID, var: guid}, {name: ID, var: id}, {name: Notes, var: notes}, {name: People, var: people}, {name: RecipeID, var: body_recipe_id}, {name: UserID, var: user_id}, {name: Variations, var: variations}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, note_id: $note_id, creation_date: $creation_date, date: $date, date_dt: $date_dt, guid: $guid, id: $id, notes: $notes, people: $people, body_recipe_id: $body_recipe_id, user_id: $user_id, variations: $variations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# recipe/100/notes
#
# GET /recipe/{recipeId}/notes
# Returns: record<ResultCount: int, Results: table<CreationDate: string, Date: string, DateDT: string, GUID: string, ID: int, Notes: string, People: string, RecipeID: int, UserID: int, Variations: string>>
# operationId: Note_GetNotes
export def "note-get-notes" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # page (int, starting from 1) (format: int32)
  --rpp: int # recipeId (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/notes"
    path_params: [{name: recipeId, var: recipe_id}]
    query: [{name: pg, var: pg}, {name: rpp, var: rpp}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, pg: $pg, rpp: $rpp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all the photos for a recipe
#
# GET /recipe/{recipeId}/photos
# Returns: record<ResultCount: int, Results: table<Caption: string, CreationDate: string, ImageID: int, IsPrimary: bool, MaxImageSquare: int, PhotoUrl: string, Poster: record>>
# operationId: Images_GetRecipePhotos
export def "images-get-recipe-photos" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # format: int32
  --rpp: int # format: int32
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/photos"
    path_params: [{name: recipeId, var: recipe_id}]
    query: [{name: pg, var: pg}, {name: rpp, var: rpp}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, pg: $pg, rpp: $rpp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get recipes related to the given recipeId
#
# GET /recipe/{recipeId}/related
# Returns: record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string>
# operationId: Recipe_Related
export def "recipe-related" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # The page (format: int32)
  --rpp: int # The results per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/related"
    path_params: [{name: recipeId, var: recipe_id}]
    query: [{name: pg, var: pg}, {name: rpp, var: rpp}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, pg: $pg, rpp: $rpp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get *my* review for the recipe {recipeId}, where "me" is determined by standard authentication headers
#
# GET /recipe/{recipeId}/review
# Returns: record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>
export def "get-recipe-recipe-id-review" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/review"
    path_params: [{name: recipeId, var: recipe_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a new review. Only one review can be provided per {userId, recipeId} pair. Otherwise your review will be updated.
#
# POST /recipe/{recipeId}/review
# Returns: record
# operationId: Review_Post
export def "review-post" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # How many minutes of ACTIVE time (i.e., actively working on the recipe, not waiting for rising, baking, etc.) did it demand of the cook? Optional. (format: int32)
  --comment: string # The notes
  --make-again: string # "yes" or "no"
  --star-rating: int # 1, 2, 3, 4, or 5 (format: int32)
  --total-minutes: int # How long, start to finish, in minutes (integer) did it take? Optional. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/recipe/{recipeId}/review"
    path_params: [{name: recipeId, var: recipe_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveMinutes, var: active_minutes}, {name: Comment, var: comment}, {name: MakeAgain, var: make_again}, {name: StarRating, var: star_rating}, {name: TotalMinutes, var: total_minutes}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, active_minutes: $active_minutes, comment: $comment, make_again: $make_again, star_rating: $star_rating, total_minutes: $total_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DEPRECATED! - Deletes a review by recipeId and reviewId. Please use recipe/review/{reviewId} instead.
#
# DELETE /recipe/{recipeId}/review/{reviewId}
# Returns: record
# operationId: Review_Delete
export def "review-delete" [
  recipe_id: int
  review_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/recipe/{recipeId}/review/{reviewId}"
    path_params: [{name: recipeId, var: recipe_id}, {name: reviewId, var: review_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, review_id: $review_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a given review - DEPRECATED. See recipe/review/{reviewId} for the current usage. Beginning in January 2017, BigOven moded from an integer-based ID system to a GUID-style string-based ID system for reviews and replies. We are also supporting more of a "Google Play" style model for Reviews and Replies. That is, there are top-level Reviews and then an unlimited list of replies (which do not carry star ratings) underneath existing reviews. Also, a given user can only have one review per recipe. Existing legacy endpoints will continue to work, but we strongly recommend you migrate to using the newer endpoints listed which do NOT carry the "DEPRECATED" flag.
#
# GET /recipe/{recipeId}/review/{reviewId}
# Returns: record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>
# operationId: Review_Get
export def "review-get" [
  recipe_id: int
  review_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/review/{reviewId}"
    path_params: [{name: recipeId, var: recipe_id}, {name: reviewId, var: review_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, review_id: $review_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# HTTP PUT (update) a recipe review. DEPRECATED. Please see recipe/review/{reviewId} PUT for the new endpoint. We are moving to a string-based primary key system, no longer integers, for reviews and replies.
#
# PUT /recipe/{recipeId}/review/{reviewId}
# Returns: record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record<FirstName: string, LastName: string, PhotoUrl: string, UserID: int, UserName: string>, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>
# operationId: Review_PutLegacy
export def "review-put-legacy" [
  recipe_id: int
  review_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-minutes: int # format: int32
  --comment: string
  --guid: string
  --make-again: string
  --parent-id: int # format: int32
  --star-rating: int # format: int32
  --total-minutes: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/recipe/{recipeId}/review/{reviewId}"
    path_params: [{name: recipeId, var: recipe_id}, {name: reviewId, var: review_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: ActiveMinutes, var: active_minutes}, {name: Comment, var: comment}, {name: GUID, var: guid}, {name: MakeAgain, var: make_again}, {name: ParentID, var: parent_id}, {name: StarRating, var: star_rating}, {name: TotalMinutes, var: total_minutes}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, review_id: $review_id, active_minutes: $active_minutes, comment: $comment, guid: $guid, make_again: $make_again, parent_id: $parent_id, star_rating: $star_rating, total_minutes: $total_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get paged list of reviews for a recipe. Each review will have at most one FeaturedReply, as well as a ReplyCount.
#
# GET /recipe/{recipeId}/reviews
# Returns: table<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record<Comment: string, CreationDate: string, ID: string, LastModified: string, Poster: record, ReviewID: string>, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, Replies: list<any>, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>
# operationId: Review_GetReviews
export def "review-get-reviews" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # the page (int), starting with 1 (format: int32)
  --rpp: int # results per page (int) (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/reviews"
    path_params: [{name: recipeId, var: recipe_id}]
    query: [{name: pg, var: pg}, {name: rpp, var: rpp}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id, pg: $pg, rpp: $rpp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of RecipeScan images for the recipe. There will be at most 3 per recipe.
#
# GET /recipe/{recipeId}/scans
# Returns: table<Caption: string, CreationDate: string, ImageID: int, ImageSquares: list<int>, ImageURL: string, ImageURL120: string, ImageURL128: string, ImageURL200: string, ImageURL256: string, ImageURL48: string, ImageURL64: string, IsPrimary: bool, MaxImageSquare: int, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>>
# operationId: Images_GetScanImages
export def "images-get-scan-images" [
  recipe_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipe/{recipeId}/scans"
    path_params: [{name: recipeId, var: recipe_id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    recipe_id: $recipe_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for recipes. There are many parameters that you can apply. Starting with the most common, use title_kw to search within a title. Use any_kw to search across the entire recipe. If you'd like to limit by course, set the parameter "include_primarycat" to one of (appetizers,bread,breakfast,dessert,drinks,maindish,salad,sidedish,soup,marinades,other). If you'd like to exclude a category, set exclude_cat to one or more (comma-separated) list of those categories to exclude. If you'd like to include a category, set include_cat to one or more (comma-separated) of those categories to include. To explicitly include an ingredient in your search, set the parameter "include_ing" to a CSV of up to three ingredients, e.g.:include_ing=mustard,chicken,beef%20tips To explicitly exclude an ingredient in your search, set the parameter "exclude_ing" to a CSV of up to three ingredients. All searches must contain the paging parameters pg and rpp, which are integers, and represent the page number (1-based) and results per page (rpp). So, to get the third page of a result set paged with 25 recipes per page, you'd pass pg=3&rpp=25 If you'd like to target searches to just a single target user's recipes, set userId=the target userId (number). Or, you can set username=theirusername vtn;vgn;chs;glf;ntf;dyf;sff;slf;tnf;wmf;rmf;cps cuisine photos filter=added,try,favorites,myrecipes\r\n\r\n folder=FolderNameCaseSensitive coll=ID of Collection
#
# GET /recipes
# Returns: record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string>
# operationId: Recipe_RecipeSearch
export def "recipe-recipe-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --any-kw: string # Search anywhere in the recipe for the keyword
  --folder: string # Search in a specific folder name for the authenticated user
  --coll: int # Limit to a collection ID number (format: int32)
  --filter: string # optionally set to either "myrecipes", "try", "favorites","added" to filter to just the authenticated user's recipe set
  --title-kw: string # Search just in the recipe title for the keyword
  --user-id: int # Set the target userid to search their public recipes (format: int32)
  --username: string # Set the target username to search their public recipes
  --qp-token: string # (spec name: token)
  --photos: oneof<nothing, bool> # if set to true, limit search results to photos only
  --boostmine: oneof<nothing, bool> # if set to true, boost my own recipes in my folders so they show up high in the list (at the expense of other sort orders)
  --include-cat: string # integer of the subcategory you'd like to limit searches to (see the /recipe/categories endpoint for available id numbers). For instance, 58 is "Main Dish > Casseroles".
  --exclude-cat: string # like include_cat, set this to an integer to exclude a specific category
  --include-primarycat: string # csv indicating up to three top-level categories -- valid values are [appetizers,bread,breakfast,desserts,drinks,maindish,salads,sidedish,soups,marinades,other]
  --exclude-primarycat: string # csv indicating integer values for up to 3 top-level categories -- valid values are 1...11 [appetizers,bread,breakfast,desserts,drinks,maindish,salads,sidedish,soups,marinades,other]
  --include-ing: string # A CSV representing up to 3 ingredients to include, e.g., tomatoes,corn%20%starch,chicken
  --exclude-ing: string # A CSV representing up to 3 ingredients to exclude (Powersearch-capable plan required)
  --cuisine: string # Limit to a specific cuisine. Cooks can enter anything free-form, but the few dozen preconfigured values are Afghan,African,American,American-South,Asian,Australian,Brazilian,Cajun,Canadian,Caribbean,Chinese,Croatian,Cuban,Dessert,Eastern European,English,French,German,Greek,Hawaiian,Hungarian,India,Indian,Irish,Italian,Japanese,Jewish,Korean,Latin,Mediterranean,Mexican,Middle Eastern,Moroccan,Polish,Russian,Scandanavian,Seafood,Southern,Southwestern,Spanish,Tex-Mex,Thai,Vegan,Vegetarian,Vietnamese
  --db: string
  --userset: string # If set to a given username, it'll force the search to filter to just that username
  --servings-min: float # Limit to yield of a given number size or greater. Note that cooks usually enter recipes by Servings, but sometimes they are posted by "dozen", etc. This parameter simply specifies the minimum number for that value entered in "yield." (format: double)
  --total-mins: int # Optional. If supplied, will restrict results to recipes that can be made in {totalMins} or less. (Convert "1 hour, 15 minutes" to 75 before passing in.) (format: int32)
  --max-ingredients: int # Optional. If supplied, will restrict results to recipes that can be made with {maxIngredients} ingredients or less (format: int32)
  --min-ingredients: int # Optional. If supplied, will restrict results to recipes that have at least {minIngredients} (format: int32)
  --rpp: int # integer; results per page (format: int32)
  --pg: int # integer: the page number (format: int32)
  --vtn: int # when set to 1, limit to vegetarian (Powersearch-capable plan required) (format: int32)
  --vgn: int # when set to 1, limit to vegan (Powersearch-capable plan required) (format: int32)
  --chs: int # when set to 1, limit to contains-cheese (Powersearch-capable plan required) (format: int32)
  --glf: int # when set to 1, limit to gluten-free (Powersearch-capable plan required) (format: int32)
  --ntf: int # when set to 1, limit to nut-free (Powersearch-capable plan required) (format: int32)
  --dyf: int # when set to 1, limit to dairy-free (Powersearch-capable plan required) (format: int32)
  --sff: int # when set to 1, limit to seafood-free (Powersearch-capable plan required) (format: int32)
  --slf: int # when set to 1, limit to shellfish-free (Powersearch-capable plan required) (format: int32)
  --tnf: int # when set to 1, limit to tree-nut free (Powersearch-capable plan required) (format: int32)
  --wmf: int # when set to 1, limit to white-meat free (Powersearch-capable plan required) (format: int32)
  --rmf: int # when set to 1, limit to red-meat free (Powersearch-capable plan required) (format: int32)
  --cps: int # when set to 1, recipe contains pasta, set to 0 means contains no pasta (Powersearch-capable plan required) (format: int32)
  --champion: int # optional. When set to 1, this will limit search results to "best of" recipes as determined by various internal editorial and programmatic algorithms. For the most comprehensive results, don't include this parameter. (format: int32)
  --synonyms: oneof<nothing, bool> # optional, default is false. When set to true, BigOven will attempt to apply synonyms in search (e.g., excluding pork will also exclude bacon)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes"
    query: [{name: any_kw, var: any_kw}, {name: folder, var: folder}, {name: coll, var: coll}, {name: filter, var: filter}, {name: title_kw, var: title_kw}, {name: userId, var: user_id}, {name: username, var: username}, {name: token, var: qp_token}, {name: photos, var: photos}, {name: boostmine, var: boostmine}, {name: include_cat, var: include_cat}, {name: exclude_cat, var: exclude_cat}, {name: include_primarycat, var: include_primarycat}, {name: exclude_primarycat, var: exclude_primarycat}, {name: include_ing, var: include_ing}, {name: exclude_ing, var: exclude_ing}, {name: cuisine, var: cuisine}, {name: db, var: db}, {name: userset, var: userset}, {name: servingsMin, var: servings_min}, {name: totalMins, var: total_mins}, {name: maxIngredients, var: max_ingredients}, {name: minIngredients, var: min_ingredients}, {name: rpp, var: rpp}, {name: pg, var: pg}, {name: vtn, var: vtn}, {name: vgn, var: vgn}, {name: chs, var: chs}, {name: glf, var: glf}, {name: ntf, var: ntf}, {name: dyf, var: dyf}, {name: sff, var: sff}, {name: slf, var: slf}, {name: tnf, var: tnf}, {name: wmf, var: wmf}, {name: rmf, var: rmf}, {name: cps, var: cps}, {name: champion, var: champion}, {name: synonyms, var: synonyms}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    any_kw: $any_kw, folder: $folder, coll: $coll, filter: $filter, title_kw: $title_kw, user_id: $user_id, username: $username, qp_token: $qp_token, photos: $photos, boostmine: $boostmine, include_cat: $include_cat, exclude_cat: $exclude_cat, include_primarycat: $include_primarycat, exclude_primarycat: $exclude_primarycat, include_ing: $include_ing, exclude_ing: $exclude_ing, cuisine: $cuisine, db: $db, userset: $userset, servings_min: $servings_min, total_mins: $total_mins, max_ingredients: $max_ingredients, min_ingredients: $min_ingredients, rpp: $rpp, pg: $pg, vtn: $vtn, vgn: $vgn, chs: $chs, glf: $glf, ntf: $ntf, dyf: $dyf, sff: $sff, slf: $slf, tnf: $tnf, wmf: $wmf, rmf: $rmf, cps: $cps, champion: $champion, synonyms: $synonyms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a random, home-page-quality Recipe.
#
# GET /recipes/random
# Returns: record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, HeroPhotoUrl: string, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, WebURL: string, YieldNumber: float, YieldUnit: string>
# operationId: Recipe_GetRandomRecipe
export def "recipe-get-random-recipe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/random"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the recipe/comment tuples for those recipes with 4 or 5 star ratings
#
# GET /recipes/raves
# Returns: table<RecipeInfo: record<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, Review: record<ActiveMinutes: int, Comment: string, CreationDate: string, FeaturedReply: record, GUID: string, ID: string, LastModified: string, ParentID: int, Poster: record, Replies: list, ReplyCount: int, ReviewID: int, StarRating: float, TotalMinutes: int>>
# operationId: Recipe_Raves
export def "recipe-raves" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # page, starting with 1 (format: int32)
  --rpp: int # results per page (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/raves"
    query: [{name: pg, var: pg}, {name: rpp, var: rpp}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    pg: $pg, rpp: $rpp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of recipes that the authenticated user has most recently viewed
#
# GET /recipes/recentviews
# Returns: table<date: string, recipeInfo: record<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>>
# operationId: Recipe_RecentViews
export def "recipe-recent-views" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pg: int # Page number starting with 1 (format: int32)
  --rpp: int # results per page (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/recentviews"
    query: [{name: pg, var: pg}, {name: rpp, var: rpp}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    pg: $pg, rpp: $rpp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search for recipes. There are many parameters that you can apply. Starting with the most common, use title_kw to search within a title. Use any_kw to search across the entire recipe. If you'd like to limit by course, set the parameter "include_primarycat" to one of (appetizers,bread,breakfast,dessert,drinks,maindish,salad,sidedish,soup,marinades,other). If you'd like to exclude a category, set exclude_cat to one or more (comma-separated) list of those categories to exclude. If you'd like to include a category, set include_cat to one or more (comma-separated) of those categories to include. To explicitly include an ingredient in your search, set the parameter "include_ing" to a CSV of up to three ingredients, e.g.:include_ing=mustard,chicken,beef%20tips To explicitly exclude an ingredient in your search, set the parameter "exclude_ing" to a CSV of up to three ingredients. All searches must contain the paging parameters pg and rpp, which are integers, and represent the page number (1-based) and results per page (rpp). So, to get the third page of a result set paged with 25 recipes per page, you'd pass pg=3&rpp=25 If you'd like to target searches to just a single target user's recipes, set userId=the target userId (number). Or, you can set username=theirusername vtn;vgn;chs;glf;ntf;dyf;sff;slf;tnf;wmf;rmf;cps cuisine photos filter=added,try,favorites,myrecipes\r\n\r\n folder=FolderNameCaseSensitive coll=ID of Collection
#
# GET /recipes/top25random
# Returns: record<ResultCount: int, Results: table<Category: string, CreationDate: string, Cuisine: string, HasVideos: bool, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, Microcategory: string, PhotoUrl: string, Poster: record, RecipeID: int, ReviewCount: int, Servings: float, StarRating: float, Subcategory: string, Title: string, TotalTries: int, WebURL: string>, SpellSuggest: string>
# operationId: Recipe_RecipeSearchRandom
export def "recipe-recipe-search-random" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --any-kw: string # Search anywhere in the recipe for the keyword
  --folder: string # Search in a specific folder name for the authenticated user
  --coll: int # Limit to a collection ID number (format: int32)
  --filter: string # optionally set to either "myrecipes", "try", "favorites","added" to filter to just the authenticated user's recipe set
  --title-kw: string # Search just in the recipe title for the keyword
  --user-id: int # Set the target userid to search their public recipes (format: int32)
  --username: string # Set the target username to search their public recipes
  --qp-token: string # (spec name: token)
  --photos: oneof<nothing, bool> # if set to true, limit search results to photos only
  --boostmine: oneof<nothing, bool> # if set to true, boost my own recipes in my folders so they show up high in the list (at the expense of other sort orders)
  --include-cat: string # integer of the subcategory you'd like to limit searches to (see the /recipe/categories endpoint for available id numbers). For instance, 58 is "Main Dish > Casseroles".
  --exclude-cat: string # like include_cat, set this to an integer to exclude a specific category
  --include-primarycat: string # csv indicating up to three top-level categories -- valid values are [appetizers,bread,breakfast,desserts,drinks,maindish,salads,sidedish,soups,marinades,other]
  --exclude-primarycat: string # csv indicating integer values for up to 3 top-level categories -- valid values are 1...11 [appetizers,bread,breakfast,desserts,drinks,maindish,salads,sidedish,soups,marinades,other]
  --include-ing: string # A CSV representing up to 3 ingredients to include, e.g., tomatoes,corn%20%starch,chicken
  --exclude-ing: string # A CSV representing up to 3 ingredients to exclude (Powersearch-capable plan required)
  --cuisine: string # Limit to a specific cuisine. Cooks can enter anything free-form, but the few dozen preconfigured values are Afghan,African,American,American-South,Asian,Australian,Brazilian,Cajun,Canadian,Caribbean,Chinese,Croatian,Cuban,Dessert,Eastern European,English,French,German,Greek,Hawaiian,Hungarian,India,Indian,Irish,Italian,Japanese,Jewish,Korean,Latin,Mediterranean,Mexican,Middle Eastern,Moroccan,Polish,Russian,Scandanavian,Seafood,Southern,Southwestern,Spanish,Tex-Mex,Thai,Vegan,Vegetarian,Vietnamese
  --db: string
  --userset: string # If set to a given username, it'll force the search to filter to just that username
  --servings-min: float # Limit to yield of a given number size or greater. Note that cooks usually enter recipes by Servings, but sometimes they are posted by "dozen", etc. This parameter simply specifies the minimum number for that value entered in "yield." (format: double)
  --total-mins: int # Optional. If supplied, will restrict results to recipes that can be made in {totalMins} or less. (Convert "1 hour, 15 minutes" to 75 before passing in.) (format: int32)
  --max-ingredients: int # Optional. If supplied, will restrict results to recipes that can be made with {maxIngredients} ingredients or less (format: int32)
  --min-ingredients: int # Optional. If supplied, will restrict results to recipes that have at least {minIngredients} (format: int32)
  --vtn: int # when set to 1, limit to vegetarian (Powersearch-capable plan required) (format: int32)
  --vgn: int # when set to 1, limit to vegan (Powersearch-capable plan required) (format: int32)
  --chs: int # when set to 1, limit to contains-cheese (Powersearch-capable plan required) (format: int32)
  --glf: int # when set to 1, limit to gluten-free (Powersearch-capable plan required) (format: int32)
  --ntf: int # when set to 1, limit to nut-free (Powersearch-capable plan required) (format: int32)
  --dyf: int # when set to 1, limit to dairy-free (Powersearch-capable plan required) (format: int32)
  --sff: int # when set to 1, limit to seafood-free (Powersearch-capable plan required) (format: int32)
  --slf: int # when set to 1, limit to shellfish-free (Powersearch-capable plan required) (format: int32)
  --tnf: int # when set to 1, limit to tree-nut free (Powersearch-capable plan required) (format: int32)
  --wmf: int # when set to 1, limit to white-meat free (Powersearch-capable plan required) (format: int32)
  --rmf: int # when set to 1, limit to red-meat free (Powersearch-capable plan required) (format: int32)
  --cps: int # when set to 1, recipe contains pasta, set to 0 means contains no pasta (Powersearch-capable plan required) (format: int32)
  --champion: int # optional. When set to 1, this will limit search results to "best of" recipes as determined by various internal editorial and programmatic algorithms. For the most comprehensive results, don't include this parameter. (format: int32)
  --synonyms: oneof<nothing, bool> # optional, default is false. When set to true, BigOven will attempt to apply synonyms in search (e.g., excluding pork will also exclude bacon)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/top25random"
    query: [{name: any_kw, var: any_kw}, {name: folder, var: folder}, {name: coll, var: coll}, {name: filter, var: filter}, {name: title_kw, var: title_kw}, {name: userId, var: user_id}, {name: username, var: username}, {name: token, var: qp_token}, {name: photos, var: photos}, {name: boostmine, var: boostmine}, {name: include_cat, var: include_cat}, {name: exclude_cat, var: exclude_cat}, {name: include_primarycat, var: include_primarycat}, {name: exclude_primarycat, var: exclude_primarycat}, {name: include_ing, var: include_ing}, {name: exclude_ing, var: exclude_ing}, {name: cuisine, var: cuisine}, {name: db, var: db}, {name: userset, var: userset}, {name: servingsMin, var: servings_min}, {name: totalMins, var: total_mins}, {name: maxIngredients, var: max_ingredients}, {name: minIngredients, var: min_ingredients}, {name: vtn, var: vtn}, {name: vgn, var: vgn}, {name: chs, var: chs}, {name: glf, var: glf}, {name: ntf, var: ntf}, {name: dyf, var: dyf}, {name: sff, var: sff}, {name: slf, var: slf}, {name: tnf, var: tnf}, {name: wmf, var: wmf}, {name: rmf, var: rmf}, {name: cps, var: cps}, {name: champion, var: champion}, {name: synonyms, var: synonyms}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    any_kw: $any_kw, folder: $folder, coll: $coll, filter: $filter, title_kw: $title_kw, user_id: $user_id, username: $username, qp_token: $qp_token, photos: $photos, boostmine: $boostmine, include_cat: $include_cat, exclude_cat: $exclude_cat, include_primarycat: $include_primarycat, exclude_primarycat: $exclude_primarycat, include_ing: $include_ing, exclude_ing: $exclude_ing, cuisine: $cuisine, db: $db, userset: $userset, servings_min: $servings_min, total_mins: $total_mins, max_ingredients: $max_ingredients, min_ingredients: $min_ingredients, vtn: $vtn, vgn: $vgn, chs: $chs, glf: $glf, ntf: $ntf, dyf: $dyf, sff: $sff, slf: $slf, tnf: $tnf, wmf: $wmf, rmf: $rmf, cps: $cps, champion: $champion, synonyms: $synonyms
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Same as GET recipe but also includes the recipe videos (if any)
#
# GET /recipes/{id}
# Returns: record<ActiveMinutes: int, AdTags: string, AdminBoost: int, AllCategoriesText: string, BookmarkImageURL: string, BookmarkSiteLogo: string, BookmarkURL: string, Category: string, Collection: string, CollectionID: int, CreationDate: string, Cuisine: string, Description: string, FavoriteCount: int, ImageSquares: list<int>, ImageURL: string, Ingredients: table<DisplayIndex: int, DisplayQuantity: string, HTMLName: string, IngredientID: int, IngredientInfo: record, IsHeading: bool, IsLinked: bool, MetricDisplayQuantity: string, MetricQuantity: float, MetricUnit: string, Name: string, PreparationNotes: string, Quantity: float, Unit: string>, IngredientsTextBlock: string, Instructions: string, IsBookmark: bool, IsPrivate: bool, IsRecipeScan: bool, IsSponsored: bool, LastModified: string, MaxImageSquare: int, MedalCount: int, MenuCount: int, Microcategory: string, NotesCount: int, NutritionInfo: record<CaloriesFromFat: float, Cholesterol: float, CholesterolPct: float, DietaryFiber: float, DietaryFiberPct: float, MonoFat: float, PolyFat: float, Potassium: float, PotassiumPct: float, Protein: float, ProteinPct: float, SatFat: float, SatFatPct: float, SingularYieldUnit: string, Sodium: float, SodiumPct: float, Sugar: float, TotalCalories: float, TotalCarbs: float, TotalCarbsPct: float, TotalFat: float, TotalFatPct: float, TransFat: float>, PhotoUrl: string, Poster: record<FirstName: string, ImageUrl48: string, IsKitchenHelper: bool, IsPremium: bool, IsUsingRecurly: bool, LastName: string, MemberSince: string, PhotoUrl: string, PhotoUrl48: string, PremiumExpiryDate: string, UserID: int, UserName: string, WebUrl: string>, PrimaryIngredient: string, RecipeID: int, ReviewCount: int, StarRating: float, Steps: table<EndGantt: int, StartGantt: int, Text: string>, Subcategory: string, Title: string, TotalMinutes: int, VariantOfRecipeID: int, VerifiedByClass: string, VerifiedDateTime: string, Videos: table<InsertedOn: string, IsPrimaryVideo: bool, MediaId: string, VidId: int>, WebURL: string, YieldNumber: float, YieldUnit: string>
# operationId: Recipe_GetV2
export def "recipe-get-v2" [
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
  --accept: string@accept-completer # Response content type
  --prefetch: oneof<nothing, bool> # The prefetch.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/recipes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: prefetch, var: prefetch}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: x-bigoven-api-key
  } {
    id: $id, prefetch: $prefetch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
