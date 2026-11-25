# Auto-generated client for Wikimedia v1.0.0
# Source: https://api.apis.guru/v2/specs/wikimedia.org/1.0.0/swagger.json
# Auth: --token flag or $env.WIKIMEDIA_TOKEN

const CLIENT = {
  base_url: "https://wikimedia.org/api/rest_v1"
  token_env_var: "WIKIMEDIA_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: cookie, in: header, header_name: cookie, prefix: ""}
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

def base-url-completer [] { ["https://wikimedia.org/api/rest_v1"] }
def auth-scheme-completer [] { ["cookie"] }

# Completers for enum parameters
def accept-completer [] { ["application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Availability/1.0.1\"" "application/problem+json"] }
def type-completer [] { ["chem" "inline-tex" "tex"] }
def accept-completer-1 [] { ["application/json" "application/problem+json"] }
def format-completer [] { ["mml" "png" "svg"] }
def accept-completer-2 [] { ["application/mathml+xml" "application/problem+json" "image/png" "image/svg+xml"] }
def editor-type-completer [] { ["all-editor-types" "anonymous" "group-bot" "name-bot" "user"] }
def page-type-completer [] { ["all-page-types" "content" "non-content"] }
def granularity-completer [] { ["daily" "monthly"] }
def activity-level-completer [] { ["1..4-edits" "100..-edits" "25..99-edits" "5..24-edits" "all-activity-levels"] }
def access-site-completer [] { ["all-sites" "desktop-site" "mobile-site"] }
def granularity-completer-1 [] { ["daily" "hourly" "monthly"] }
def access-completer [] { ["all-access" "desktop" "mobile-app" "mobile-web"] }
def agent-completer [] { ["all-agents" "spider" "user"] }
def agent-completer-1 [] { ["all-agents" "bot" "spider" "user"] }
def provider-completer [] { ["Apertium" "Yandex" "Youdao"] }
def tool-completer [] { ["dictionary" "mt"] }
def provider-completer-1 [] { ["Dictd" "JsonDict"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-feed-availability: "record<in_the_news: list<string>, most_read: list<string>, on_this_day: list<string>, picture_of_the_day: list<string>, todays_featured_article: list<string>>"
    get-metrics-bytes-difference-absolute-aggregate-project-editor-type-page-type-granularity-start-end: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-bytes-difference-absolute-per-page-project-page-title-editor-type-granularity-start-end: "record<items: table<editor-type: string, granularity: string, page-title: string, project: string, results: list>>"
    get-metrics-bytes-difference-net-aggregate-project-editor-type-page-type-granularity-start-end: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-bytes-difference-net-per-page-project-page-title-editor-type-granularity-start-end: "record<items: table<editor-type: string, granularity: string, page-title: string, project: string, results: list>>"
    get-metrics-edited-pages-aggregate-project-editor-type-page-type-activity-level-granularity-start-end: "record<items: table<activity-level: string, editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-edited-pages-new-project-editor-type-page-type-granularity-start-end: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-edited-pages-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-edited-pages-top-by-edits-project-editor-type-page-type-year-month-day: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-edited-pages-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-editors-aggregate-project-editor-type-page-type-activity-level-granularity-start-end: "record<items: table<activity-level: string, editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-editors-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-editors-top-by-edits-project-editor-type-page-type-year-month-day: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-editors-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-edits-aggregate-project-editor-type-page-type-granularity-start-end: "record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>"
    get-metrics-edits-per-page-project-page-title-editor-type-granularity-start-end: "record<items: table<editor-type: string, granularity: string, page-title: string, project: string, results: list>>"
    get-metrics-legacy-pagecounts-aggregate-project-access-site-granularity-start-end: "record<items: table<access-site: string, count: int, granularity: string, project: string, timestamp: string>>"
    get-metrics-pageviews-aggregate-project-access-agent-granularity-start-end: "record<items: table<access: string, agent: string, granularity: string, project: string, timestamp: string, views: int>>"
    get-metrics-pageviews-per-article-project-access-agent-article-granularity-start-end: "record<items: table<access: string, agent: string, article: string, granularity: string, project: string, timestamp: string, views: int>>"
    get-metrics-pageviews-top-by-country-project-access-year-month: "record<items: table<access: string, countries: list, month: string, project: string, year: string>>"
    get-metrics-pageviews-top-project-access-year-month-day: "record<items: table<access: string, articles: list, day: string, month: string, project: string, year: string>>"
    get-metrics-registered-users-new-project-granularity-start-end: "record<items: table<granularity: string, project: string, results: list>>"
    get-metrics-unique-devices-project-access-site-granularity-start-end: "record<items: table<access-site: string, devices: int, granularity: string, project: string, timestamp: string>>"
    post-transform-html-from-from-lang-to-to-lang: "record<contents: string>"
    post-transform-html-from-from-lang-to-to-lang-provider: "record<contents: string>"
    get-transform-list-languagepairs: "record<source: list<string>, target: list<string>>"
    get-transform-list-pair-from-to: "record<tools: list<string>>"
    get-transform-list-tool-tool: "record"
    get-transform-list-tool-tool-from: "record"
    get-transform-list-tool-tool-from-to: "record"
    get-transform-word-from-from-lang-to-to-lang-word: "record<source: string, translations: table<info: string, phrase: string, sources: string>>"
    get-transform-word-from-from-lang-to-to-lang-word-provider: "record<source: string, translations: table<info: string, phrase: string, sources: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-feed-availability" "post-media-math-check-type" "get-media-math-formula-hash" "get-media-math-render-format-hash" "get-metrics-bytes-difference-absolute-aggregate-project-editor-type-page-type-granularity-start-end" "get-metrics-bytes-difference-absolute-per-page-project-page-title-editor-type-granularity-start-end" "get-metrics-bytes-difference-net-aggregate-project-editor-type-page-type-granularity-start-end" "get-metrics-bytes-difference-net-per-page-project-page-title-editor-type-granularity-start-end" "get-metrics-edited-pages-aggregate-project-editor-type-page-type-activity-level-granularity-start-end" "get-metrics-edited-pages-new-project-editor-type-page-type-granularity-start-end" "get-metrics-edited-pages-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day" "get-metrics-edited-pages-top-by-edits-project-editor-type-page-type-year-month-day" "get-metrics-edited-pages-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day" "get-metrics-editors-aggregate-project-editor-type-page-type-activity-level-granularity-start-end" "get-metrics-editors-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day" "get-metrics-editors-top-by-edits-project-editor-type-page-type-year-month-day" "get-metrics-editors-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day" "get-metrics-edits-aggregate-project-editor-type-page-type-granularity-start-end" "get-metrics-edits-per-page-project-page-title-editor-type-granularity-start-end" "get-metrics-legacy-pagecounts-aggregate-project-access-site-granularity-start-end" "get-metrics-pageviews-aggregate-project-access-agent-granularity-start-end" "get-metrics-pageviews-per-article-project-access-agent-article-granularity-start-end" "get-metrics-pageviews-top-by-country-project-access-year-month" "get-metrics-pageviews-top-project-access-year-month-day" "get-metrics-registered-users-new-project-granularity-start-end" "get-metrics-unique-devices-project-access-site-granularity-start-end" "post-transform-html-from-from-lang-to-to-lang" "post-transform-html-from-from-lang-to-to-lang-provider" "get-transform-list-languagepairs" "get-transform-list-pair-from-to" "get-transform-list-tool-tool" "get-transform-list-tool-tool-from" "get-transform-list-tool-tool-from-to" "get-transform-word-from-from-lang-to-to-lang-word" "get-transform-word-from-from-lang-to-to-lang-word-provider" "commands"] | sort) } | get name | first)
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

