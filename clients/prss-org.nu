# Auto-generated client for ContentDepot v2.0.0
# Source: https://api.apis.guru/v2/specs/prss.org/2.0.0/openapi.json
# Auth: --token flag or $env.CONTENTDEPOT_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "CONTENTDEPOT_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru" "https://radiodns.prss.org" "https://radiodnsstage.prss.org" "https://radiodnsdev.mgmt.prss.org"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-by-id-completer [] { ["asc" "desc"] }
def format-completer [] { ["radiodns"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-api-v2-broadcastservices: "table<beginAirDate: string, beginTransmissionDate: string, createdDate: string, customerId: int, endAirDate: string, endTransmissionDate: string, id: int, lastModifiedDate: string, programId: int, title: string>"
    get-api-v2-broadcastservices-id: "record<createdDate: string, description: string, id: int, lastModifiedDate: string, name: string>"
    post-api-v2-cddrive-files-content: "record<createdDate: string, id: int, lastModifiedDate: string, name: string, parentId: int, size: int>"
    get-api-v2-cddrive-files-file-id: "record<createdDate: string, id: int, lastModifiedDate: string, name: string, parentId: int, size: int>"
    get-api-v2-cddrive-files-file-id-content: "binary"
    post-api-v2-cddrive-folders: "record<createdDate: string, id: int, lastModifiedDate: string, name: string, parentId: int>"
    get-api-v2-cddrive-folders-folder-id: "record<createdDate: string, id: int, lastModifiedDate: string, name: string, parentId: int>"
    get-api-v2-cddrive-folders-folder-id-items: "record<entries: table<id: int, name: string, type: string>, limit: int, offset: int, totalCount: int>"
    get-api-v2-episodes: "table<beginAirDate: string, beginTransmissionDate: string, createdDate: string, customerId: int, endAirDate: string, endTransmissionDate: string, id: int, lastModifiedDate: string, programId: int, title: string>"
    get-api-v2-episodes-id: "record<beginAirDate: string, beginTransmissionDate: string, createdDate: string, customerId: int, endAirDate: string, endTransmissionDate: string, id: int, lastModifiedDate: string, programId: int, title: string>"
    post-api-v2-metapub-program-information-batch: "record<createdDate: string, finishedDate: string, format: string, id: int, message: string, name: string, program: record<airDate: string, title: string>, status: string, uri: string>"
    get-api-v2-metapub-program-information-batch-batch-id: "record<createdDate: string, finishedDate: string, format: string, id: int, message: string, name: string, program: record<airDate: string, title: string>, status: string, uri: string>"
    get-api-v2-pieces: "table<contributor: string, createdDate: string, description: string, episodeId: int, fullDescription: string, id: int, imageCdDriveUri: string, imageFileName: string, imageFileSize: int, imageOriginalFileName: string, lastModifiedDate: string, relativeEndTime: int, relativeStartTime: int, segmentNumber: int, title: string>"
    post-api-v2-pieces: "record<contributor: string, createdDate: string, description: string, episodeId: int, fullDescription: string, id: int, imageCdDriveUri: string, imageFileName: string, imageFileSize: int, imageOriginalFileName: string, lastModifiedDate: string, relativeEndTime: int, relativeStartTime: int, segmentNumber: int, title: string>"
    get-api-v2-pieces-id: "record<contributor: string, createdDate: string, description: string, episodeId: int, fullDescription: string, id: int, imageCdDriveUri: string, imageFileName: string, imageFileSize: int, imageOriginalFileName: string, lastModifiedDate: string, relativeEndTime: int, relativeStartTime: int, segmentNumber: int, title: string>"
    get-api-v2-programs-search: "table<createdDate: string, customerId: int, id: int, lastModifiedDate: string, title: string>"
    get-api-v2-programs-id: "record<createdDate: string, customerId: int, id: int, lastModifiedDate: string, title: string>"
    get-api-v2-segments: "table<channels: int, createdDate: string, episodeId: int, fileName: string, fileSize: int, id: int, inCue: string, lastModifiedDate: string, length: int, originalFileName: string, outCue: string, segmentNumber: int>"
    post-api-v2-segments: "record<channels: int, createdDate: string, episodeId: int, fileName: string, fileSize: int, id: int, inCue: string, lastModifiedDate: string, length: int, originalFileName: string, outCue: string, segmentNumber: int>"
    get-api-v2-segments-id: "record<channels: int, createdDate: string, episodeId: int, fileName: string, fileSize: int, id: int, inCue: string, lastModifiedDate: string, length: int, originalFileName: string, outCue: string, segmentNumber: int>"
    get-api-v2-segments-id-content: "binary"
    get-api-v2-spotinsertions: "table<broadcastServiceId: int, createdDate: string, cue: string, customerId: int, duration: int, endDate: string, id: int, programId: int, spots: list<int>, startDate: string>"
    post-api-v2-spotinsertions: "record<broadcastServiceId: int, createdDate: string, cue: string, customerId: int, duration: int, endDate: string, id: int, programId: int, spots: list<int>, startDate: string>"
    get-api-v2-spotinsertions-id: "record<broadcastServiceId: int, createdDate: string, cue: string, customerId: int, duration: int, endDate: string, id: int, programId: int, spots: list<int>, startDate: string>"
    get-api-v2-spots: "table<createdDate: string, duration: int, fileName: string, fileSize: int, id: int, lastModifiedDate: string, lastUploadedDate: string, name: string, notes: string, originalFileName: string>"
    post-api-v2-spots: "record<createdDate: string, duration: int, fileName: string, fileSize: int, id: int, lastModifiedDate: string, lastUploadedDate: string, name: string, notes: string, originalFileName: string>"
    get-api-v2-spots-id: "record<createdDate: string, duration: int, fileName: string, fileSize: int, id: int, lastModifiedDate: string, lastUploadedDate: string, name: string, notes: string, originalFileName: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api-v2-broadcastservices" "get-api-v2-broadcastservices-id" "post-api-v2-cddrive-files-content" "delete-api-v2-cddrive-files-file-id" "get-api-v2-cddrive-files-file-id" "get-api-v2-cddrive-files-file-id-content" "post-api-v2-cddrive-folders" "delete-api-v2-cddrive-folders-folder-id" "get-api-v2-cddrive-folders-folder-id" "get-api-v2-cddrive-folders-folder-id-items" "get-api-v2-episodes" "get-api-v2-episodes-id" "post-api-v2-metapub-program-information-batch" "get-api-v2-metapub-program-information-batch-batch-id" "get-api-v2-pieces" "post-api-v2-pieces" "delete-api-v2-pieces-id" "get-api-v2-pieces-id" "get-api-v2-programs-search" "get-api-v2-programs-id" "get-api-v2-segments" "post-api-v2-segments" "delete-api-v2-segments-id" "get-api-v2-segments-id" "get-api-v2-segments-id-content" "get-api-v2-spotinsertions" "post-api-v2-spotinsertions" "delete-api-v2-spotinsertions-id" "get-api-v2-spotinsertions-id" "get-api-v2-spots" "post-api-v2-spots" "delete-api-v2-spots-id" "get-api-v2-spots-id" "get-radiodns-spi-3-1-gi-xml" "get-radiodns-spi-3-1-si-xml" "get-radiodns-spi-3-1-id-fqdn-sid-date-pi-xml" "commands"] | sort) } | get name | first)
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

