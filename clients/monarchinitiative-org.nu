# Auto-generated client for BioLink API v1.1.14
# Source: https://api.apis.guru/v2/specs/monarchinitiative.org/1.1.14/openapi.json
# Auth: --token flag or $env.BIOLINK_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/api"
  token_env_var: "BIOLINK_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def association-type-completer [] { ["both" "causal" "non_causal"] }
def relationship-type-completer [] { ["acts_upstream_of_or_within" "involved_in" "involved_in_regulation_of"] }
def homology-type-completer [] { ["LDO" "O" "P"] }
def type-completer [] { ["anatomy" "case" "disease" "gene" "genotype" "goterm" "individual" "model" "pathway" "phenotype" "publication" "substance" "variant"] }
def relationship-type-completer-1 [] { ["acts_upstream_of_or_within" "involved_in"] }
def direction-completer [] { ["BOTH" "INCOMING" "OUTGOING"] }
def graph-completer [] { ["data" "ontology"] }
def graph-type-completer [] { ["neighborhood_graph" "neighborhood_limited_graph" "regulates_transitivity_graph" "topology_graph"] }
def metric-completer [] { ["jaccard" "phenodigm" "resnik" "simGIC" "symmetric_resnik"] }
def per-page-completer [] { ["10" "2" "20" "30" "40" "50"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-associations-between: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-association-by-subject-category-search: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-association-by-subject-and-object-category-search: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-associations-from: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-associations-to: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-association-by-subject-and-assoc-type: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-association-object: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-anatomy-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-case-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-case-genotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-case-model-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-case-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-case-variant-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-case-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-genotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-model-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-model-taxon-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-pathway-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string, frequency: record, onset: record>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-publication-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-disease-variant-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-function-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-anatomy-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-case-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-expression-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-function-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-genotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-homolog-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-interactions: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-model-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-ortholog-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-ortholog-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-pathway-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-publication-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-gene-variant-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-genotype-case-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-genotype-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-genotype-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-genotype-genotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-genotype-model-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-genotype-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-genotype-publication-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-genotype-variant-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-goterm-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-model-case-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-model-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-model-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-model-genotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-model-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-model-publication-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-model-variant-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-pathway-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-pathway-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-pathway-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-phenotype-anatomy-associations: "table<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: list<record>, types: list<string>>"
    get-phenotype-case-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-phenotype-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string, frequency: record, onset: record>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-phenotype-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-phenotype-genotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-phenotype-pathway-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-phenotype-publication-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-phenotype-variant-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-publication-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-publication-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-publication-genotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-publication-model-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-publication-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-publication-variant-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-substance-participant-in-associations: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-substance-role-associations: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-variant-case-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-variant-disease-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-variant-gene-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-variant-genotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-variant-model-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-variant-phenotype-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-variant-publication-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-generic-object: "record<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: table<pred: string, val: string, xrefs: list>, types: list<string>, association_counts: record, taxon: record<id: string, label: string>, xrefs: list<string>>"
    get-generic-associations: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>"
    get-entity-set-associations: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-entity-set-homologs: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-instance-object: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-evidence-graph-object: "table<edges: list<record>, nodes: list<record>>"
    get-evidence-graph-table: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-features-within-resource: "table<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: list<record>, types: list<string>, association_counts: record, taxon: record<id: string, label: string>, xrefs: list<string>, homology_associations: list<record>, locations: list<record>, seq: record<category: list, id: string, iri: string, label: string, consider: list, deprecated: bool, description: string, replaced_by: list, synonyms: list, types: list, association_counts: record, taxon: record, xrefs: list, alphabet: string, md5checksum: string, residues: string, seqlen: string>>"
    get-edge-resource: "table<edges: list<record>, nodes: list<record>>"
    get-node-resource: "table<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: list<record>, types: list<string>, association_counts: record, taxon: record<id: string, label: string>, xrefs: list<string>>"
    get-identifier-mapper: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-pedigree: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-individual: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-annotate-entities: "record<content: string, spans: table<end: int, start: int, text: string, token: list>>"
    post-annotate-entities: "record<content: string, spans: table<end: int, start: int, text: string, token: list>>"
    get-dl-query: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-sparql-query: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-relation-usage-resource: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-relation-usage-between-resource: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-relation-usage-pivot-resource: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-relation-usage-pivot-label-resource: "table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>"
    get-autocomplete: "record<docs: table<category: list, equivalent_ids: list, has_highlight: bool, highlight: string, id: string, label: list, match: string, taxon: string, taxon_label: string>>"
    get-search-hpo-entities: "record<results: table<highlight: string, id: string, label: string, matched_synonym: string>>"
    get-search-entities: "record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int>"
    get-sim-compare: "record<matches: table<id: string, label: string, taxon: record, type: string, pairwise_match: list, rank: string, score: float, significance: string>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record<id: string, label: string, taxon: record, type: string>, target_ids: list<list>, unresolved_ids: list<string>>>"
    post-sim-compare: "record<matches: table<id: string, label: string, taxon: record, type: string, pairwise_match: list, rank: string, score: float, significance: string>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record<id: string, label: string, taxon: record, type: string>, target_ids: list<list>, unresolved_ids: list<string>>>"
    get-annotation-score: "record<categorical_score: float, scaled_score: float, simple_score: float>"
    post-annotation-score: "record<categorical_score: float, scaled_score: float, simple_score: float>"
    get-sim-search: "record<matches: table<id: string, label: string, taxon: record, type: string, pairwise_match: list, rank: string, score: float, significance: string>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record<id: string, label: string, taxon: record, type: string>, target_ids: list<list>, unresolved_ids: list<string>>>"
    get-variant-sets-collection: "record<page: int, pages: int, per_page: int, total: int, items: table<body: string, category: string, category_id: int, id: int, pub_date: string, title: string>>"
    get-variant-analyze: "table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>"
    get-variant-sets-archive-collection: "record<page: int, pages: int, per_page: int, total: int, items: table<body: string, category: string, category_id: int, id: int, pub_date: string, title: string>>"
    get-variant-set-item: "record<body: string, category: string, category_id: int, id: int, pub_date: string, title: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-associations-between" "get-association-by-subject-category-search" "get-association-by-subject-and-object-category-search" "get-associations-from" "get-associations-to" "get-association-by-subject-and-assoc-type" "get-association-object" "get-anatomy-gene-associations" "get-anatomy-gene-by-taxon-associations" "get-case-disease-associations" "get-case-genotype-associations" "get-case-model-associations" "get-case-phenotype-associations" "get-case-variant-associations" "get-disease-case-associations" "get-disease-gene-associations" "get-disease-genotype-associations" "get-disease-model-associations" "get-disease-model-taxon-associations" "get-disease-pathway-associations" "get-disease-phenotype-associations" "get-disease-publication-associations" "get-disease-substance-associations" "get-disease-variant-associations" "get-function-associations" "get-function-gene-associations" "get-function-publication-associations" "get-function-taxon-associations" "get-gene-anatomy-associations" "get-gene-case-associations" "get-gene-disease-associations" "get-gene-expression-associations" "get-gene-function-associations" "get-gene-genotype-associations" "get-gene-homolog-associations" "get-gene-interactions" "get-gene-model-associations" "get-gene-ortholog-disease-associations" "get-gene-ortholog-phenotype-associations" "get-gene-pathway-associations" "get-gene-phenotype-associations" "get-gene-publication-associations" "get-gene-variant-associations" "get-genotype-case-associations" "get-genotype-disease-associations" "get-genotype-gene-associations" "get-genotype-genotype-associations" "get-genotype-model-associations" "get-genotype-phenotype-associations" "get-genotype-publication-associations" "get-genotype-variant-associations" "get-goterm-gene-associations" "get-model-case-associations" "get-model-disease-associations" "get-model-gene-associations" "get-model-genotype-associations" "get-model-phenotype-associations" "get-model-publication-associations" "get-model-variant-associations" "get-pathway-disease-associations" "get-pathway-gene-associations" "get-pathway-phenotype-associations" "get-phenotype-anatomy-associations" "get-phenotype-case-associations" "get-phenotype-disease-associations" "get-phenotype-gene-by-taxon-associations" "get-phenotype-gene-associations" "get-phenotype-genotype-associations" "get-phenotype-pathway-associations" "get-phenotype-publication-associations" "get-phenotype-variant-associations" "get-publication-disease-associations" "get-publication-gene-associations" "get-publication-genotype-associations" "get-publication-model-associations" "get-publication-phenotype-associations" "get-publication-variant-associations" "get-substance-participant-in-associations" "get-substance-role-associations" "get-substance-treats-associations" "get-variant-case-associations" "get-variant-disease-associations" "get-variant-gene-associations" "get-variant-genotype-associations" "get-variant-model-associations" "get-variant-phenotype-associations" "get-variant-publication-associations" "get-generic-object" "get-generic-associations" "get-generic-object-by-type" "get-entity-set-associations" "get-entity-set-summary" "get-entity-set-graph-resource" "get-entity-set-homologs" "get-over-representation" "get-entity-set-anatomy-slimmer" "get-entity-set-function-slimmer" "get-entity-set-phenotype-slimmer" "get-activity-collection" "get-instance-object" "get-model-instances" "get-model-collection" "get-model-contributors" "get-model-properties" "get-model-property-values" "get-model-query" "get-model-object" "get-physical-interaction" "get-evidence-graph-object" "get-evidence-graph-table" "get-features-within-resource" "get-edge-resource" "get-node-resource" "get-identifier-mapper" "get-prefix-collection" "get-prefix-contract" "get-prefix-expand" "get-pedigree" "get-individual" "get-mart-case-associations-resource" "get-mart-disease-associations-resource" "get-mart-gene-associations-resource" "get-mart-ortholog-associations-resource" "get-mart-paralog-associations-resource" "get-metadata-for-datasets" "post-disease-mme" "post-fly-mme" "post-mouse-mme" "post-nematode-mme" "post-zebrafish-mme" "get-annotate" "post-annotate" "get-annotate-entities" "post-annotate-entities" "get-ontol-identifier-resource" "post-ontol-identifier-resource" "get-information-content-resource" "get-ontol-labeler-resource" "get-extract-ontology-subgraph-resource" "post-extract-ontology-subgraph-resource" "get-ontology-terms-shared-ancestor" "get-ontology-subset" "get-ontology-term" "get-ontology-term-graph" "get-ontology-term-subgraph" "get-ontology-term-subsets" "get-dl-query" "get-sparql-query" "get-pair-sim-jaccard-resource" "get-relation-usage-resource" "get-relation-usage-between-resource" "get-relation-usage-pivot-resource" "get-relation-usage-pivot-label-resource" "get-autocomplete" "get-search-hpo-entities" "get-search-entities" "get-sim-compare" "post-sim-compare" "get-annotation-score" "post-annotation-score" "get-sim-search" "get-variant-sets-collection" "post-variant-sets-collection" "get-variant-analyze" "get-variant-sets-archive-collection" "delete-variant-set-item" "get-variant-set-item" "put-variant-set-item" "commands"] | sort) } | get name | first)
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