# Gets availability of featured feed content for the apps by wiki domain.
#
# GET /feed/availability
# Returns: record<in_the_news: list<string>, most_read: list<string>, on_this_day: list<string>, picture_of_the_day: list<string>, todays_featured_article: list<string>>
export def "get-feed-availability" [
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
    path: "/feed/availability"
    accept: ["application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Availability/1.0.1\"", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check and normalize a TeX formula.
#
# POST /media/math/check/{type}
export def "post-media-math-check-type" [
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
  --accept: string@accept-completer-1 # Response content type
  q: string # The formula to check
]: any -> any {
  $in | http-request {
    method: post
    path: "/media/math/check/{type}"
    path_params: [{name: type, var: type}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: q, var: q}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    type: $type, q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a previously-stored formula
#
# GET /media/math/formula/{hash}
export def "get-media-math-formula-hash" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/media/math/formula/{hash}"
    path_params: [{name: hash, var: hash}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    hash: $hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get rendered formula in the given format.
#
# GET /media/math/render/{format}/{hash}
export def "get-media-math-render-format-hash" [
  format: string@format-completer
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  http-request {
    method: get
    path: "/media/math/render/{format}/{hash}"
    path_params: [{name: format, var: format}, {name: hash, var: hash}]
    accept: ["image/svg+xml", "application/mathml+xml", "image/png", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    format: $format, hash: $hash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the sum of absolute value of text bytes difference between current edit and previous one.
#
# GET /metrics/bytes-difference/absolute/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-bytes-difference-absolute-aggregate-project-editor-type-page-type-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/bytes-difference/absolute/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the sum of absolute text bytes difference per page.
#
# GET /metrics/bytes-difference/absolute/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
# Returns: record<items: table<editor-type: string, granularity: string, page-title: string, project: string, results: list>>
export def "get-metrics-bytes-difference-absolute-per-page-project-page-title-editor-type-granularity-start-end" [
  project: string
  page_title: string
  editor_type: string@editor-type-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/bytes-difference/absolute/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: page-title, var: page_title}, {name: editor-type, var: editor_type}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, page_title: $page_title, editor_type: $editor_type, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the sum of net text bytes difference between current edit and previous one.
#
# GET /metrics/bytes-difference/net/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-bytes-difference-net-aggregate-project-editor-type-page-type-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/bytes-difference/net/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the sum of net text bytes difference per page.
#
# GET /metrics/bytes-difference/net/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
# Returns: record<items: table<editor-type: string, granularity: string, page-title: string, project: string, results: list>>
export def "get-metrics-bytes-difference-net-per-page-project-page-title-editor-type-granularity-start-end" [
  project: string
  page_title: string
  editor_type: string@editor-type-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/bytes-difference/net/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: page-title, var: page_title}, {name: editor-type, var: editor_type}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, page_title: $page_title, editor_type: $editor_type, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get edited-pages counts for a project.
#
# GET /metrics/edited-pages/aggregate/{project}/{editor-type}/{page-type}/{activity-level}/{granularity}/{start}/{end}
# Returns: record<items: table<activity-level: string, editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-edited-pages-aggregate-project-editor-type-page-type-activity-level-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  activity_level: string@activity-level-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/edited-pages/aggregate/{project}/{editor-type}/{page-type}/{activity-level}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: activity-level, var: activity_level}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, activity_level: $activity_level, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get new pages counts for a project.
#
# GET /metrics/edited-pages/new/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-edited-pages-new-project-editor-type-page-type-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/edited-pages/new/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get top 100 edited-pages by absolute bytes-difference.
#
# GET /metrics/edited-pages/top-by-absolute-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-edited-pages-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/edited-pages/top-by-absolute-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, year: $year, month: $month, day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get top 100 edited-pages by edits count.
#
# GET /metrics/edited-pages/top-by-edits/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-edited-pages-top-by-edits-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/edited-pages/top-by-edits/{project}/{editor-type}/{page-type}/{year}/{month}/{day}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, year: $year, month: $month, day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get top 100 edited-pages by net bytes-difference.
#
# GET /metrics/edited-pages/top-by-net-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-edited-pages-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/edited-pages/top-by-net-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, year: $year, month: $month, day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get editors counts for a project.
#
# GET /metrics/editors/aggregate/{project}/{editor-type}/{page-type}/{activity-level}/{granularity}/{start}/{end}
# Returns: record<items: table<activity-level: string, editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-editors-aggregate-project-editor-type-page-type-activity-level-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  activity_level: string@activity-level-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/editors/aggregate/{project}/{editor-type}/{page-type}/{activity-level}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: activity-level, var: activity_level}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, activity_level: $activity_level, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get top 100 editors by absolute bytes-difference.
#
# GET /metrics/editors/top-by-absolute-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-editors-top-by-absolute-bytes-difference-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/editors/top-by-absolute-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, year: $year, month: $month, day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get top 100 editors by edits count.
#
# GET /metrics/editors/top-by-edits/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-editors-top-by-edits-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/editors/top-by-edits/{project}/{editor-type}/{page-type}/{year}/{month}/{day}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, year: $year, month: $month, day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get top 100 editors by net bytes-difference.
#
# GET /metrics/editors/top-by-net-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-editors-top-by-net-bytes-difference-project-editor-type-page-type-year-month-day" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/editors/top-by-net-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, year: $year, month: $month, day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get edits counts for a project.
#
# GET /metrics/edits/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
# Returns: record<items: table<editor-type: string, granularity: string, page-type: string, project: string, results: list>>
export def "get-metrics-edits-aggregate-project-editor-type-page-type-granularity-start-end" [
  project: string
  editor_type: string@editor-type-completer
  page_type: string@page-type-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/edits/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: editor-type, var: editor_type}, {name: page-type, var: page_type}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, editor_type: $editor_type, page_type: $page_type, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get edit counts for a page in a project.
#
# GET /metrics/edits/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
# Returns: record<items: table<editor-type: string, granularity: string, page-title: string, project: string, results: list>>
export def "get-metrics-edits-per-page-project-page-title-editor-type-granularity-start-end" [
  project: string
  page_title: string
  editor_type: string@editor-type-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/edits/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: page-title, var: page_title}, {name: editor-type, var: editor_type}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, page_title: $page_title, editor_type: $editor_type, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Given a project and a date range, returns a timeseries of pagecounts. You can filter by access site (mobile or desktop) and you can choose between monthly, daily and hourly granularity as well. - Stability: [experimental](https://www.mediawiki.org/wiki/API_versioning#Experimental) - Rate limit: 100 req/s - License: Data accessible via this endpoint is available under the [CC0 1.0 license](https://creativecommons.org/publicdomain/zero/1.0/).
#
# GET /metrics/legacy/pagecounts/aggregate/{project}/{access-site}/{granularity}/{start}/{end}
# Returns: record<items: table<access-site: string, count: int, granularity: string, project: string, timestamp: string>>
export def "get-metrics-legacy-pagecounts-aggregate-project-access-site-granularity-start-end" [
  project: string
  access_site: string@access-site-completer
  granularity: string@granularity-completer-1
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/legacy/pagecounts/aggregate/{project}/{access-site}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: access-site, var: access_site}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, access_site: $access_site, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get pageview counts for a project.
#
# GET /metrics/pageviews/aggregate/{project}/{access}/{agent}/{granularity}/{start}/{end}
# Returns: record<items: table<access: string, agent: string, granularity: string, project: string, timestamp: string, views: int>>
export def "get-metrics-pageviews-aggregate-project-access-agent-granularity-start-end" [
  project: string
  access: string@access-completer
  agent: string@agent-completer
  granularity: string@granularity-completer-1
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/pageviews/aggregate/{project}/{access}/{agent}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: access, var: access}, {name: agent, var: agent}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, access: $access, agent: $agent, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get pageview counts for a page.
#
# GET /metrics/pageviews/per-article/{project}/{access}/{agent}/{article}/{granularity}/{start}/{end}
# Returns: record<items: table<access: string, agent: string, article: string, granularity: string, project: string, timestamp: string, views: int>>
export def "get-metrics-pageviews-per-article-project-access-agent-article-granularity-start-end" [
  project: string
  access: string@access-completer
  agent: string@agent-completer-1
  article: string
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/pageviews/per-article/{project}/{access}/{agent}/{article}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: access, var: access}, {name: agent, var: agent}, {name: article, var: article}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, access: $access, agent: $agent, article: $article, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get pageviews by country and access method.
#
# GET /metrics/pageviews/top-by-country/{project}/{access}/{year}/{month}
# Returns: record<items: table<access: string, countries: list, month: string, project: string, year: string>>
export def "get-metrics-pageviews-top-by-country-project-access-year-month" [
  project: string
  access: string@access-completer
  year: string
  month: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/pageviews/top-by-country/{project}/{access}/{year}/{month}"
    path_params: [{name: project, var: project}, {name: access, var: access}, {name: year, var: year}, {name: month, var: month}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, access: $access, year: $year, month: $month
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the most viewed articles for a project.
#
# GET /metrics/pageviews/top/{project}/{access}/{year}/{month}/{day}
# Returns: record<items: table<access: string, articles: list, day: string, month: string, project: string, year: string>>
export def "get-metrics-pageviews-top-project-access-year-month-day" [
  project: string
  access: string@access-completer
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/pageviews/top/{project}/{access}/{year}/{month}/{day}"
    path_params: [{name: project, var: project}, {name: access, var: access}, {name: year, var: year}, {name: month, var: month}, {name: day, var: day}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, access: $access, year: $year, month: $month, day: $day
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get newly registered users counts for a project.
#
# GET /metrics/registered-users/new/{project}/{granularity}/{start}/{end}
# Returns: record<items: table<granularity: string, project: string, results: list>>
export def "get-metrics-registered-users-new-project-granularity-start-end" [
  project: string
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/registered-users/new/{project}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get unique devices count per project
#
# GET /metrics/unique-devices/{project}/{access-site}/{granularity}/{start}/{end}
# Returns: record<items: table<access-site: string, devices: int, granularity: string, project: string, timestamp: string>>
export def "get-metrics-unique-devices-project-access-site-granularity-start-end" [
  project: string
  access_site: string@access-site-completer
  granularity: string@granularity-completer
  start: string
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/metrics/unique-devices/{project}/{access-site}/{granularity}/{start}/{end}"
    path_params: [{name: project, var: project}, {name: access-site, var: access_site}, {name: granularity, var: granularity}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    project: $project, access_site: $access_site, granularity: $granularity, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Machine-translate content
#
# POST /transform/html/from/{from_lang}/to/{to_lang}
# Returns: record<contents: string>
export def "post-transform-html-from-from-lang-to-to-lang" [
  from_lang: string
  to_lang: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  html: string # The HTML content to translate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transform/html/from/{from_lang}/to/{to_lang}"
    path_params: [{name: from_lang, var: from_lang}, {name: to_lang, var: to_lang}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: html, var: html}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    from_lang: $from_lang, to_lang: $to_lang, html: $html
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Machine-translate content
#
# POST /transform/html/from/{from_lang}/to/{to_lang}/{provider}
# Returns: record<contents: string>
export def "post-transform-html-from-from-lang-to-to-lang-provider" [
  from_lang: string
  to_lang: string
  provider: string@provider-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  html: string # The HTML content to translate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/transform/html/from/{from_lang}/to/{to_lang}/{provider}"
    path_params: [{name: from_lang, var: from_lang}, {name: to_lang, var: to_lang}, {name: provider, var: provider}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: html, var: html}]}
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    from_lang: $from_lang, to_lang: $to_lang, provider: $provider, html: $html
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists the language pairs supported by the back-end
#
# GET /transform/list/languagepairs/
# Returns: record<source: list<string>, target: list<string>>
export def "get-transform-list-languagepairs" [
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
    path: "/transform/list/languagepairs/"
    accept: ["application/json"]
    ok: [200]
    auth: cookie
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tools available for a language pair
#
# GET /transform/list/pair/{from}/{to}/
# Returns: record<tools: list<string>>
export def "get-transform-list-pair-from-to" [
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transform/list/pair/{from}/{to}/"
    path_params: [{name: from, var: from}, {name: to, var: to}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}
# Returns: record
export def "get-transform-list-tool-tool" [
  tool: string@tool-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transform/list/tool/{tool}"
    path_params: [{name: tool, var: tool}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    tool: $tool
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}/{from}
# Returns: record
export def "get-transform-list-tool-tool-from" [
  tool: string@tool-completer
  from: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transform/list/tool/{tool}/{from}"
    path_params: [{name: tool, var: tool}, {name: from, var: from}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    tool: $tool, from: $from
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}/{from}/{to}
# Returns: record
export def "get-transform-list-tool-tool-from-to" [
  tool: string@tool-completer
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transform/list/tool/{tool}/{from}/{to}"
    path_params: [{name: tool, var: tool}, {name: from, var: from}, {name: to, var: to}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    tool: $tool, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch the dictionary meaning of a word
#
# GET /transform/word/from/{from_lang}/to/{to_lang}/{word}
# Returns: record<source: string, translations: table<info: string, phrase: string, sources: string>>
export def "get-transform-word-from-from-lang-to-to-lang-word" [
  from_lang: string
  to_lang: string
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transform/word/from/{from_lang}/to/{to_lang}/{word}"
    path_params: [{name: from_lang, var: from_lang}, {name: to_lang, var: to_lang}, {name: word, var: word}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    from_lang: $from_lang, to_lang: $to_lang, word: $word
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Fetch the dictionary meaning of a word
#
# GET /transform/word/from/{from_lang}/to/{to_lang}/{word}/{provider}
# Returns: record<source: string, translations: table<info: string, phrase: string, sources: string>>
export def "get-transform-word-from-from-lang-to-to-lang-word-provider" [
  from_lang: string
  to_lang: string
  word: string
  provider: string@provider-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transform/word/from/{from_lang}/to/{to_lang}/{word}/{provider}"
    path_params: [{name: from_lang, var: from_lang}, {name: to_lang, var: to_lang}, {name: word, var: word}, {name: provider, var: provider}]
    accept: ["application/json", "application/problem+json"]
    ok: [200]
    auth: cookie
  } {
    from_lang: $from_lang, to_lang: $to_lang, word: $word, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