# Gets broadcast services matching the given criteria.
#
# GET /api/v2/broadcastservices
# Returns: table<beginAirDate: string, beginTransmissionDate: string, createdDate: string, customerId: int, endAirDate: string, endTransmissionDate: string, id: int, lastModifiedDate: string, programId: int, title: string>
export def "get-api-v2-broadcastservices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-start: int # The start page of the results to return. The first item is indexed at 0. (format: int32, default: 0)
  --page-size: int # The number of items to return. Must be between 0 and 500, inclusive. (format: int32, default: 500)
  --order-by-id: string@order-by-id-completer # The sort order of the list of broadcast services, based on broadcast service ID. If unspecified, the broadcast services are returned in random order. If using paging to iterate through the results, sort order should be specified.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/broadcastservices"
    query: [{name: pageStart, var: page_start}, {name: pageSize, var: page_size}, {name: orderById, var: order_by_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_start: $page_start, page_size: $page_size, order_by_id: $order_by_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the broadcast service matching the given ID.
#
# GET /api/v2/broadcastservices/{id}
# Returns: record<createdDate: string, description: string, id: int, lastModifiedDate: string, name: string>
export def "get-api-v2-broadcastservices-id" [
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
    path: "/api/v2/broadcastservices/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a file.
#
# POST /api/v2/cddrive/files/content
# Returns: record<createdDate: string, id: int, lastModifiedDate: string, name: string, parentId: int, size: int>
export def "post-api-v2-cddrive-files-content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-md5: string # If present, the MD5 will be compared against the file received as a message integrity check. (format: md5)
  --file: string # The file content being uploaded. (format: binary)
  --name: string # The name of the file, including extension.
  --parent-id: int # The ID of the parent folder or 0 for the root folder. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/cddrive/files/content"
    header: [{name: Content-MD5, var: content_md5}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: name, var: name}, {name: parent-id, var: parent_id}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    content_md5: $content_md5, file: $file, name: $name, parent_id: $parent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a file.
#
# DELETE /api/v2/cddrive/files/{file-id}
export def "delete-api-v2-cddrive-files-file-id" [
  file_id: int
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
    path: "/api/v2/cddrive/files/{file-id}"
    path_params: [{name: file-id, var: file_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file information.
#
# GET /api/v2/cddrive/files/{file-id}
# Returns: record<createdDate: string, id: int, lastModifiedDate: string, name: string, parentId: int, size: int>
export def "get-api-v2-cddrive-files-file-id" [
  file_id: int
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
    path: "/api/v2/cddrive/files/{file-id}"
    path_params: [{name: file-id, var: file_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UNDER DEVELOPMENT - Download a file.
#
# GET /api/v2/cddrive/files/{file-id}/content
# Returns: binary
export def "get-api-v2-cddrive-files-file-id-content" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --range: string # Can be used to limit the range of bytes retrieved. Only a single byte range in the format ```bytes={start-range}-{end-range}``` is supported. (format: single byte range)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v2/cddrive/files/{file-id}/content"
    path_params: [{name: file-id, var: file_id}]
    header: [{name: Range, var: range}]
    accept: ["application/octet-stream"]
    ok: [200, 302]
    auth: bearer
  } {
    file_id: $file_id, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a folder.
#
# POST /api/v2/cddrive/folders
# Returns: record<createdDate: string, id: int, lastModifiedDate: string, name: string, parentId: int>
export def "post-api-v2-cddrive-folders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # the name of the folder
  --parent-id: int # The ID of the parent folder or 0 for the root folder. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/cddrive/folders"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: parent-id, var: parent_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, parent_id: $parent_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UNDER DEVELOPMENT - Delete a folder.
#
# DELETE /api/v2/cddrive/folders/{folder-id}
export def "delete-api-v2-cddrive-folders-folder-id" [
  folder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recursive: oneof<nothing, bool> # Flag to indicate if the folder should be deleted if it has items inside of it. (default: true)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v2/cddrive/folders/{folder-id}"
    path_params: [{name: folder-id, var: folder_id}]
    query: [{name: recursive, var: recursive}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    folder_id: $folder_id, recursive: $recursive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UNDER DEVELOPMENT - Get folder information.
#
# GET /api/v2/cddrive/folders/{folder-id}
# Returns: record<createdDate: string, id: int, lastModifiedDate: string, name: string, parentId: int>
export def "get-api-v2-cddrive-folders-folder-id" [
  folder_id: int
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
    path: "/api/v2/cddrive/folders/{folder-id}"
    path_params: [{name: folder-id, var: folder_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the items in the folder.
#
# GET /api/v2/cddrive/folders/{folder-id}/items
# Returns: record<entries: table<id: int, name: string, type: string>, limit: int, offset: int, totalCount: int>
export def "get-api-v2-cddrive-folders-folder-id-items" [
  folder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The offset into the items to begin the response. (format: int32, default: 0)
  --limit: int # The maximum number of items to return in the response. (format: int32, default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/cddrive/folders/{folder-id}/items"
    path_params: [{name: folder-id, var: folder_id}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    folder_id: $folder_id, offset: $offset, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets episodes matching the given criteria.
#
# GET /api/v2/episodes
# Returns: table<beginAirDate: string, beginTransmissionDate: string, createdDate: string, customerId: int, endAirDate: string, endTransmissionDate: string, id: int, lastModifiedDate: string, programId: int, title: string>
export def "get-api-v2-episodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Matches on the ID of the episode. (format: int64)
  --begin-air-date-after: string # Matches on the begin air date of the episode (inclusive). (format: date-time)
  --end-air-date-before: string # Matches on the end air date of the episode (inclusive). (format: date-time)
  --program-id: int # Matches on the ID of the program that owns the episode. (required, format: int64)
  --page-start: int # The start page of the results to return. The first item is indexed at 0. (format: int32, default: 0)
  --page-size: int # The number of items to return. Must be between 0 and 500, inclusive. (format: int32, default: 500)
  --order-by-id: string@order-by-id-completer # The sort order of the list of episodes, based on episode ID. If unspecified, the episodes are returned in random order. If using paging to iterate through the results, sort order should be specified.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/episodes"
    query: [{name: id, var: id}, {name: beginAirDateAfter, var: begin_air_date_after}, {name: endAirDateBefore, var: end_air_date_before}, {name: programId, var: program_id, required: true}, {name: pageStart, var: page_start}, {name: pageSize, var: page_size}, {name: orderById, var: order_by_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, begin_air_date_after: $begin_air_date_after, end_air_date_before: $end_air_date_before, program_id: $program_id, page_start: $page_start, page_size: $page_size, order_by_id: $order_by_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the episode matching the given ID.
#
# GET /api/v2/episodes/{id}
# Returns: record<beginAirDate: string, beginTransmissionDate: string, createdDate: string, customerId: int, endAirDate: string, endTransmissionDate: string, id: int, lastModifiedDate: string, programId: int, title: string>
export def "get-api-v2-episodes-id" [
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
    path: "/api/v2/episodes/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a batch operation on EPG information.
#
# POST /api/v2/metapub/program-information/batch
# DEPRECATED
# Docs: /api/epg-cd-mapping.html — Find RadioDns to ContentDepot Mapping here
# Returns: record<createdDate: string, finishedDate: string, format: string, id: int, message: string, name: string, program: record<airDate: string, title: string>, status: string, uri: string>
@deprecated
export def "post-api-v2-metapub-program-information-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  format: string@format-completer # The format of the metadata file defining the create or update actions to be performed on one or more EPG programs. For more information on how RadioDNS EPG maps to ContentDepot click here (/api/epg-cd-mapping.html)
  --name: string # An optional human readable name for the batch.
  --program: record # The program information to associate the ingested metadata with. This is only required if the metadata format doesn't provide the program title and air date information directly. — shape: {airDate: string, title: string}
  uri: string # The URI to the metadata file. Currently only the ```cddrive``` scheme is supported. (format: uri)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/metapub/program-information/batch"
    body: {content_type: "application/json", kind: json, fields: [{name: format, var: format}, {name: name, var: name}, {name: program, var: program}, {name: uri, var: uri}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    format: $format, name: $name, program: $program, uri: $uri
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an EPG batch operation.
#
# GET /api/v2/metapub/program-information/batch/{batch-id}
# DEPRECATED
# Returns: record<createdDate: string, finishedDate: string, format: string, id: int, message: string, name: string, program: record<airDate: string, title: string>, status: string, uri: string>
@deprecated
export def "get-api-v2-metapub-program-information-batch-batch-id" [
  batch_id: int
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
    path: "/api/v2/metapub/program-information/batch/{batch-id}"
    path_params: [{name: batch-id, var: batch_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    batch_id: $batch_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the pieces matching the query parameters.
#
# GET /api/v2/pieces
# Returns: table<contributor: string, createdDate: string, description: string, episodeId: int, fullDescription: string, id: int, imageCdDriveUri: string, imageFileName: string, imageFileSize: int, imageOriginalFileName: string, lastModifiedDate: string, relativeEndTime: int, relativeStartTime: int, segmentNumber: int, title: string>
export def "get-api-v2-pieces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --episode-id: int # The ID of the episode that owns the piece. (required, format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/pieces"
    query: [{name: episodeId, var: episode_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    episode_id: $episode_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new piece.
#
# POST /api/v2/pieces
# Returns: record<contributor: string, createdDate: string, description: string, episodeId: int, fullDescription: string, id: int, imageCdDriveUri: string, imageFileName: string, imageFileSize: int, imageOriginalFileName: string, lastModifiedDate: string, relativeEndTime: int, relativeStartTime: int, segmentNumber: int, title: string>
export def "post-api-v2-pieces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contributor: string # The artist or contributor name.
  --description: string # The short description of the piece.
  episode_id: int # The ID of the episode that owns the piece. (format: int64)
  --full-description: string # The long description of the piece.
  --image-cd-drive-uri: string # The URI to the piece image content in CD Drive. Format should be 'cddrive:id:{value}' or 'cddrive://{path}'. This property is only used on modification and is not returned.
  --image-file-name: string # The name of the piece image file. Generated at creation.
  --image-file-size: int # The size of the piece image file in bytes. Generated at creation. (format: int64)
  --image-original-file-name: string # The user's original name of the piece image file.
  relative_end_time: int # Seconds relative to the start of the episode. (format: int32)
  relative_start_time: int # Seconds relative to the start of the episode. (format: int32)
  --segment-number: int # The number of the segment that this piece is in, starting with 1. This is an optional field but it can be used to provide more detail by linking the piece to a specific audio segment. (format: int32)
  title: string # The human readable title of the piece that is normally displayed on an end user's device.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/pieces"
    body: {content_type: "application/json", kind: json, fields: [{name: contributor, var: contributor}, {name: description, var: description}, {name: episodeId, var: episode_id}, {name: fullDescription, var: full_description}, {name: imageCdDriveUri, var: image_cd_drive_uri}, {name: imageFileName, var: image_file_name}, {name: imageFileSize, var: image_file_size}, {name: imageOriginalFileName, var: image_original_file_name}, {name: relativeEndTime, var: relative_end_time}, {name: relativeStartTime, var: relative_start_time}, {name: segmentNumber, var: segment_number}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    contributor: $contributor, description: $description, episode_id: $episode_id, full_description: $full_description, image_cd_drive_uri: $image_cd_drive_uri, image_file_name: $image_file_name, image_file_size: $image_file_size, image_original_file_name: $image_original_file_name, relative_end_time: $relative_end_time, relative_start_time: $relative_start_time, segment_number: $segment_number, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the piece with the given ID.
#
# DELETE /api/v2/pieces/{id}
export def "delete-api-v2-pieces-id" [
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
    path: "/api/v2/pieces/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the piece matching the given ID.
#
# GET /api/v2/pieces/{id}
# Returns: record<contributor: string, createdDate: string, description: string, episodeId: int, fullDescription: string, id: int, imageCdDriveUri: string, imageFileName: string, imageFileSize: int, imageOriginalFileName: string, lastModifiedDate: string, relativeEndTime: int, relativeStartTime: int, segmentNumber: int, title: string>
export def "get-api-v2-pieces-id" [
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
    path: "/api/v2/pieces/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Optimized free-text search for programs using various filters.
#
# GET /api/v2/programs/search
# Returns: table<createdDate: string, customerId: int, id: int, lastModifiedDate: string, title: string>
export def "get-api-v2-programs-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keywords: string # Free text search that matches against the program title or description.
  --page-start: int # The start page of the results to return. The first item is indexed at 0. (format: int32, default: 0)
  --page-size: int # The number of items to return. Must be between 0 and 500, inclusive. (format: int32, default: 500)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/programs/search"
    query: [{name: keywords, var: keywords}, {name: pageStart, var: page_start}, {name: pageSize, var: page_size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    keywords: $keywords, page_start: $page_start, page_size: $page_size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the program matching the given ID.
#
# GET /api/v2/programs/{id}
# Returns: record<createdDate: string, customerId: int, id: int, lastModifiedDate: string, title: string>
export def "get-api-v2-programs-id" [
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
    path: "/api/v2/programs/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the segments matching the query parameters.
#
# GET /api/v2/segments
# Returns: table<channels: int, createdDate: string, episodeId: int, fileName: string, fileSize: int, id: int, inCue: string, lastModifiedDate: string, length: int, originalFileName: string, outCue: string, segmentNumber: int>
export def "get-api-v2-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --episode-id: int # The ID of the episode that owns the segment. (required, format: int64)
  --segment-number: int # format: int32
  --page-start: int # The start page of the results to return. The first item is indexed at 0. (format: int32, default: 0)
  --page-size: int # The number of items to return. Must be between 0 and 500, inclusive. (format: int32, default: 500)
  --order-by-id: string@order-by-id-completer # The sort order of the list of segments, based on segment ID. If unspecified, the segments are returned in random order. If using paging to iterate through the results, sort order should be specified.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/segments"
    query: [{name: episodeId, var: episode_id, required: true}, {name: segmentNumber, var: segment_number}, {name: pageStart, var: page_start}, {name: pageSize, var: page_size}, {name: orderById, var: order_by_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    episode_id: $episode_id, segment_number: $segment_number, page_start: $page_start, page_size: $page_size, order_by_id: $order_by_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new segment.
#
# POST /api/v2/segments
# Returns: record<channels: int, createdDate: string, episodeId: int, fileName: string, fileSize: int, id: int, inCue: string, lastModifiedDate: string, length: int, originalFileName: string, outCue: string, segmentNumber: int>
export def "post-api-v2-segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cd_drive_uri: string # The URI to the segment content in CD Drive. Format should be 'cddrive:id:{value}' or 'cddrive://{path}'.
  episode_id: int # The ID of the episode that owns the segment. (format: int64)
  --in-cue: string # The incue for the segment. Defaults to the program segment incue.
  --out-cue: string # The outcue for the segment. Defaults to the program segment outcue.
  segment_number: int # The segment number of the segment. (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/segments"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: cdDriveUri, var: cd_drive_uri}, {name: episodeId, var: episode_id}, {name: inCue, var: in_cue}, {name: outCue, var: out_cue}, {name: segmentNumber, var: segment_number}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    cd_drive_uri: $cd_drive_uri, episode_id: $episode_id, in_cue: $in_cue, out_cue: $out_cue, segment_number: $segment_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the segment with the given ID.
#
# DELETE /api/v2/segments/{id}
export def "delete-api-v2-segments-id" [
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
    path: "/api/v2/segments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the segment matching the given ID.
#
# GET /api/v2/segments/{id}
# Returns: record<channels: int, createdDate: string, episodeId: int, fileName: string, fileSize: int, id: int, inCue: string, lastModifiedDate: string, length: int, originalFileName: string, outCue: string, segmentNumber: int>
export def "get-api-v2-segments-id" [
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
    path: "/api/v2/segments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# UNDER DEVELOPMENT - Returns the audio content segment matching the given ID.
#
# GET /api/v2/segments/{id}/content
# Returns: binary
export def "get-api-v2-segments-id-content" [
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
    method: get
    path: "/api/v2/segments/{id}/content"
    path_params: [{name: id, var: id}]
    accept: ["application/octet-stream"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the spot insertions matching the query parameters.
#
# GET /api/v2/spotinsertions
# Returns: table<broadcastServiceId: int, createdDate: string, cue: string, customerId: int, duration: int, endDate: string, id: int, programId: int, spots: list<int>, startDate: string>
export def "get-api-v2-spotinsertions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-start: int # The start page of the results to return. The first item is indexed at 0. (format: int32, default: 0)
  --page-size: int # The number of items to return. Must be between 0 and 500, inclusive. (format: int32, default: 500)
  --order-by-id: string@order-by-id-completer # The sort order of the list of spot insertions, based on ID. If unspecified, the spot insertions are returned in random order. If using paging to iterate through the results, sort order should be specified.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/spotinsertions"
    query: [{name: pageStart, var: page_start}, {name: pageSize, var: page_size}, {name: orderById, var: order_by_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_start: $page_start, page_size: $page_size, order_by_id: $order_by_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new spot insertion.
#
# POST /api/v2/spotinsertions
# Returns: record<broadcastServiceId: int, createdDate: string, cue: string, customerId: int, duration: int, endDate: string, id: int, programId: int, spots: list<int>, startDate: string>
export def "post-api-v2-spotinsertions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  broadcast_service_id: int # The ID of the broadcast service for the spot insertion. (format: int64)
  cue: string # The cue that triggers the spot insertion. (e.g. S:000_SPOT)
  duration: int # The duration of the spot insertion. (format: int32)
  end_date: string # The date the spot insertion ends. The time will be set to midnight Eastern Time. (format: date, e.g. 2020-01-31)
  program_id: int # The ID of the program for the spot insertion. (format: int64)
  spots: list<int> # The ordered list of spot IDs to play.
  start_date: string # The date the spot insertion can start. The time will be set to midnight Eastern Time. (format: date, e.g. 2020-01-31)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/spotinsertions"
    body: {content_type: "application/json", kind: json, fields: [{name: broadcastServiceId, var: broadcast_service_id}, {name: cue, var: cue}, {name: duration, var: duration}, {name: endDate, var: end_date}, {name: programId, var: program_id}, {name: spots, var: spots}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    broadcast_service_id: $broadcast_service_id, cue: $cue, duration: $duration, end_date: $end_date, program_id: $program_id, spots: $spots, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the spot insertion with the given ID.
#
# DELETE /api/v2/spotinsertions/{id}
export def "delete-api-v2-spotinsertions-id" [
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
    path: "/api/v2/spotinsertions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the spot insertion matching the given ID.
#
# GET /api/v2/spotinsertions/{id}
# Returns: record<broadcastServiceId: int, createdDate: string, cue: string, customerId: int, duration: int, endDate: string, id: int, programId: int, spots: list<int>, startDate: string>
export def "get-api-v2-spotinsertions-id" [
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
    path: "/api/v2/spotinsertions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the spots matching the query parameters.
#
# GET /api/v2/spots
# Returns: table<createdDate: string, duration: int, fileName: string, fileSize: int, id: int, lastModifiedDate: string, lastUploadedDate: string, name: string, notes: string, originalFileName: string>
export def "get-api-v2-spots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-start: int # The start page of the spot to return. The first item is indexed at 0. (format: int32, default: 0)
  --page-size: int # The number of items to return. Must be between 0 and 500, inclusive. (format: int32, default: 500)
  --order-by-id: string@order-by-id-completer # The sort order of the list of spots, based on spot ID. If unspecified, the spots are returned in random order. If using paging to iterate through the results, sort order should be specified.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/v2/spots"
    query: [{name: pageStart, var: page_start}, {name: pageSize, var: page_size}, {name: orderById, var: order_by_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page_start: $page_start, page_size: $page_size, order_by_id: $order_by_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new spot.
#
# POST /api/v2/spots
# Returns: record<createdDate: string, duration: int, fileName: string, fileSize: int, id: int, lastModifiedDate: string, lastUploadedDate: string, name: string, notes: string, originalFileName: string>
export def "post-api-v2-spots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cd_drive_uri: string # The URI to the spot content in CD Drive. Format should be 'cddrive:id:{value}' or 'cddrive://{path}'.
  name: string # The name of the spot to create/update.
  notes: string # Notes pertaining to the spot.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v2/spots"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: cdDriveUri, var: cd_drive_uri}, {name: name, var: name}, {name: notes, var: notes}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    cd_drive_uri: $cd_drive_uri, name: $name, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the spot with the given ID.
#
# DELETE /api/v2/spots/{id}
export def "delete-api-v2-spots-id" [
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
    path: "/api/v2/spots/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the spot matching the given ID.
#
# GET /api/v2/spots/{id}
# Returns: record<createdDate: string, duration: int, fileName: string, fileSize: int, id: int, lastModifiedDate: string, lastUploadedDate: string, name: string, notes: string, originalFileName: string>
export def "get-api-v2-spots-id" [
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
    path: "/api/v2/spots/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the group information document.
#
# GET /radiodns/spi/3.1/GI.xml
export def "get-radiodns-spi-3-1-gi-xml" [
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
    path: "/radiodns/spi/3.1/GI.xml"
    accept: ["application/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the service information document.
#
# GET /radiodns/spi/3.1/SI.xml
export def "get-radiodns-spi-3-1-si-xml" [
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
    path: "/radiodns/spi/3.1/SI.xml"
    accept: ["application/xml"]
    ok: [200]
    base_url: "https://api.apis.guru"
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the program information document.
#
# GET /radiodns/spi/3.1/id/{fqdn}/{sid}/{date}_PI.xml
export def "get-radiodns-spi-3-1-id-fqdn-sid-date-pi-xml" [
  fqdn: string
  sid: string
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
  --x-radiodnsspi-api-key: string # The API client Id you received. This is required for National PI documents, but not Station PI documents. Contact help desk if you need one.
]: nothing -> any {
  http-request {
    method: get
    path: "/radiodns/spi/3.1/id/{fqdn}/{sid}/{date}_PI.xml"
    path_params: [{name: fqdn, var: fqdn}, {name: sid, var: sid}, {name: date, var: date}]
    header: [{name: x-radiodnsspi-api-key, var: x_radiodnsspi_api_key}]
    accept: ["application/xml"]
    ok: [200]
    base_url: "https://api.apis.guru"
    auth: bearer
  } {
    fqdn: $fqdn, sid: $sid, date: $date, x_radiodnsspi_api_key: $x_radiodnsspi_api_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
