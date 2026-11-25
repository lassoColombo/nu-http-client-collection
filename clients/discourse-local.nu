# Auto-generated client for Discourse API Documentation vlatest
# Source: https://api.apis.guru/v2/specs/discourse.local/latest/openapi.json
# Auth: --token flag or $env.DISCOURSE_API_DOCUMENTATION_TOKEN

const CLIENT = {
  base_url: "http://discourse.local"
  token_env_var: "DISCOURSE_API_DOCUMENTATION_TOKEN"
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

def base-url-completer [] { ["http://discourse.local" "https://discourse.example.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def flag-completer [] { ["active" "blocked" "new" "staff" "suspect" "suspended"] }
def order-completer [] { ["created" "days_visited" "email" "last_emailed" "posts" "posts_read" "read_time" "seen" "topics_viewed" "trust_level" "username"] }
def asc-completer [] { ["true"] }
def include-subcategories-completer [] { ["true"] }
def period-completer [] { ["all" "daily" "monthly" "quarterly" "weekly" "yearly"] }
def order-completer-1 [] { ["days_visited" "likes_given" "likes_received" "post_count" "posts_read" "topic_count" "topics_entered"] }
def notification-level-completer [] { ["0" "1" "2" "3"] }
def enabled-completer [] { ["false" "true"] }
def status-completer [] { ["archived" "closed" "pinned" "pinned_globally" "visible"] }
def type-completer [] { ["custom" "gravatar" "system" "uploaded"] }
def type-completer-1 [] { ["avatar" "card_background" "composer" "custom_emoji" "profile_background"] }
def upload-type-completer [] { ["avatar" "card_background" "composer" "custom_emoji" "profile_background"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-backups: "table<filename: string, last_modified: string, size: int>"
    create-backup: "record<success: string>"
    admin-list-badges: "record<admin_badges: record<badge_grouping_ids: list<any>, badge_ids: list<any>, badge_type_ids: list<any>, protected_system_fields: list<any>, triggers: record<none: int, post_action: int, post_revision: int, trust_level_change: int, user_change: int>>, badge_groupings: table<description: string, id: int, name: string, position: int, system: bool>, badge_types: table<id: int, name: string, sort_order: int>, badges: table<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, i18n_name: string, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: int>>"
    create-badge: "record<badge: record<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: string>, badge_types: table<id: int, name: string, sort_order: int>>"
    update-badge: "record<badge: record<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: string>, badge_types: table<id: int, name: string, sort_order: int>>"
    create-group: "record<basic_group: record<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>>"
    delete-group: "record<success: string>"
    admin-list-users: "table<active: bool, admin: bool, avatar_template: string, created_at: string, created_at_age: float, days_visited: int, email: string, flag_level: int, id: int, last_emailed_age: float, last_emailed_at: string, last_seen_age: float, last_seen_at: string, manual_locked_trust_level: string, moderator: bool, name: string, post_count: int, posts_read_count: int, secondary_emails: list<any>, staged: bool, time_read: int, title: string, topics_entered: int, trust_level: int, username: string>"
    delete-user: "record<deleted: bool>"
    admin-get-user: "record<active: bool, admin: bool, api_key_count: int, approved_by: record<avatar_template: string, id: int, name: string, username: string>, associated_accounts: list<any>, avatar_template: string, badge_count: int, bounce_score: int, can_activate: bool, can_be_anonymized: bool, can_be_deleted: bool, can_be_merged: bool, can_deactivate: bool, can_delete_all_posts: bool, can_delete_sso_record: bool, can_disable_second_factor: bool, can_grant_admin: bool, can_grant_moderation: bool, can_impersonate: bool, can_revoke_admin: bool, can_revoke_moderation: bool, can_send_activation_email: bool, can_view_action_logs: bool, created_at: string, created_at_age: float, days_visited: int, external_ids: record, flag_level: int, flags_given_count: int, flags_received_count: int, full_suspend_reason: string, groups: table<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_see_members: bool, default_notification_level: int, display_name: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>, id: int, ip_address: string, last_emailed_age: float, last_emailed_at: string, last_seen_age: float, last_seen_at: string, like_count: int, like_given_count: int, manual_locked_trust_level: string, moderator: bool, name: string, next_penalty: string, penalty_counts: record<silenced: int, suspended: int>, post_count: int, post_edits_count: int, posts_read_count: int, primary_group_id: string, private_topics_count: int, registration_ip_address: string, reset_bounce_score_after: string, silence_reason: string, silenced_by: string, single_sign_on_record: string, staged: bool, suspended_by: string, time_read: int, title: string, tl3_requirements: record<days_visited: int, max_flagged_by_users: int, max_flagged_posts: int, min_days_visited: int, min_likes_given: int, min_likes_received: int, min_likes_received_days: int, min_likes_received_users: int, min_posts_read: int, min_posts_read_all_time: int, min_topics_replied_to: int, min_topics_viewed: int, min_topics_viewed_all_time: int, num_flagged_by_users: int, num_flagged_posts: int, num_likes_given: int, num_likes_received: int, num_likes_received_days: int, num_likes_received_users: int, num_topics_replied_to: int, on_grace_period: bool, penalty_counts: record<silenced: int, suspended: int, total: int>, posts_read: int, posts_read_all_time: int, requirements_lost: bool, requirements_met: bool, time_period: int, topics_viewed: int, topics_viewed_all_time: int, trust_level_locked: bool>, topic_count: int, topics_entered: int, trust_level: int, username: string, warnings_received_count: int>"
    anonymize-user: "record<success: string, username: string>"
    log-out-user: "record<success: string>"
    silence-user: "record<silence: record<silence_reason: string, silenced: bool, silenced_at: string, silenced_by: record<avatar_template: string, id: int, name: string, username: string>, silenced_till: string>>"
    suspend-user: "record<suspension: record<full_suspend_reason: string, suspend_reason: string, suspended_at: string, suspended_by: record<avatar_template: string, id: int, name: string, username: string>, suspended_till: string>>"
    get-category: "record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>>"
    list-category-topics: "record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, per_page: int, top_tags: list<any>, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>"
    list-categories: "record<category_list: record<can_create_category: bool, can_create_topic: bool, categories: list<record>>>"
    create-category: "record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>>"
    update-category: "record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: string, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>, success: string>"
    list-users-public: "record<directory_items: table<days_visited: int, id: int, likes_given: int, likes_received: int, post_count: int, posts_read: int, topic_count: int, topics_entered: int, user: record>, meta: record<last_updated_at: string, load_more_directory_items: string, total_rows_directory_items: int>>"
    list-groups: "record<extras: record<type_filters: list<any>>, groups: table<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, display_name: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, is_group_owner: bool, is_group_user: bool, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>, load_more_groups: string, total_rows_groups: int>"
    get-group: "record<extras: record<visible_group_names: list<any>>, group: record<allow_membership_requests: bool, allow_unknown_sender_topic_replies: bool, associated_group_ids: list<any>, automatic: bool, automatic_membership_email_domains: string, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, email_from_alias: string, email_password: string, email_username: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, imap_enabled: bool, imap_last_error: string, imap_mailbox_name: string, imap_mailboxes: list<any>, imap_new_emails: string, imap_old_emails: string, imap_port: string, imap_server: string, imap_ssl: string, imap_updated_at: string, imap_updated_by: record, incoming_email: string, is_group_owner_display: bool, is_group_user: bool, members_visibility_level: int, membership_request_template: string, mentionable: bool, mentionable_level: int, message_count: int, messageable: bool, messageable_level: int, muted_category_ids: list<any>, muted_tags: list<any>, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, regular_category_ids: list<any>, regular_tags: list<any>, smtp_enabled: bool, smtp_port: string, smtp_server: string, smtp_ssl: string, smtp_updated_at: string, smtp_updated_by: record, title: string, tracking_category_ids: list<any>, tracking_tags: list<any>, user_count: int, visibility_level: int, watching_category_ids: list<any>, watching_first_post_category_ids: list<any>, watching_first_post_tags: list<any>, watching_tags: list<any>>>"
    update-group: "record<success: string>"
    remove-group-members: "record<skipped_usernames: list<any>, success: string, usernames: list<any>>"
    list-group-members: "record<members: table<added_at: string, avatar_template: string, id: int, last_posted_at: string, last_seen_at: string, name: string, timezone: string, title: string, username: string>, meta: record<limit: int, offset: int, total: int>, owners: table<added_at: string, avatar_template: string, id: int, last_posted_at: string, last_seen_at: string, name: string, timezone: string, title: string, username: string>>"
    add-group-members: "record<emails: list<any>, success: string, usernames: list<any>>"
    create-invite: "record<created_at: string, custom_message: string, email: string, emailed: bool, expired: bool, expires_at: string, groups: list<any>, id: int, link: string, topics: list<any>, updated_at: string>"
    list-latest-topics: "record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>"
    get-notifications: "record<load_more_notifications: string, notifications: table<created_at: string, data: record, id: int, notification_type: int, post_number: string, read: bool, slug: string, topic_id: int, user_id: int>, seen_notification_id: int, total_rows_notifications: int>"
    mark-notifications-as-read: "record<success: string>"
    perform-post-action: "record<actions_summary: table<acted: bool, can_undo: bool, count: int, id: int>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, notice: record, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>"
    list-posts: "record<latest_posts: table<actions_summary: list, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, category_id: int, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_html_title: string, topic_id: int, topic_slug: string, topic_title: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>>"
    create-topic-post-pm: "record<actions_summary: table<can_act: bool, id: int>, admin: bool, avatar_template: string, bookmarked: bool, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, draft_sequence: int, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, mentioned_users: list<any>, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>"
    get-post: "record<actions_summary: table<can_act: bool, id: int>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>"
    update-post: "record<post: record<actions_summary: list<record>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, draft_sequence: int, edit_reason: string, flair_bg_color: string, flair_color: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>>"
    lock-post: "record<locked: bool>"
    post-replies: "table<actions_summary: list<record>, admin: bool, avatar_template: string, bookmarked: bool, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: int, reply_to_user: record<avatar_template: string, name: string, username: string>, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>"
    search: "record<categories: list<any>, grouped_search_result: record<can_create_topic: bool, category_ids: list<any>, error: string, group_ids: list<any>, more_categories: string, more_full_page_results: string, more_posts: string, more_users: string, post_ids: list<any>, search_log_id: int, tag_ids: list<any>, term: string, user_ids: list<any>>, groups: list<any>, posts: list<any>, tags: list<any>, users: list<any>>"
    send-password-reset-email: "record<success: string, user_found: bool>"
    get-site: "record<anonymous_top_menu_items: list<any>, archetypes: table<id: string, name: string, options: list>, auth_providers: list<any>, can_associate_groups: bool, can_create_tag: bool, can_tag_pms: bool, can_tag_topics: bool, categories: table<allow_global_tags: bool, allowed_tag_groups: list, allowed_tags: list, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, form_template_ids: list, has_children: bool, id: int, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, parent_category_id: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>, censored_regexp: list<record>, custom_emoji_translation: record, default_archetype: string, default_dark_color_scheme: record, displayed_about_plugin_stat_groups: list<any>, filters: list<any>, groups: table<flair_bg_color: string, flair_color: string, flair_url: string, id: int, name: string>, hashtag_configurations: record, hashtag_icons: list<any>, markdown_additional_options: record, notification_types: record<assigned: int, bookmark_reminder: int, chat_group_mention: int, chat_invitation: int, chat_mention: int, chat_message: int, chat_quoted: int, circles_activity: int, code_review_commit_approved: int, custom: int, edited: int, event_invitation: int, event_reminder: int, following: int, following_created_topic: int, following_replied: int, granted_badge: int, group_mentioned: int, group_message_summary: int, invited_to_private_message: int, invited_to_topic: int, invitee_accepted: int, liked: int, liked_consolidated: int, linked: int, membership_request_accepted: int, membership_request_consolidated: int, mentioned: int, moved_post: int, new_features: int, post_approved: int, posted: int, private_message: int, question_answer_user_commented: int, quoted: int, reaction: int, replied: int, topic_reminder: int, votes_released: int, watching_category_or_tag: int, watching_first_post: int>, periods: list<any>, post_action_types: table<description: string, id: int, is_custom_flag: bool, is_flag: bool, name: string, name_key: string, short_description: string>, post_types: record<moderator_action: int, regular: int, small_action: int, whisper: int>, show_welcome_topic_banner: bool, tags_filter_regexp: string, top_menu_items: list<any>, top_tags: list<any>, topic_featured_link_allowed_category_ids: list<any>, topic_flag_types: table<description: string, id: int, is_custom_flag: bool, is_flag: bool, name: string, name_key: string, short_description: string>, trust_levels: record<basic: int, leader: int, member: int, newuser: int, regular: int>, uncategorized_category_id: int, user_color_schemes: table<id: int, is_dark: bool, name: string>, user_field_max_length: int, user_fields: list<any>, user_themes: table<color_scheme_id: int, default: bool, name: string, theme_id: int>, watched_words_link: string, watched_words_replace: string, whispers_allowed_groups_names: list<any>, wizard_required: bool>"
    update-topic: "record<basic_topic: record<fancy_title: string, id: int, posts_count: int, slug: string, title: string>>"
    get-topic: "record<actions_summary: table<can_act: bool, count: int, hidden: bool, id: int>, archetype: string, archived: bool, bookmarked: bool, bookmarks: list<any>, category_id: int, chunk_size: int, closed: bool, created_at: string, current_post_number: int, deleted_at: string, deleted_by: string, details: record<can_archive_topic: bool, can_close_topic: bool, can_convert_topic: bool, can_create_post: bool, can_delete: bool, can_edit: bool, can_edit_staff_notes: bool, can_flag_topic: bool, can_invite_to: bool, can_invite_via_email: bool, can_moderate_category: bool, can_move_posts: bool, can_pin_unpin_topic: bool, can_remove_allowed_users: bool, can_remove_self_id: int, can_reply_as_new_topic: bool, can_review_topic: bool, can_split_merge_topic: bool, can_toggle_topic_visibility: bool, created_by: record<avatar_template: string, id: int, name: string, username: string>, last_poster: record<avatar_template: string, id: int, name: string, username: string>, notification_level: int, participants: list<record>>, draft: string, draft_key: string, draft_sequence: int, fancy_title: string, featured_link: string, has_deleted: bool, has_summary: bool, highest_post_number: int, id: int, image_url: string, last_posted_at: string, like_count: int, message_bus_last_id: int, participant_count: int, pinned: bool, pinned_at: string, pinned_globally: bool, pinned_until: string, post_stream: record<posts: list<record>, stream: list<any>>, posts_count: int, reply_count: int, show_read_indicator: bool, slow_mode_enabled_until: string, slow_mode_seconds: int, slug: string, suggested_topics: table<archetype: string, archived: bool, bookmarked: string, bumped: bool, bumped_at: string, category_id: int, closed: bool, created_at: string, excerpt: string, fancy_title: string, featured_link: string, highest_post_number: int, id: int, image_url: string, last_posted_at: string, like_count: int, liked: string, pinned: bool, posters: list, posts_count: int, reply_count: int, slug: string, tags: list, tags_descriptions: record, title: string, unpinned: string, unseen: bool, views: int, visible: bool>, tags: list<any>, tags_descriptions: record, thumbnails: string, timeline_lookup: list<any>, title: string, topic_timer: string, unpinned: string, user_id: int, views: int, visible: bool, word_count: int>"
    update-topic-timestamp: "record<success: string>"
    invite-to-topic: "record<user: record<avatar_template: string, id: int, name: string, username: string>>"
    set-notification-level: "record<success: string>"
    get-specific-posts-from-topic: "record<id: int, post_stream: record<posts: list<record>>>"
    update-topic-status: "record<success: string, topic_status_update: string>"
    create-topic-timer: "record<based_on_last_post: bool, category_id: string, closed: bool, duration: string, execute_at: string, success: string>"
    get-tag: "record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, tags: list<record>, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>"
    list-tag-groups: "record<tag_groups: table<id: int, name: string, one_per_topic: bool, parent_tag_name: list, permissions: record, tag_names: list>>"
    create-tag-group: "record<tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record, tag_names: list<any>>>"
    get-tag-group: "record<tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record<everyone: int>, tag_names: list<any>>>"
    update-tag-group: "record<success: string, tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record<everyone: int>, tag_names: list<any>>>"
    list-tags: "record<extras: record<categories: list<any>>, tags: table<count: int, id: string, pm_count: int, target_tag: string, text: string>>"
    list-top-topics: "record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, for_period: string, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>"
    get-user-sent-private-messages: "record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>"
    list-user-private-messages: "record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>"
    get-user-external-id: "record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<\"1\": string, \"2\": string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>>"
    get-user-identiy-provider-external-id: "record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<\"1\": string, \"2\": string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>>"
    get-user: "record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<\"1\": string, \"2\": string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>>"
    update-user: "record<success: string, user: record>"
    get-user-emails: "record<associated_accounts: list<any>, email: string, secondary_emails: list<any>, unconfirmed_emails: list<any>>"
    update-avatar: "record<success: string>"
    create-upload: "record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int>"
    abort-multipart: "record<success: string>"
    batch-presign-multipart-parts: "record<presigned_urls: record>"
    complete-external-upload: "record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int>"
    complete-multipart: "record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int>"
    create-multipart-upload: "record<external_upload_identifier: string, key: string, unique_identifier: string>"
    generate-presigned-put: "record<key: string, unique_identifier: string, url: string>"
    list-user-badges: "record<badge_types: table<id: int, name: string, sort_order: int>, badges: table<allow_title: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, manually_grantable: bool, multiple_grant: bool, name: string, slug: string, system: bool>, granted_bies: table<admin: bool, avatar_template: string, flair_name: string, id: int, moderator: bool, name: string, trust_level: int, username: string>, user_badges: table<badge_id: int, can_favorite: bool, granted_at: string, granted_by_id: int, grouping_position: int, id: int, is_favorite: string>>"
    list-user-actions: "record<user_actions: table<acting_avatar_template: string, acting_name: string, acting_user_id: int, acting_username: string, action_code: string, action_type: int, archived: bool, avatar_template: string, category_id: int, closed: bool, created_at: string, deleted: bool, excerpt: string, hidden: string, name: string, post_id: string, post_number: int, post_type: string, slug: string, target_name: string, target_user_id: int, target_username: string, title: string, topic_id: int, user_id: int, username: string>>"
    refresh-gravatar: "record<gravatar_avatar_template: string, gravatar_upload_id: int>"
    create-user: "record<active: bool, message: string, success: bool, user_id: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-backups" "create-backup" "download-backup" "send-download-backup-email" "admin-list-badges" "create-badge" "delete-badge" "update-badge" "create-group" "delete-group" "admin-list-users" "delete-user" "admin-get-user" "anonymize-user" "log-out-user" "silence-user" "suspend-user" "get-category" "list-category-topics" "list-categories" "create-category" "update-category" "list-users-public" "list-groups" "get-group" "update-group" "remove-group-members" "list-group-members" "add-group-members" "create-invite" "list-latest-topics" "get-notifications" "mark-notifications-as-read" "perform-post-action" "list-posts" "create-topic-post-pm" "delete-post" "get-post" "update-post" "lock-post" "post-replies" "search" "send-password-reset-email" "get-site" "update-topic" "get-topic-by-external-id" "remove-topic" "get-topic" "bookmark-topic" "update-topic-timestamp" "invite-to-topic" "set-notification-level" "get-specific-posts-from-topic" "update-topic-status" "create-topic-timer" "get-tag" "list-tag-groups" "create-tag-group" "get-tag-group" "update-tag-group" "list-tags" "list-top-topics" "get-user-sent-private-messages" "list-user-private-messages" "get-user-external-id" "get-user-identiy-provider-external-id" "get-user" "update-user" "get-user-emails" "update-avatar" "update-email" "update-username" "create-upload" "abort-multipart" "batch-presign-multipart-parts" "complete-external-upload" "complete-multipart" "create-multipart-upload" "generate-presigned-put" "list-user-badges" "list-user-actions" "refresh-gravatar" "create-user" "change-password" "commands"] | sort) } | get name | first)
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

# List backups
#
# GET /admin/backups.json
# Returns: table<filename: string, last_modified: string, size: int>
# operationId: getBackups
export def "get-backups" [
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
    path: "/admin/backups.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create backup
#
# POST /admin/backups.json
# Returns: record<success: string>
# operationId: createBackup
export def "create-backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-uploads: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/backups.json"
    body: {content_type: "application/json", kind: json, fields: [{name: with_uploads, var: with_uploads, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    with_uploads: $with_uploads
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download backup
#
# GET /admin/backups/{filename}
# operationId: downloadBackup
export def "download-backup" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # required (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/admin/backups/{filename}"
    path_params: [{name: filename, var: filename}]
    query: [{name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filename: $filename, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send download backup email
#
# PUT /admin/backups/{filename}
# operationId: sendDownloadBackupEmail
export def "send-download-backup-email" [
  filename: string
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
    path: "/admin/backups/{filename}"
    path_params: [{name: filename, var: filename}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    filename: $filename
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List badges
#
# GET /admin/badges.json
# Returns: record<admin_badges: record<badge_grouping_ids: list<any>, badge_ids: list<any>, badge_type_ids: list<any>, protected_system_fields: list<any>, triggers: record<none: int, post_action: int, post_revision: int, trust_level_change: int, user_change: int>>, badge_groupings: table<description: string, id: int, name: string, position: int, system: bool>, badge_types: table<id: int, name: string, sort_order: int>, badges: table<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, i18n_name: string, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: int>>
# operationId: adminListBadges
export def "admin-list-badges" [
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
    path: "/admin/badges.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create badge
#
# POST /admin/badges.json
# Returns: record<badge: record<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: string>, badge_types: table<id: int, name: string, sort_order: int>>
# operationId: createBadge
export def "create-badge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  badge_type_id: int # The ID for the badge type. 1 for Gold, 2 for Silver, 3 for Bronze.
  name: string # The name for the new badge.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/badges.json"
    body: {content_type: "application/json", kind: json, fields: [{name: badge_type_id, var: badge_type_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    badge_type_id: $badge_type_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete badge
#
# DELETE /admin/badges/{id}.json
# operationId: deleteBadge
export def "delete-badge" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/admin/badges/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update badge
#
# PUT /admin/badges/{id}.json
# Returns: record<badge: record<allow_title: bool, auto_revoke: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, long_description: string, manually_grantable: bool, multiple_grant: bool, name: string, query: string, show_posts: bool, slug: string, system: bool, target_posts: bool, trigger: string>, badge_types: table<id: int, name: string, sort_order: int>>
# operationId: updateBadge
export def "update-badge" [
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
  badge_type_id: int # The ID for the badge type. 1 for Gold, 2 for Silver, 3 for Bronze.
  name: string # The name for the new badge.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/badges/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: badge_type_id, var: badge_type_id}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, badge_type_id: $badge_type_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a group
#
# POST /admin/groups.json
# Returns: record<basic_group: record<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>>
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
  group: record # shape: {automatic_membership_email_domains?: string, bio_raw?: string, default_notification_level?: int, flair_bg_color?: string, flair_icon?: string, flair_upload_id?: int, full_name?: string, muted_category_ids?: list<int>, name: string, owner_usernames?: string, primary_group?: bool, public_admission?: bool, public_exit?: bool, regular_category_ids?: list<int>, tracking_category_ids?: list<int>, usernames?: string, visibility_level?: int, watching_category_ids?: list<int>, ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/groups.json"
    body: {content_type: "application/json", kind: json, fields: [{name: group, var: group}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a group
#
# DELETE /admin/groups/{id}.json
# Returns: record<success: string>
# operationId: deleteGroup
export def "delete-group" [
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
    path: "/admin/groups/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of users
#
# GET /admin/users/list/{flag}.json
# Returns: table<active: bool, admin: bool, avatar_template: string, created_at: string, created_at_age: float, days_visited: int, email: string, flag_level: int, id: int, last_emailed_age: float, last_emailed_at: string, last_seen_age: float, last_seen_at: string, manual_locked_trust_level: string, moderator: bool, name: string, post_count: int, posts_read_count: int, secondary_emails: list<any>, staged: bool, time_read: int, title: string, topics_entered: int, trust_level: int, username: string>
# operationId: adminListUsers
export def "admin-list-users" [
  flag: string@flag-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer
  --asc: string@asc-completer
  --page: int
  --show-emails: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/admin/users/list/{flag}.json"
    path_params: [{name: flag, var: flag}]
    query: [{name: order, var: order}, {name: asc, var: asc}, {name: page, var: page}, {name: show_emails, var: show_emails}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    flag: $flag, order: $order, asc: $asc, page: $page, show_emails: $show_emails
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user
#
# DELETE /admin/users/{id}.json
# Returns: record<deleted: bool>
# operationId: deleteUser
export def "delete-user" [
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
  --block-email: oneof<nothing, bool>
  --block-ip: oneof<nothing, bool>
  --block-urls: oneof<nothing, bool>
  --delete-posts: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/admin/users/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: block_email, var: block_email}, {name: block_ip, var: block_ip}, {name: block_urls, var: block_urls}, {name: delete_posts, var: delete_posts}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, block_email: $block_email, block_ip: $block_ip, block_urls: $block_urls, delete_posts: $delete_posts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user by id
#
# GET /admin/users/{id}.json
# Returns: record<active: bool, admin: bool, api_key_count: int, approved_by: record<avatar_template: string, id: int, name: string, username: string>, associated_accounts: list<any>, avatar_template: string, badge_count: int, bounce_score: int, can_activate: bool, can_be_anonymized: bool, can_be_deleted: bool, can_be_merged: bool, can_deactivate: bool, can_delete_all_posts: bool, can_delete_sso_record: bool, can_disable_second_factor: bool, can_grant_admin: bool, can_grant_moderation: bool, can_impersonate: bool, can_revoke_admin: bool, can_revoke_moderation: bool, can_send_activation_email: bool, can_view_action_logs: bool, created_at: string, created_at_age: float, days_visited: int, external_ids: record, flag_level: int, flags_given_count: int, flags_received_count: int, full_suspend_reason: string, groups: table<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_see_members: bool, default_notification_level: int, display_name: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>, id: int, ip_address: string, last_emailed_age: float, last_emailed_at: string, last_seen_age: float, last_seen_at: string, like_count: int, like_given_count: int, manual_locked_trust_level: string, moderator: bool, name: string, next_penalty: string, penalty_counts: record<silenced: int, suspended: int>, post_count: int, post_edits_count: int, posts_read_count: int, primary_group_id: string, private_topics_count: int, registration_ip_address: string, reset_bounce_score_after: string, silence_reason: string, silenced_by: string, single_sign_on_record: string, staged: bool, suspended_by: string, time_read: int, title: string, tl3_requirements: record<days_visited: int, max_flagged_by_users: int, max_flagged_posts: int, min_days_visited: int, min_likes_given: int, min_likes_received: int, min_likes_received_days: int, min_likes_received_users: int, min_posts_read: int, min_posts_read_all_time: int, min_topics_replied_to: int, min_topics_viewed: int, min_topics_viewed_all_time: int, num_flagged_by_users: int, num_flagged_posts: int, num_likes_given: int, num_likes_received: int, num_likes_received_days: int, num_likes_received_users: int, num_topics_replied_to: int, on_grace_period: bool, penalty_counts: record<silenced: int, suspended: int, total: int>, posts_read: int, posts_read_all_time: int, requirements_lost: bool, requirements_met: bool, time_period: int, topics_viewed: int, topics_viewed_all_time: int, trust_level_locked: bool>, topic_count: int, topics_entered: int, trust_level: int, username: string, warnings_received_count: int>
# operationId: adminGetUser
export def "admin-get-user" [
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
    path: "/admin/users/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Anonymize a user
#
# PUT /admin/users/{id}/anonymize.json
# Returns: record<success: string, username: string>
# operationId: anonymizeUser
export def "anonymize-user" [
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
    method: put
    path: "/admin/users/{id}/anonymize.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Log a user out
#
# POST /admin/users/{id}/log_out.json
# Returns: record<success: string>
# operationId: logOutUser
export def "log-out-user" [
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
    method: post
    path: "/admin/users/{id}/log_out.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Silence a user
#
# PUT /admin/users/{id}/silence.json
# Returns: record<silence: record<silence_reason: string, silenced: bool, silenced_at: string, silenced_by: record<avatar_template: string, id: int, name: string, username: string>, silenced_till: string>>
# operationId: silenceUser
export def "silence-user" [
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
  --message: string # Will send an email with this message when present
  --post-action: string
  --reason: string
  --silenced-till: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/users/{id}/silence.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: post_action, var: post_action}, {name: reason, var: reason}, {name: silenced_till, var: silenced_till}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, message: $message, post_action: $post_action, reason: $reason, silenced_till: $silenced_till
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspend a user
#
# PUT /admin/users/{id}/suspend.json
# Returns: record<suspension: record<full_suspend_reason: string, suspend_reason: string, suspended_at: string, suspended_by: record<avatar_template: string, id: int, name: string, username: string>, suspended_till: string>>
# operationId: suspendUser
export def "suspend-user" [
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
  --message: string # Will send an email with this message when present
  --post-action: string
  reason: string
  suspend_until: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/admin/users/{id}/suspend.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: message, var: message}, {name: post_action, var: post_action}, {name: reason, var: reason}, {name: suspend_until, var: suspend_until}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, message: $message, post_action: $post_action, reason: $reason, suspend_until: $suspend_until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show category
#
# GET /c/{id}/show.json
# Returns: record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>>
# operationId: getCategory
export def "get-category" [
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
    path: "/c/{id}/show.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List topics
#
# GET /c/{slug}/{id}.json
# Returns: record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, per_page: int, top_tags: list<any>, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>
# operationId: listCategoryTopics
export def "list-category-topics" [
  slug: string
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
    path: "/c/{slug}/{id}.json"
    path_params: [{name: slug, var: slug}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    slug: $slug, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of categories
#
# GET /categories.json
# Returns: record<category_list: record<can_create_category: bool, can_create_topic: bool, categories: list<record>>>
# operationId: listCategories
export def "list-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-subcategories: oneof<nothing, bool>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/categories.json"
    query: [{name: include_subcategories, var: include_subcategories}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    include_subcategories: $include_subcategories
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a category
#
# POST /categories.json
# Returns: record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>>
# operationId: createCategory
export def "create-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-badges: oneof<nothing, bool>
  --color: string
  --form-template-ids: list
  name: string
  --parent-category-id: int
  --permissions: record # shape: {everyone?: int, staff?: int}
  --search-priority: int
  --slug: string
  --text-color: string
  --topic-featured-links-allowed: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/categories.json"
    body: {content_type: "application/json", kind: json, fields: [{name: allow_badges, var: allow_badges}, {name: color, var: color}, {name: form_template_ids, var: form_template_ids}, {name: name, var: name}, {name: parent_category_id, var: parent_category_id}, {name: permissions, var: permissions}, {name: search_priority, var: search_priority}, {name: slug, var: slug}, {name: text_color, var: text_color}, {name: topic_featured_links_allowed, var: topic_featured_links_allowed}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_badges: $allow_badges, color: $color, form_template_ids: $form_template_ids, name: $name, parent_category_id: $parent_category_id, permissions: $permissions, search_priority: $search_priority, slug: $slug, text_color: $text_color, topic_featured_links_allowed: $topic_featured_links_allowed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a category
#
# PUT /categories/{id}.json
# Returns: record<category: record<all_topics_wiki: bool, allow_badges: bool, allow_global_tags: bool, allow_unlimited_owner_edits_on_first_post: bool, allowed_tag_groups: list<any>, allowed_tags: list<any>, auto_close_based_on_last_post: bool, auto_close_hours: string, available_groups: list<any>, can_delete: bool, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_slow_mode_seconds: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, email_in: string, email_in_allow_strangers: bool, form_template_ids: list<any>, group_permissions: list<record>, has_children: string, id: int, mailinglist_mirror: bool, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, permission: string, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list<record>, search_priority: int, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_featured_link_allowed: bool, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>, success: string>
# operationId: updateCategory
export def "update-category" [
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
  --allow-badges: oneof<nothing, bool>
  --color: string
  --form-template-ids: list
  name: string
  --parent-category-id: int
  --permissions: record # shape: {everyone?: int, staff?: int}
  --search-priority: int
  --slug: string
  --text-color: string
  --topic-featured-links-allowed: oneof<nothing, bool>
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/categories/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: allow_badges, var: allow_badges}, {name: color, var: color}, {name: form_template_ids, var: form_template_ids}, {name: name, var: name}, {name: parent_category_id, var: parent_category_id}, {name: permissions, var: permissions}, {name: search_priority, var: search_priority}, {name: slug, var: slug}, {name: text_color, var: text_color}, {name: topic_featured_links_allowed, var: topic_featured_links_allowed}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, allow_badges: $allow_badges, color: $color, form_template_ids: $form_template_ids, name: $name, parent_category_id: $parent_category_id, permissions: $permissions, search_priority: $search_priority, slug: $slug, text_color: $text_color, topic_featured_links_allowed: $topic_featured_links_allowed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a public list of users
#
# GET /directory_items.json
# Returns: record<directory_items: table<days_visited: int, id: int, likes_given: int, likes_received: int, post_count: int, posts_read: int, topic_count: int, topics_entered: int, user: record>, meta: record<last_updated_at: string, load_more_directory_items: string, total_rows_directory_items: int>>
# operationId: listUsersPublic
export def "list-users-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # required
  --order: string@order-completer-1 # required
  --asc: string@asc-completer
  --page: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/directory_items.json"
    query: [{name: period, var: period, required: true}, {name: order, var: order, required: true}, {name: asc, var: asc}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, order: $order, asc: $asc, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List groups
#
# GET /groups.json
# Returns: record<extras: record<type_filters: list<any>>, groups: table<allow_membership_requests: bool, automatic: bool, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, display_name: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, incoming_email: string, is_group_owner: bool, is_group_user: bool, members_visibility_level: int, membership_request_template: string, mentionable_level: int, messageable_level: int, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, title: string, user_count: int, visibility_level: int>, load_more_groups: string, total_rows_groups: int>
# operationId: listGroups
export def "list-groups" [
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
    path: "/groups.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a group
#
# GET /groups/{id}.json
# Returns: record<extras: record<visible_group_names: list<any>>, group: record<allow_membership_requests: bool, allow_unknown_sender_topic_replies: bool, associated_group_ids: list<any>, automatic: bool, automatic_membership_email_domains: string, bio_cooked: string, bio_excerpt: string, bio_raw: string, can_admin_group: bool, can_edit_group: bool, can_see_members: bool, default_notification_level: int, email_from_alias: string, email_password: string, email_username: string, flair_bg_color: string, flair_color: string, flair_url: string, full_name: string, grant_trust_level: string, has_messages: bool, id: int, imap_enabled: bool, imap_last_error: string, imap_mailbox_name: string, imap_mailboxes: list<any>, imap_new_emails: string, imap_old_emails: string, imap_port: string, imap_server: string, imap_ssl: string, imap_updated_at: string, imap_updated_by: record, incoming_email: string, is_group_owner_display: bool, is_group_user: bool, members_visibility_level: int, membership_request_template: string, mentionable: bool, mentionable_level: int, message_count: int, messageable: bool, messageable_level: int, muted_category_ids: list<any>, muted_tags: list<any>, name: string, primary_group: bool, public_admission: bool, public_exit: bool, publish_read_state: bool, regular_category_ids: list<any>, regular_tags: list<any>, smtp_enabled: bool, smtp_port: string, smtp_server: string, smtp_ssl: string, smtp_updated_at: string, smtp_updated_by: record, title: string, tracking_category_ids: list<any>, tracking_tags: list<any>, user_count: int, visibility_level: int, watching_category_ids: list<any>, watching_first_post_category_ids: list<any>, watching_first_post_tags: list<any>, watching_tags: list<any>>>
# operationId: getGroup
export def "get-group" [
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
    path: "/groups/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a group
#
# PUT /groups/{id}.json
# Returns: record<success: string>
# operationId: updateGroup
export def "update-group" [
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
  group: record # shape: {automatic_membership_email_domains?: string, bio_raw?: string, default_notification_level?: int, flair_bg_color?: string, flair_icon?: string, flair_upload_id?: int, full_name?: string, muted_category_ids?: list<int>, name: string, owner_usernames?: string, primary_group?: bool, public_admission?: bool, public_exit?: bool, regular_category_ids?: list<int>, tracking_category_ids?: list<int>, usernames?: string, visibility_level?: int, watching_category_ids?: list<int>, ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: group, var: group}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove group members
#
# DELETE /groups/{id}/members.json
# Returns: record<skipped_usernames: list<any>, success: string, usernames: list<any>>
# operationId: removeGroupMembers
export def "remove-group-members" [
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
  --usernames: string # comma separated list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: delete
    path: "/groups/{id}/members.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: usernames, var: usernames}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, usernames: $usernames
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List group members
#
# GET /groups/{id}/members.json
# Returns: record<members: table<added_at: string, avatar_template: string, id: int, last_posted_at: string, last_seen_at: string, name: string, timezone: string, title: string, username: string>, meta: record<limit: int, offset: int, total: int>, owners: table<added_at: string, avatar_template: string, id: int, last_posted_at: string, last_seen_at: string, name: string, timezone: string, title: string, username: string>>
# operationId: listGroupMembers
export def "list-group-members" [
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
    path: "/groups/{id}/members.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add group members
#
# PUT /groups/{id}/members.json
# Returns: record<emails: list<any>, success: string, usernames: list<any>>
# operationId: addGroupMembers
export def "add-group-members" [
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
  --usernames: string # comma separated list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/groups/{id}/members.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: usernames, var: usernames}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, usernames: $usernames
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an invite
#
# POST /invites.json
# Returns: record<created_at: string, custom_message: string, email: string, emailed: bool, expired: bool, expires_at: string, groups: list<any>, id: int, link: string, topics: list<any>, updated_at: string>
# operationId: createInvite
export def "create-invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --api-username: string # required
  --custom-message: string # optional, for email invites
  --email: string # required for email invites only
  --expires-at: string # optional, if not supplied, the invite_expiry_days site setting is used
  --group-id: int # optional, either this or `group_names`
  --group-names: string # optional, either this or `group_id`
  --max-redemptions-allowed: int # optional, for link invites (default: 1)
  --skip-email: oneof<nothing, bool> # default: false
  --topic-id: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/invites.json"
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: custom_message, var: custom_message}, {name: email, var: email}, {name: expires_at, var: expires_at}, {name: group_id, var: group_id}, {name: group_names, var: group_names}, {name: max_redemptions_allowed, var: max_redemptions_allowed}, {name: skip_email, var: skip_email}, {name: topic_id, var: topic_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, api_username: $api_username, custom_message: $custom_message, email: $email, expires_at: $expires_at, group_id: $group_id, group_names: $group_names, max_redemptions_allowed: $max_redemptions_allowed, skip_email: $skip_email, topic_id: $topic_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest topics
#
# GET /latest.json
# Returns: record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>
# operationId: listLatestTopics
export def "list-latest-topics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # Enum: `default`, `created`, `activity`, `views`, `posts`, `category`, `likes`, `op_likes`, `posters`
  --ascending: string # Defaults to `desc`, add `ascending=true` to sort asc
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/latest.json"
    query: [{name: order, var: order}, {name: ascending, var: ascending}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order: $order, ascending: $ascending, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the notifications that belong to the current user
#
# GET /notifications.json
# Returns: record<load_more_notifications: string, notifications: table<created_at: string, data: record, id: int, notification_type: int, post_number: string, read: bool, slug: string, topic_id: int, user_id: int>, seen_notification_id: int, total_rows_notifications: int>
# operationId: getNotifications
export def "get-notifications" [
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
    path: "/notifications.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark notifications as read
#
# PUT /notifications/mark-read.json
# Returns: record<success: string>
# operationId: markNotificationsAsRead
export def "mark-notifications-as-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # (optional) Leave off to mark all notifications as read
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/notifications/mark-read.json"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Like a post and other actions
#
# POST /post_actions.json
# Returns: record<actions_summary: table<acted: bool, can_undo: bool, count: int, id: int>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, notice: record, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>
# operationId: performPostAction
export def "perform-post-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --api-username: string # required
  --flag-topic: oneof<nothing, bool>
  id: int
  post_action_type_id: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/post_actions.json"
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: flag_topic, var: flag_topic}, {name: id, var: id}, {name: post_action_type_id, var: post_action_type_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, api_username: $api_username, flag_topic: $flag_topic, id: $id, post_action_type_id: $post_action_type_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List latest posts across topics
#
# GET /posts.json
# Returns: record<latest_posts: table<actions_summary: list, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, category_id: int, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_html_title: string, topic_id: int, topic_slug: string, topic_title: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>>
# operationId: listPosts
export def "list-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: string # Load posts with an id lower than this value. Useful for pagination.
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts.json"
    query: [{name: before, var: before}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    before: $before, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new topic, a new post, or a private message
#
# POST /posts.json
# Returns: record<actions_summary: table<can_act: bool, id: int>, admin: bool, avatar_template: string, bookmarked: bool, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, draft_sequence: int, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, mentioned_users: list<any>, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>
# operationId: createTopicPostPM
@deprecated --flag target-usernames
export def "create-topic-post-pm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --archetype: string # Required for new private message.
  --category: int # Optional if creating a new topic, and ignored if creating a new post.
  --created-at: string
  --embed-url: string # Provide a URL from a remote system to associate a forum topic with that URL, typically for using Discourse as a comments system for an external blog.
  --external-id: string # Provide an external_id from a remote system to associate a forum topic with that id.
  --body-raw: string # (spec name: raw)
  --target-recipients: string # Required for private message, comma separated.
  --target-usernames: string # Deprecated. Use target_recipients instead. (DEPRECATED)
  --title: string # Required if creating a new topic or new private message.
  --topic-id: int # Required if creating a new post.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/posts.json"
    body: {content_type: "application/json", kind: json, fields: [{name: archetype, var: archetype}, {name: category, var: category}, {name: created_at, var: created_at}, {name: embed_url, var: embed_url}, {name: external_id, var: external_id}, {name: raw, var: body_raw, required: true}, {name: target_recipients, var: target_recipients}, {name: target_usernames, var: target_usernames}, {name: title, var: title}, {name: topic_id, var: topic_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    archetype: $archetype, category: $category, created_at: $created_at, embed_url: $embed_url, external_id: $external_id, body_raw: $body_raw, target_recipients: $target_recipients, target_usernames: $target_usernames, title: $title, topic_id: $topic_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# delete a single post
#
# DELETE /posts/{id}.json
# operationId: deletePost
export def "delete-post" [
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
  --force-destroy: oneof<nothing, bool> # The `SiteSetting.can_permanently_delete` needs to be enabled first before this param can be used. Also this endpoint needs to be called first without `force_destroy` and then followed up with a second call 5 minutes later with `force_destroy` to permanently delete.
]: any -> any {
  $in | http-request {
    method: delete
    path: "/posts/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: force_destroy, var: force_destroy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, force_destroy: $force_destroy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a single post
#
# GET /posts/{id}.json
# Returns: record<actions_summary: table<can_act: bool, id: int>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, raw: string, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>
# operationId: getPost
export def "get-post" [
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
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts/{id}.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a single post
#
# PUT /posts/{id}.json
# Returns: record<post: record<actions_summary: list<record>, admin: bool, avatar_template: string, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, draft_sequence: int, edit_reason: string, flair_bg_color: string, flair_color: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: string, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: float, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>>
# operationId: updatePost
export def "update-post" [
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
  --api-key: string # required
  --api-username: string # required
  --post: record # shape: {edit_reason?: string, raw: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/posts/{id}.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: post, var: post}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username, post: $post
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lock a post from being edited
#
# PUT /posts/{id}/locked.json
# Returns: record<locked: bool>
# operationId: lockPost
export def "lock-post" [
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
  --api-key: string # required
  --api-username: string # required
  locked: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/posts/{id}/locked.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: locked, var: locked}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username, locked: $locked
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List replies to a post
#
# GET /posts/{id}/replies.json
# Returns: table<actions_summary: list<record>, admin: bool, avatar_template: string, bookmarked: bool, can_delete: bool, can_edit: bool, can_recover: bool, can_view_edit_history: bool, can_wiki: bool, cooked: string, created_at: string, deleted_at: string, display_username: string, edit_reason: string, flair_bg_color: string, flair_color: string, flair_name: string, flair_url: string, hidden: bool, id: int, incoming_link_count: int, moderator: bool, name: string, post_number: int, post_type: int, primary_group_name: string, quote_count: int, readers_count: int, reads: int, reply_count: int, reply_to_post_number: int, reply_to_user: record<avatar_template: string, name: string, username: string>, reviewable_id: string, reviewable_score_count: int, reviewable_score_pending_count: int, score: int, staff: bool, topic_id: int, topic_slug: string, trust_level: int, updated_at: string, user_deleted: bool, user_id: int, user_title: string, username: string, version: int, wiki: bool, yours: bool>
# operationId: postReplies
export def "post-replies" [
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
    path: "/posts/{id}/replies.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for a term
#
# GET /search.json
# Returns: record<categories: list<any>, grouped_search_result: record<can_create_topic: bool, category_ids: list<any>, error: string, group_ids: list<any>, more_categories: string, more_full_page_results: string, more_posts: string, more_users: string, post_ids: list<any>, search_log_id: int, tag_ids: list<any>, term: string, user_ids: list<any>>, groups: list<any>, posts: list<any>, tags: list<any>, users: list<any>>
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
  --q: string # The query string needs to be url encoded and is made up of the following options: - Search term. This is just a string. Usually it would be the first item in the query. - `@`: Use the `@` followed by the username to specify posts by this user. - `#`: Use the `#` followed by the category slug to search within this category. - `tags:`: `api,solved` or for posts that have all the specified tags `api+solved`. - `before:`: `yyyy-mm-dd` - `after:`: `yyyy-mm-dd` - `order:`: `latest`, `likes`, `views`, `latest_topic` - `assigned:`: username (without `@`) - `in:`: `title`, `likes`, `personal`, `messages`, `seen`, `unseen`, `posted`, `created`, `watching`, `tracking`, `bookmarks`, `assigned`, `unassigned`, `first`, `pinned`, `wiki` - `with:`: `images` - `status:`: `open`, `closed`, `public`, `archived`, `noreplies`, `single_user`, `solved`, `unsolved` - `group:`: group_name or group_id - `group_messages:`: group_name or group_id - `min_posts:`: 1 - `max_posts:`: 10 - `min_views:`: 1 - `max_views:`: 10 If you are using cURL you can use the `-G` and the `--data-urlencode` flags to encode the query: ``` curl -i -sS -X GET -G "http://localhost:4200/search.json" \ --data-urlencode 'q=wordpress @scossar #fun after:2020-01-01' ``` (e.g. api @blake #support tags:api after:2021-06-04 in:unseen in:open order:latest_topic)
  --page: int # e.g. 1
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search.json"
    query: [{name: q, var: q}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send password reset email
#
# POST /session/forgot_password.json
# Returns: record<success: string, user_found: bool>
# operationId: sendPasswordResetEmail
export def "send-password-reset-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  login: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/session/forgot_password.json"
    body: {content_type: "application/json", kind: json, fields: [{name: login, var: login}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    login: $login
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get site info
#
# GET /site.json
# Returns: record<anonymous_top_menu_items: list<any>, archetypes: table<id: string, name: string, options: list>, auth_providers: list<any>, can_associate_groups: bool, can_create_tag: bool, can_tag_pms: bool, can_tag_topics: bool, categories: table<allow_global_tags: bool, allowed_tag_groups: list, allowed_tags: list, can_edit: bool, color: string, custom_fields: record, default_list_filter: string, default_top_period: string, default_view: string, description: string, description_excerpt: string, description_text: string, form_template_ids: list, has_children: bool, id: int, minimum_required_tags: int, name: string, navigate_to_first_post_after_read: bool, notification_level: int, num_featured_topics: int, parent_category_id: int, permission: int, position: int, post_count: int, read_only_banner: string, read_restricted: bool, required_tag_groups: list, show_subcategory_list: bool, slug: string, sort_ascending: string, sort_order: string, subcategory_list_style: string, text_color: string, topic_count: int, topic_template: string, topic_url: string, uploaded_background: string, uploaded_logo: string, uploaded_logo_dark: string>, censored_regexp: list<record>, custom_emoji_translation: record, default_archetype: string, default_dark_color_scheme: record, displayed_about_plugin_stat_groups: list<any>, filters: list<any>, groups: table<flair_bg_color: string, flair_color: string, flair_url: string, id: int, name: string>, hashtag_configurations: record, hashtag_icons: list<any>, markdown_additional_options: record, notification_types: record<assigned: int, bookmark_reminder: int, chat_group_mention: int, chat_invitation: int, chat_mention: int, chat_message: int, chat_quoted: int, circles_activity: int, code_review_commit_approved: int, custom: int, edited: int, event_invitation: int, event_reminder: int, following: int, following_created_topic: int, following_replied: int, granted_badge: int, group_mentioned: int, group_message_summary: int, invited_to_private_message: int, invited_to_topic: int, invitee_accepted: int, liked: int, liked_consolidated: int, linked: int, membership_request_accepted: int, membership_request_consolidated: int, mentioned: int, moved_post: int, new_features: int, post_approved: int, posted: int, private_message: int, question_answer_user_commented: int, quoted: int, reaction: int, replied: int, topic_reminder: int, votes_released: int, watching_category_or_tag: int, watching_first_post: int>, periods: list<any>, post_action_types: table<description: string, id: int, is_custom_flag: bool, is_flag: bool, name: string, name_key: string, short_description: string>, post_types: record<moderator_action: int, regular: int, small_action: int, whisper: int>, show_welcome_topic_banner: bool, tags_filter_regexp: string, top_menu_items: list<any>, top_tags: list<any>, topic_featured_link_allowed_category_ids: list<any>, topic_flag_types: table<description: string, id: int, is_custom_flag: bool, is_flag: bool, name: string, name_key: string, short_description: string>, trust_levels: record<basic: int, leader: int, member: int, newuser: int, regular: int>, uncategorized_category_id: int, user_color_schemes: table<id: int, is_dark: bool, name: string>, user_field_max_length: int, user_fields: list<any>, user_themes: table<color_scheme_id: int, default: bool, name: string, theme_id: int>, watched_words_link: string, watched_words_replace: string, whispers_allowed_groups_names: list<any>, wizard_required: bool>
# operationId: getSite
export def "get-site" [
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
    path: "/site.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a topic
#
# PUT /t/-/{id}.json
# Returns: record<basic_topic: record<fancy_title: string, id: int, posts_count: int, slug: string, title: string>>
# operationId: updateTopic
export def "update-topic" [
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
  --api-key: string # required
  --api-username: string # required
  --topic: record # shape: {category_id?: int, title?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/t/-/{id}.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: topic, var: topic}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username, topic: $topic
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get topic by external_id
#
# GET /t/external_id/{external_id}.json
# operationId: getTopicByExternalId
export def "get-topic-by-external-id" [
  external_id: string
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
    path: "/t/external_id/{external_id}.json"
    path_params: [{name: external_id, var: external_id}]
    accept: ["application/json"]
    ok: [301]
    auth: bearer
  } {
    external_id: $external_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a topic
#
# DELETE /t/{id}.json
# operationId: removeTopic
export def "remove-topic" [
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
  --api-key: string # required
  --api-username: string # required
]: nothing -> any {
  http-request {
    method: delete
    path: "/t/{id}.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single topic
#
# GET /t/{id}.json
# Returns: record<actions_summary: table<can_act: bool, count: int, hidden: bool, id: int>, archetype: string, archived: bool, bookmarked: bool, bookmarks: list<any>, category_id: int, chunk_size: int, closed: bool, created_at: string, current_post_number: int, deleted_at: string, deleted_by: string, details: record<can_archive_topic: bool, can_close_topic: bool, can_convert_topic: bool, can_create_post: bool, can_delete: bool, can_edit: bool, can_edit_staff_notes: bool, can_flag_topic: bool, can_invite_to: bool, can_invite_via_email: bool, can_moderate_category: bool, can_move_posts: bool, can_pin_unpin_topic: bool, can_remove_allowed_users: bool, can_remove_self_id: int, can_reply_as_new_topic: bool, can_review_topic: bool, can_split_merge_topic: bool, can_toggle_topic_visibility: bool, created_by: record<avatar_template: string, id: int, name: string, username: string>, last_poster: record<avatar_template: string, id: int, name: string, username: string>, notification_level: int, participants: list<record>>, draft: string, draft_key: string, draft_sequence: int, fancy_title: string, featured_link: string, has_deleted: bool, has_summary: bool, highest_post_number: int, id: int, image_url: string, last_posted_at: string, like_count: int, message_bus_last_id: int, participant_count: int, pinned: bool, pinned_at: string, pinned_globally: bool, pinned_until: string, post_stream: record<posts: list<record>, stream: list<any>>, posts_count: int, reply_count: int, show_read_indicator: bool, slow_mode_enabled_until: string, slow_mode_seconds: int, slug: string, suggested_topics: table<archetype: string, archived: bool, bookmarked: string, bumped: bool, bumped_at: string, category_id: int, closed: bool, created_at: string, excerpt: string, fancy_title: string, featured_link: string, highest_post_number: int, id: int, image_url: string, last_posted_at: string, like_count: int, liked: string, pinned: bool, posters: list, posts_count: int, reply_count: int, slug: string, tags: list, tags_descriptions: record, title: string, unpinned: string, unseen: bool, views: int, visible: bool>, tags: list<any>, tags_descriptions: record, thumbnails: string, timeline_lookup: list<any>, title: string, topic_timer: string, unpinned: string, user_id: int, views: int, visible: bool, word_count: int>
# operationId: getTopic
export def "get-topic" [
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
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/t/{id}.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bookmark topic
#
# PUT /t/{id}/bookmark.json
# operationId: bookmarkTopic
export def "bookmark-topic" [
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
  --api-key: string # required
  --api-username: string # required
]: nothing -> any {
  http-request {
    method: put
    path: "/t/{id}/bookmark.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update topic timestamp
#
# PUT /t/{id}/change-timestamp.json
# Returns: record<success: string>
# operationId: updateTopicTimestamp
export def "update-topic-timestamp" [
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
  --api-key: string # required
  --api-username: string # required
  timestamp: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/t/{id}/change-timestamp.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite to topic
#
# POST /t/{id}/invite.json
# Returns: record<user: record<avatar_template: string, id: int, name: string, username: string>>
# operationId: inviteToTopic
export def "invite-to-topic" [
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
  --api-key: string # required
  --api-username: string # required
  --email: string
  --user: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/t/{id}/invite.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: user, var: user}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username, email: $email, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set notification level
#
# POST /t/{id}/notifications.json
# Returns: record<success: string>
# operationId: setNotificationLevel
export def "set-notification-level" [
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
  --api-key: string # required
  --api-username: string # required
  notification_level: string@notification-level-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/t/{id}/notifications.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: notification_level, var: notification_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username, notification_level: $notification_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get specific posts from a topic
#
# GET /t/{id}/posts.json
# Returns: record<id: int, post_stream: record<posts: list<record>>>
# operationId: getSpecificPostsFromTopic
export def "get-specific-posts-from-topic" [
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
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/t/{id}/posts.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the status of a topic
#
# PUT /t/{id}/status.json
# Returns: record<success: string, topic_status_update: string>
# operationId: updateTopicStatus
export def "update-topic-status" [
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
  --api-key: string # required
  --api-username: string # required
  enabled: string@enabled-completer
  status: string@status-completer
  --until: string # Only required for `pinned` and `pinned_globally`
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/t/{id}/status.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: status, var: status}, {name: until, var: until}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username, enabled: $enabled, status: $status, until: $until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create topic timer
#
# POST /t/{id}/timer.json
# Returns: record<based_on_last_post: bool, category_id: string, closed: bool, duration: string, execute_at: string, success: string>
# operationId: createTopicTimer
export def "create-topic-timer" [
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
  --api-key: string # required
  --api-username: string # required
  --based-on-last-post: oneof<nothing, bool>
  --category-id: int
  --status-type: string
  --time: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/t/{id}/timer.json"
    path_params: [{name: id, var: id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: based_on_last_post, var: based_on_last_post}, {name: category_id, var: category_id}, {name: status_type, var: status_type}, {name: time, var: time}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, api_key: $api_key, api_username: $api_username, based_on_last_post: $based_on_last_post, category_id: $category_id, status_type: $status_type, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific tag
#
# GET /tag/{name}.json
# Returns: record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, tags: list<record>, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>
# operationId: getTag
export def "get-tag" [
  name: string
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
    path: "/tag/{name}.json"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of tag groups
#
# GET /tag_groups.json
# Returns: record<tag_groups: table<id: int, name: string, one_per_topic: bool, parent_tag_name: list, permissions: record, tag_names: list>>
# operationId: listTagGroups
export def "list-tag-groups" [
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
    path: "/tag_groups.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a tag group
#
# POST /tag_groups.json
# Returns: record<tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record, tag_names: list<any>>>
# operationId: createTagGroup
export def "create-tag-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tag_groups.json"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single tag group
#
# GET /tag_groups/{id}.json
# Returns: record<tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record<everyone: int>, tag_names: list<any>>>
# operationId: getTagGroup
export def "get-tag-group" [
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
    path: "/tag_groups/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update tag group
#
# PUT /tag_groups/{id}.json
# Returns: record<success: string, tag_group: record<id: int, name: string, one_per_topic: bool, parent_tag_name: list<any>, permissions: record<everyone: int>, tag_names: list<any>>>
# operationId: updateTagGroup
export def "update-tag-group" [
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
  --name: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tag_groups/{id}.json"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of tags
#
# GET /tags.json
# Returns: record<extras: record<categories: list<any>>, tags: table<count: int, id: string, pm_count: int, target_tag: string, text: string>>
# operationId: listTags
export def "list-tags" [
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
    path: "/tags.json"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the top topics filtered by period
#
# GET /top.json
# Returns: record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, for_period: string, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>
# operationId: listTopTopics
export def "list-top-topics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string # Enum: `all`, `yearly`, `quarterly`, `monthly`, `weekly`, `daily`
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/top.json"
    query: [{name: period, var: period}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    period: $period, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of private messages sent for a user
#
# GET /topics/private-messages-sent/{username}.json
# Returns: record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>
# operationId: getUserSentPrivateMessages
export def "get-user-sent-private-messages" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/topics/private-messages-sent/{username}.json"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of private messages for a user
#
# GET /topics/private-messages/{username}.json
# Returns: record<primary_groups: list<any>, topic_list: record<can_create_topic: bool, draft: string, draft_key: string, draft_sequence: int, per_page: int, topics: list<record>>, users: table<avatar_template: string, id: int, name: string, username: string>>
# operationId: listUserPrivateMessages
export def "list-user-private-messages" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/topics/private-messages/{username}.json"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user by external_id
#
# GET /u/by-external/{external_id}.json
# Returns: record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<"1": string, "2": string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>>
# operationId: getUserExternalId
export def "get-user-external-id" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/u/by-external/{external_id}.json"
    path_params: [{name: external_id, var: external_id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_id: $external_id, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user by identity provider external ID
#
# GET /u/by-external/{provider}/{external_id}.json
# Returns: record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<"1": string, "2": string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>>
# operationId: getUserIdentiyProviderExternalId
export def "get-user-identiy-provider-external-id" [
  provider: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/u/by-external/{provider}/{external_id}.json"
    path_params: [{name: provider, var: provider}, {name: external_id, var: external_id}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    provider: $provider, external_id: $external_id, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single user by username
#
# GET /u/{username}.json
# Returns: record<user: record<admin: bool, allowed_pm_usernames: list<any>, avatar_template: string, badge_count: int, can_be_deleted: bool, can_change_bio: bool, can_change_location: bool, can_change_tracking_preferences: bool, can_change_website: bool, can_delete_all_posts: bool, can_edit: bool, can_edit_email: bool, can_edit_name: bool, can_edit_username: bool, can_ignore_user: bool, can_mute_user: bool, can_send_private_message_to_user: bool, can_send_private_messages: bool, can_upload_profile_header: bool, can_upload_user_card_background: bool, created_at: string, custom_fields: record<first_name: string>, featured_topic: string, featured_user_badge_ids: list<any>, flair_bg_color: string, flair_color: string, flair_group_id: string, flair_name: string, flair_url: string, group_users: list<record>, groups: list<record>, has_title_badges: bool, id: int, ignored: bool, ignored_usernames: list<any>, invited_by: string, last_posted_at: string, last_seen_at: string, locale: string, mailing_list_posts_per_day: int, moderator: bool, muted: bool, muted_category_ids: list<any>, muted_tags: list<any>, muted_usernames: list<any>, name: string, pending_count: int, pending_posts_count: int, post_count: int, primary_group_id: string, primary_group_name: string, profile_view_count: int, recent_time_read: int, regular_category_ids: list<any>, second_factor_backup_enabled: bool, second_factor_enabled: bool, staged: bool, system_avatar_template: string, system_avatar_upload_id: string, time_read: int, title: string, tracked_category_ids: list<any>, tracked_tags: list<any>, trust_level: int, uploaded_avatar_id: string, use_logo_small_as_avatar: bool, user_api_keys: string, user_auth_tokens: list<record>, user_fields: record<"1": string, "2": string>, user_notification_schedule: record<day_0_end_time: int, day_0_start_time: int, day_1_end_time: int, day_1_start_time: int, day_2_end_time: int, day_2_start_time: int, day_3_end_time: int, day_3_start_time: int, day_4_end_time: int, day_4_start_time: int, day_5_end_time: int, day_5_start_time: int, day_6_end_time: int, day_6_start_time: int, enabled: bool>, user_option: record<allow_private_messages: bool, auto_track_topics_after_msecs: int, automatically_unpin_topics: bool, bookmark_auto_delete_preference: int, color_scheme_id: string, dark_scheme_id: string, default_calendar: string, digest_after_minutes: int, dynamic_favicon: bool, email_digests: bool, email_in_reply_to: bool, email_level: int, email_messages_level: int, email_previous_replies: int, enable_allowed_pm_users: bool, enable_defer: bool, enable_quoting: bool, external_links_in_new_tab: bool, hide_profile_and_presence: bool, homepage_id: string, include_tl0_in_digests: bool, like_notification_frequency: int, mailing_list_mode: bool, mailing_list_mode_frequency: int, new_topic_duration_minutes: int, notification_level_when_replying: int, oldest_search_log_date: string, seen_popups: list, sidebar_list_destination: string, skip_new_user_tips: bool, text_size: string, text_size_seq: int, theme_ids: list, theme_key_seq: int, timezone: string, title_count_mode: string, user_id: int>, username: string, watched_category_ids: list<any>, watched_first_post_category_ids: list<any>, watched_tags: list<any>, watching_first_post_tags: list<any>>, user_badges: list<any>>
# operationId: getUser
export def "get-user" [
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
  --api-key: string # required
  --api-username: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/u/{username}.json"
    path_params: [{name: username, var: username}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, api_key: $api_key, api_username: $api_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user
#
# PUT /u/{username}.json
# Returns: record<success: string, user: record>
# operationId: updateUser
export def "update-user" [
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
  --api-key: string # required
  --api-username: string # required
  --email: string
  --external-ids: record
  --name: string
  --password: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/u/{username}.json"
    path_params: [{name: username, var: username}]
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: external_ids, var: external_ids}, {name: name, var: name}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, api_key: $api_key, api_username: $api_username, email: $email, external_ids: $external_ids, name: $name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get email addresses belonging to a user
#
# GET /u/{username}/emails.json
# Returns: record<associated_accounts: list<any>, email: string, secondary_emails: list<any>, unconfirmed_emails: list<any>>
# operationId: getUserEmails
export def "get-user-emails" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/u/{username}/emails.json"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update avatar
#
# PUT /u/{username}/preferences/avatar/pick.json
# Returns: record<success: string>
# operationId: updateAvatar
export def "update-avatar" [
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
  type: string@type-completer
  upload_id: int
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/u/{username}/preferences/avatar/pick.json"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}, {name: upload_id, var: upload_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, type: $type, upload_id: $upload_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update email
#
# PUT /u/{username}/preferences/email.json
# operationId: updateEmail
export def "update-email" [
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
  email: string # format: email
]: any -> any {
  $in | http-request {
    method: put
    path: "/u/{username}/preferences/email.json"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update username
#
# PUT /u/{username}/preferences/username.json
# operationId: updateUsername
export def "update-username" [
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
  new_username: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/u/{username}/preferences/username.json"
    path_params: [{name: username, var: username}]
    body: {content_type: "application/json", kind: json, fields: [{name: new_username, var: new_username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, new_username: $new_username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an upload
#
# POST /uploads.json
# Returns: record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int>
# operationId: createUpload
export def "create-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --synchronous: oneof<nothing, bool> # Use this flag to return an id and url
  type: string@type-completer-1
  --user-id: int # required if uploading an avatar
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploads.json"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: synchronous, var: synchronous}, {name: type, var: type}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    synchronous: $synchronous, type: $type, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Abort multipart upload
#
# POST /uploads/abort-multipart.json
# Returns: record<success: string>
# operationId: abortMultipart
export def "abort-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  external_upload_identifier: string # The identifier of the multipart upload in the external storage provider. This is the multipart upload_id in AWS S3.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploads/abort-multipart.json"
    body: {content_type: "application/json", kind: json, fields: [{name: external_upload_identifier, var: external_upload_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    external_upload_identifier: $external_upload_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates batches of presigned URLs for multipart parts
#
# POST /uploads/batch-presign-multipart-parts.json
# Returns: record<presigned_urls: record>
# operationId: batchPresignMultipartParts
export def "batch-presign-multipart-parts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  part_numbers: list # The part numbers to generate the presigned URLs for, must be between 1 and 10000.
  unique_identifier: string # The unique identifier returned in the original /create-multipart request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploads/batch-presign-multipart-parts.json"
    body: {content_type: "application/json", kind: json, fields: [{name: part_numbers, var: part_numbers}, {name: unique_identifier, var: unique_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    part_numbers: $part_numbers, unique_identifier: $unique_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completes a direct external upload
#
# POST /uploads/complete-external-upload.json
# Returns: record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int>
# operationId: completeExternalUpload
export def "complete-external-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-private-message: string # Optionally set this to true if the upload is for a private message.
  --for-site-setting: string # Optionally set this to true if the upload is for a site setting.
  --pasted: string # Optionally set this to true if the upload was pasted into the upload area. This will convert PNG files to JPEG.
  unique_identifier: string # The unique identifier returned in the original /generate-presigned-put request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploads/complete-external-upload.json"
    body: {content_type: "application/json", kind: json, fields: [{name: for_private_message, var: for_private_message}, {name: for_site_setting, var: for_site_setting}, {name: pasted, var: pasted}, {name: unique_identifier, var: unique_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    for_private_message: $for_private_message, for_site_setting: $for_site_setting, pasted: $pasted, unique_identifier: $unique_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete multipart upload
#
# POST /uploads/complete-multipart.json
# Returns: record<dominant_color: string, extension: string, filesize: int, height: int, human_filesize: string, id: int, original_filename: string, retain_hours: string, short_path: string, short_url: string, thumbnail_height: int, thumbnail_width: int, url: string, width: int>
# operationId: completeMultipart
export def "complete-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  parts: list # All of the part numbers and their corresponding ETags that have been uploaded must be provided.
  unique_identifier: string # The unique identifier returned in the original /create-multipart request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploads/complete-multipart.json"
    body: {content_type: "application/json", kind: json, fields: [{name: parts, var: parts}, {name: unique_identifier, var: unique_identifier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parts: $parts, unique_identifier: $unique_identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a multipart external upload
#
# POST /uploads/create-multipart.json
# Returns: record<external_upload_identifier: string, key: string, unique_identifier: string>
# operationId: createMultipartUpload
export def "create-multipart-upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_name: string
  file_size: int # File size should be represented in bytes.
  --metadata: record # shape: {sha1-checksum?: string}
  upload_type: string@upload-type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploads/create-multipart.json"
    body: {content_type: "application/json", kind: json, fields: [{name: file_name, var: file_name}, {name: file_size, var: file_size}, {name: metadata, var: metadata}, {name: upload_type, var: upload_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_name: $file_name, file_size: $file_size, metadata: $metadata, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiates a direct external upload
#
# POST /uploads/generate-presigned-put.json
# Returns: record<key: string, unique_identifier: string, url: string>
# operationId: generatePresignedPut
export def "generate-presigned-put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_name: string
  file_size: int # File size should be represented in bytes.
  --metadata: record # shape: {sha1-checksum?: string}
  type: string@type-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/uploads/generate-presigned-put.json"
    body: {content_type: "application/json", kind: json, fields: [{name: file_name, var: file_name}, {name: file_size, var: file_size}, {name: metadata, var: metadata}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_name: $file_name, file_size: $file_size, metadata: $metadata, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List badges for a user
#
# GET /user-badges/{username}.json
# Returns: record<badge_types: table<id: int, name: string, sort_order: int>, badges: table<allow_title: bool, badge_grouping_id: int, badge_type_id: int, description: string, enabled: bool, grant_count: int, icon: string, id: int, image_url: string, listable: bool, manually_grantable: bool, multiple_grant: bool, name: string, slug: string, system: bool>, granted_bies: table<admin: bool, avatar_template: string, flair_name: string, id: int, moderator: bool, name: string, trust_level: int, username: string>, user_badges: table<badge_id: int, can_favorite: bool, granted_at: string, granted_by_id: int, grouping_position: int, id: int, is_favorite: string>>
# operationId: listUserBadges
export def "list-user-badges" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user-badges/{username}.json"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of user actions
#
# GET /user_actions.json
# Returns: record<user_actions: table<acting_avatar_template: string, acting_name: string, acting_user_id: int, acting_username: string, action_code: string, action_type: int, archived: bool, avatar_template: string, category_id: int, closed: bool, created_at: string, deleted: bool, excerpt: string, hidden: string, name: string, post_id: string, post_number: int, post_type: string, slug: string, target_name: string, target_user_id: int, target_username: string, title: string, topic_id: int, user_id: int, username: string>>
# operationId: listUserActions
export def "list-user-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # required
  --username: string # required
  --filter: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user_actions.json"
    query: [{name: offset, var: offset, required: true}, {name: username, var: username, required: true}, {name: filter, var: filter, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    offset: $offset, username: $username, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refresh gravatar
#
# POST /user_avatar/{username}/refresh_gravatar.json
# Returns: record<gravatar_avatar_template: string, gravatar_upload_id: int>
# operationId: refreshGravatar
export def "refresh-gravatar" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/user_avatar/{username}/refresh_gravatar.json"
    path_params: [{name: username, var: username}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a user
#
# POST /users.json
# Returns: record<active: bool, message: string, success: bool, user_id: int>
# operationId: createUser
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
  --api-key: string # required
  --api-username: string # required
  --active: oneof<nothing, bool> # This param requires an api key in the request header or it will be ignored
  --approved: oneof<nothing, bool>
  email: string
  --external-ids: record
  name: string
  password: string
  --user-fields-1: oneof<nothing, bool>
  username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users.json"
    header: [{name: Api-Key, var: api_key, required: true}, {name: Api-Username, var: api_username, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: approved, var: approved}, {name: email, var: email}, {name: external_ids, var: external_ids}, {name: name, var: name}, {name: password, var: password}, {name: "user_fields[1]", var: user_fields_1}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    api_key: $api_key, api_username: $api_username, active: $active, approved: $approved, email: $email, external_ids: $external_ids, name: $name, password: $password, user_fields_1: $user_fields_1, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password
#
# PUT /users/password-reset/{token}.json
# operationId: changePassword
export def "change-password" [
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
  password: string
  username: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/users/password-reset/{token}.json"
    path_params: [{name: token, var: token_arg}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    token_arg: $token_arg, password: $password, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