# Returns associations connecting two entities
#
# GET /association/between/{subject}/{object}
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_associations_between
export def "get-associations-between" [
  subject: string
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/association/between/{subject}/{object}"
    path_params: [{name: subject, var: subject}, {name: object, var: object}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: evidence, var: evidence}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: use_compact_associations, var: use_compact_associations}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject, object: $object, rows: $rows, start: $start, evidence: $evidence, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, use_compact_associations: $use_compact_associations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matching associations for a given subject category
#
# GET /association/find/{subject_category}
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_association_by_subject_category_search
export def "get-association-by-subject-category-search" [
  subject_category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --subject-taxon: string # Subject taxon ID, e.g. NCBITaxon:9606 (Includes inferred associations, by default)
  --object-taxon: string # Object taxon ID, e.g. NCBITaxon:10090 (Includes inferred associations, by default)
  --relation: string # Filter by relation CURIE, e.g. RO:0002200 (has_phenotype), RO:0002607 (is marker for), RO:HOM0000017 (orthologous to), etc.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/association/find/{subject_category}"
    path_params: [{name: subject_category, var: subject_category}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: evidence, var: evidence}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: use_compact_associations, var: use_compact_associations}, {name: subject_taxon, var: subject_taxon}, {name: object_taxon, var: object_taxon}, {name: relation, var: relation}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject_category: $subject_category, rows: $rows, start: $start, evidence: $evidence, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, use_compact_associations: $use_compact_associations, subject_taxon: $subject_taxon, object_taxon: $object_taxon, relation: $relation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matching associations between a given subject and object category
#
# GET /association/find/{subject_category}/{object_category}
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_association_by_subject_and_object_category_search
export def "get-association-by-subject-and-object-category-search" [
  subject_category: string
  object_category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --subject: string # Subject CURIE
  --object: string # Object CURIE
  --subject-taxon: string # Subject taxon ID, e.g. NCBITaxon:9606 (Includes inferred associations, by default)
  --object-taxon: string # Object taxon ID, e.g. NCBITaxon:10090 (Includes inferred associations, by default)
  --relation: string # Filter by relation CURIE, e.g. RO:0002200 (has_phenotype), RO:0002607 (is marker for), RO:HOM0000017 (orthologous to), etc.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/association/find/{subject_category}/{object_category}"
    path_params: [{name: subject_category, var: subject_category}, {name: object_category, var: object_category}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: evidence, var: evidence}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: use_compact_associations, var: use_compact_associations}, {name: subject, var: subject}, {name: object, var: object}, {name: subject_taxon, var: subject_taxon}, {name: object_taxon, var: object_taxon}, {name: relation, var: relation}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject_category: $subject_category, object_category: $object_category, rows: $rows, start: $start, evidence: $evidence, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, use_compact_associations: $use_compact_associations, subject: $subject, object: $object, subject_taxon: $subject_taxon, object_taxon: $object_taxon, relation: $relation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matching associations starting from a given subject (source)
#
# GET /association/from/{subject}
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_associations_from
export def "get-associations-from" [
  subject: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --object-taxon: string # Object taxon ID, e.g. NCBITaxon:10090 (Includes inferred associations, by default)
  --relation: string # Filter by relation CURIE, e.g. RO:0002200 (has_phenotype), RO:0002607 (is marker for), RO:HOM0000017 (orthologous to), etc.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/association/from/{subject}"
    path_params: [{name: subject, var: subject}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: evidence, var: evidence}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: use_compact_associations, var: use_compact_associations}, {name: object_taxon, var: object_taxon}, {name: relation, var: relation}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject, rows: $rows, start: $start, evidence: $evidence, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, use_compact_associations: $use_compact_associations, object_taxon: $object_taxon, relation: $relation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matching associations pointing to a given object (target)
#
# GET /association/to/{object}
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_associations_to
export def "get-associations-to" [
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/association/to/{object}"
    path_params: [{name: object, var: object}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: evidence, var: evidence}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: use_compact_associations, var: use_compact_associations}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object: $object, rows: $rows, start: $start, evidence: $evidence, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, use_compact_associations: $use_compact_associations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matching associations of a given type
#
# GET /association/type/{association_type}
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_association_by_subject_and_assoc_type
export def "get-association-by-subject-and-assoc-type" [
  association_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --subject: string # Subject CURIE
  --object: string # Object CURIE
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/association/type/{association_type}"
    path_params: [{name: association_type, var: association_type}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: evidence, var: evidence}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: use_compact_associations, var: use_compact_associations}, {name: subject, var: subject}, {name: object, var: object}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    association_type: $association_type, rows: $rows, start: $start, evidence: $evidence, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, use_compact_associations: $use_compact_associations, subject: $subject, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the association with a given identifier
#
# GET /association/{id}
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_association_object
export def "get-association-object" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/association/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated with a given anatomy
#
# GET /bioentity/anatomy/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_anatomy_gene_associations
export def "get-anatomy-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/anatomy/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns gene IDs for all genes associated with a given anatomy, filtered by taxon
#
# GET /bioentity/anatomy/{id}/genes/{taxid}
# DEPRECATED
# operationId: get_anatomy_gene_by_taxon_associations
@deprecated
export def "get-anatomy-gene-by-taxon-associations" [
  id: string
  taxid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentity/anatomy/{id}/genes/{taxid}"
    path_params: [{name: id, var: id}, {name: taxid, var: taxid}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, taxid: $taxid, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns diseases associated with a case
#
# GET /bioentity/case/{id}/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_case_disease_associations
export def "get-case-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/case/{id}/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes associated with a case
#
# GET /bioentity/case/{id}/genotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_case_genotype_associations
export def "get-case-genotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/case/{id}/genotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns models associated with a case
#
# GET /bioentity/case/{id}/models
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_case_model_associations
export def "get-case-model-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/case/{id}/models"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phenotypes associated with a case
#
# GET /bioentity/case/{id}/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_case_phenotype_associations
export def "get-case-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/case/{id}/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns variants associated with a case
#
# GET /bioentity/case/{id}/variants
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_case_variant_associations
export def "get-case-variant-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/case/{id}/variants"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns cases associated with a disease
#
# GET /bioentity/disease/{id}/cases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_case_associations
export def "get-disease-case-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/cases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated with a disease
#
# GET /bioentity/disease/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_gene_associations
export def "get-disease-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
  --association-type: string@association-type-completer # Additional filters: causal, non_causal, both (default: both)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}, {name: association_type, var: association_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q, association_type: $association_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes associated with a disease
#
# GET /bioentity/disease/{id}/genotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_genotype_associations
export def "get-disease-genotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/genotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns associations to models of the disease
#
# GET /bioentity/disease/{id}/models
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_model_associations
export def "get-disease-model-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/models"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns associations to models of the disease constrained by taxon
#
# GET /bioentity/disease/{id}/models/{taxon}
# DEPRECATED
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_model_taxon_associations
@deprecated
export def "get-disease-model-taxon-associations" [
  id: string
  taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/models/{taxon}"
    path_params: [{name: id, var: id}, {name: taxon, var: taxon}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, taxon: $taxon, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns pathways associated with a disease
#
# GET /bioentity/disease/{id}/pathways
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_pathway_associations
export def "get-disease-pathway-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/pathways"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phenotypes associated with disease
#
# GET /bioentity/disease/{id}/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string, frequency: record, onset: record>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_phenotype_associations
export def "get-disease-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns publications associated with a disease
#
# GET /bioentity/disease/{id}/publications
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_publication_associations
export def "get-disease-publication-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/publications"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns substances associated with a disease
#
# GET /bioentity/disease/{id}/treatment
# operationId: get_disease_substance_associations
export def "get-disease-substance-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/treatment"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns variants associated with a disease
#
# GET /bioentity/disease/{id}/variants
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_disease_variant_associations
export def "get-disease-variant-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/disease/{id}/variants"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns annotations associated to a function term
#
# GET /bioentity/function/{id}
# operationId: get_function_associations
export def "get-function-associations" [
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
  --start: int # beginning row (default: 0)
  --rows: int # number of rows (default: 100)
  --evidence: list<string> # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentity/function/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: start, var: start}, {name: rows, var: rows}, {name: evidence, var: evidence, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start: $start, rows: $rows, evidence: $evidence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated to a GO term
#
# GET /bioentity/function/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_function_gene_associations
export def "get-function-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
  --relationship-type: string@relationship-type-completer # relationship type ('involved_in', 'involved_in_regulation_of' or 'acts_upstream_of_or_within') (default: involved_in)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/function/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}, {name: relationship_type, var: relationship_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q, relationship_type: $relationship_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns publications associated to a GO term
#
# GET /bioentity/function/{id}/publications
# operationId: get_function_publication_associations
export def "get-function-publication-associations" [
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
  --start: int # beginning row (default: 0)
  --rows: int # number of rows (default: 100)
  --evidence: list<string> # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentity/function/{id}/publications"
    path_params: [{name: id, var: id}]
    query: [{name: start, var: start}, {name: rows, var: rows}, {name: evidence, var: evidence, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start: $start, rows: $rows, evidence: $evidence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns taxons associated to a GO term
#
# GET /bioentity/function/{id}/taxons
# operationId: get_function_taxon_associations
export def "get-function-taxon-associations" [
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
  --start: int # beginning row (default: 0)
  --rows: int # number of rows (default: 100)
  --evidence: list<string> # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentity/function/{id}/taxons"
    path_params: [{name: id, var: id}]
    query: [{name: start, var: start}, {name: rows, var: rows}, {name: evidence, var: evidence, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, start: $start, rows: $rows, evidence: $evidence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns anatomical entities associated with a gene
#
# GET /bioentity/gene/{id}/anatomy
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_anatomy_associations
export def "get-gene-anatomy-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/anatomy"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns cases associated with a gene
#
# GET /bioentity/gene/{id}/cases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_case_associations
export def "get-gene-case-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/cases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns diseases associated with gene
#
# GET /bioentity/gene/{id}/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_disease_associations
export def "get-gene-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
  --association-type: string@association-type-completer # Additional filters: causal, non_causal, both (default: both)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}, {name: association_type, var: association_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q, association_type: $association_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns expression events for a gene
#
# GET /bioentity/gene/{id}/expression/anatomy
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_expression_associations
export def "get-gene-expression-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/expression/anatomy"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns function associations for a gene
#
# GET /bioentity/gene/{id}/function
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_function_associations
export def "get-gene-function-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/function"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes associated with a gene
#
# GET /bioentity/gene/{id}/genotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_genotype_associations
export def "get-gene-genotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/genotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns homologs for a gene
#
# GET /bioentity/gene/{id}/homologs
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_homolog_associations
export def "get-gene-homolog-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # Taxon CURIE of homolog, e.g. NCBITaxon:9606 (Can be an ancestral node in the ontology; includes inferred associations by default)
  --homology-type: string@homology-type-completer # P (paralog), O (Ortholog) or LDO (least-diverged ortholog)
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/homologs"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: homology_type, var: homology_type}, {name: direct_taxon, var: direct_taxon}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, homology_type: $homology_type, direct_taxon: $direct_taxon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns interactions for a gene
#
# GET /bioentity/gene/{id}/interactions
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_interactions
export def "get-gene-interactions" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/interactions"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns models associated with a gene
#
# GET /bioentity/gene/{id}/models
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_model_associations
export def "get-gene-model-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/models"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return diseases associated with orthologs of a gene
#
# GET /bioentity/gene/{id}/ortholog/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_ortholog_disease_associations
export def "get-gene-ortholog-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/ortholog/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return phenotypes associated with orthologs for a gene
#
# GET /bioentity/gene/{id}/ortholog/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_ortholog_phenotype_associations
export def "get-gene-ortholog-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/ortholog/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns pathways associated with gene
#
# GET /bioentity/gene/{id}/pathways
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_pathway_associations
export def "get-gene-pathway-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/pathways"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phenotypes associated with gene
#
# GET /bioentity/gene/{id}/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_phenotype_associations
export def "get-gene-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns publications associated with a gene
#
# GET /bioentity/gene/{id}/publications
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_publication_associations
export def "get-gene-publication-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/publications"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns variants associated with a gene
#
# GET /bioentity/gene/{id}/variants
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_gene_variant_associations
export def "get-gene-variant-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/gene/{id}/variants"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns cases associated with a genotype
#
# GET /bioentity/genotype/{id}/cases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_genotype_case_associations
export def "get-genotype-case-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/genotype/{id}/cases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns diseases associated with a genotype
#
# GET /bioentity/genotype/{id}/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_genotype_disease_associations
export def "get-genotype-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/genotype/{id}/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated with a genotype
#
# GET /bioentity/genotype/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_genotype_gene_associations
export def "get-genotype-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/genotype/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes-genotype associations
#
# GET /bioentity/genotype/{id}/genotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_genotype_genotype_associations
export def "get-genotype-genotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/genotype/{id}/genotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns models associated with a genotype
#
# GET /bioentity/genotype/{id}/models
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_genotype_model_associations
export def "get-genotype-model-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/genotype/{id}/models"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phenotypes associated with a genotype
#
# GET /bioentity/genotype/{id}/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_genotype_phenotype_associations
export def "get-genotype-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/genotype/{id}/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns publications associated with a genotype
#
# GET /bioentity/genotype/{id}/publications
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_genotype_publication_associations
export def "get-genotype-publication-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/genotype/{id}/publications"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes-variant associations
#
# GET /bioentity/genotype/{id}/variants
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_genotype_variant_associations
export def "get-genotype-variant-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/genotype/{id}/variants"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns associations to GO terms for a gene
#
# GET /bioentity/goterm/{id}/genes
# DEPRECATED
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_goterm_gene_associations
@deprecated
export def "get-goterm-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --relationship-type: string@relationship-type-completer # relationship type ('involved_in', 'involved_in_regulation_of' or 'acts_upstream_of_or_within') (default: involved_in)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/goterm/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: relationship_type, var: relationship_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, relationship_type: $relationship_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns cases associated with a model
#
# GET /bioentity/model/{id}/cases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_model_case_associations
export def "get-model-case-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/model/{id}/cases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns diseases associated with a model
#
# GET /bioentity/model/{id}/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_model_disease_associations
export def "get-model-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/model/{id}/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated with a model
#
# GET /bioentity/model/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_model_gene_associations
export def "get-model-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/model/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes associated with a model
#
# GET /bioentity/model/{id}/genotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_model_genotype_associations
export def "get-model-genotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/model/{id}/genotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phenotypes associated with a model
#
# GET /bioentity/model/{id}/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_model_phenotype_associations
export def "get-model-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/model/{id}/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns publications associated with a model
#
# GET /bioentity/model/{id}/publications
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_model_publication_associations
export def "get-model-publication-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/model/{id}/publications"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns variants associated with a model
#
# GET /bioentity/model/{id}/variants
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_model_variant_associations
export def "get-model-variant-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/model/{id}/variants"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns diseases associated with a pathway
#
# GET /bioentity/pathway/{id}/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_pathway_disease_associations
export def "get-pathway-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/pathway/{id}/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated with a pathway
#
# GET /bioentity/pathway/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_pathway_gene_associations
export def "get-pathway-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/pathway/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phenotypes associated with a pathway
#
# GET /bioentity/pathway/{id}/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_pathway_phenotype_associations
export def "get-pathway-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/pathway/{id}/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns anatomical entities associated with a phenotype
#
# GET /bioentity/phenotype/{id}/anatomy
# Returns: table<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: list<record>, types: list<string>>
# operationId: get_phenotype_anatomy_associations
export def "get-phenotype-anatomy-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/anatomy"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns cases associated with a phenotype
#
# GET /bioentity/phenotype/{id}/cases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_phenotype_case_associations
export def "get-phenotype-case-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/cases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns diseases associated with a phenotype
#
# GET /bioentity/phenotype/{id}/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string, frequency: record, onset: record>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_phenotype_disease_associations
export def "get-phenotype-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns gene IDs for all genes associated with a given phenotype, filtered by taxon
#
# GET /bioentity/phenotype/{id}/gene/{taxid}/ids
# DEPRECATED
# operationId: get_phenotype_gene_by_taxon_associations
@deprecated
export def "get-phenotype-gene-by-taxon-associations" [
  id: string
  taxid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/gene/{taxid}/ids"
    path_params: [{name: id, var: id}, {name: taxid, var: taxid}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, taxid: $taxid, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated with a phenotype
#
# GET /bioentity/phenotype/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_phenotype_gene_associations
export def "get-phenotype-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes associated with a phenotype
#
# GET /bioentity/phenotype/{id}/genotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_phenotype_genotype_associations
export def "get-phenotype-genotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/genotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns pathways associated with a phenotype
#
# GET /bioentity/phenotype/{id}/pathways
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_phenotype_pathway_associations
export def "get-phenotype-pathway-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/pathways"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns publications associated with a phenotype
#
# GET /bioentity/phenotype/{id}/publications
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_phenotype_publication_associations
export def "get-phenotype-publication-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/publications"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns variants associated with a phenotype
#
# GET /bioentity/phenotype/{id}/variants
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_phenotype_variant_associations
export def "get-phenotype-variant-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/phenotype/{id}/variants"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns diseases associated with a publication
#
# GET /bioentity/publication/{id}/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_publication_disease_associations
export def "get-publication-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/publication/{id}/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated with a publication
#
# GET /bioentity/publication/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_publication_gene_associations
export def "get-publication-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/publication/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes associated with a publication
#
# GET /bioentity/publication/{id}/genotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_publication_genotype_associations
export def "get-publication-genotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/publication/{id}/genotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns models associated with a publication
#
# GET /bioentity/publication/{id}/models
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_publication_model_associations
export def "get-publication-model-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/publication/{id}/models"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phenotypes associated with a publication
#
# GET /bioentity/publication/{id}/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_publication_phenotype_associations
export def "get-publication-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/publication/{id}/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns variants associated with a publication
#
# GET /bioentity/publication/{id}/variants
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_publication_variant_associations
export def "get-publication-variant-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/publication/{id}/variants"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns associations between an activity and process and the specified substance
#
# GET /bioentity/substance/{id}/participant_in
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_substance_participant_in_associations
export def "get-substance-participant-in-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/substance/{id}/participant_in"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns associations between given drug and roles
#
# GET /bioentity/substance/{id}/roles
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_substance_role_associations
export def "get-substance-role-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/substance/{id}/roles"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns substances associated with a disease
#
# GET /bioentity/substance/{id}/treats
# operationId: get_substance_treats_associations
export def "get-substance-treats-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentity/substance/{id}/treats"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns cases associated with a variant
#
# GET /bioentity/variant/{id}/cases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_variant_case_associations
export def "get-variant-case-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/variant/{id}/cases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns diseases associated with a variant
#
# GET /bioentity/variant/{id}/diseases
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_variant_disease_associations
export def "get-variant-disease-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/variant/{id}/diseases"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genes associated with a variant
#
# GET /bioentity/variant/{id}/genes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_variant_gene_associations
export def "get-variant-gene-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/variant/{id}/genes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns genotypes associated with a variant
#
# GET /bioentity/variant/{id}/genotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_variant_genotype_associations
export def "get-variant-genotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/variant/{id}/genotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns models associated with a variant
#
# GET /bioentity/variant/{id}/models
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_variant_model_associations
export def "get-variant-model-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/variant/{id}/models"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns phenotypes associated with a variant
#
# GET /bioentity/variant/{id}/phenotypes
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_variant_phenotype_associations
export def "get-variant-phenotype-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/variant/{id}/phenotypes"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns publications associated with a variant
#
# GET /bioentity/variant/{id}/publications
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_variant_publication_associations
export def "get-variant-publication-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/variant/{id}/publications"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns basic info on object of any type
#
# GET /bioentity/{id}
# Returns: record<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: table<pred: string, val: string, xrefs: list>, types: list<string>, association_counts: record, taxon: record<id: string, label: string>, xrefs: list<string>>
# operationId: get_generic_object
export def "get-generic-object" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns associations for an entity regardless of the type
#
# GET /bioentity/{id}/associations
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: table<evidence_graph: record, evidence_types: list, id: string, negated: bool, object: record, object_eq: list, object_extensions: list, provided_by: list, publications: list, qualifiers: list, relation: record, slim: list, subject: record, subject_eq: list, subject_extensions: list, type: string>, compact_associations: table<objects: list, relation: string, subject: string>, objects: list<string>>
# operationId: get_generic_associations
export def "get-generic-associations" [
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --taxon: list<string> # One or more taxon CURIE to filter associations by subject taxon; includes inferred associations by default
  --direct-taxon: oneof<nothing, bool> # Set true to exclude inferred taxa (default: false)
  --relation: string # A relation CURIE to filter associations
  --sort: string # Sorting responses <desc,asc>
  --q: string # Query string to filter documents
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/bioentity/{id}/associations"
    path_params: [{name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: taxon, var: taxon, style: multi}, {name: direct_taxon, var: direct_taxon}, {name: relation, var: relation}, {name: sort, var: sort}, {name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, taxon: $taxon, direct_taxon: $direct_taxon, relation: $relation, sort: $sort, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return basic info on an object for a given type
#
# GET /bioentity/{type}/{id}
# operationId: get_generic_object_by_type
export def "get-generic-object-by-type" [
  type: string@type-completer
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
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
  --facet: oneof<nothing, bool> # Enable faceting (default: false)
  --facet-fields: list<string> # Fields to facet on
  --unselect-evidence: oneof<nothing, bool> # If true, excludes evidence objects in response (default: false)
  --exclude-automatic-assertions: oneof<nothing, bool> # If true, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --fetch-objects: oneof<nothing, bool> # If true, returns a distinct set of association.objects (typically ontology terms). This appears at the top level of the results payload (default: false)
  --use-compact-associations: oneof<nothing, bool> # If true, returns results in compact associations format (default: false)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting object, e.g. ZFIN:ZDB-PUB-060503-2
  --direct: oneof<nothing, bool> # Set true to only include direct associations, and false to include inferred (via subclass or subclass|part of), default=False (default: false)
  --get-association-counts: oneof<nothing, bool> # Get association counts (default: false)
  --distinct-counts: oneof<nothing, bool> # Get distinct counts for associations (to be used in conjunction with 'get_association_counts' parameter) (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentity/{type}/{id}"
    path_params: [{name: type, var: type}, {name: id, var: id}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: facet, var: facet}, {name: facet_fields, var: facet_fields, style: multi}, {name: unselect_evidence, var: unselect_evidence}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: fetch_objects, var: fetch_objects}, {name: use_compact_associations, var: use_compact_associations}, {name: slim, var: slim, style: multi}, {name: evidence, var: evidence}, {name: direct, var: direct}, {name: get_association_counts, var: get_association_counts}, {name: distinct_counts, var: distinct_counts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    type: $type, id: $id, rows: $rows, start: $start, facet: $facet, facet_fields: $facet_fields, unselect_evidence: $unselect_evidence, exclude_automatic_assertions: $exclude_automatic_assertions, fetch_objects: $fetch_objects, use_compact_associations: $use_compact_associations, slim: $slim, evidence: $evidence, direct: $direct, get_association_counts: $get_association_counts, distinct_counts: $distinct_counts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns compact associations for a given input set
#
# GET /bioentityset/associations
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_entity_set_associations
export def "get-entity-set-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --background: list<string> # Entity ids in background set, e.g. NCBIGene:84570, NCBIGene:3630; used in over-representation tests
  --object-category: string # E.g. phenotype, function
  --object-slim: string # Slim or subset to which the descriptors are to be mapped, NOT IMPLEMENTED
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bioentityset/associations"
    query: [{name: subject, var: subject, style: multi}, {name: background, var: background, style: multi}, {name: object_category, var: object_category}, {name: object_slim, var: object_slim}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject, background: $background, object_category: $object_category, object_slim: $object_slim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Summary statistics for objects associated
#
# GET /bioentityset/descriptor/counts
# operationId: get_entity_set_summary
export def "get-entity-set-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --background: list<string> # Entity ids in background set, e.g. NCBIGene:84570, NCBIGene:3630; used in over-representation tests
  --object-category: string # E.g. phenotype, function
  --object-slim: string # Slim or subset to which the descriptors are to be mapped, NOT IMPLEMENTED
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentityset/descriptor/counts"
    query: [{name: subject, var: subject, style: multi}, {name: background, var: background, style: multi}, {name: object_category, var: object_category}, {name: object_slim, var: object_slim}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject, background: $background, object_category: $object_category, object_slim: $object_slim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# TODO Graph object spanning all entities
#
# GET /bioentityset/graph
# operationId: get_entity_set_graph_resource
export def "get-entity-set-graph-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --background: list<string> # Entity ids in background set, e.g. NCBIGene:84570, NCBIGene:3630; used in over-representation tests
  --object-category: string # E.g. phenotype, function
  --object-slim: string # Slim or subset to which the descriptors are to be mapped, NOT IMPLEMENTED
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentityset/graph"
    query: [{name: subject, var: subject, style: multi}, {name: background, var: background, style: multi}, {name: object_category, var: object_category}, {name: object_slim, var: object_slim}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject, background: $background, object_category: $object_category, object_slim: $object_slim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns homology associations for a given input set of genes
#
# GET /bioentityset/homologs/
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_entity_set_homologs
export def "get-entity-set-homologs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/bioentityset/homologs/"
    query: [{name: subject, var: subject, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Summary statistics for objects associated
#
# GET /bioentityset/overrepresentation
# operationId: get_over_representation
export def "get-over-representation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --object-category: string # E.g. phenotype, function
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387
  --background: list<string> # Entity ids in background set, e.g. NCBIGene:84570, NCBIGene:3630; used in over-representation tests
  --subject-category: string # Default: gene. Other types may be used e.g. disease but statistics may not make sense (default: gene)
  --max-p-value: string # Exclude results with p-value greater than this (default: 0.05)
  --ontology: string # ontology id. Must be obo id. Examples: go, mp, hp, uberon (optional: will be inferred if left blank)
  --taxon: string # must be NCBITaxon CURIE. Example: NCBITaxon:9606
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentityset/overrepresentation"
    query: [{name: object_category, var: object_category}, {name: subject, var: subject, style: multi}, {name: background, var: background, style: multi}, {name: subject_category, var: subject_category}, {name: max_p_value, var: max_p_value}, {name: ontology, var: ontology}, {name: taxon, var: taxon}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_category: $object_category, subject: $subject, background: $background, subject_category: $subject_category, max_p_value: $max_p_value, ontology: $ontology, taxon: $taxon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For a given gene(s), summarize its annotations over a defined set of slim
#
# GET /bioentityset/slimmer/anatomy
# operationId: get_entity_set_anatomy_slimmer
export def "get-entity-set-anatomy-slimmer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387 (required)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID (IMPLEMENTED) or subset ID (TODO) (required)
  --exclude-automatic-assertions: oneof<nothing, bool> # If set, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentityset/slimmer/anatomy"
    query: [{name: subject, var: subject, style: multi, required: true}, {name: slim, var: slim, style: multi, required: true}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: rows, var: rows}, {name: start, var: start}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject, slim: $slim, exclude_automatic_assertions: $exclude_automatic_assertions, rows: $rows, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For a given gene(s), summarize its annotations over a defined set of slim
#
# GET /bioentityset/slimmer/function
# operationId: get_entity_set_function_slimmer
export def "get-entity-set-function-slimmer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --relationship-type: string@relationship-type-completer-1 # relationship type ('involved_in' or 'acts_upstream_of_or_within') (default: acts_upstream_of_or_within)
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387 (required)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID (IMPLEMENTED) or subset ID (TODO) (required)
  --exclude-automatic-assertions: oneof<nothing, bool> # If set, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentityset/slimmer/function"
    query: [{name: relationship_type, var: relationship_type}, {name: subject, var: subject, style: multi, required: true}, {name: slim, var: slim, style: multi, required: true}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: rows, var: rows}, {name: start, var: start}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    relationship_type: $relationship_type, subject: $subject, slim: $slim, exclude_automatic_assertions: $exclude_automatic_assertions, rows: $rows, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# For a given gene(s), summarize its annotations over a defined set of slim
#
# GET /bioentityset/slimmer/phenotype
# operationId: get_entity_set_phenotype_slimmer
export def "get-entity-set-phenotype-slimmer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: list<string> # Entity ids to be examined, e.g. NCBIGene:9342, NCBIGene:7227, NCBIGene:8131, NCBIGene:157570, NCBIGene:51164, NCBIGene:6689, NCBIGene:6387 (required)
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID (IMPLEMENTED) or subset ID (TODO) (required)
  --exclude-automatic-assertions: oneof<nothing, bool> # If set, excludes associations that involve IEAs (ECO:0000501) (default: false)
  --rows: int # number of rows (default: 100)
  --start: int # beginning row
]: nothing -> any {
  http-request {
    method: get
    path: "/bioentityset/slimmer/phenotype"
    query: [{name: subject, var: subject, style: multi, required: true}, {name: slim, var: slim, style: multi, required: true}, {name: exclude_automatic_assertions, var: exclude_automatic_assertions}, {name: rows, var: rows}, {name: start, var: start}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject, slim: $slim, exclude_automatic_assertions: $exclude_automatic_assertions, rows: $rows, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of models
#
# GET /cam/activity
# operationId: get_activity_collection
export def "get-activity-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  http-request {
    method: get
    path: "/cam/activity"
    query: [{name: title, var: title}, {name: contributor, var: contributor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    title: $title, contributor: $contributor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matches
#
# GET /cam/instance/{id}
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_instance_object
export def "get-instance-object" [
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
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/cam/instance/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: title, var: title}, {name: contributor, var: contributor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, title: $title, contributor: $contributor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of all instances
#
# GET /cam/instances
# operationId: get_model_instances
export def "get-model-instances" [
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
    path: "/cam/instances"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of ALL models
#
# GET /cam/model
# operationId: get_model_collection
export def "get-model-collection" [
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
    path: "/cam/model"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of all contributors across all models
#
# GET /cam/model/contributors
# operationId: get_model_contributors
export def "get-model-contributors" [
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
    path: "/cam/model/contributors"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of all properties used across all models
#
# GET /cam/model/properties
# operationId: get_model_properties
export def "get-model-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  http-request {
    method: get
    path: "/cam/model/properties"
    query: [{name: title, var: title}, {name: contributor, var: contributor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    title: $title, contributor: $contributor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list property-values for all models
#
# GET /cam/model/property_values
# operationId: get_model_property_values
export def "get-model-property-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  http-request {
    method: get
    path: "/cam/model/property_values"
    query: [{name: title, var: title}, {name: contributor, var: contributor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    title: $title, contributor: $contributor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of models matching query
#
# GET /cam/model/query
# operationId: get_model_query
export def "get-model-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  http-request {
    method: get
    path: "/cam/model/query"
    query: [{name: title, var: title}, {name: contributor, var: contributor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    title: $title, contributor: $contributor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a complete model
#
# GET /cam/model/{id}
# operationId: get_model_object
export def "get-model-object" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/cam/model/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of models
#
# GET /cam/physical_interaction
# operationId: get_physical_interaction
export def "get-physical-interaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # string to search for in title of model
  --contributor: string # string to search for in contributor of model
]: nothing -> any {
  http-request {
    method: get
    path: "/cam/physical_interaction"
    query: [{name: title, var: title}, {name: contributor, var: contributor}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    title: $title, contributor: $contributor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns evidence graph object for a given association
#
# GET /evidence/graph/{id}
# Returns: table<edges: list<record>, nodes: list<record>>
# operationId: get_evidence_graph_object
export def "get-evidence-graph-object" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/evidence/graph/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns evidence as a association_results object given an association
#
# GET /evidence/graph/{id}/table
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_evidence_graph_table
export def "get-evidence-graph-table" [
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
  --is-publication: oneof<nothing, bool> # If true, considers dc:source as edge (default: false)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/evidence/graph/{id}/table"
    path_params: [{name: id, var: id}]
    query: [{name: is_publication, var: is_publication}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, is_publication: $is_publication
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matches
#
# GET /genome/features/within/{build}/{reference}/{begin}/{end}
# Returns: table<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: list<record>, types: list<string>, association_counts: record, taxon: record<id: string, label: string>, xrefs: list<string>, homology_associations: list<record>, locations: list<record>, seq: record<category: list, id: string, iri: string, label: string, consider: list, deprecated: bool, description: string, replaced_by: list, synonyms: list, types: list, association_counts: record, taxon: record, xrefs: list, alphabet: string, md5checksum: string, residues: string, seqlen: string>>
# operationId: get_features_within_resource
export def "get-features-within-resource" [
  build: string
  reference: string
  begin: string
  end: string
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
    path: "/genome/features/within/{build}/{reference}/{begin}/{end}"
    path_params: [{name: build, var: build}, {name: reference, var: reference}, {name: begin, var: begin}, {name: end, var: end}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    build: $build, reference: $reference, begin: $begin, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns edges emanating from a given node
#
# GET /graph/edges/from/{id}
# Returns: table<edges: list<record>, nodes: list<record>>
# operationId: get_edge_resource
export def "get-edge-resource" [
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
  --depth: int # How far to traverse for neighbors (default: 1)
  --direction: string@direction-completer # Which direction to traverse (used only if relationship_type is defined) (default: BOTH)
  --relationship-type: list<string> # Relationship type to traverse
  --entail: oneof<nothing, bool> # Include sub-properties and equivalent properties (default: false)
  --graph: string@graph-completer # Which monarch graph to query (default: data)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/graph/edges/from/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: depth, var: depth}, {name: direction, var: direction}, {name: relationship_type, var: relationship_type, style: multi}, {name: entail, var: entail}, {name: graph, var: graph}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, depth: $depth, direction: $direction, relationship_type: $relationship_type, entail: $entail, graph: $graph
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a graph node
#
# GET /graph/node/{id}
# Returns: table<category: list<string>, id: string, iri: string, label: string, consider: list<string>, deprecated: bool, description: string, replaced_by: list<string>, synonyms: list<record>, types: list<string>, association_counts: record, taxon: record<id: string, label: string>, xrefs: list<string>>
# operationId: get_node_resource
export def "get-node-resource" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/graph/node/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# TODO maps a list of identifiers from a source to a target
#
# GET /identifier/mapper/{source}/{target}/
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_identifier_mapper
export def "get-identifier-mapper" [
  source: string
  target: string
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
    path: "/identifier/mapper/{source}/{target}/"
    path_params: [{name: source, var: source}, {name: target, var: target}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of prefixes
#
# GET /identifier/prefixes/
# operationId: get_prefix_collection
export def "get-prefix-collection" [
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
    path: "/identifier/prefixes/"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns contracted URI
#
# GET /identifier/prefixes/contract/{uri}
# operationId: get_prefix_contract
export def "get-prefix-contract" [
  uri: string
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
    path: "/identifier/prefixes/contract/{uri}"
    path_params: [{name: uri, var: uri}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns expanded URI
#
# GET /identifier/prefixes/expand/{id}
# operationId: get_prefix_expand
export def "get-prefix-expand" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/identifier/prefixes/expand/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matches
#
# GET /individual/pedigree/{id}
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_pedigree
export def "get-pedigree" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/individual/pedigree/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matches
#
# GET /individual/{id}
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_individual
export def "get-individual" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/individual/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk download of case associations
#
# GET /mart/case/{object_category}/{taxon}
# operationId: get_mart_case_associations_resource
export def "get-mart-case-associations-resource" [
  object_category: string
  taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
]: nothing -> any {
  http-request {
    method: get
    path: "/mart/case/{object_category}/{taxon}"
    path_params: [{name: object_category, var: object_category}, {name: taxon, var: taxon}]
    query: [{name: slim, var: slim, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_category: $object_category, taxon: $taxon, slim: $slim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk download of disease associations
#
# GET /mart/disease/{object_category}/{taxon}
# operationId: get_mart_disease_associations_resource
export def "get-mart-disease-associations-resource" [
  object_category: string
  taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
]: nothing -> any {
  http-request {
    method: get
    path: "/mart/disease/{object_category}/{taxon}"
    path_params: [{name: object_category, var: object_category}, {name: taxon, var: taxon}]
    query: [{name: slim, var: slim, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_category: $object_category, taxon: $taxon, slim: $slim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk download of gene associations
#
# GET /mart/gene/{object_category}/{taxon}
# operationId: get_mart_gene_associations_resource
export def "get-mart-gene-associations-resource" [
  object_category: string
  taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --slim: list<string> # Map objects up (slim) to a higher level category. Value can be ontology class ID or subset ID
]: nothing -> any {
  http-request {
    method: get
    path: "/mart/gene/{object_category}/{taxon}"
    path_params: [{name: object_category, var: object_category}, {name: taxon, var: taxon}]
    query: [{name: slim, var: slim, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    object_category: $object_category, taxon: $taxon, slim: $slim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk download of orthologs
#
# GET /mart/ortholog/{taxon1}/{taxon2}
# operationId: get_mart_ortholog_associations_resource
export def "get-mart-ortholog-associations-resource" [
  taxon1: string
  taxon2: string
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
    path: "/mart/ortholog/{taxon1}/{taxon2}"
    path_params: [{name: taxon1, var: taxon1}, {name: taxon2, var: taxon2}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    taxon1: $taxon1, taxon2: $taxon2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bulk download of paralogs
#
# GET /mart/paralog/{taxon1}/{taxon2}
# operationId: get_mart_paralog_associations_resource
export def "get-mart-paralog-associations-resource" [
  taxon1: string
  taxon2: string
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
    path: "/mart/paralog/{taxon1}/{taxon2}"
    path_params: [{name: taxon1, var: taxon1}, {name: taxon2, var: taxon2}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    taxon1: $taxon1, taxon2: $taxon2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get metadata for all datasets from SciGraph
#
# GET /metadata/datasets
# operationId: get_metadata_for_datasets
export def "get-metadata-for-datasets" [
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
    path: "/metadata/datasets"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Match a patient to diseases based on their phenotypes
#
# POST /mme/disease
# operationId: post_disease_mme
export def "post-disease-mme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/mme/disease"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Match a patient to fruit fly genes based on similar phenotypes
#
# POST /mme/fly
# operationId: post_fly_mme
export def "post-fly-mme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/mme/fly"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Match a patient to mouse genes based on similar phenotypes
#
# POST /mme/mouse
# operationId: post_mouse_mme
export def "post-mouse-mme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/mme/mouse"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Match a patient to nematode genes based on similar phenotypes
#
# POST /mme/nematode
# operationId: post_nematode_mme
export def "post-nematode-mme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/mme/nematode"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Match a patient to zebrafish genes based on similar phenotypes
#
# POST /mme/zebrafish
# operationId: post_zebrafish_mme
export def "post-zebrafish-mme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  $in | http-request {
    method: post
    path: "/mme/zebrafish"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Annotate a given text using SciGraph annotator
#
# GET /nlp/annotate/
# operationId: get_annotate
export def "get-annotate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The text content to annotate
  --include-category: list<string> # Categories to include for annotation
  --exclude-category: list<string> # Categories to exclude for annotation
  --min-length: string # The minimum number of characters in the annotated entity (default: 4)
  --longest-only: oneof<nothing, bool> # Should only the longest entity be returned for an overlapping group (default: false)
  --include-abbreviation: oneof<nothing, bool> # Should abbreviations be included (default: false)
  --include-acronym: oneof<nothing, bool> # Should acronyms be included (default: false)
  --include-numbers: oneof<nothing, bool> # Should numbers be included (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/nlp/annotate/"
    query: [{name: content, var: content}, {name: include_category, var: include_category, style: multi}, {name: exclude_category, var: exclude_category, style: multi}, {name: min_length, var: min_length}, {name: longest_only, var: longest_only}, {name: include_abbreviation, var: include_abbreviation}, {name: include_acronym, var: include_acronym}, {name: include_numbers, var: include_numbers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content: $content, include_category: $include_category, exclude_category: $exclude_category, min_length: $min_length, longest_only: $longest_only, include_abbreviation: $include_abbreviation, include_acronym: $include_acronym, include_numbers: $include_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Annotate a given text using SciGraph annotator
#
# POST /nlp/annotate/
# operationId: post_annotate
export def "post-annotate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The text content to annotate
  --include-category: list<string> # Categories to include for annotation
  --exclude-category: list<string> # Categories to exclude for annotation
  --min-length: string # The minimum number of characters in the annotated entity (default: 4)
  --longest-only: oneof<nothing, bool> # Should only the longest entity be returned for an overlapping group (default: false)
  --include-abbreviation: oneof<nothing, bool> # Should abbreviations be included (default: false)
  --include-acronym: oneof<nothing, bool> # Should acronyms be included (default: false)
  --include-numbers: oneof<nothing, bool> # Should numbers be included (default: false)
]: nothing -> any {
  http-request {
    method: post
    path: "/nlp/annotate/"
    query: [{name: content, var: content}, {name: include_category, var: include_category, style: multi}, {name: exclude_category, var: exclude_category, style: multi}, {name: min_length, var: min_length}, {name: longest_only, var: longest_only}, {name: include_abbreviation, var: include_abbreviation}, {name: include_acronym, var: include_acronym}, {name: include_numbers, var: include_numbers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content: $content, include_category: $include_category, exclude_category: $exclude_category, min_length: $min_length, longest_only: $longest_only, include_abbreviation: $include_abbreviation, include_acronym: $include_acronym, include_numbers: $include_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Annotate a given content using SciGraph annotator and get all entities from content
#
# GET /nlp/annotate/entities
# Returns: record<content: string, spans: table<end: int, start: int, text: string, token: list>>
# operationId: get_annotate_entities
export def "get-annotate-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The text content to annotate
  --include-category: list<string> # Categories to include for annotation
  --exclude-category: list<string> # Categories to exclude for annotation
  --min-length: string # The minimum number of characters in the annotated entity (default: 4)
  --longest-only: oneof<nothing, bool> # Should only the longest entity be returned for an overlapping group (default: false)
  --include-abbreviation: oneof<nothing, bool> # Should abbreviations be included (default: false)
  --include-acronym: oneof<nothing, bool> # Should acronyms be included (default: false)
  --include-numbers: oneof<nothing, bool> # Should numbers be included (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/nlp/annotate/entities"
    query: [{name: content, var: content}, {name: include_category, var: include_category, style: multi}, {name: exclude_category, var: exclude_category, style: multi}, {name: min_length, var: min_length}, {name: longest_only, var: longest_only}, {name: include_abbreviation, var: include_abbreviation}, {name: include_acronym, var: include_acronym}, {name: include_numbers, var: include_numbers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content: $content, include_category: $include_category, exclude_category: $exclude_category, min_length: $min_length, longest_only: $longest_only, include_abbreviation: $include_abbreviation, include_acronym: $include_acronym, include_numbers: $include_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Annotate a given content using SciGraph annotator and get all entities from content
#
# POST /nlp/annotate/entities
# Returns: record<content: string, spans: table<end: int, start: int, text: string, token: list>>
# operationId: post_annotate_entities
export def "post-annotate-entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # The text content to annotate
  --include-category: list<string> # Categories to include for annotation
  --exclude-category: list<string> # Categories to exclude for annotation
  --min-length: string # The minimum number of characters in the annotated entity (default: 4)
  --longest-only: oneof<nothing, bool> # Should only the longest entity be returned for an overlapping group (default: false)
  --include-abbreviation: oneof<nothing, bool> # Should abbreviations be included (default: false)
  --include-acronym: oneof<nothing, bool> # Should acronyms be included (default: false)
  --include-numbers: oneof<nothing, bool> # Should numbers be included (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/nlp/annotate/entities"
    query: [{name: content, var: content}, {name: include_category, var: include_category, style: multi}, {name: exclude_category, var: exclude_category, style: multi}, {name: min_length, var: min_length}, {name: longest_only, var: longest_only}, {name: include_abbreviation, var: include_abbreviation}, {name: include_acronym, var: include_acronym}, {name: include_numbers, var: include_numbers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content: $content, include_category: $include_category, exclude_category: $exclude_category, min_length: $min_length, longest_only: $longest_only, include_abbreviation: $include_abbreviation, include_acronym: $include_acronym, include_numbers: $include_numbers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches a map from CURIEs/IDs to labels
#
# GET /ontol/identifier/
# operationId: get_ontol_identifier_resource
export def "get-ontol-identifier-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: list<string> # List of labels (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/ontol/identifier/"
    query: [{name: label, var: label, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches a map from CURIEs/IDs to labels
#
# POST /ontol/identifier/
# operationId: post_ontol_identifier_resource
export def "post-ontol-identifier-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: list<string> # List of labels (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/ontol/identifier/"
    query: [{name: label, var: label, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    label: $label
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information content (IC) for a set of relevant ontology classes
#
# GET /ontol/information_content/{subject_category}/{object_category}/{subject_taxon}
# operationId: get_information_content_resource
export def "get-information-content-resource" [
  subject_category: string
  object_category: string
  subject_taxon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> any {
  http-request {
    method: get
    path: "/ontol/information_content/{subject_category}/{object_category}/{subject_taxon}"
    path_params: [{name: subject_category, var: subject_category}, {name: object_category, var: object_category}, {name: subject_taxon, var: subject_taxon}]
    query: [{name: evidence, var: evidence}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject_category: $subject_category, object_category: $object_category, subject_taxon: $subject_taxon, evidence: $evidence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fetches a map from CURIEs/IDs to labels
#
# GET /ontol/labeler/
# operationId: get_ontol_labeler_resource
export def "get-ontol-labeler-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # List of ids (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/ontol/labeler/"
    query: [{name: id, var: id, style: multi, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extract a subgraph from an ontology
#
# GET /ontol/subgraph/{ontology}/{node}
# operationId: get_extract_ontology_subgraph_resource
export def "get-extract-ontology-subgraph-resource" [
  ontology: string
  node: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cnode: list<string> # Additional classes
  --include-ancestors: oneof<nothing, bool> # Include Ancestors (default: true)
  --include-descendants: oneof<nothing, bool> # Include Descendants
  --relation: list<string> # Additional classes (default: [subClassOf, BFO:0000050])
  --include-meta: oneof<nothing, bool> # Include metadata in response (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/ontol/subgraph/{ontology}/{node}"
    path_params: [{name: ontology, var: ontology}, {name: node, var: node}]
    query: [{name: cnode, var: cnode, style: multi}, {name: include_ancestors, var: include_ancestors}, {name: include_descendants, var: include_descendants}, {name: relation, var: relation, style: multi}, {name: include_meta, var: include_meta}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ontology: $ontology, node: $node, cnode: $cnode, include_ancestors: $include_ancestors, include_descendants: $include_descendants, relation: $relation, include_meta: $include_meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extract a subgraph from an ontology
#
# POST /ontol/subgraph/{ontology}/{node}
# operationId: post_extract_ontology_subgraph_resource
export def "post-extract-ontology-subgraph-resource" [
  ontology: string
  node: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cnode: list<string> # Additional classes
  --include-ancestors: oneof<nothing, bool> # Include Ancestors (default: true)
  --include-descendants: oneof<nothing, bool> # Include Descendants
  --relation: list<string> # Additional classes (default: [subClassOf, BFO:0000050])
  --include-meta: oneof<nothing, bool> # Include metadata in response (default: false)
]: nothing -> any {
  http-request {
    method: post
    path: "/ontol/subgraph/{ontology}/{node}"
    path_params: [{name: ontology, var: ontology}, {name: node, var: node}]
    query: [{name: cnode, var: cnode, style: multi}, {name: include_ancestors, var: include_ancestors}, {name: include_descendants, var: include_descendants}, {name: relation, var: relation, style: multi}, {name: include_meta, var: include_meta}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    ontology: $ontology, node: $node, cnode: $cnode, include_ancestors: $include_ancestors, include_descendants: $include_descendants, relation: $relation, include_meta: $include_meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the ancestor ontology terms shared by two ontology terms
#
# GET /ontology/shared/{subject}/{object}
# operationId: get_ontology_terms_shared_ancestor
export def "get-ontology-terms-shared-ancestor" [
  subject: string
  object: string
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
    path: "/ontology/shared/{subject}/{object}"
    path_params: [{name: subject, var: subject}, {name: object, var: object}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject: $subject, object: $object
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns meta data of an ontology subset (slim)
#
# GET /ontology/subset/{id}
# operationId: get_ontology_subset
export def "get-ontology-subset" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/ontology/subset/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns meta data of an ontology term
#
# GET /ontology/term/{id}
# operationId: get_ontology_term
export def "get-ontology-term" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/ontology/term/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns graph of an ontology term
#
# GET /ontology/term/{id}/graph
# operationId: get_ontology_term_graph
export def "get-ontology-term-graph" [
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
  --graph-type: string@graph-type-completer # graph type ('topology_graph', 'regulates_transitivity_graph' or 'neighborhood_graph') (default: topology_graph)
]: nothing -> any {
  http-request {
    method: get
    path: "/ontology/term/{id}/graph"
    path_params: [{name: id, var: id}]
    query: [{name: graph_type, var: graph_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, graph_type: $graph_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Extract a subgraph from an ontology term
#
# GET /ontology/term/{id}/subgraph
# operationId: get_ontology_term_subgraph
export def "get-ontology-term-subgraph" [
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
  --cnode: list<string> # Additional classes
  --include-ancestors: oneof<nothing, bool> # Include Ancestors (default: true)
  --include-descendants: oneof<nothing, bool> # Include Descendants
  --relation: list<string> # Additional classes (default: [subClassOf, BFO:0000050])
  --include-meta: oneof<nothing, bool> # Include metadata in response (default: false)
]: nothing -> any {
  http-request {
    method: get
    path: "/ontology/term/{id}/subgraph"
    path_params: [{name: id, var: id}]
    query: [{name: cnode, var: cnode, style: multi}, {name: include_ancestors, var: include_ancestors}, {name: include_descendants, var: include_descendants}, {name: relation, var: relation, style: multi}, {name: include_meta, var: include_meta}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, cnode: $cnode, include_ancestors: $include_ancestors, include_descendants: $include_descendants, relation: $relation, include_meta: $include_meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns subsets (slims) associated to an ontology term
#
# GET /ontology/term/{id}/subsets
# operationId: get_ontology_term_subsets
export def "get-ontology-term-subsets" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/ontology/term/{id}/subsets"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Placeholder - use OWLery for now
#
# GET /owl/ontology/dlquery/{query}
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_dl_query
export def "get-dl-query" [
  query: string
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
    path: "/owl/ontology/dlquery/{query}"
    path_params: [{name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Placeholder - use direct SPARQL endpoint for now
#
# GET /owl/ontology/sparql/{query}
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_sparql_query
export def "get-sparql-query" [
  query: string
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
    path: "/owl/ontology/sparql/{query}"
    path_params: [{name: query, var: query}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pairwise similarity
#
# GET /pair/sim/jaccard/{id1}/{id2}
# operationId: get_pair_sim_jaccard_resource
export def "get-pair-sim-jaccard-resource" [
  id1: string
  id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --object-category: string # e.g. disease, phenotype, gene. Two subjects will be compared based on overlap between associations to objects in this category
]: nothing -> any {
  http-request {
    method: get
    path: "/pair/sim/jaccard/{id1}/{id2}"
    path_params: [{name: id1, var: id1}, {name: id2, var: id2}]
    query: [{name: object_category, var: object_category}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id1: $id1, id2: $id2, object_category: $object_category
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All relations used plus count of associations
#
# GET /relation/usage/
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_relation_usage_resource
export def "get-relation-usage-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject-taxon: string # SUBJECT TAXON id, e.g. NCBITaxon:9606. Includes inferred by default
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/relation/usage/"
    query: [{name: subject_taxon, var: subject_taxon}, {name: evidence, var: evidence}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject_taxon: $subject_taxon, evidence: $evidence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All relations used plus count of associations
#
# GET /relation/usage/between/{subject_category}/{object_category}
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_relation_usage_between_resource
export def "get-relation-usage-between-resource" [
  subject_category: string
  object_category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject-taxon: string # SUBJECT TAXON id, e.g. NCBITaxon:9606. Includes inferred by default
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/relation/usage/between/{subject_category}/{object_category}"
    path_params: [{name: subject_category, var: subject_category}, {name: object_category, var: object_category}]
    query: [{name: subject_taxon, var: subject_taxon}, {name: evidence, var: evidence}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject_category: $subject_category, object_category: $object_category, subject_taxon: $subject_taxon, evidence: $evidence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Relation usage count for all subj x obj category combinations
#
# GET /relation/usage/pivot
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_relation_usage_pivot_resource
export def "get-relation-usage-pivot-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject-taxon: string # SUBJECT TAXON id, e.g. NCBITaxon:9606. Includes inferred by default
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/relation/usage/pivot"
    query: [{name: subject_taxon, var: subject_taxon}, {name: evidence, var: evidence}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject_taxon: $subject_taxon, evidence: $evidence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Relation usage count for all subj x obj category combinations, showing label
#
# GET /relation/usage/pivot/label
# Returns: table<docs: list<record>, facet_counts: record, highlighting: record, numFound: int, associations: list<record>, compact_associations: list<record>, objects: list<string>>
# operationId: get_relation_usage_pivot_label_resource
export def "get-relation-usage-pivot-label-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject-taxon: string # SUBJECT TAXON id, e.g. NCBITaxon:9606. Includes inferred by default
  --evidence: string # Object id, e.g. ECO:0000501 (for IEA; Includes inferred by default) or a specific publication or other supporting ibject, e.g. ZFIN:ZDB-PUB-060503-2.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/relation/usage/pivot/label"
    query: [{name: subject_taxon, var: subject_taxon}, {name: evidence, var: evidence}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    subject_taxon: $subject_taxon, evidence: $evidence
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matching concepts or entities using lexical search
#
# GET /search/entity/autocomplete/{term}
# Returns: record<docs: table<category: list, equivalent_ids: list, has_highlight: bool, highlight: string, id: string, label: list, match: string, taxon: string, taxon_label: string>>
# operationId: get_autocomplete
export def "get-autocomplete" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fq: list<string> # fq string passed directly to solr, note that multiple filters will be combined with an AND operator. Combining fq_string with other parameters may result in unexpected behavior.
  --category: list<string> # e.g. gene, disease
  --prefix: list<string> # ontology prefix: HP, -MONDO
  --include-eqs: oneof<nothing, bool> # Include equivalent ids in prefix filter (default: false)
  --boost-fx: list<string> # boost function e.g. pow(edges,0.334)
  --boost-q: list<string> # boost query e.g. category:genotype^-10
  --taxon: list<string> # taxon filter, eg NCBITaxon:9606, includes inferred taxa
  --rows: int # number of rows (default: 20)
  --start: string # row number to start from (default: 0)
  --highlight-class: string # highlight class
  --min-match: string # minimum should match parameter, see solr docs for details
  --exclude-groups: oneof<nothing, bool> # Exclude grouping classes (classes with subclasses) (default: false)
  --minimal-tokenizer: oneof<nothing, bool> # set to true to use the minimal tokenizer, good for variants and genotypes (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/entity/autocomplete/{term}"
    path_params: [{name: term, var: term}]
    query: [{name: fq, var: fq, style: multi}, {name: category, var: category, style: multi}, {name: prefix, var: prefix, style: multi}, {name: include_eqs, var: include_eqs}, {name: boost_fx, var: boost_fx, style: multi}, {name: boost_q, var: boost_q, style: multi}, {name: taxon, var: taxon, style: multi}, {name: rows, var: rows}, {name: start, var: start}, {name: highlight_class, var: highlight_class}, {name: min_match, var: min_match}, {name: exclude_groups, var: exclude_groups}, {name: minimal_tokenizer, var: minimal_tokenizer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    term: $term, fq: $fq, category: $category, prefix: $prefix, include_eqs: $include_eqs, boost_fx: $boost_fx, boost_q: $boost_q, taxon: $taxon, rows: $rows, start: $start, highlight_class: $highlight_class, min_match: $min_match, exclude_groups: $exclude_groups, minimal_tokenizer: $minimal_tokenizer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matching concepts or entities using lexical search
#
# GET /search/entity/hpo-pl/{term}
# Returns: record<results: table<highlight: string, id: string, label: string, matched_synonym: string>>
# operationId: get_search_hpo_entities
export def "get-search-hpo-entities" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rows: int # number of rows (default: 10)
  --start: string # row number to start from (default: 0)
  --phenotype-group: string # phenotype group id
  --phenotype-group-label: string # phenotype group label
  --anatomical-system: string # anatomical system id
  --anatomical-system-label: string # anatomical system label
  --highlight-class: string # highlight class
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/entity/hpo-pl/{term}"
    path_params: [{name: term, var: term}]
    query: [{name: rows, var: rows}, {name: start, var: start}, {name: phenotype_group, var: phenotype_group}, {name: phenotype_group_label, var: phenotype_group_label}, {name: anatomical_system, var: anatomical_system}, {name: anatomical_system_label, var: anatomical_system_label}, {name: highlight_class, var: highlight_class}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    term: $term, rows: $rows, start: $start, phenotype_group: $phenotype_group, phenotype_group_label: $phenotype_group_label, anatomical_system: $anatomical_system, anatomical_system_label: $anatomical_system_label, highlight_class: $highlight_class
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matching concepts or entities using lexical search
#
# GET /search/entity/{term}
# Returns: record<docs: list<record>, facet_counts: record, highlighting: record, numFound: int>
# operationId: get_search_entities
export def "get-search-entities" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fq: list<string> # fq string passed directly to solr, note that multiple filters will be combined with an AND operator. Combining fq_string with other parameters may result in unexpected behavior.
  --category: list<string> # e.g. gene, disease
  --prefix: list<string> # ontology prefix: HP, -MONDO
  --include-eqs: oneof<nothing, bool> # Include equivalent ids in prefix filter (default: false)
  --boost-fx: list<string> # boost function e.g. pow(edges,0.334)
  --boost-q: list<string> # boost query e.g. category:genotype^-10
  --taxon: list<string> # taxon filter, eg NCBITaxon:9606, includes inferred taxa
  --rows: int # number of rows (default: 20)
  --start: string # row number to start from (default: 0)
  --highlight-class: string # highlight class
  --min-match: string # minimum should match parameter, see solr docs for details
  --exclude-groups: oneof<nothing, bool> # Exclude grouping classes (classes with subclasses) (default: false)
  --minimal-tokenizer: oneof<nothing, bool> # set to true to use the minimal tokenizer, good for variants and genotypes (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/entity/{term}"
    path_params: [{name: term, var: term}]
    query: [{name: fq, var: fq, style: multi}, {name: category, var: category, style: multi}, {name: prefix, var: prefix, style: multi}, {name: include_eqs, var: include_eqs}, {name: boost_fx, var: boost_fx, style: multi}, {name: boost_q, var: boost_q, style: multi}, {name: taxon, var: taxon, style: multi}, {name: rows, var: rows}, {name: start, var: start}, {name: highlight_class, var: highlight_class}, {name: min_match, var: min_match}, {name: exclude_groups, var: exclude_groups}, {name: minimal_tokenizer, var: minimal_tokenizer}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    term: $term, fq: $fq, category: $category, prefix: $prefix, include_eqs: $include_eqs, boost_fx: $boost_fx, boost_q: $boost_q, taxon: $taxon, rows: $rows, start: $start, highlight_class: $highlight_class, min_match: $min_match, exclude_groups: $exclude_groups, minimal_tokenizer: $minimal_tokenizer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compare a reference profile vs one profiles
#
# GET /sim/compare
# Returns: record<matches: table<id: string, label: string, taxon: record, type: string, pairwise_match: list, rank: string, score: float, significance: string>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record<id: string, label: string, taxon: record, type: string>, target_ids: list<list>, unresolved_ids: list<string>>>
# operationId: get_sim_compare
export def "get-sim-compare" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-feature-set: oneof<nothing, bool> # set to true if *all* input ids are phenotypic features, else set to false (default: true)
  --metric: string@metric-completer # Metric for computing similarity (default: phenodigm)
  --ref-id: list<string> # A phenotype or identifier that is composed of phenotypes (eg disease, gene) (default: [])
  --query-id: list<string> # A phenotype or identifier that is composed of phenotypes (eg disease, gene) (default: [])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim/compare"
    query: [{name: is_feature_set, var: is_feature_set}, {name: metric, var: metric}, {name: ref_id, var: ref_id, style: multi}, {name: query_id, var: query_id, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    is_feature_set: $is_feature_set, metric: $metric, ref_id: $ref_id, query_id: $query_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compare a reference profile vs one or more profiles
#
# POST /sim/compare
# Returns: record<matches: table<id: string, label: string, taxon: record, type: string, pairwise_match: list, rank: string, score: float, significance: string>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record<id: string, label: string, taxon: record, type: string>, target_ids: list<list>, unresolved_ids: list<string>>>
# operationId: post_sim_compare
export def "post-sim-compare" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query-ids: list # list of query profiles
  --reference-ids: list<string> # list of ids
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sim/compare"
    body: {content_type: "application/json", kind: json, fields: [{name: query_ids, var: query_ids}, {name: reference_ids, var: reference_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    query_ids: $query_ids, reference_ids: $reference_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get annotation score
#
# GET /sim/score
# Returns: record<categorical_score: float, scaled_score: float, simple_score: float>
# operationId: get_annotation_score
export def "get-annotation-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Phenotype identifier (eg HP:0004935)
  --absent-id: list<string> # absent phenotype (eg HP:0002828) (default: [])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim/score"
    query: [{name: id, var: id, style: multi}, {name: absent_id, var: absent_id, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, absent_id: $absent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get annotation score
#
# POST /sim/score
# Returns: record<categorical_score: float, scaled_score: float, simple_score: float>
# operationId: post_annotation_score
export def "post-annotation-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --features: list # list of features — item shape: {id?: string, isPresent?: bool, label?: string, type?: string}
  --id: string # curie formatted id
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sim/score"
    body: {content_type: "application/json", kind: json, fields: [{name: features, var: features}, {name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    features: $features, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for phenotypically similar diseases or model genes
#
# GET /sim/search
# Returns: record<matches: table<id: string, label: string, taxon: record, type: string, pairwise_match: list, rank: string, score: float, significance: string>, metadata: record<max_max_ic: float>, query: record<ids: list<record>, negated_ids: list<record>, reference: record<id: string, label: string, taxon: record, type: string>, target_ids: list<list>, unresolved_ids: list<string>>>
# operationId: get_sim_search
export def "get-sim-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-feature-set: oneof<nothing, bool> # set to true if *all* input ids are phenotypic features, else set to false (default: true)
  --metric: string@metric-completer # Metric for computing similarity (default: phenodigm)
  --id: list<string> # A phenotype or identifier that is composed of phenotypes (eg disease, gene) (default: [])
  --limit: int # number of rows, max 500 (default: 20)
  --taxon: string # ncbi taxon id
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sim/search"
    query: [{name: is_feature_set, var: is_feature_set}, {name: metric, var: metric}, {name: id, var: id, style: multi}, {name: limit, var: limit}, {name: taxon, var: taxon}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    is_feature_set: $is_feature_set, metric: $metric, id: $id, limit: $limit, taxon: $taxon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of variant sets
#
# GET /variation/set/
# Returns: record<page: int, pages: int, per_page: int, total: int, items: table<body: string, category: string, category_id: int, id: int, pub_date: string, title: string>>
# operationId: get_variant_sets_collection
export def "get-variant-sets-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (default: 1)
  --per-page: int@per-page-completer # Results per page {error_msg} (default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/variation/set/"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new variant set
#
# POST /variation/set/
# operationId: post_variant_sets_collection
export def "post-variant-sets-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # Article content
  --category: string
  --category-id: int
  --id: int # The unique identifier of a variant set
  --pub-date: string # format: date-time
  title: string # Article title
]: any -> any {
  $in | http-request {
    method: post
    path: "/variation/set/"
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: category, var: category}, {name: category_id, var: category_id}, {name: id, var: id}, {name: pub_date, var: pub_date}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body, category: $category, category_id: $category_id, id: $id, pub_date: $pub_date, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of matches
#
# GET /variation/set/analyze/{id}
# Returns: table<evidence_graph: record<edges: list, nodes: list>, evidence_types: list<record>, id: string, negated: bool, object: record<category: list, id: string, iri: string, label: string, taxon: record>, object_eq: list<string>, object_extensions: list<record>, provided_by: list<string>, publications: list<record>, qualifiers: list<string>, relation: record<category: list, id: string, iri: string, label: string, inverse: bool>, slim: list<string>, subject: record<category: list, id: string, iri: string, label: string, taxon: record>, subject_eq: list<string>, subject_extensions: list<record>, type: string>
# operationId: get_variant_analyze
export def "get-variant-analyze" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/variation/set/analyze/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns list of variant sets from a specified time period
#
# GET /variation/set/archive/{year}/{month}/{day}
# Returns: record<page: int, pages: int, per_page: int, total: int, items: table<body: string, category: string, category_id: int, id: int, pub_date: string, title: string>>
# operationId: get_variant_sets_archive_collection
export def "get-variant-sets-archive-collection" [
  year: int
  month: int
  day: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (default: 1)
  --per-page: int@per-page-completer # Results per page {error_msg} (default: 10)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/variation/set/archive/{year}/{month}/{day}"
    path_params: [{name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    year: $year, month: $month, day: $day, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes variant set
#
# DELETE /variation/set/{id}
# operationId: delete_variant_set_item
export def "delete-variant-set-item" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/variation/set/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a variant set
#
# GET /variation/set/{id}
# Returns: record<body: string, category: string, category_id: int, id: int, pub_date: string, title: string>
# operationId: get_variant_set_item
export def "get-variant-set-item" [
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
    path: "/variation/set/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a variant set
#
# PUT /variation/set/{id}
# operationId: put_variant_set_item
export def "put-variant-set-item" [
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
  body: string # Article content
  --category: string
  --category-id: int
  --body-id: int # The unique identifier of a variant set (spec name: id)
  --pub-date: string # format: date-time
  title: string # Article title
]: any -> any {
  $in | http-request {
    method: put
    path: "/variation/set/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}, {name: category, var: category}, {name: category_id, var: category_id}, {name: id, var: body_id}, {name: pub_date, var: pub_date}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    id: $id, body: $body, category: $category, category_id: $category_id, body_id: $body_id, pub_date: $pub_date, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
