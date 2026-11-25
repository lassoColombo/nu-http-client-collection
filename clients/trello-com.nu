# Auto-generated client for Trello v1.0
# Source: https://api.apis.guru/v2/specs/trello.com/1.0/openapi.json
# Auth: --token flag or $env.TRELLO_TOKEN

const CLIENT = {
  base_url: "https://trello.com/1"
  token_env_var: "TRELLO_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-key, in: query, header_name: key, prefix: ""}
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

def base-url-completer [] { ["https://trello.com/1"] }
def auth-scheme-completer [] { ["query-key" "query-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-actions-by-id-action" "get-actions-by-id-action" "update-actions-by-id-action" "get-actions-board-by-id-action" "get-actions-board-by-id-action-by-field" "get-actions-card-by-id-action" "get-actions-card-by-id-action-by-field" "get-actions-display-by-id-action" "get-actions-entities-by-id-action" "get-actions-list-by-id-action" "get-actions-list-by-id-action-by-field" "get-actions-member-by-id-action" "get-actions-member-by-id-action-by-field" "get-actions-member-creator-by-id-action" "get-actions-member-creator-by-id-action-by-field" "get-actions-organization-by-id-action" "get-actions-organization-by-id-action-by-field" "update-actions-text-by-id-action" "get-actions-by-id-action-by-field" "get-batch" "add-boards" "get-boards-by-id-board" "update-boards-by-id-board" "get-boards-actions-by-id-board" "get-boards-board-stars-by-id-board" "add-boards-calendar-key-generate-by-id-board" "get-boards-cards-by-id-board" "get-boards-cards-by-id-board-by-filter" "get-boards-cards-by-id-board-by-id-card" "get-boards-checklists-by-id-board" "add-boards-checklists-by-id-board" "update-boards-closed-by-id-board" "get-boards-deltas-by-id-board" "update-boards-desc-by-id-board" "add-boards-email-key-generate-by-id-board" "update-boards-id-organization-by-id-board" "update-boards-label-names-blue-by-id-board" "update-boards-label-names-green-by-id-board" "update-boards-label-names-orange-by-id-board" "update-boards-label-names-purple-by-id-board" "update-boards-label-names-red-by-id-board" "update-boards-label-names-yellow-by-id-board" "get-boards-labels-by-id-board" "add-boards-labels-by-id-board" "get-boards-labels-by-id-board-by-id-label" "get-boards-lists-by-id-board" "add-boards-lists-by-id-board" "get-boards-lists-by-id-board-by-filter" "add-boards-mark-as-viewed-by-id-board" "get-boards-members-by-id-board" "update-boards-members-by-id-board" "get-boards-members-by-id-board-by-filter" "delete-boards-members-by-id-board-by-id-member" "update-boards-members-by-id-board-by-id-member" "get-boards-members-cards-by-id-board-by-id-member" "get-boards-members-invited-by-id-board" "get-boards-members-invited-by-id-board-by-field" "get-boards-memberships-by-id-board" "get-boards-memberships-by-id-board-by-id-membership" "update-boards-memberships-by-id-board-by-id-membership" "get-boards-my-prefs-by-id-board" "update-boards-my-prefs-email-position-by-id-board" "update-boards-my-prefs-id-email-list-by-id-board" "update-boards-my-prefs-show-list-guide-by-id-board" "update-boards-my-prefs-show-sidebar-by-id-board" "update-boards-my-prefs-show-sidebar-activity-by-id-board" "update-boards-my-prefs-show-sidebar-board-actions-by-id-board" "update-boards-my-prefs-show-sidebar-members-by-id-board" "update-boards-name-by-id-board" "get-boards-organization-by-id-board" "get-boards-organization-by-id-board-by-field" "add-boards-power-ups-by-id-board" "delete-boards-power-ups-by-id-board-by-power-up" "update-boards-prefs-background-by-id-board" "update-boards-prefs-calendar-feed-enabled-by-id-board" "update-boards-prefs-card-aging-by-id-board" "update-boards-prefs-card-covers-by-id-board" "update-boards-prefs-comments-by-id-board" "update-boards-prefs-invitations-by-id-board" "update-boards-prefs-permission-level-by-id-board" "update-boards-prefs-self-join-by-id-board" "update-boards-prefs-voting-by-id-board" "update-boards-subscribed-by-id-board" "get-boards-by-id-board-by-field" "add-cards" "delete-cards-by-id-card" "get-cards-by-id-card" "update-cards-by-id-card" "get-cards-actions-by-id-card" "add-cards-actions-comments-by-id-card" "delete-cards-actions-comments-by-id-card-by-id-action" "update-cards-actions-comments-by-id-card-by-id-action" "get-cards-attachments-by-id-card" "add-cards-attachments-by-id-card" "delete-cards-attachments-by-id-card-by-id-attachment" "get-cards-attachments-by-id-card-by-id-attachment" "get-cards-board-by-id-card" "get-cards-board-by-id-card-by-field" "get-cards-check-item-states-by-id-card" "update-cards-checklist-check-item-by-id-card-by-id-checklist-current-by-id-check-item" "add-cards-checklist-check-item-by-id-card-by-id-checklist" "delete-cards-checklist-check-item-by-id-card-by-id-checklist-by-id-check-item" "add-cards-checklist-check-item-convert-to-card-by-id-card-by-id-checklist-by-id-check-item" "update-cards-checklist-check-item-name-by-id-card-by-id-checklist-by-id-check-item" "update-cards-checklist-check-item-pos-by-id-card-by-id-checklist-by-id-check-item" "update-cards-checklist-check-item-state-by-id-card-by-id-checklist-by-id-check-item" "get-cards-checklists-by-id-card" "add-cards-checklists-by-id-card" "delete-cards-checklists-by-id-card-by-id-checklist" "update-cards-closed-by-id-card" "update-cards-desc-by-id-card" "update-cards-due-by-id-card" "update-cards-id-attachment-cover-by-id-card" "update-cards-id-board-by-id-card" "add-cards-id-labels-by-id-card" "delete-cards-id-labels-by-id-card-by-id-label" "update-cards-id-list-by-id-card" "add-cards-id-members-by-id-card" "update-cards-id-members-by-id-card" "delete-cards-id-members-by-id-card-by-id-member" "add-cards-labels-by-id-card" "update-cards-labels-by-id-card" "delete-cards-labels-by-id-card-by-color" "get-cards-list-by-id-card" "get-cards-list-by-id-card-by-field" "add-cards-mark-associated-notifications-read-by-id-card" "get-cards-members-by-id-card" "get-cards-members-voted-by-id-card" "add-cards-members-voted-by-id-card" "delete-cards-members-voted-by-id-card-by-id-member" "update-cards-name-by-id-card" "update-cards-pos-by-id-card" "get-cards-stickers-by-id-card" "add-cards-stickers-by-id-card" "delete-cards-stickers-by-id-card-by-id-sticker" "get-cards-stickers-by-id-card-by-id-sticker" "update-cards-stickers-by-id-card-by-id-sticker" "update-cards-subscribed-by-id-card" "get-cards-by-id-card-by-field" "add-checklists" "delete-checklists-by-id-checklist" "get-checklists-by-id-checklist" "update-checklists-by-id-checklist" "get-checklists-board-by-id-checklist" "get-checklists-board-by-id-checklist-by-field" "get-checklists-cards-by-id-checklist" "get-checklists-cards-by-id-checklist-by-filter" "get-checklists-check-items-by-id-checklist" "add-checklists-check-items-by-id-checklist" "delete-checklists-check-items-by-id-checklist-by-id-check-item" "get-checklists-check-items-by-id-checklist-by-id-check-item" "update-checklists-id-card-by-id-checklist" "update-checklists-name-by-id-checklist" "update-checklists-pos-by-id-checklist" "get-checklists-by-id-checklist-by-field" "add-labels" "delete-labels-by-id-label" "get-labels-by-id-label" "update-labels-by-id-label" "get-labels-board-by-id-label" "get-labels-board-by-id-label-by-field" "update-labels-color-by-id-label" "update-labels-name-by-id-label" "add-lists" "get-lists-by-id-list" "update-lists-by-id-list" "get-lists-actions-by-id-list" "add-lists-archive-all-cards-by-id-list" "get-lists-board-by-id-list" "get-lists-board-by-id-list-by-field" "get-lists-cards-by-id-list" "add-lists-cards-by-id-list" "get-lists-cards-by-id-list-by-filter" "update-lists-closed-by-id-list" "update-lists-id-board-by-id-list" "add-lists-move-all-cards-by-id-list" "update-lists-name-by-id-list" "update-lists-pos-by-id-list" "update-lists-subscribed-by-id-list" "get-lists-by-id-list-by-field" "get-members-by-id-member" "update-members-by-id-member" "get-members-actions-by-id-member" "add-members-avatar-by-id-member" "update-members-avatar-source-by-id-member" "update-members-bio-by-id-member" "get-members-board-backgrounds-by-id-member" "add-members-board-backgrounds-by-id-member" "delete-members-board-backgrounds-by-id-member-by-id-board-background" "get-members-board-backgrounds-by-id-member-by-id-board-background" "update-members-board-backgrounds-by-id-member-by-id-board-background" "get-members-board-stars-by-id-member" "add-members-board-stars-by-id-member" "delete-members-board-stars-by-id-member-by-id-board-star" "get-members-board-stars-by-id-member-by-id-board-star" "update-members-board-stars-by-id-member-by-id-board-star" "update-members-board-stars-id-board-by-id-member-by-id-board-star" "update-members-board-stars-pos-by-id-member-by-id-board-star" "get-members-boards-by-id-member" "get-members-boards-by-id-member-by-filter" "get-members-boards-invited-by-id-member" "get-members-boards-invited-by-id-member-by-field" "get-members-cards-by-id-member" "get-members-cards-by-id-member-by-filter" "get-members-custom-board-backgrounds-by-id-member" "add-members-custom-board-backgrounds-by-id-member" "delete-members-custom-board-backgrounds-by-id-member-by-id-board-background" "get-members-custom-board-backgrounds-by-id-member-by-id-board-background" "update-members-custom-board-backgrounds-by-id-member-by-id-board-background" "get-members-custom-emoji-by-id-member" "add-members-custom-emoji-by-id-member" "get-members-custom-emoji-by-id-member-by-id-custom-emoji" "get-members-custom-stickers-by-id-member" "add-members-custom-stickers-by-id-member" "delete-members-custom-stickers-by-id-member-by-id-custom-sticker" "get-members-custom-stickers-by-id-member-by-id-custom-sticker" "get-members-deltas-by-id-member" "update-members-full-name-by-id-member" "update-members-initials-by-id-member" "get-members-notifications-by-id-member" "get-members-notifications-by-id-member-by-filter" "add-members-one-time-messages-dismissed-by-id-member" "get-members-organizations-by-id-member" "get-members-organizations-by-id-member-by-filter" "get-members-organizations-invited-by-id-member" "get-members-organizations-invited-by-id-member-by-field" "update-members-prefs-color-blind-by-id-member" "update-members-prefs-locale-by-id-member" "update-members-prefs-minutes-between-summaries-by-id-member" "get-members-saved-searches-by-id-member" "add-members-saved-searches-by-id-member" "delete-members-saved-searches-by-id-member-by-id-saved-search" "get-members-saved-searches-by-id-member-by-id-saved-search" "update-members-saved-searches-by-id-member-by-id-saved-search" "update-members-saved-searches-name-by-id-member-by-id-saved-search" "update-members-saved-searches-pos-by-id-member-by-id-saved-search" "update-members-saved-searches-query-by-id-member-by-id-saved-search" "get-members-tokens-by-id-member" "update-members-username-by-id-member" "get-members-by-id-member-by-field" "add-notifications-all-read" "get-notifications-by-id-notification" "update-notifications-by-id-notification" "get-notifications-board-by-id-notification" "get-notifications-board-by-id-notification-by-field" "get-notifications-card-by-id-notification" "get-notifications-card-by-id-notification-by-field" "get-notifications-display-by-id-notification" "get-notifications-entities-by-id-notification" "get-notifications-list-by-id-notification" "get-notifications-list-by-id-notification-by-field" "get-notifications-member-by-id-notification" "get-notifications-member-by-id-notification-by-field" "get-notifications-member-creator-by-id-notification" "get-notifications-member-creator-by-id-notification-by-field" "get-notifications-organization-by-id-notification" "get-notifications-organization-by-id-notification-by-field" "update-notifications-unread-by-id-notification" "get-notifications-by-id-notification-by-field" "add-organizations" "delete-organizations-by-id-org" "get-organizations-by-id-org" "update-organizations-by-id-org" "get-organizations-actions-by-id-org" "get-organizations-boards-by-id-org" "get-organizations-boards-by-id-org-by-filter" "get-organizations-deltas-by-id-org" "update-organizations-desc-by-id-org" "update-organizations-display-name-by-id-org" "delete-organizations-logo-by-id-org" "add-organizations-logo-by-id-org" "get-organizations-members-by-id-org" "update-organizations-members-by-id-org" "get-organizations-members-by-id-org-by-filter" "delete-organizations-members-by-id-org-by-id-member" "update-organizations-members-by-id-org-by-id-member" "delete-organizations-members-all-by-id-org-by-id-member" "get-organizations-members-cards-by-id-org-by-id-member" "update-organizations-members-deactivated-by-id-org-by-id-member" "get-organizations-members-invited-by-id-org" "get-organizations-members-invited-by-id-org-by-field" "get-organizations-memberships-by-id-org" "get-organizations-memberships-by-id-org-by-id-membership" "update-organizations-memberships-by-id-org-by-id-membership" "update-organizations-name-by-id-org" "delete-organizations-prefs-associated-domain-by-id-org" "update-organizations-prefs-associated-domain-by-id-org" "update-organizations-prefs-board-visibility-restrict-org-by-id-org" "update-organizations-prefs-board-visibility-restrict-private-by-id-org" "update-organizations-prefs-board-visibility-restrict-public-by-id-org" "update-organizations-prefs-external-members-disabled-by-id-org" "update-organizations-prefs-google-apps-version-by-id-org" "delete-organizations-prefs-org-invite-restrict-by-id-org" "update-organizations-prefs-org-invite-restrict-by-id-org" "update-organizations-prefs-permission-level-by-id-org" "update-organizations-website-by-id-org" "get-organizations-by-id-org-by-field" "get-search" "get-search-members" "add-sessions" "get-sessions-socket" "update-sessions-by-id-session" "update-sessions-status-by-id-session" "delete-tokens-by-token" "get-tokens-by-token" "get-tokens-member-by-token" "get-tokens-member-by-token-by-field" "get-tokens-webhooks-by-token" "add-tokens-webhooks-by-token" "update-tokens-webhooks-by-token" "delete-tokens-webhooks-by-token-by-id-webhook" "get-tokens-webhooks-by-token-by-id-webhook" "get-tokens-by-token-by-field" "get-types-by-id" "add-webhooks" "update-webhooks" "delete-webhooks-by-id-webhook" "get-webhooks-by-id-webhook" "update-webhooks-by-id-webhook" "update-webhooks-active-by-id-webhook" "update-webhooks-callback-url-by-id-webhook" "update-webhooks-description-by-id-webhook" "update-webhooks-id-model-by-id-webhook" "get-webhooks-by-id-webhook-by-field" "commands"] | sort) } | get name | first)
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

# deleteActionsByIdAction()
#
# DELETE /actions/{idAction}
# operationId: deleteActionsByIdAction
export def "delete-actions-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/actions/{idAction}"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsByIdAction()
#
# GET /actions/{idAction}
# operationId: getActionsByIdAction
export def "get-actions-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display: string # true or false
  --entities: string # true or false
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: display, var: display}, {name: entities, var: entities}, {name: fields, var: fields}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: memberCreator, var: member_creator}, {name: memberCreator_fields, var: member_creator_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, display: $display, entities: $entities, fields: $fields, member: $member, member_fields: $member_fields, member_creator: $member_creator, member_creator_fields: $member_creator_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateActionsByIdAction()
#
# PUT /actions/{idAction}
# operationId: updateActionsByIdAction
export def "update-actions-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/actions/{idAction}"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, key: $key, qp_token: $qp_token, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsBoardByIdAction()
#
# GET /actions/{idAction}/board
# operationId: getActionsBoardByIdAction
export def "get-actions-board-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/board"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsBoardByIdActionByField()
#
# GET /actions/{idAction}/board/{field}
# operationId: getActionsBoardByIdActionByField
export def "get-actions-board-by-id-action-by-field" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/board/{field}"
    path_params: [{name: idAction, var: id_action}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsCardByIdAction()
#
# GET /actions/{idAction}/card
# operationId: getActionsCardByIdAction
export def "get-actions-card-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/card"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsCardByIdActionByField()
#
# GET /actions/{idAction}/card/{field}
# operationId: getActionsCardByIdActionByField
export def "get-actions-card-by-id-action-by-field" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/card/{field}"
    path_params: [{name: idAction, var: id_action}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsDisplayByIdAction()
#
# GET /actions/{idAction}/display
# operationId: getActionsDisplayByIdAction
export def "get-actions-display-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/display"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsEntitiesByIdAction()
#
# GET /actions/{idAction}/entities
# operationId: getActionsEntitiesByIdAction
export def "get-actions-entities-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/entities"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsListByIdAction()
#
# GET /actions/{idAction}/list
# operationId: getActionsListByIdAction
export def "get-actions-list-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/list"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsListByIdActionByField()
#
# GET /actions/{idAction}/list/{field}
# operationId: getActionsListByIdActionByField
export def "get-actions-list-by-id-action-by-field" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/list/{field}"
    path_params: [{name: idAction, var: id_action}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsMemberByIdAction()
#
# GET /actions/{idAction}/member
# operationId: getActionsMemberByIdAction
export def "get-actions-member-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/member"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsMemberByIdActionByField()
#
# GET /actions/{idAction}/member/{field}
# operationId: getActionsMemberByIdActionByField
export def "get-actions-member-by-id-action-by-field" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/member/{field}"
    path_params: [{name: idAction, var: id_action}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsMemberCreatorByIdAction()
#
# GET /actions/{idAction}/memberCreator
# operationId: getActionsMemberCreatorByIdAction
export def "get-actions-member-creator-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/memberCreator"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsMemberCreatorByIdActionByField()
#
# GET /actions/{idAction}/memberCreator/{field}
# operationId: getActionsMemberCreatorByIdActionByField
export def "get-actions-member-creator-by-id-action-by-field" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/memberCreator/{field}"
    path_params: [{name: idAction, var: id_action}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsOrganizationByIdAction()
#
# GET /actions/{idAction}/organization
# operationId: getActionsOrganizationByIdAction
export def "get-actions-organization-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/organization"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsOrganizationByIdActionByField()
#
# GET /actions/{idAction}/organization/{field}
# operationId: getActionsOrganizationByIdActionByField
export def "get-actions-organization-by-id-action-by-field" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/organization/{field}"
    path_params: [{name: idAction, var: id_action}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateActionsTextByIdAction()
#
# PUT /actions/{idAction}/text
# operationId: updateActionsTextByIdAction
export def "update-actions-text-by-id-action" [
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/actions/{idAction}/text"
    path_params: [{name: idAction, var: id_action}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getActionsByIdActionByField()
#
# GET /actions/{idAction}/{field}
# operationId: getActionsByIdActionByField
export def "get-actions-by-id-action-by-field" [
  id_action: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/actions/{idAction}/{field}"
    path_params: [{name: idAction, var: id_action}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_action: $id_action, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBatch()
#
# GET /batch
# operationId: getBatch
export def "get-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --urls: string # list of API v1 GET routes, not including the version prefix (required)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/batch"
    query: [{name: urls, var: urls, required: true}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    urls: $urls, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addBoards()
#
# POST /boards
# operationId: addBoards
export def "add-boards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --closed: string # true or false
  --desc: string # a string with a length from 0 to 16384
  --id-board-source: string # The id of the board to copy into the new board
  --id-organization: string # The id or name of the organization to add the board to.
  --keep-from-source: string # Components of the source board to copy.
  --label-names-blue: string # a string with a length from 0 to 16384
  --label-names-green: string # a string with a length from 0 to 16384
  --label-names-orange: string # a string with a length from 0 to 16384
  --label-names-purple: string # a string with a length from 0 to 16384
  --label-names-red: string # a string with a length from 0 to 16384
  --label-names-yellow: string # a string with a length from 0 to 16384
  --name: string # a string with a length from 1 to 16384
  --power-ups: string # all or a comma-separated list of: calendar, cardAging, recap or voting
  --prefs-background: string # A standard background name, or the id of a custom background
  --prefs-calendar-feed-enabled: string # true or false
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string # true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string # true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --body-prefs-background: string # a string with a length from 0 to 16384 (spec name: prefs_background)
  --body-prefs-card-aging: string # One of: pirate or regular (spec name: prefs_cardAging)
  --body-prefs-card-covers: string # true or false (spec name: prefs_cardCovers)
  --body-prefs-comments: string # One of: disabled, members, observers, org or public (spec name: prefs_comments)
  --body-prefs-invitations: string # One of: admins or members (spec name: prefs_invitations)
  --body-prefs-permission-level: string # One of: org, private or public (spec name: prefs_permissionLevel)
  --body-prefs-self-join: string # true or false (spec name: prefs_selfJoin)
  --body-prefs-voting: string # One of: disabled, members, observers, org or public (spec name: prefs_voting)
  --subscribed: string # true or false
]: any -> any {
  $in | http-request {
    method: post
    path: "/boards"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed, var: closed}, {name: desc, var: desc}, {name: idBoardSource, var: id_board_source}, {name: idOrganization, var: id_organization}, {name: keepFromSource, var: keep_from_source}, {name: "labelNames/blue", var: label_names_blue}, {name: "labelNames/green", var: label_names_green}, {name: "labelNames/orange", var: label_names_orange}, {name: "labelNames/purple", var: label_names_purple}, {name: "labelNames/red", var: label_names_red}, {name: "labelNames/yellow", var: label_names_yellow}, {name: name, var: name}, {name: powerUps, var: power_ups}, {name: "prefs/background", var: prefs_background}, {name: "prefs/calendarFeedEnabled", var: prefs_calendar_feed_enabled}, {name: "prefs/cardAging", var: prefs_card_aging}, {name: "prefs/cardCovers", var: prefs_card_covers}, {name: "prefs/comments", var: prefs_comments}, {name: "prefs/invitations", var: prefs_invitations}, {name: "prefs/permissionLevel", var: prefs_permission_level}, {name: "prefs/selfJoin", var: prefs_self_join}, {name: "prefs/voting", var: prefs_voting}, {name: prefs_background, var: body_prefs_background}, {name: prefs_cardAging, var: body_prefs_card_aging}, {name: prefs_cardCovers, var: body_prefs_card_covers}, {name: prefs_comments, var: body_prefs_comments}, {name: prefs_invitations, var: body_prefs_invitations}, {name: prefs_permissionLevel, var: body_prefs_permission_level}, {name: prefs_selfJoin, var: body_prefs_self_join}, {name: prefs_voting, var: body_prefs_voting}, {name: subscribed, var: subscribed}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, closed: $closed, desc: $desc, id_board_source: $id_board_source, id_organization: $id_organization, keep_from_source: $keep_from_source, label_names_blue: $label_names_blue, label_names_green: $label_names_green, label_names_orange: $label_names_orange, label_names_purple: $label_names_purple, label_names_red: $label_names_red, label_names_yellow: $label_names_yellow, name: $name, power_ups: $power_ups, prefs_background: $prefs_background, prefs_calendar_feed_enabled: $prefs_calendar_feed_enabled, prefs_card_aging: $prefs_card_aging, prefs_card_covers: $prefs_card_covers, prefs_comments: $prefs_comments, prefs_invitations: $prefs_invitations, prefs_permission_level: $prefs_permission_level, prefs_self_join: $prefs_self_join, prefs_voting: $prefs_voting, body_prefs_background: $body_prefs_background, body_prefs_card_aging: $body_prefs_card_aging, body_prefs_card_covers: $body_prefs_card_covers, body_prefs_comments: $body_prefs_comments, body_prefs_invitations: $body_prefs_invitations, body_prefs_permission_level: $body_prefs_permission_level, body_prefs_self_join: $body_prefs_self_join, body_prefs_voting: $body_prefs_voting, subscribed: $subscribed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsByIdBoard()
#
# GET /boards/{idBoard}
# operationId: getBoardsByIdBoard
export def "get-boards-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member: string # true or false
  --action-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --action-member-creator: string # true or false
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --card-attachments: string # A boolean value or "cover" for only card cover attachments
  --card-attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --card-checklists: string # One of: all or none (default: none)
  --card-stickers: string # true or false
  --board-stars: string # One of: mine or none (default: none)
  --labels: string # One of: all or none (default: none)
  --label-fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --labels-limit: string # a number from 0 to 1000 (default: 50)
  --lists: string # One of: all, closed, none or open (default: none)
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --memberships-member: string # true or false
  --memberships-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --members: string # One of: admins, all, none, normal or owners (default: none)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName, username and confirmed)
  --members-invited: string # One of: admins, all, none, normal or owners (default: none)
  --members-invited-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --organization: string # true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --organization-memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --my-prefs: string # true or false
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url, shortUrl, prefs and labelNames)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: actions, var: actions}, {name: actions_entities, var: actions_entities}, {name: actions_display, var: actions_display}, {name: actions_format, var: actions_format}, {name: actions_since, var: actions_since}, {name: actions_limit, var: actions_limit}, {name: action_fields, var: action_fields}, {name: action_member, var: action_member}, {name: action_member_fields, var: action_member_fields}, {name: action_memberCreator, var: action_member_creator}, {name: action_memberCreator_fields, var: action_member_creator_fields}, {name: cards, var: cards}, {name: card_fields, var: card_fields}, {name: card_attachments, var: card_attachments}, {name: card_attachment_fields, var: card_attachment_fields}, {name: card_checklists, var: card_checklists}, {name: card_stickers, var: card_stickers}, {name: boardStars, var: board_stars}, {name: labels, var: labels}, {name: label_fields, var: label_fields}, {name: labels_limit, var: labels_limit}, {name: lists, var: lists}, {name: list_fields, var: list_fields}, {name: memberships, var: memberships}, {name: memberships_member, var: memberships_member}, {name: memberships_member_fields, var: memberships_member_fields}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: membersInvited, var: members_invited}, {name: membersInvited_fields, var: members_invited_fields}, {name: checklists, var: checklists}, {name: checklist_fields, var: checklist_fields}, {name: organization, var: organization}, {name: organization_fields, var: organization_fields}, {name: organization_memberships, var: organization_memberships}, {name: myPrefs, var: my_prefs}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, actions: $actions, actions_entities: $actions_entities, actions_display: $actions_display, actions_format: $actions_format, actions_since: $actions_since, actions_limit: $actions_limit, action_fields: $action_fields, action_member: $action_member, action_member_fields: $action_member_fields, action_member_creator: $action_member_creator, action_member_creator_fields: $action_member_creator_fields, cards: $cards, card_fields: $card_fields, card_attachments: $card_attachments, card_attachment_fields: $card_attachment_fields, card_checklists: $card_checklists, card_stickers: $card_stickers, board_stars: $board_stars, labels: $labels, label_fields: $label_fields, labels_limit: $labels_limit, lists: $lists, list_fields: $list_fields, memberships: $memberships, memberships_member: $memberships_member, memberships_member_fields: $memberships_member_fields, members: $members, member_fields: $member_fields, members_invited: $members_invited, members_invited_fields: $members_invited_fields, checklists: $checklists, checklist_fields: $checklist_fields, organization: $organization, organization_fields: $organization_fields, organization_memberships: $organization_memberships, my_prefs: $my_prefs, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsByIdBoard()
#
# PUT /boards/{idBoard}
# operationId: updateBoardsByIdBoard
export def "update-boards-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --closed: string # true or false
  --desc: string # a string with a length from 0 to 16384
  --id-board-source: string # The id of the board to copy into the new board
  --id-organization: string # The id or name of the organization to add the board to.
  --keep-from-source: string # Components of the source board to copy.
  --label-names-blue: string # a string with a length from 0 to 16384
  --label-names-green: string # a string with a length from 0 to 16384
  --label-names-orange: string # a string with a length from 0 to 16384
  --label-names-purple: string # a string with a length from 0 to 16384
  --label-names-red: string # a string with a length from 0 to 16384
  --label-names-yellow: string # a string with a length from 0 to 16384
  --name: string # a string with a length from 1 to 16384
  --power-ups: string # all or a comma-separated list of: calendar, cardAging, recap or voting
  --prefs-background: string # A standard background name, or the id of a custom background
  --prefs-calendar-feed-enabled: string # true or false
  --prefs-card-aging: string # One of: pirate or regular
  --prefs-card-covers: string # true or false
  --prefs-comments: string # One of: disabled, members, observers, org or public
  --prefs-invitations: string # One of: admins or members
  --prefs-permission-level: string # One of: org, private or public
  --prefs-self-join: string # true or false
  --prefs-voting: string # One of: disabled, members, observers, org or public
  --body-prefs-background: string # a string with a length from 0 to 16384 (spec name: prefs_background)
  --body-prefs-card-aging: string # One of: pirate or regular (spec name: prefs_cardAging)
  --body-prefs-card-covers: string # true or false (spec name: prefs_cardCovers)
  --body-prefs-comments: string # One of: disabled, members, observers, org or public (spec name: prefs_comments)
  --body-prefs-invitations: string # One of: admins or members (spec name: prefs_invitations)
  --body-prefs-permission-level: string # One of: org, private or public (spec name: prefs_permissionLevel)
  --body-prefs-self-join: string # true or false (spec name: prefs_selfJoin)
  --body-prefs-voting: string # One of: disabled, members, observers, org or public (spec name: prefs_voting)
  --subscribed: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed, var: closed}, {name: desc, var: desc}, {name: idBoardSource, var: id_board_source}, {name: idOrganization, var: id_organization}, {name: keepFromSource, var: keep_from_source}, {name: "labelNames/blue", var: label_names_blue}, {name: "labelNames/green", var: label_names_green}, {name: "labelNames/orange", var: label_names_orange}, {name: "labelNames/purple", var: label_names_purple}, {name: "labelNames/red", var: label_names_red}, {name: "labelNames/yellow", var: label_names_yellow}, {name: name, var: name}, {name: powerUps, var: power_ups}, {name: "prefs/background", var: prefs_background}, {name: "prefs/calendarFeedEnabled", var: prefs_calendar_feed_enabled}, {name: "prefs/cardAging", var: prefs_card_aging}, {name: "prefs/cardCovers", var: prefs_card_covers}, {name: "prefs/comments", var: prefs_comments}, {name: "prefs/invitations", var: prefs_invitations}, {name: "prefs/permissionLevel", var: prefs_permission_level}, {name: "prefs/selfJoin", var: prefs_self_join}, {name: "prefs/voting", var: prefs_voting}, {name: prefs_background, var: body_prefs_background}, {name: prefs_cardAging, var: body_prefs_card_aging}, {name: prefs_cardCovers, var: body_prefs_card_covers}, {name: prefs_comments, var: body_prefs_comments}, {name: prefs_invitations, var: body_prefs_invitations}, {name: prefs_permissionLevel, var: body_prefs_permission_level}, {name: prefs_selfJoin, var: body_prefs_self_join}, {name: prefs_voting, var: body_prefs_voting}, {name: subscribed, var: subscribed}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, closed: $closed, desc: $desc, id_board_source: $id_board_source, id_organization: $id_organization, keep_from_source: $keep_from_source, label_names_blue: $label_names_blue, label_names_green: $label_names_green, label_names_orange: $label_names_orange, label_names_purple: $label_names_purple, label_names_red: $label_names_red, label_names_yellow: $label_names_yellow, name: $name, power_ups: $power_ups, prefs_background: $prefs_background, prefs_calendar_feed_enabled: $prefs_calendar_feed_enabled, prefs_card_aging: $prefs_card_aging, prefs_card_covers: $prefs_card_covers, prefs_comments: $prefs_comments, prefs_invitations: $prefs_invitations, prefs_permission_level: $prefs_permission_level, prefs_self_join: $prefs_self_join, prefs_voting: $prefs_voting, body_prefs_background: $body_prefs_background, body_prefs_card_aging: $body_prefs_card_aging, body_prefs_card_covers: $body_prefs_card_covers, body_prefs_comments: $body_prefs_comments, body_prefs_invitations: $body_prefs_invitations, body_prefs_permission_level: $body_prefs_permission_level, body_prefs_self_join: $body_prefs_self_join, body_prefs_voting: $body_prefs_voting, subscribed: $subscribed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsActionsByIdBoard()
#
# GET /boards/{idBoard}/actions
# operationId: getBoardsActionsByIdBoard
export def "get-boards-actions-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/actions"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: entities, var: entities}, {name: display, var: display}, {name: filter, var: filter}, {name: fields, var: fields}, {name: limit, var: limit}, {name: format, var: format}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: idModels, var: id_models}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: memberCreator, var: member_creator}, {name: memberCreator_fields, var: member_creator_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, entities: $entities, display: $display, filter: $filter, fields: $fields, limit: $limit, format: $format, since: $since, before: $before, page: $page, id_models: $id_models, member: $member, member_fields: $member_fields, member_creator: $member_creator, member_creator_fields: $member_creator_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsBoardStarsByIdBoard()
#
# GET /boards/{idBoard}/boardStars
# operationId: getBoardsBoardStarsByIdBoard
export def "get-boards-board-stars-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: mine or none (default: mine)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/boardStars"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: filter, var: filter}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addBoardsCalendarKeyGenerateByIdBoard()
#
# POST /boards/{idBoard}/calendarKey/generate
# operationId: addBoardsCalendarKeyGenerateByIdBoard
export def "add-boards-calendar-key-generate-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/boards/{idBoard}/calendarKey/generate"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsCardsByIdBoard()
#
# GET /boards/{idBoard}/cards
# operationId: getBoardsCardsByIdBoard
export def "get-boards-cards-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string # true or false
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/cards"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: actions, var: actions}, {name: attachments, var: attachments}, {name: attachment_fields, var: attachment_fields}, {name: stickers, var: stickers}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: checkItemStates, var: check_item_states}, {name: checklists, var: checklists}, {name: limit, var: limit}, {name: since, var: since}, {name: before, var: before}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, actions: $actions, attachments: $attachments, attachment_fields: $attachment_fields, stickers: $stickers, members: $members, member_fields: $member_fields, check_item_states: $check_item_states, checklists: $checklists, limit: $limit, since: $since, before: $before, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsCardsByIdBoardByFilter()
#
# GET /boards/{idBoard}/cards/{filter}
# operationId: getBoardsCardsByIdBoardByFilter
export def "get-boards-cards-by-id-board-by-filter" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/cards/{filter}"
    path_params: [{name: idBoard, var: id_board}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsCardsByIdBoardByIdCard()
#
# GET /boards/{idBoard}/cards/{idCard}
# operationId: getBoardsCardsByIdBoardByIdCard
export def "get-boards-cards-by-id-board-by-id-card" [
  id_board: string
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --check-item-states: string # true or false
  --check-item-state-fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --labels: string # true or false
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/cards/{idCard}"
    path_params: [{name: idBoard, var: id_board}, {name: idCard, var: id_card}]
    query: [{name: attachments, var: attachments}, {name: attachment_fields, var: attachment_fields}, {name: actions, var: actions}, {name: actions_entities, var: actions_entities}, {name: actions_display, var: actions_display}, {name: actions_limit, var: actions_limit}, {name: action_fields, var: action_fields}, {name: action_memberCreator_fields, var: action_member_creator_fields}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: checkItemStates, var: check_item_states}, {name: checkItemState_fields, var: check_item_state_fields}, {name: labels, var: labels}, {name: checklists, var: checklists}, {name: checklist_fields, var: checklist_fields}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, id_card: $id_card, attachments: $attachments, attachment_fields: $attachment_fields, actions: $actions, actions_entities: $actions_entities, actions_display: $actions_display, actions_limit: $actions_limit, action_fields: $action_fields, action_member_creator_fields: $action_member_creator_fields, members: $members, member_fields: $member_fields, check_item_states: $check_item_states, check_item_state_fields: $check_item_state_fields, labels: $labels, checklists: $checklists, checklist_fields: $checklist_fields, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsChecklistsByIdBoard()
#
# GET /boards/{idBoard}/checklists
# operationId: getBoardsChecklistsByIdBoard
export def "get-boards-checklists-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/checklists"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: cards, var: cards}, {name: card_fields, var: card_fields}, {name: checkItems, var: check_items}, {name: checkItem_fields, var: check_item_fields}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, cards: $cards, card_fields: $card_fields, check_items: $check_items, check_item_fields: $check_item_fields, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addBoardsChecklistsByIdBoard()
#
# POST /boards/{idBoard}/checklists
# operationId: addBoardsChecklistsByIdBoard
export def "add-boards-checklists-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --name: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: post
    path: "/boards/{idBoard}/checklists"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsClosedByIdBoard()
#
# PUT /boards/{idBoard}/closed
# operationId: updateBoardsClosedByIdBoard
export def "update-boards-closed-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/closed"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsDeltasByIdBoard()
#
# GET /boards/{idBoard}/deltas
# operationId: getBoardsDeltasByIdBoard
export def "get-boards-deltas-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing (required)
  --ix-last-update: string # a number from -1 to Infinity (required)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/deltas"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: tags, var: tags, required: true}, {name: ixLastUpdate, var: ix_last_update, required: true}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, tags: $tags, ix_last_update: $ix_last_update, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsDescByIdBoard()
#
# PUT /boards/{idBoard}/desc
# operationId: updateBoardsDescByIdBoard
export def "update-boards-desc-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/desc"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addBoardsEmailKeyGenerateByIdBoard()
#
# POST /boards/{idBoard}/emailKey/generate
# operationId: addBoardsEmailKeyGenerateByIdBoard
export def "add-boards-email-key-generate-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/boards/{idBoard}/emailKey/generate"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsIdOrganizationByIdBoard()
#
# PUT /boards/{idBoard}/idOrganization
# operationId: updateBoardsIdOrganizationByIdBoard
export def "update-boards-id-organization-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/idOrganization"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsLabelNamesBlueByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/blue
# operationId: updateBoardsLabelNamesBlueByIdBoard
export def "update-boards-label-names-blue-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/labelNames/blue"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsLabelNamesGreenByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/green
# operationId: updateBoardsLabelNamesGreenByIdBoard
export def "update-boards-label-names-green-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/labelNames/green"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsLabelNamesOrangeByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/orange
# operationId: updateBoardsLabelNamesOrangeByIdBoard
export def "update-boards-label-names-orange-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/labelNames/orange"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsLabelNamesPurpleByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/purple
# operationId: updateBoardsLabelNamesPurpleByIdBoard
export def "update-boards-label-names-purple-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/labelNames/purple"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsLabelNamesRedByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/red
# operationId: updateBoardsLabelNamesRedByIdBoard
export def "update-boards-label-names-red-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/labelNames/red"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsLabelNamesYellowByIdBoard()
#
# PUT /boards/{idBoard}/labelNames/yellow
# operationId: updateBoardsLabelNamesYellowByIdBoard
export def "update-boards-label-names-yellow-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/labelNames/yellow"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsLabelsByIdBoard()
#
# GET /boards/{idBoard}/labels
# operationId: getBoardsLabelsByIdBoard
export def "get-boards-labels-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/labels"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: fields, var: fields}, {name: limit, var: limit}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, fields: $fields, limit: $limit, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addBoardsLabelsByIdBoard()
#
# POST /boards/{idBoard}/labels
# operationId: addBoardsLabelsByIdBoard
export def "add-boards-labels-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: post
    path: "/boards/{idBoard}/labels"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, color: $color, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsLabelsByIdBoardByIdLabel()
#
# GET /boards/{idBoard}/labels/{idLabel}
# operationId: getBoardsLabelsByIdBoardByIdLabel
export def "get-boards-labels-by-id-board-by-id-label" [
  id_board: string
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/labels/{idLabel}"
    path_params: [{name: idBoard, var: id_board}, {name: idLabel, var: id_label}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, id_label: $id_label, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsListsByIdBoard()
#
# GET /boards/{idBoard}/lists
# operationId: getBoardsListsByIdBoard
export def "get-boards-lists-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/lists"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: cards, var: cards}, {name: card_fields, var: card_fields}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, cards: $cards, card_fields: $card_fields, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addBoardsListsByIdBoard()
#
# POST /boards/{idBoard}/lists
# operationId: addBoardsListsByIdBoard
export def "add-boards-lists-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: post
    path: "/boards/{idBoard}/lists"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: pos, var: pos}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, name: $name, pos: $pos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsListsByIdBoardByFilter()
#
# GET /boards/{idBoard}/lists/{filter}
# operationId: getBoardsListsByIdBoardByFilter
export def "get-boards-lists-by-id-board-by-filter" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/lists/{filter}"
    path_params: [{name: idBoard, var: id_board}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addBoardsMarkAsViewedByIdBoard()
#
# POST /boards/{idBoard}/markAsViewed
# operationId: addBoardsMarkAsViewedByIdBoard
export def "add-boards-mark-as-viewed-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/boards/{idBoard}/markAsViewed"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsMembersByIdBoard()
#
# GET /boards/{idBoard}/members
# operationId: getBoardsMembersByIdBoard
export def "get-boards-members-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: admins, all, none, normal or owners (default: all)
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --activity: string # true or false ; works for premium organizations only.
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/members"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: filter, var: filter}, {name: fields, var: fields}, {name: activity, var: activity}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, filter: $filter, fields: $fields, activity: $activity, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMembersByIdBoard()
#
# PUT /boards/{idBoard}/members
# operationId: updateBoardsMembersByIdBoard
export def "update-boards-members-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --email: string # An email address
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/members"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: fullName, var: full_name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, email: $email, full_name: $full_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsMembersByIdBoardByFilter()
#
# GET /boards/{idBoard}/members/{filter}
# operationId: getBoardsMembersByIdBoardByFilter
export def "get-boards-members-by-id-board-by-filter" [
  id_board: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/members/{filter}"
    path_params: [{name: idBoard, var: id_board}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteBoardsMembersByIdBoardByIdMember()
#
# DELETE /boards/{idBoard}/members/{idMember}
# operationId: deleteBoardsMembersByIdBoardByIdMember
export def "delete-boards-members-by-id-board-by-id-member" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/boards/{idBoard}/members/{idMember}"
    path_params: [{name: idBoard, var: id_board}, {name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, id_member: $id_member, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMembersByIdBoardByIdMember()
#
# PUT /boards/{idBoard}/members/{idMember}
# operationId: updateBoardsMembersByIdBoardByIdMember
export def "update-boards-members-by-id-board-by-id-member" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --email: string # An email address
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/members/{idMember}"
    path_params: [{name: idBoard, var: id_board}, {name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: fullName, var: full_name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, id_member: $id_member, key: $key, qp_token: $qp_token, email: $email, full_name: $full_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsMembersCardsByIdBoardByIdMember()
#
# GET /boards/{idBoard}/members/{idMember}/cards
# operationId: getBoardsMembersCardsByIdBoardByIdMember
export def "get-boards-members-cards-by-id-board-by-id-member" [
  id_board: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, closed, idOrganization, pinned, url and prefs)
  --list: string # true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/members/{idMember}/cards"
    path_params: [{name: idBoard, var: id_board}, {name: idMember, var: id_member}]
    query: [{name: actions, var: actions}, {name: attachments, var: attachments}, {name: attachment_fields, var: attachment_fields}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: checkItemStates, var: check_item_states}, {name: checklists, var: checklists}, {name: board, var: board}, {name: board_fields, var: board_fields}, {name: list, var: list}, {name: list_fields, var: list_fields}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, id_member: $id_member, actions: $actions, attachments: $attachments, attachment_fields: $attachment_fields, members: $members, member_fields: $member_fields, check_item_states: $check_item_states, checklists: $checklists, board: $board, board_fields: $board_fields, list: $list, list_fields: $list_fields, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsMembersInvitedByIdBoard()
#
# GET /boards/{idBoard}/membersInvited
# operationId: getBoardsMembersInvitedByIdBoard
export def "get-boards-members-invited-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/membersInvited"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsMembersInvitedByIdBoardByField()
#
# GET /boards/{idBoard}/membersInvited/{field}
# operationId: getBoardsMembersInvitedByIdBoardByField
export def "get-boards-members-invited-by-id-board-by-field" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/membersInvited/{field}"
    path_params: [{name: idBoard, var: id_board}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsMembershipsByIdBoard()
#
# GET /boards/{idBoard}/memberships
# operationId: getBoardsMembershipsByIdBoard
export def "get-boards-memberships-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: all)
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/memberships"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: filter, var: filter}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, filter: $filter, member: $member, member_fields: $member_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsMembershipsByIdBoardByIdMembership()
#
# GET /boards/{idBoard}/memberships/{idMembership}
# operationId: getBoardsMembershipsByIdBoardByIdMembership
export def "get-boards-memberships-by-id-board-by-id-membership" [
  id_board: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/memberships/{idMembership}"
    path_params: [{name: idBoard, var: id_board}, {name: idMembership, var: id_membership}]
    query: [{name: member, var: member}, {name: member_fields, var: member_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, id_membership: $id_membership, member: $member, member_fields: $member_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMembershipsByIdBoardByIdMembership()
#
# PUT /boards/{idBoard}/memberships/{idMembership}
# operationId: updateBoardsMembershipsByIdBoardByIdMembership
export def "update-boards-memberships-by-id-board-by-id-membership" [
  id_board: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username
  --type: string # One of: admin, normal or observer
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/memberships/{idMembership}"
    path_params: [{name: idBoard, var: id_board}, {name: idMembership, var: id_membership}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: member_fields, var: member_fields}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, id_membership: $id_membership, key: $key, qp_token: $qp_token, member_fields: $member_fields, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsMyPrefsByIdBoard()
#
# GET /boards/{idBoard}/myPrefs
# operationId: getBoardsMyPrefsByIdBoard
export def "get-boards-my-prefs-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/myPrefs"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMyPrefsEmailPositionByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/emailPosition
# operationId: updateBoardsMyPrefsEmailPositionByIdBoard
export def "update-boards-my-prefs-email-position-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: bottom or top
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/myPrefs/emailPosition"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMyPrefsIdEmailListByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/idEmailList
# operationId: updateBoardsMyPrefsIdEmailListByIdBoard
export def "update-boards-my-prefs-id-email-list-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # An id
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/myPrefs/idEmailList"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMyPrefsShowListGuideByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showListGuide
# operationId: updateBoardsMyPrefsShowListGuideByIdBoard
export def "update-boards-my-prefs-show-list-guide-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/myPrefs/showListGuide"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMyPrefsShowSidebarByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showSidebar
# operationId: updateBoardsMyPrefsShowSidebarByIdBoard
export def "update-boards-my-prefs-show-sidebar-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/myPrefs/showSidebar"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMyPrefsShowSidebarActivityByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showSidebarActivity
# operationId: updateBoardsMyPrefsShowSidebarActivityByIdBoard
export def "update-boards-my-prefs-show-sidebar-activity-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/myPrefs/showSidebarActivity"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMyPrefsShowSidebarBoardActionsByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showSidebarBoardActions
# operationId: updateBoardsMyPrefsShowSidebarBoardActionsByIdBoard
export def "update-boards-my-prefs-show-sidebar-board-actions-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/myPrefs/showSidebarBoardActions"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsMyPrefsShowSidebarMembersByIdBoard()
#
# PUT /boards/{idBoard}/myPrefs/showSidebarMembers
# operationId: updateBoardsMyPrefsShowSidebarMembersByIdBoard
export def "update-boards-my-prefs-show-sidebar-members-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/myPrefs/showSidebarMembers"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsNameByIdBoard()
#
# PUT /boards/{idBoard}/name
# operationId: updateBoardsNameByIdBoard
export def "update-boards-name-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/name"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsOrganizationByIdBoard()
#
# GET /boards/{idBoard}/organization
# operationId: getBoardsOrganizationByIdBoard
export def "get-boards-organization-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/organization"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsOrganizationByIdBoardByField()
#
# GET /boards/{idBoard}/organization/{field}
# operationId: getBoardsOrganizationByIdBoardByField
export def "get-boards-organization-by-id-board-by-field" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/organization/{field}"
    path_params: [{name: idBoard, var: id_board}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addBoardsPowerUpsByIdBoard()
#
# POST /boards/{idBoard}/powerUps
# operationId: addBoardsPowerUpsByIdBoard
export def "add-boards-power-ups-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: calendar, cardAging, recap or voting
]: any -> any {
  $in | http-request {
    method: post
    path: "/boards/{idBoard}/powerUps"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteBoardsPowerUpsByIdBoardByPowerUp()
#
# DELETE /boards/{idBoard}/powerUps/{powerUp}
# operationId: deleteBoardsPowerUpsByIdBoardByPowerUp
export def "delete-boards-power-ups-by-id-board-by-power-up" [
  id_board: string
  power_up: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/boards/{idBoard}/powerUps/{powerUp}"
    path_params: [{name: idBoard, var: id_board}, {name: powerUp, var: power_up}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, power_up: $power_up, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsBackgroundByIdBoard()
#
# PUT /boards/{idBoard}/prefs/background
# operationId: updateBoardsPrefsBackgroundByIdBoard
export def "update-boards-prefs-background-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A standard background name, or the id of a custom background
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/background"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsCalendarFeedEnabledByIdBoard()
#
# PUT /boards/{idBoard}/prefs/calendarFeedEnabled
# operationId: updateBoardsPrefsCalendarFeedEnabledByIdBoard
export def "update-boards-prefs-calendar-feed-enabled-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/calendarFeedEnabled"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsCardAgingByIdBoard()
#
# PUT /boards/{idBoard}/prefs/cardAging
# operationId: updateBoardsPrefsCardAgingByIdBoard
export def "update-boards-prefs-card-aging-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: pirate or regular
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/cardAging"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsCardCoversByIdBoard()
#
# PUT /boards/{idBoard}/prefs/cardCovers
# operationId: updateBoardsPrefsCardCoversByIdBoard
export def "update-boards-prefs-card-covers-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/cardCovers"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsCommentsByIdBoard()
#
# PUT /boards/{idBoard}/prefs/comments
# operationId: updateBoardsPrefsCommentsByIdBoard
export def "update-boards-prefs-comments-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: disabled, members, observers, org or public
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/comments"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsInvitationsByIdBoard()
#
# PUT /boards/{idBoard}/prefs/invitations
# operationId: updateBoardsPrefsInvitationsByIdBoard
export def "update-boards-prefs-invitations-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: admins or members
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/invitations"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsPermissionLevelByIdBoard()
#
# PUT /boards/{idBoard}/prefs/permissionLevel
# operationId: updateBoardsPrefsPermissionLevelByIdBoard
export def "update-boards-prefs-permission-level-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: private or public
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/permissionLevel"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsSelfJoinByIdBoard()
#
# PUT /boards/{idBoard}/prefs/selfJoin
# operationId: updateBoardsPrefsSelfJoinByIdBoard
export def "update-boards-prefs-self-join-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/selfJoin"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsPrefsVotingByIdBoard()
#
# PUT /boards/{idBoard}/prefs/voting
# operationId: updateBoardsPrefsVotingByIdBoard
export def "update-boards-prefs-voting-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: disabled, members, observers, org or public
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/prefs/voting"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateBoardsSubscribedByIdBoard()
#
# PUT /boards/{idBoard}/subscribed
# operationId: updateBoardsSubscribedByIdBoard
export def "update-boards-subscribed-by-id-board" [
  id_board: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/boards/{idBoard}/subscribed"
    path_params: [{name: idBoard, var: id_board}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getBoardsByIdBoardByField()
#
# GET /boards/{idBoard}/{field}
# operationId: getBoardsByIdBoardByField
export def "get-boards-by-id-board-by-field" [
  id_board: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/boards/{idBoard}/{field}"
    path_params: [{name: idBoard, var: id_board}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_board: $id_board, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCards()
#
# POST /cards
# operationId: addCards
export def "add-cards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --closed: string # true or false
  --desc: string # a string with a length from 0 to 16384
  --due: string # A date, or null
  --file-source: string # A file
  --id-attachment-cover: string # Id of the image attachment of this card to use as its cover, or null for no cover
  --id-board: string # id of the board the card should be moved to
  --id-card-source: string # The id of the card to copy into a new card.
  --id-labels: string # A comma-separated list of objectIds, 24-character hex strings
  --id-list: string # id of the list that the card should be added to
  --id-members: string # A comma-separated list of objectIds, 24-character hex strings
  --keep-from-source: string # Properties of the card to copy over from the source.
  --labels: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
  --name: string # The name of the new card. It isn't required if the name is being copied from provided by a URL, file or card that is being copied.
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string # true or false
  --url-source: string # A URL starting with http:// or https:// or null
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed, var: closed}, {name: desc, var: desc}, {name: due, var: due}, {name: fileSource, var: file_source}, {name: idAttachmentCover, var: id_attachment_cover}, {name: idBoard, var: id_board}, {name: idCardSource, var: id_card_source}, {name: idLabels, var: id_labels}, {name: idList, var: id_list}, {name: idMembers, var: id_members}, {name: keepFromSource, var: keep_from_source}, {name: labels, var: labels}, {name: name, var: name}, {name: pos, var: pos}, {name: subscribed, var: subscribed}, {name: urlSource, var: url_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, closed: $closed, desc: $desc, due: $due, file_source: $file_source, id_attachment_cover: $id_attachment_cover, id_board: $id_board, id_card_source: $id_card_source, id_labels: $id_labels, id_list: $id_list, id_members: $id_members, keep_from_source: $keep_from_source, labels: $labels, name: $name, pos: $pos, subscribed: $subscribed, url_source: $url_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsByIdCard()
#
# DELETE /cards/{idCard}
# operationId: deleteCardsByIdCard
export def "delete-cards-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsByIdCard()
#
# GET /cards/{idCard}
# operationId: getCardsByIdCard
export def "get-cards-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --members-voted: string # true or false
  --member-voted-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --check-item-state-fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --checklists: string # One of: all or none (default: none)
  --checklist-fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url and prefs)
  --list: string # true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --stickers: string # true or false
  --sticker-fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idBoard, idChecklists, idLabels, idList, idMembers, idShort, idAttachmentCover, manualCoverAttachment, labels, name, pos, shortUrl and url)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: actions, var: actions}, {name: actions_entities, var: actions_entities}, {name: actions_display, var: actions_display}, {name: actions_limit, var: actions_limit}, {name: action_fields, var: action_fields}, {name: action_memberCreator_fields, var: action_member_creator_fields}, {name: attachments, var: attachments}, {name: attachment_fields, var: attachment_fields}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: membersVoted, var: members_voted}, {name: memberVoted_fields, var: member_voted_fields}, {name: checkItemStates, var: check_item_states}, {name: checkItemState_fields, var: check_item_state_fields}, {name: checklists, var: checklists}, {name: checklist_fields, var: checklist_fields}, {name: board, var: board}, {name: board_fields, var: board_fields}, {name: list, var: list}, {name: list_fields, var: list_fields}, {name: stickers, var: stickers}, {name: sticker_fields, var: sticker_fields}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, actions: $actions, actions_entities: $actions_entities, actions_display: $actions_display, actions_limit: $actions_limit, action_fields: $action_fields, action_member_creator_fields: $action_member_creator_fields, attachments: $attachments, attachment_fields: $attachment_fields, members: $members, member_fields: $member_fields, members_voted: $members_voted, member_voted_fields: $member_voted_fields, check_item_states: $check_item_states, check_item_state_fields: $check_item_state_fields, checklists: $checklists, checklist_fields: $checklist_fields, board: $board, board_fields: $board_fields, list: $list, list_fields: $list_fields, stickers: $stickers, sticker_fields: $sticker_fields, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsByIdCard()
#
# PUT /cards/{idCard}
# operationId: updateCardsByIdCard
export def "update-cards-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --closed: string # true or false
  --desc: string # a string with a length from 0 to 16384
  --due: string # A date, or null
  --file-source: string # A file
  --id-attachment-cover: string # Id of the image attachment of this card to use as its cover, or null for no cover
  --id-board: string # id of the board the card should be moved to
  --id-card-source: string # The id of the card to copy into a new card.
  --id-labels: string # A comma-separated list of objectIds, 24-character hex strings
  --id-list: string # id of the list that the card should be added to
  --id-members: string # A comma-separated list of objectIds, 24-character hex strings
  --keep-from-source: string # Properties of the card to copy over from the source.
  --labels: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
  --name: string # The name of the new card. It isn't required if the name is being copied from provided by a URL, file or card that is being copied.
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string # true or false
  --url-source: string # A URL starting with http:// or https:// or null
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed, var: closed}, {name: desc, var: desc}, {name: due, var: due}, {name: fileSource, var: file_source}, {name: idAttachmentCover, var: id_attachment_cover}, {name: idBoard, var: id_board}, {name: idCardSource, var: id_card_source}, {name: idLabels, var: id_labels}, {name: idList, var: id_list}, {name: idMembers, var: id_members}, {name: keepFromSource, var: keep_from_source}, {name: labels, var: labels}, {name: name, var: name}, {name: pos, var: pos}, {name: subscribed, var: subscribed}, {name: urlSource, var: url_source}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, closed: $closed, desc: $desc, due: $due, file_source: $file_source, id_attachment_cover: $id_attachment_cover, id_board: $id_board, id_card_source: $id_card_source, id_labels: $id_labels, id_list: $id_list, id_members: $id_members, keep_from_source: $keep_from_source, labels: $labels, name: $name, pos: $pos, subscribed: $subscribed, url_source: $url_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsActionsByIdCard()
#
# GET /cards/{idCard}/actions
# operationId: getCardsActionsByIdCard
export def "get-cards-actions-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: commentCard and updateCard:idList)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/actions"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: entities, var: entities}, {name: display, var: display}, {name: filter, var: filter}, {name: fields, var: fields}, {name: limit, var: limit}, {name: format, var: format}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: idModels, var: id_models}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: memberCreator, var: member_creator}, {name: memberCreator_fields, var: member_creator_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, entities: $entities, display: $display, filter: $filter, fields: $fields, limit: $limit, format: $format, since: $since, before: $before, page: $page, id_models: $id_models, member: $member, member_fields: $member_fields, member_creator: $member_creator, member_creator_fields: $member_creator_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsActionsCommentsByIdCard()
#
# POST /cards/{idCard}/actions/comments
# operationId: addCardsActionsCommentsByIdCard
export def "add-cards-actions-comments-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/actions/comments"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsActionsCommentsByIdCardByIdAction()
#
# DELETE /cards/{idCard}/actions/{idAction}/comments
# operationId: deleteCardsActionsCommentsByIdCardByIdAction
export def "delete-cards-actions-comments-by-id-card-by-id-action" [
  id_card: string
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/actions/{idAction}/comments"
    path_params: [{name: idCard, var: id_card}, {name: idAction, var: id_action}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_action: $id_action, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsActionsCommentsByIdCardByIdAction()
#
# PUT /cards/{idCard}/actions/{idAction}/comments
# operationId: updateCardsActionsCommentsByIdCardByIdAction
export def "update-cards-actions-comments-by-id-card-by-id-action" [
  id_card: string
  id_action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --text: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/actions/{idAction}/comments"
    path_params: [{name: idCard, var: id_card}, {name: idAction, var: id_action}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_action: $id_action, key: $key, qp_token: $qp_token, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsAttachmentsByIdCard()
#
# GET /cards/{idCard}/attachments
# operationId: getCardsAttachmentsByIdCard
export def "get-cards-attachments-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --filter: string # A boolean value or "cover" for only card cover attachments
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/attachments"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: fields, var: fields}, {name: filter, var: filter}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, fields: $fields, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsAttachmentsByIdCard()
#
# POST /cards/{idCard}/attachments
# operationId: addCardsAttachmentsByIdCard
export def "add-cards-attachments-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --file: string # A file
  --mime-type: string # a string with a length from 0 to 256
  --name: string # a string with a length from 0 to 256
  --url: string # A URL starting with http:// or https:// or null
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/attachments"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}, {name: mimeType, var: mime_type}, {name: name, var: name}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, file: $file, mime_type: $mime_type, name: $name, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsAttachmentsByIdCardByIdAttachment()
#
# DELETE /cards/{idCard}/attachments/{idAttachment}
# operationId: deleteCardsAttachmentsByIdCardByIdAttachment
export def "delete-cards-attachments-by-id-card-by-id-attachment" [
  id_card: string
  id_attachment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/attachments/{idAttachment}"
    path_params: [{name: idCard, var: id_card}, {name: idAttachment, var: id_attachment}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_attachment: $id_attachment, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsAttachmentsByIdCardByIdAttachment()
#
# GET /cards/{idCard}/attachments/{idAttachment}
# operationId: getCardsAttachmentsByIdCardByIdAttachment
export def "get-cards-attachments-by-id-card-by-id-attachment" [
  id_card: string
  id_attachment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/attachments/{idAttachment}"
    path_params: [{name: idCard, var: id_card}, {name: idAttachment, var: id_attachment}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_attachment: $id_attachment, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsBoardByIdCard()
#
# GET /cards/{idCard}/board
# operationId: getCardsBoardByIdCard
export def "get-cards-board-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/board"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsBoardByIdCardByField()
#
# GET /cards/{idCard}/board/{field}
# operationId: getCardsBoardByIdCardByField
export def "get-cards-board-by-id-card-by-field" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/board/{field}"
    path_params: [{name: idCard, var: id_card}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsCheckItemStatesByIdCard()
#
# GET /cards/{idCard}/checkItemStates
# operationId: getCardsCheckItemStatesByIdCard
export def "get-cards-check-item-states-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: idCheckItem or state (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/checkItemStates"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsChecklistCheckItemByIdCardByIdChecklistCurrentByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklistCurrent}/checkItem/{idCheckItem}
# operationId: updateCardsChecklistCheckItemByIdCardByIdChecklistCurrentByIdCheckItem
export def "update-cards-checklist-check-item-by-id-card-by-id-checklist-current-by-id-check-item" [
  id_card: string
  id_checklist_current: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-checklist: string # An id, or null
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --state: string # One of: complete, false, incomplete or true
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/checklist/{idChecklistCurrent}/checkItem/{idCheckItem}"
    path_params: [{name: idCard, var: id_card}, {name: idChecklistCurrent, var: id_checklist_current}, {name: idCheckItem, var: id_check_item}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idChecklist, var: id_checklist}, {name: name, var: name}, {name: pos, var: pos}, {name: state, var: state}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_checklist_current: $id_checklist_current, id_check_item: $id_check_item, key: $key, qp_token: $qp_token, id_checklist: $id_checklist, name: $name, pos: $pos, state: $state
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsChecklistCheckItemByIdCardByIdChecklist()
#
# POST /cards/{idCard}/checklist/{idChecklist}/checkItem
# operationId: addCardsChecklistCheckItemByIdCardByIdChecklist
export def "add-cards-checklist-check-item-by-id-card-by-id-checklist" [
  id_card: string
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/checklist/{idChecklist}/checkItem"
    path_params: [{name: idCard, var: id_card}, {name: idChecklist, var: id_checklist}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: pos, var: pos}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_checklist: $id_checklist, key: $key, qp_token: $qp_token, name: $name, pos: $pos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsChecklistCheckItemByIdCardByIdChecklistByIdCheckItem()
#
# DELETE /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}
# operationId: deleteCardsChecklistCheckItemByIdCardByIdChecklistByIdCheckItem
export def "delete-cards-checklist-check-item-by-id-card-by-id-checklist-by-id-check-item" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}"
    path_params: [{name: idCard, var: id_card}, {name: idChecklist, var: id_checklist}, {name: idCheckItem, var: id_check_item}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsChecklistCheckItemConvertToCardByIdCardByIdChecklistByIdCheckItem()
#
# POST /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/convertToCard
# operationId: addCardsChecklistCheckItemConvertToCardByIdCardByIdChecklistByIdCheckItem
export def "add-cards-checklist-check-item-convert-to-card-by-id-card-by-id-checklist-by-id-check-item" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/convertToCard"
    path_params: [{name: idCard, var: id_card}, {name: idChecklist, var: id_checklist}, {name: idCheckItem, var: id_check_item}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsChecklistCheckItemNameByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/name
# operationId: updateCardsChecklistCheckItemNameByIdCardByIdChecklistByIdCheckItem
export def "update-cards-checklist-check-item-name-by-id-card-by-id-checklist-by-id-check-item" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/name"
    path_params: [{name: idCard, var: id_card}, {name: idChecklist, var: id_checklist}, {name: idCheckItem, var: id_check_item}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsChecklistCheckItemPosByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/pos
# operationId: updateCardsChecklistCheckItemPosByIdCardByIdChecklistByIdCheckItem
export def "update-cards-checklist-check-item-pos-by-id-card-by-id-checklist-by-id-check-item" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/pos"
    path_params: [{name: idCard, var: id_card}, {name: idChecklist, var: id_checklist}, {name: idCheckItem, var: id_check_item}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsChecklistCheckItemStateByIdCardByIdChecklistByIdCheckItem()
#
# PUT /cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/state
# operationId: updateCardsChecklistCheckItemStateByIdCardByIdChecklistByIdCheckItem
export def "update-cards-checklist-check-item-state-by-id-card-by-id-checklist-by-id-check-item" [
  id_card: string
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: complete, false, incomplete or true
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/checklist/{idChecklist}/checkItem/{idCheckItem}/state"
    path_params: [{name: idCard, var: id_card}, {name: idChecklist, var: id_checklist}, {name: idCheckItem, var: id_check_item}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_checklist: $id_checklist, id_check_item: $id_check_item, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsChecklistsByIdCard()
#
# GET /cards/{idCard}/checklists
# operationId: getCardsChecklistsByIdCard
export def "get-cards-checklists-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/checklists"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: cards, var: cards}, {name: card_fields, var: card_fields}, {name: checkItems, var: check_items}, {name: checkItem_fields, var: check_item_fields}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, cards: $cards, card_fields: $card_fields, check_items: $check_items, check_item_fields: $check_item_fields, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsChecklistsByIdCard()
#
# POST /cards/{idCard}/checklists
# operationId: addCardsChecklistsByIdCard
export def "add-cards-checklists-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-checklist-source: string # The id of the source checklist to copy into a new checklist.
  --name: string # a string with a length from 0 to 16384
  --value: string # The id of the checklist to add to the card, or null to create a new one.
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/checklists"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idChecklistSource, var: id_checklist_source}, {name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, id_checklist_source: $id_checklist_source, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsChecklistsByIdCardByIdChecklist()
#
# DELETE /cards/{idCard}/checklists/{idChecklist}
# operationId: deleteCardsChecklistsByIdCardByIdChecklist
export def "delete-cards-checklists-by-id-card-by-id-checklist" [
  id_card: string
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/checklists/{idChecklist}"
    path_params: [{name: idCard, var: id_card}, {name: idChecklist, var: id_checklist}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_checklist: $id_checklist, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsClosedByIdCard()
#
# PUT /cards/{idCard}/closed
# operationId: updateCardsClosedByIdCard
export def "update-cards-closed-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/closed"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsDescByIdCard()
#
# PUT /cards/{idCard}/desc
# operationId: updateCardsDescByIdCard
export def "update-cards-desc-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/desc"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsDueByIdCard()
#
# PUT /cards/{idCard}/due
# operationId: updateCardsDueByIdCard
export def "update-cards-due-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A date, or null
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/due"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsIdAttachmentCoverByIdCard()
#
# PUT /cards/{idCard}/idAttachmentCover
# operationId: updateCardsIdAttachmentCoverByIdCard
export def "update-cards-id-attachment-cover-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # Id of the image attachment of this card to use as its cover, or null for no cover
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/idAttachmentCover"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsIdBoardByIdCard()
#
# PUT /cards/{idCard}/idBoard
# operationId: updateCardsIdBoardByIdCard
export def "update-cards-id-board-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-list: string # id of the list that the card should be moved to on the new board
  --value: string # id of the board the card should be moved to
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/idBoard"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idList, var: id_list}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, id_list: $id_list, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsIdLabelsByIdCard()
#
# POST /cards/{idCard}/idLabels
# operationId: addCardsIdLabelsByIdCard
export def "add-cards-id-labels-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # The id of the label to add
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/idLabels"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsIdLabelsByIdCardByIdLabel()
#
# DELETE /cards/{idCard}/idLabels/{idLabel}
# operationId: deleteCardsIdLabelsByIdCardByIdLabel
export def "delete-cards-id-labels-by-id-card-by-id-label" [
  id_card: string
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/idLabels/{idLabel}"
    path_params: [{name: idCard, var: id_card}, {name: idLabel, var: id_label}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_label: $id_label, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsIdListByIdCard()
#
# PUT /cards/{idCard}/idList
# operationId: updateCardsIdListByIdCard
export def "update-cards-id-list-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # id of the list the card should be moved to
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/idList"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsIdMembersByIdCard()
#
# POST /cards/{idCard}/idMembers
# operationId: addCardsIdMembersByIdCard
export def "add-cards-id-members-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # The id of the member to add to the card
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/idMembers"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsIdMembersByIdCard()
#
# PUT /cards/{idCard}/idMembers
# operationId: updateCardsIdMembersByIdCard
export def "update-cards-id-members-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # The id of the member to add to the card
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/idMembers"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsIdMembersByIdCardByIdMember()
#
# DELETE /cards/{idCard}/idMembers/{idMember}
# operationId: deleteCardsIdMembersByIdCardByIdMember
export def "delete-cards-id-members-by-id-card-by-id-member" [
  id_card: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/idMembers/{idMember}"
    path_params: [{name: idCard, var: id_card}, {name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_member: $id_member, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsLabelsByIdCard()
#
# POST /cards/{idCard}/labels
# operationId: addCardsLabelsByIdCard
export def "add-cards-labels-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
  --value: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/labels"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, color: $color, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsLabelsByIdCard()
#
# PUT /cards/{idCard}/labels
# operationId: updateCardsLabelsByIdCard
export def "update-cards-labels-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --color: string # A valid label color or null
  --name: string # a string with a length from 0 to 16384
  --value: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/labels"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: name, var: name}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, color: $color, name: $name, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsLabelsByIdCardByColor()
#
# DELETE /cards/{idCard}/labels/{color}
# operationId: deleteCardsLabelsByIdCardByColor
export def "delete-cards-labels-by-id-card-by-color" [
  id_card: string
  color: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/labels/{color}"
    path_params: [{name: idCard, var: id_card}, {name: color, var: color}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, color: $color, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsListByIdCard()
#
# GET /cards/{idCard}/list
# operationId: getCardsListByIdCard
export def "get-cards-list-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/list"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsListByIdCardByField()
#
# GET /cards/{idCard}/list/{field}
# operationId: getCardsListByIdCardByField
export def "get-cards-list-by-id-card-by-field" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/list/{field}"
    path_params: [{name: idCard, var: id_card}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsMarkAssociatedNotificationsReadByIdCard()
#
# POST /cards/{idCard}/markAssociatedNotificationsRead
# operationId: addCardsMarkAssociatedNotificationsReadByIdCard
export def "add-cards-mark-associated-notifications-read-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/cards/{idCard}/markAssociatedNotificationsRead"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsMembersByIdCard()
#
# GET /cards/{idCard}/members
# operationId: getCardsMembersByIdCard
export def "get-cards-members-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/members"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsMembersVotedByIdCard()
#
# GET /cards/{idCard}/membersVoted
# operationId: getCardsMembersVotedByIdCard
export def "get-cards-members-voted-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/membersVoted"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsMembersVotedByIdCard()
#
# POST /cards/{idCard}/membersVoted
# operationId: addCardsMembersVotedByIdCard
export def "add-cards-members-voted-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # The id of the member to vote 'yes' on the card
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/membersVoted"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsMembersVotedByIdCardByIdMember()
#
# DELETE /cards/{idCard}/membersVoted/{idMember}
# operationId: deleteCardsMembersVotedByIdCardByIdMember
export def "delete-cards-members-voted-by-id-card-by-id-member" [
  id_card: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/membersVoted/{idMember}"
    path_params: [{name: idCard, var: id_card}, {name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_member: $id_member, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsNameByIdCard()
#
# PUT /cards/{idCard}/name
# operationId: updateCardsNameByIdCard
export def "update-cards-name-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/name"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsPosByIdCard()
#
# PUT /cards/{idCard}/pos
# operationId: updateCardsPosByIdCard
export def "update-cards-pos-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/pos"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsStickersByIdCard()
#
# GET /cards/{idCard}/stickers
# operationId: getCardsStickersByIdCard
export def "get-cards-stickers-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/stickers"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addCardsStickersByIdCard()
#
# POST /cards/{idCard}/stickers
# operationId: addCardsStickersByIdCard
export def "add-cards-stickers-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --image: string # a string with a length from 0 to 16384
  --left: string # undefined
  --rotate: string # undefined
  --top: string # undefined
  --z-index: string # Valid Z values for stickers, must be an integer
]: any -> any {
  $in | http-request {
    method: post
    path: "/cards/{idCard}/stickers"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: image, var: image}, {name: left, var: left}, {name: rotate, var: rotate}, {name: top, var: top}, {name: zIndex, var: z_index}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, image: $image, left: $left, rotate: $rotate, top: $top, z_index: $z_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteCardsStickersByIdCardByIdSticker()
#
# DELETE /cards/{idCard}/stickers/{idSticker}
# operationId: deleteCardsStickersByIdCardByIdSticker
export def "delete-cards-stickers-by-id-card-by-id-sticker" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/cards/{idCard}/stickers/{idSticker}"
    path_params: [{name: idCard, var: id_card}, {name: idSticker, var: id_sticker}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_sticker: $id_sticker, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsStickersByIdCardByIdSticker()
#
# GET /cards/{idCard}/stickers/{idSticker}
# operationId: getCardsStickersByIdCardByIdSticker
export def "get-cards-stickers-by-id-card-by-id-sticker" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: image, imageScaled, imageUrl, left, rotate, top or zIndex (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/stickers/{idSticker}"
    path_params: [{name: idCard, var: id_card}, {name: idSticker, var: id_sticker}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_sticker: $id_sticker, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsStickersByIdCardByIdSticker()
#
# PUT /cards/{idCard}/stickers/{idSticker}
# operationId: updateCardsStickersByIdCardByIdSticker
export def "update-cards-stickers-by-id-card-by-id-sticker" [
  id_card: string
  id_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --image: string # a string with a length from 0 to 16384
  --left: string # undefined
  --rotate: string # undefined
  --top: string # undefined
  --z-index: string # Valid Z values for stickers, must be an integer
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/stickers/{idSticker}"
    path_params: [{name: idCard, var: id_card}, {name: idSticker, var: id_sticker}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: image, var: image}, {name: left, var: left}, {name: rotate, var: rotate}, {name: top, var: top}, {name: zIndex, var: z_index}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, id_sticker: $id_sticker, key: $key, qp_token: $qp_token, image: $image, left: $left, rotate: $rotate, top: $top, z_index: $z_index
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateCardsSubscribedByIdCard()
#
# PUT /cards/{idCard}/subscribed
# operationId: updateCardsSubscribedByIdCard
export def "update-cards-subscribed-by-id-card" [
  id_card: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/cards/{idCard}/subscribed"
    path_params: [{name: idCard, var: id_card}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getCardsByIdCardByField()
#
# GET /cards/{idCard}/{field}
# operationId: getCardsByIdCardByField
export def "get-cards-by-id-card-by-field" [
  id_card: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/cards/{idCard}/{field}"
    path_params: [{name: idCard, var: id_card}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_card: $id_card, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addChecklists()
#
# POST /checklists
# operationId: addChecklists
export def "add-checklists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-board: string # id of the board that the checklist should be added to
  --id-card: string # id of the card that the checklist should be added to
  --id-checklist-source: string # The id of the source checklist to copy into a new checklist.
  --name: string # a string with a length from 0 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: post
    path: "/checklists"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idBoard, var: id_board}, {name: idCard, var: id_card}, {name: idChecklistSource, var: id_checklist_source}, {name: name, var: name}, {name: pos, var: pos}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, id_board: $id_board, id_card: $id_card, id_checklist_source: $id_checklist_source, name: $name, pos: $pos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteChecklistsByIdChecklist()
#
# DELETE /checklists/{idChecklist}
# operationId: deleteChecklistsByIdChecklist
export def "delete-checklists-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/checklists/{idChecklist}"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getChecklistsByIdChecklist()
#
# GET /checklists/{idChecklist}
# operationId: getChecklistsByIdChecklist
export def "get-checklists-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --check-items: string # One of: all or none (default: all)
  --check-item-fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --fields: string # all or a comma-separated list of: idBoard, idCard, name or pos (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/checklists/{idChecklist}"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: cards, var: cards}, {name: card_fields, var: card_fields}, {name: checkItems, var: check_items}, {name: checkItem_fields, var: check_item_fields}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, cards: $cards, card_fields: $card_fields, check_items: $check_items, check_item_fields: $check_item_fields, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateChecklistsByIdChecklist()
#
# PUT /checklists/{idChecklist}
# operationId: updateChecklistsByIdChecklist
export def "update-checklists-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-board: string # id of the board that the checklist should be added to
  --id-card: string # id of the card that the checklist should be added to
  --id-checklist-source: string # The id of the source checklist to copy into a new checklist.
  --name: string # a string with a length from 0 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: put
    path: "/checklists/{idChecklist}"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idBoard, var: id_board}, {name: idCard, var: id_card}, {name: idChecklistSource, var: id_checklist_source}, {name: name, var: name}, {name: pos, var: pos}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, key: $key, qp_token: $qp_token, id_board: $id_board, id_card: $id_card, id_checklist_source: $id_checklist_source, name: $name, pos: $pos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getChecklistsBoardByIdChecklist()
#
# GET /checklists/{idChecklist}/board
# operationId: getChecklistsBoardByIdChecklist
export def "get-checklists-board-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/checklists/{idChecklist}/board"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getChecklistsBoardByIdChecklistByField()
#
# GET /checklists/{idChecklist}/board/{field}
# operationId: getChecklistsBoardByIdChecklistByField
export def "get-checklists-board-by-id-checklist-by-field" [
  id_checklist: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/checklists/{idChecklist}/board/{field}"
    path_params: [{name: idChecklist, var: id_checklist}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getChecklistsCardsByIdChecklist()
#
# GET /checklists/{idChecklist}/cards
# operationId: getChecklistsCardsByIdChecklist
export def "get-checklists-cards-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string # true or false
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/checklists/{idChecklist}/cards"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: actions, var: actions}, {name: attachments, var: attachments}, {name: attachment_fields, var: attachment_fields}, {name: stickers, var: stickers}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: checkItemStates, var: check_item_states}, {name: checklists, var: checklists}, {name: limit, var: limit}, {name: since, var: since}, {name: before, var: before}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, actions: $actions, attachments: $attachments, attachment_fields: $attachment_fields, stickers: $stickers, members: $members, member_fields: $member_fields, check_item_states: $check_item_states, checklists: $checklists, limit: $limit, since: $since, before: $before, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getChecklistsCardsByIdChecklistByFilter()
#
# GET /checklists/{idChecklist}/cards/{filter}
# operationId: getChecklistsCardsByIdChecklistByFilter
export def "get-checklists-cards-by-id-checklist-by-filter" [
  id_checklist: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/checklists/{idChecklist}/cards/{filter}"
    path_params: [{name: idChecklist, var: id_checklist}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getChecklistsCheckItemsByIdChecklist()
#
# GET /checklists/{idChecklist}/checkItems
# operationId: getChecklistsCheckItemsByIdChecklist
export def "get-checklists-check-items-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/checklists/{idChecklist}/checkItems"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addChecklistsCheckItemsByIdChecklist()
#
# POST /checklists/{idChecklist}/checkItems
# operationId: addChecklistsCheckItemsByIdChecklist
export def "add-checklists-check-items-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --checked: string # true or false
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: post
    path: "/checklists/{idChecklist}/checkItems"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: checked, var: checked}, {name: name, var: name}, {name: pos, var: pos}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, key: $key, qp_token: $qp_token, checked: $checked, name: $name, pos: $pos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteChecklistsCheckItemsByIdChecklistByIdCheckItem()
#
# DELETE /checklists/{idChecklist}/checkItems/{idCheckItem}
# operationId: deleteChecklistsCheckItemsByIdChecklistByIdCheckItem
export def "delete-checklists-check-items-by-id-checklist-by-id-check-item" [
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/checklists/{idChecklist}/checkItems/{idCheckItem}"
    path_params: [{name: idChecklist, var: id_checklist}, {name: idCheckItem, var: id_check_item}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, id_check_item: $id_check_item, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getChecklistsCheckItemsByIdChecklistByIdCheckItem()
#
# GET /checklists/{idChecklist}/checkItems/{idCheckItem}
# operationId: getChecklistsCheckItemsByIdChecklistByIdCheckItem
export def "get-checklists-check-items-by-id-checklist-by-id-check-item" [
  id_checklist: string
  id_check_item: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: name, nameData, pos, state or type (default: name, nameData, pos and state)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/checklists/{idChecklist}/checkItems/{idCheckItem}"
    path_params: [{name: idChecklist, var: id_checklist}, {name: idCheckItem, var: id_check_item}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, id_check_item: $id_check_item, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateChecklistsIdCardByIdChecklist()
#
# PUT /checklists/{idChecklist}/idCard
# operationId: updateChecklistsIdCardByIdChecklist
export def "update-checklists-id-card-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # The id of the card that the checklist is on
]: any -> any {
  $in | http-request {
    method: put
    path: "/checklists/{idChecklist}/idCard"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateChecklistsNameByIdChecklist()
#
# PUT /checklists/{idChecklist}/name
# operationId: updateChecklistsNameByIdChecklist
export def "update-checklists-name-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/checklists/{idChecklist}/name"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateChecklistsPosByIdChecklist()
#
# PUT /checklists/{idChecklist}/pos
# operationId: updateChecklistsPosByIdChecklist
export def "update-checklists-pos-by-id-checklist" [
  id_checklist: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: put
    path: "/checklists/{idChecklist}/pos"
    path_params: [{name: idChecklist, var: id_checklist}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getChecklistsByIdChecklistByField()
#
# GET /checklists/{idChecklist}/{field}
# operationId: getChecklistsByIdChecklistByField
export def "get-checklists-by-id-checklist-by-field" [
  id_checklist: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/checklists/{idChecklist}/{field}"
    path_params: [{name: idChecklist, var: id_checklist}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_checklist: $id_checklist, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addLabels()
#
# POST /labels
# operationId: addLabels
export def "add-labels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --color: string # A valid label color or null
  --id-board: string # An id
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: post
    path: "/labels"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: idBoard, var: id_board}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, color: $color, id_board: $id_board, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteLabelsByIdLabel()
#
# DELETE /labels/{idLabel}
# operationId: deleteLabelsByIdLabel
export def "delete-labels-by-id-label" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/labels/{idLabel}"
    path_params: [{name: idLabel, var: id_label}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_label: $id_label, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getLabelsByIdLabel()
#
# GET /labels/{idLabel}
# operationId: getLabelsByIdLabel
export def "get-labels-by-id-label" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: color, idBoard, name or uses (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/labels/{idLabel}"
    path_params: [{name: idLabel, var: id_label}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_label: $id_label, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateLabelsByIdLabel()
#
# PUT /labels/{idLabel}
# operationId: updateLabelsByIdLabel
export def "update-labels-by-id-label" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --color: string # A valid label color or null
  --id-board: string # An id
  --name: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/labels/{idLabel}"
    path_params: [{name: idLabel, var: id_label}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: color, var: color}, {name: idBoard, var: id_board}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_label: $id_label, key: $key, qp_token: $qp_token, color: $color, id_board: $id_board, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getLabelsBoardByIdLabel()
#
# GET /labels/{idLabel}/board
# operationId: getLabelsBoardByIdLabel
export def "get-labels-board-by-id-label" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/labels/{idLabel}/board"
    path_params: [{name: idLabel, var: id_label}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_label: $id_label, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getLabelsBoardByIdLabelByField()
#
# GET /labels/{idLabel}/board/{field}
# operationId: getLabelsBoardByIdLabelByField
export def "get-labels-board-by-id-label-by-field" [
  id_label: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/labels/{idLabel}/board/{field}"
    path_params: [{name: idLabel, var: id_label}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_label: $id_label, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateLabelsColorByIdLabel()
#
# PUT /labels/{idLabel}/color
# operationId: updateLabelsColorByIdLabel
export def "update-labels-color-by-id-label" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A valid label color or null
]: any -> any {
  $in | http-request {
    method: put
    path: "/labels/{idLabel}/color"
    path_params: [{name: idLabel, var: id_label}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_label: $id_label, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateLabelsNameByIdLabel()
#
# PUT /labels/{idLabel}/name
# operationId: updateLabelsNameByIdLabel
export def "update-labels-name-by-id-label" [
  id_label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/labels/{idLabel}/name"
    path_params: [{name: idLabel, var: id_label}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_label: $id_label, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addLists()
#
# POST /lists
# operationId: addLists
export def "add-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --closed: string # true or false
  --id-board: string # id of the board that the list should be added to
  --id-list-source: string # The id of the list to copy into a new list.
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string # true or false
]: any -> any {
  $in | http-request {
    method: post
    path: "/lists"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed, var: closed}, {name: idBoard, var: id_board}, {name: idListSource, var: id_list_source}, {name: name, var: name}, {name: pos, var: pos}, {name: subscribed, var: subscribed}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, closed: $closed, id_board: $id_board, id_list_source: $id_list_source, name: $name, pos: $pos, subscribed: $subscribed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getListsByIdList()
#
# GET /lists/{idList}
# operationId: getListsByIdList
export def "get-lists-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cards: string # One of: all, closed, none or open (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, descData, closed, idOrganization, pinned, url and prefs)
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: name, closed, idBoard and pos)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{idList}"
    path_params: [{name: idList, var: id_list}]
    query: [{name: cards, var: cards}, {name: card_fields, var: card_fields}, {name: board, var: board}, {name: board_fields, var: board_fields}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, cards: $cards, card_fields: $card_fields, board: $board, board_fields: $board_fields, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateListsByIdList()
#
# PUT /lists/{idList}
# operationId: updateListsByIdList
export def "update-lists-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --closed: string # true or false
  --id-board: string # id of the board that the list should be added to
  --id-list-source: string # The id of the list to copy into a new list.
  --name: string # a string with a length from 1 to 16384
  --pos: string # A position. top , bottom , or a positive number.
  --subscribed: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{idList}"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: closed, var: closed}, {name: idBoard, var: id_board}, {name: idListSource, var: id_list_source}, {name: name, var: name}, {name: pos, var: pos}, {name: subscribed, var: subscribed}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token, closed: $closed, id_board: $id_board, id_list_source: $id_list_source, name: $name, pos: $pos, subscribed: $subscribed
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getListsActionsByIdList()
#
# GET /lists/{idList}/actions
# operationId: getListsActionsByIdList
export def "get-lists-actions-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{idList}/actions"
    path_params: [{name: idList, var: id_list}]
    query: [{name: entities, var: entities}, {name: display, var: display}, {name: filter, var: filter}, {name: fields, var: fields}, {name: limit, var: limit}, {name: format, var: format}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: idModels, var: id_models}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: memberCreator, var: member_creator}, {name: memberCreator_fields, var: member_creator_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, entities: $entities, display: $display, filter: $filter, fields: $fields, limit: $limit, format: $format, since: $since, before: $before, page: $page, id_models: $id_models, member: $member, member_fields: $member_fields, member_creator: $member_creator, member_creator_fields: $member_creator_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addListsArchiveAllCardsByIdList()
#
# POST /lists/{idList}/archiveAllCards
# operationId: addListsArchiveAllCardsByIdList
export def "add-lists-archive-all-cards-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/lists/{idList}/archiveAllCards"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getListsBoardByIdList()
#
# GET /lists/{idList}/board
# operationId: getListsBoardByIdList
export def "get-lists-board-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{idList}/board"
    path_params: [{name: idList, var: id_list}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getListsBoardByIdListByField()
#
# GET /lists/{idList}/board/{field}
# operationId: getListsBoardByIdListByField
export def "get-lists-board-by-id-list-by-field" [
  id_list: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{idList}/board/{field}"
    path_params: [{name: idList, var: id_list}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getListsCardsByIdList()
#
# GET /lists/{idList}/cards
# operationId: getListsCardsByIdList
export def "get-lists-cards-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string # true or false
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none or open (default: open)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{idList}/cards"
    path_params: [{name: idList, var: id_list}]
    query: [{name: actions, var: actions}, {name: attachments, var: attachments}, {name: attachment_fields, var: attachment_fields}, {name: stickers, var: stickers}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: checkItemStates, var: check_item_states}, {name: checklists, var: checklists}, {name: limit, var: limit}, {name: since, var: since}, {name: before, var: before}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, actions: $actions, attachments: $attachments, attachment_fields: $attachment_fields, stickers: $stickers, members: $members, member_fields: $member_fields, check_item_states: $check_item_states, checklists: $checklists, limit: $limit, since: $since, before: $before, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addListsCardsByIdList()
#
# POST /lists/{idList}/cards
# operationId: addListsCardsByIdList
export def "add-lists-cards-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --desc: string # a string with a length from 0 to 16384
  --due: string # A date, or null
  --id-members: string # A comma-separated list of objectIds, 24-character hex strings
  --labels: string # all or a comma-separated list of: blue, green, orange, purple, red or yellow
  --name: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: post
    path: "/lists/{idList}/cards"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: desc, var: desc}, {name: due, var: due}, {name: idMembers, var: id_members}, {name: labels, var: labels}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token, desc: $desc, due: $due, id_members: $id_members, labels: $labels, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getListsCardsByIdListByFilter()
#
# GET /lists/{idList}/cards/{filter}
# operationId: getListsCardsByIdListByFilter
export def "get-lists-cards-by-id-list-by-filter" [
  id_list: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{idList}/cards/{filter}"
    path_params: [{name: idList, var: id_list}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateListsClosedByIdList()
#
# PUT /lists/{idList}/closed
# operationId: updateListsClosedByIdList
export def "update-lists-closed-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{idList}/closed"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateListsIdBoardByIdList()
#
# PUT /lists/{idList}/idBoard
# operationId: updateListsIdBoardByIdList
export def "update-lists-id-board-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --pos: string # position of the list on the new board
  --value: string # id of the board the list should be moved to
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{idList}/idBoard"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: pos, var: pos}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token, pos: $pos, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addListsMoveAllCardsByIdList()
#
# POST /lists/{idList}/moveAllCards
# operationId: addListsMoveAllCardsByIdList
export def "add-lists-move-all-cards-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-board: string # id of the board that the cards should be moved to
]: any -> any {
  $in | http-request {
    method: post
    path: "/lists/{idList}/moveAllCards"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idBoard, var: id_board}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token, id_board: $id_board
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateListsNameByIdList()
#
# PUT /lists/{idList}/name
# operationId: updateListsNameByIdList
export def "update-lists-name-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{idList}/name"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateListsPosByIdList()
#
# PUT /lists/{idList}/pos
# operationId: updateListsPosByIdList
export def "update-lists-pos-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{idList}/pos"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateListsSubscribedByIdList()
#
# PUT /lists/{idList}/subscribed
# operationId: updateListsSubscribedByIdList
export def "update-lists-subscribed-by-id-list" [
  id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/lists/{idList}/subscribed"
    path_params: [{name: idList, var: id_list}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getListsByIdListByField()
#
# GET /lists/{idList}/{field}
# operationId: getListsByIdListByField
export def "get-lists-by-id-list-by-field" [
  id_list: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/lists/{idList}/{field}"
    path_params: [{name: idList, var: id_list}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_list: $id_list, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersByIdMember()
#
# GET /members/{idMember}
# operationId: getMembersByIdMember
export def "get-members-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --action-since: string # A date, null or lastView
  --action-before: string # A date, or null
  --cards: string # One of: all, closed, none, open or visible (default: none)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --card-members: string # true or false
  --card-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --card-attachments: string # A boolean value or "cover" for only card cover attachments
  --card-attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: url and previews)
  --card-stickers: string # true or false
  --boards: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, closed, idOrganization and pinned)
  --board-actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --board-actions-entities: string # true or false
  --board-actions-display: string # true or false
  --board-actions-format: string # One of: count, list or minimal (default: list)
  --board-actions-since: string # A date, null or lastView
  --board-actions-limit: string # a number from 0 to 1000 (default: 50)
  --board-action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --board-lists: string # One of: all, closed, none or open (default: none)
  --board-memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --board-organization: string # true or false
  --board-organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --boards-invited: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned
  --boards-invited-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, closed, idOrganization and pinned)
  --board-stars: string # true or false
  --saved-searches: string # true or false
  --organizations: string # One of: all, members, none or public (default: none)
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --organization-paid-account: string # true or false
  --organizations-invited: string # One of: all, members, none or public (default: none)
  --organizations-invited-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --notifications: string # all or a comma-separated list of: addAdminToBoard, addAdminToOrganization, addedAttachmentToCard, addedMemberToCard, addedToBoard, addedToCard, addedToOrganization, cardDueSoon, changeCard, closeBoard, commentCard, createdCard, declinedInvitationToBoard, declinedInvitationToOrganization, invitedToBoard, invitedToOrganization, makeAdminOfBoard, makeAdminOfOrganization, memberJoinedTrello, mentionedOnCard, removedFromBoard, removedFromCard, removedFromOrganization, removedMemberFromCard, unconfirmedInvitedToBoard, unconfirmedInvitedToOrganization or updateCheckItemStateOnCard
  --notifications-entities: string # true or false
  --notifications-display: string # true or false
  --notifications-limit: string # a number from 1 to 1000 (default: 50)
  --notification-fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --notification-member-creator: string # true or false
  --notification-member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --notification-before: string # An id, or null
  --notification-since: string # An id, or null
  --tokens: string # One of: all or none (default: none)
  --paid-account: string # true or false
  --board-backgrounds: string # One of: all, custom, default, none or premium (default: none)
  --custom-board-backgrounds: string # One of: all or none (default: none)
  --custom-stickers: string # One of: all or none (default: none)
  --custom-emoji: string # One of: all or none (default: none)
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: actions, var: actions}, {name: actions_entities, var: actions_entities}, {name: actions_display, var: actions_display}, {name: actions_limit, var: actions_limit}, {name: action_fields, var: action_fields}, {name: action_since, var: action_since}, {name: action_before, var: action_before}, {name: cards, var: cards}, {name: card_fields, var: card_fields}, {name: card_members, var: card_members}, {name: card_member_fields, var: card_member_fields}, {name: card_attachments, var: card_attachments}, {name: card_attachment_fields, var: card_attachment_fields}, {name: card_stickers, var: card_stickers}, {name: boards, var: boards}, {name: board_fields, var: board_fields}, {name: board_actions, var: board_actions}, {name: board_actions_entities, var: board_actions_entities}, {name: board_actions_display, var: board_actions_display}, {name: board_actions_format, var: board_actions_format}, {name: board_actions_since, var: board_actions_since}, {name: board_actions_limit, var: board_actions_limit}, {name: board_action_fields, var: board_action_fields}, {name: board_lists, var: board_lists}, {name: board_memberships, var: board_memberships}, {name: board_organization, var: board_organization}, {name: board_organization_fields, var: board_organization_fields}, {name: boardsInvited, var: boards_invited}, {name: boardsInvited_fields, var: boards_invited_fields}, {name: boardStars, var: board_stars}, {name: savedSearches, var: saved_searches}, {name: organizations, var: organizations}, {name: organization_fields, var: organization_fields}, {name: organization_paid_account, var: organization_paid_account}, {name: organizationsInvited, var: organizations_invited}, {name: organizationsInvited_fields, var: organizations_invited_fields}, {name: notifications, var: notifications}, {name: notifications_entities, var: notifications_entities}, {name: notifications_display, var: notifications_display}, {name: notifications_limit, var: notifications_limit}, {name: notification_fields, var: notification_fields}, {name: notification_memberCreator, var: notification_member_creator}, {name: notification_memberCreator_fields, var: notification_member_creator_fields}, {name: notification_before, var: notification_before}, {name: notification_since, var: notification_since}, {name: tokens, var: tokens}, {name: paid_account, var: paid_account}, {name: boardBackgrounds, var: board_backgrounds}, {name: customBoardBackgrounds, var: custom_board_backgrounds}, {name: customStickers, var: custom_stickers}, {name: customEmoji, var: custom_emoji}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, actions: $actions, actions_entities: $actions_entities, actions_display: $actions_display, actions_limit: $actions_limit, action_fields: $action_fields, action_since: $action_since, action_before: $action_before, cards: $cards, card_fields: $card_fields, card_members: $card_members, card_member_fields: $card_member_fields, card_attachments: $card_attachments, card_attachment_fields: $card_attachment_fields, card_stickers: $card_stickers, boards: $boards, board_fields: $board_fields, board_actions: $board_actions, board_actions_entities: $board_actions_entities, board_actions_display: $board_actions_display, board_actions_format: $board_actions_format, board_actions_since: $board_actions_since, board_actions_limit: $board_actions_limit, board_action_fields: $board_action_fields, board_lists: $board_lists, board_memberships: $board_memberships, board_organization: $board_organization, board_organization_fields: $board_organization_fields, boards_invited: $boards_invited, boards_invited_fields: $boards_invited_fields, board_stars: $board_stars, saved_searches: $saved_searches, organizations: $organizations, organization_fields: $organization_fields, organization_paid_account: $organization_paid_account, organizations_invited: $organizations_invited, organizations_invited_fields: $organizations_invited_fields, notifications: $notifications, notifications_entities: $notifications_entities, notifications_display: $notifications_display, notifications_limit: $notifications_limit, notification_fields: $notification_fields, notification_member_creator: $notification_member_creator, notification_member_creator_fields: $notification_member_creator_fields, notification_before: $notification_before, notification_since: $notification_since, tokens: $tokens, paid_account: $paid_account, board_backgrounds: $board_backgrounds, custom_board_backgrounds: $custom_board_backgrounds, custom_stickers: $custom_stickers, custom_emoji: $custom_emoji, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersByIdMember()
#
# PUT /members/{idMember}
# operationId: updateMembersByIdMember
export def "update-members-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --avatar-source: string # One of: gravatar, none or upload
  --bio: string # a string with a length from 0 to 16384
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --initials: string # A string with a length from 1 to 4. Cannot begin or end with a space
  --prefs-color-blind: string # true or false
  --prefs-locale: string # a string with a length from 0 to 255
  --prefs-minutes-between-summaries: string # -1 (disabled), 1 or 60
  --username: string # A string with a length of at least 3. Only lowercase letters, underscores, and numbers are allowed. Must be unique.
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: avatarSource, var: avatar_source}, {name: bio, var: bio}, {name: fullName, var: full_name}, {name: initials, var: initials}, {name: "prefs/colorBlind", var: prefs_color_blind}, {name: "prefs/locale", var: prefs_locale}, {name: "prefs/minutesBetweenSummaries", var: prefs_minutes_between_summaries}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, avatar_source: $avatar_source, bio: $bio, full_name: $full_name, initials: $initials, prefs_color_blind: $prefs_color_blind, prefs_locale: $prefs_locale, prefs_minutes_between_summaries: $prefs_minutes_between_summaries, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersActionsByIdMember()
#
# GET /members/{idMember}/actions
# operationId: getMembersActionsByIdMember
export def "get-members-actions-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/actions"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: entities, var: entities}, {name: display, var: display}, {name: filter, var: filter}, {name: fields, var: fields}, {name: limit, var: limit}, {name: format, var: format}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: idModels, var: id_models}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: memberCreator, var: member_creator}, {name: memberCreator_fields, var: member_creator_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, entities: $entities, display: $display, filter: $filter, fields: $fields, limit: $limit, format: $format, since: $since, before: $before, page: $page, id_models: $id_models, member: $member, member_fields: $member_fields, member_creator: $member_creator, member_creator_fields: $member_creator_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addMembersAvatarByIdMember()
#
# POST /members/{idMember}/avatar
# operationId: addMembersAvatarByIdMember
export def "add-members-avatar-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --file: string # A file
]: any -> any {
  $in | http-request {
    method: post
    path: "/members/{idMember}/avatar"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersAvatarSourceByIdMember()
#
# PUT /members/{idMember}/avatarSource
# operationId: updateMembersAvatarSourceByIdMember
export def "update-members-avatar-source-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: gravatar, none or upload
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/avatarSource"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersBioByIdMember()
#
# PUT /members/{idMember}/bio
# operationId: updateMembersBioByIdMember
export def "update-members-bio-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/bio"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersBoardBackgroundsByIdMember()
#
# GET /members/{idMember}/boardBackgrounds
# operationId: getMembersBoardBackgroundsByIdMember
export def "get-members-board-backgrounds-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all, custom, default, none or premium (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/boardBackgrounds"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: filter, var: filter}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addMembersBoardBackgroundsByIdMember()
#
# POST /members/{idMember}/boardBackgrounds
# operationId: addMembersBoardBackgroundsByIdMember
export def "add-members-board-backgrounds-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string # true or false
]: any -> any {
  $in | http-request {
    method: post
    path: "/members/{idMember}/boardBackgrounds"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: brightness, var: brightness}, {name: file, var: file}, {name: tile, var: tile}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, brightness: $brightness, file: $file, tile: $tile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# DELETE /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: deleteMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "delete-members-board-backgrounds-by-id-member-by-id-board-background" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/members/{idMember}/boardBackgrounds/{idBoardBackground}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardBackground, var: id_board_background}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_background: $id_board_background, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# GET /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: getMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "get-members-board-backgrounds-by-id-member-by-id-board-background" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: brightness, fullSizeUrl, scaled or tile (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/boardBackgrounds/{idBoardBackground}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardBackground, var: id_board_background}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_background: $id_board_background, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersBoardBackgroundsByIdMemberByIdBoardBackground()
#
# PUT /members/{idMember}/boardBackgrounds/{idBoardBackground}
# operationId: updateMembersBoardBackgroundsByIdMemberByIdBoardBackground
export def "update-members-board-backgrounds-by-id-member-by-id-board-background" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/boardBackgrounds/{idBoardBackground}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardBackground, var: id_board_background}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: brightness, var: brightness}, {name: file, var: file}, {name: tile, var: tile}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_background: $id_board_background, key: $key, qp_token: $qp_token, brightness: $brightness, file: $file, tile: $tile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersBoardStarsByIdMember()
#
# GET /members/{idMember}/boardStars
# operationId: getMembersBoardStarsByIdMember
export def "get-members-board-stars-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/boardStars"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addMembersBoardStarsByIdMember()
#
# POST /members/{idMember}/boardStars
# operationId: addMembersBoardStarsByIdMember
export def "add-members-board-stars-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-board: string # The id of the board to star
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: post
    path: "/members/{idMember}/boardStars"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idBoard, var: id_board}, {name: pos, var: pos}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, id_board: $id_board, pos: $pos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteMembersBoardStarsByIdMemberByIdBoardStar()
#
# DELETE /members/{idMember}/boardStars/{idBoardStar}
# operationId: deleteMembersBoardStarsByIdMemberByIdBoardStar
export def "delete-members-board-stars-by-id-member-by-id-board-star" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/members/{idMember}/boardStars/{idBoardStar}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardStar, var: id_board_star}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_star: $id_board_star, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersBoardStarsByIdMemberByIdBoardStar()
#
# GET /members/{idMember}/boardStars/{idBoardStar}
# operationId: getMembersBoardStarsByIdMemberByIdBoardStar
export def "get-members-board-stars-by-id-member-by-id-board-star" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/boardStars/{idBoardStar}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardStar, var: id_board_star}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_star: $id_board_star, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersBoardStarsByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}
# operationId: updateMembersBoardStarsByIdMemberByIdBoardStar
export def "update-members-board-stars-by-id-member-by-id-board-star" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-board: string # The id of the board to star
  --pos: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/boardStars/{idBoardStar}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardStar, var: id_board_star}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idBoard, var: id_board}, {name: pos, var: pos}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_star: $id_board_star, key: $key, qp_token: $qp_token, id_board: $id_board, pos: $pos
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersBoardStarsIdBoardByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}/idBoard
# operationId: updateMembersBoardStarsIdBoardByIdMemberByIdBoardStar
export def "update-members-board-stars-id-board-by-id-member-by-id-board-star" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # An id
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/boardStars/{idBoardStar}/idBoard"
    path_params: [{name: idMember, var: id_member}, {name: idBoardStar, var: id_board_star}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_star: $id_board_star, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersBoardStarsPosByIdMemberByIdBoardStar()
#
# PUT /members/{idMember}/boardStars/{idBoardStar}/pos
# operationId: updateMembersBoardStarsPosByIdMemberByIdBoardStar
export def "update-members-board-stars-pos-by-id-member-by-id-board-star" [
  id_member: string
  id_board_star: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/boardStars/{idBoardStar}/pos"
    path_params: [{name: idMember, var: id_member}, {name: idBoardStar, var: id_board_star}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_star: $id_board_star, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersBoardsByIdMember()
#
# GET /members/{idMember}/boards
# operationId: getMembersBoardsByIdMember
export def "get-members-boards-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: all)
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --organization: string # true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --lists: string # One of: all, closed, none or open (default: none)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/boards"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: filter, var: filter}, {name: fields, var: fields}, {name: actions, var: actions}, {name: actions_entities, var: actions_entities}, {name: actions_limit, var: actions_limit}, {name: actions_format, var: actions_format}, {name: actions_since, var: actions_since}, {name: action_fields, var: action_fields}, {name: memberships, var: memberships}, {name: organization, var: organization}, {name: organization_fields, var: organization_fields}, {name: lists, var: lists}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, fields: $fields, actions: $actions, actions_entities: $actions_entities, actions_limit: $actions_limit, actions_format: $actions_format, actions_since: $actions_since, action_fields: $action_fields, memberships: $memberships, organization: $organization, organization_fields: $organization_fields, lists: $lists, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersBoardsByIdMemberByFilter()
#
# GET /members/{idMember}/boards/{filter}
# operationId: getMembersBoardsByIdMemberByFilter
export def "get-members-boards-by-id-member-by-filter" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/boards/{filter}"
    path_params: [{name: idMember, var: id_member}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersBoardsInvitedByIdMember()
#
# GET /members/{idMember}/boardsInvited
# operationId: getMembersBoardsInvitedByIdMember
export def "get-members-boards-invited-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/boardsInvited"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersBoardsInvitedByIdMemberByField()
#
# GET /members/{idMember}/boardsInvited/{field}
# operationId: getMembersBoardsInvitedByIdMemberByField
export def "get-members-boards-invited-by-id-member-by-field" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/boardsInvited/{field}"
    path_params: [{name: idMember, var: id_member}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersCardsByIdMember()
#
# GET /members/{idMember}/cards
# operationId: getMembersCardsByIdMember
export def "get-members-cards-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --stickers: string # true or false
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --limit: string # a number from 1 to 1000
  --since: string # A date, or null
  --before: string # A date, or null
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/cards"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: actions, var: actions}, {name: attachments, var: attachments}, {name: attachment_fields, var: attachment_fields}, {name: stickers, var: stickers}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: checkItemStates, var: check_item_states}, {name: checklists, var: checklists}, {name: limit, var: limit}, {name: since, var: since}, {name: before, var: before}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, actions: $actions, attachments: $attachments, attachment_fields: $attachment_fields, stickers: $stickers, members: $members, member_fields: $member_fields, check_item_states: $check_item_states, checklists: $checklists, limit: $limit, since: $since, before: $before, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersCardsByIdMemberByFilter()
#
# GET /members/{idMember}/cards/{filter}
# operationId: getMembersCardsByIdMemberByFilter
export def "get-members-cards-by-id-member-by-filter" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/cards/{filter}"
    path_params: [{name: idMember, var: id_member}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersCustomBoardBackgroundsByIdMember()
#
# GET /members/{idMember}/customBoardBackgrounds
# operationId: getMembersCustomBoardBackgroundsByIdMember
export def "get-members-custom-board-backgrounds-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/customBoardBackgrounds"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: filter, var: filter}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addMembersCustomBoardBackgroundsByIdMember()
#
# POST /members/{idMember}/customBoardBackgrounds
# operationId: addMembersCustomBoardBackgroundsByIdMember
export def "add-members-custom-board-backgrounds-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string # true or false
]: any -> any {
  $in | http-request {
    method: post
    path: "/members/{idMember}/customBoardBackgrounds"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: brightness, var: brightness}, {name: file, var: file}, {name: tile, var: tile}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, brightness: $brightness, file: $file, tile: $tile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# DELETE /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: deleteMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "delete-members-custom-board-backgrounds-by-id-member-by-id-board-background" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/members/{idMember}/customBoardBackgrounds/{idBoardBackground}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardBackground, var: id_board_background}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_background: $id_board_background, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# GET /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: getMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "get-members-custom-board-backgrounds-by-id-member-by-id-board-background" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: brightness, fullSizeUrl, scaled or tile (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/customBoardBackgrounds/{idBoardBackground}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardBackground, var: id_board_background}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_background: $id_board_background, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground()
#
# PUT /members/{idMember}/customBoardBackgrounds/{idBoardBackground}
# operationId: updateMembersCustomBoardBackgroundsByIdMemberByIdBoardBackground
export def "update-members-custom-board-backgrounds-by-id-member-by-id-board-background" [
  id_member: string
  id_board_background: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --brightness: string # One of: dark, light or unknown
  --file: string # A file
  --tile: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/customBoardBackgrounds/{idBoardBackground}"
    path_params: [{name: idMember, var: id_member}, {name: idBoardBackground, var: id_board_background}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: brightness, var: brightness}, {name: file, var: file}, {name: tile, var: tile}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_board_background: $id_board_background, key: $key, qp_token: $qp_token, brightness: $brightness, file: $file, tile: $tile
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersCustomEmojiByIdMember()
#
# GET /members/{idMember}/customEmoji
# operationId: getMembersCustomEmojiByIdMember
export def "get-members-custom-emoji-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/customEmoji"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: filter, var: filter}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addMembersCustomEmojiByIdMember()
#
# POST /members/{idMember}/customEmoji
# operationId: addMembersCustomEmojiByIdMember
export def "add-members-custom-emoji-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --file: string # A file
  --name: string # a string with a length from 2 to 64
]: any -> any {
  $in | http-request {
    method: post
    path: "/members/{idMember}/customEmoji"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, file: $file, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersCustomEmojiByIdMemberByIdCustomEmoji()
#
# GET /members/{idMember}/customEmoji/{idCustomEmoji}
# operationId: getMembersCustomEmojiByIdMemberByIdCustomEmoji
export def "get-members-custom-emoji-by-id-member-by-id-custom-emoji" [
  id_member: string
  id_custom_emoji: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: name or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/customEmoji/{idCustomEmoji}"
    path_params: [{name: idMember, var: id_member}, {name: idCustomEmoji, var: id_custom_emoji}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_custom_emoji: $id_custom_emoji, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersCustomStickersByIdMember()
#
# GET /members/{idMember}/customStickers
# operationId: getMembersCustomStickersByIdMember
export def "get-members-custom-stickers-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/customStickers"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: filter, var: filter}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addMembersCustomStickersByIdMember()
#
# POST /members/{idMember}/customStickers
# operationId: addMembersCustomStickersByIdMember
export def "add-members-custom-stickers-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --file: string # A file
]: any -> any {
  $in | http-request {
    method: post
    path: "/members/{idMember}/customStickers"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteMembersCustomStickersByIdMemberByIdCustomSticker()
#
# DELETE /members/{idMember}/customStickers/{idCustomSticker}
# operationId: deleteMembersCustomStickersByIdMemberByIdCustomSticker
export def "delete-members-custom-stickers-by-id-member-by-id-custom-sticker" [
  id_member: string
  id_custom_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/members/{idMember}/customStickers/{idCustomSticker}"
    path_params: [{name: idMember, var: id_member}, {name: idCustomSticker, var: id_custom_sticker}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_custom_sticker: $id_custom_sticker, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersCustomStickersByIdMemberByIdCustomSticker()
#
# GET /members/{idMember}/customStickers/{idCustomSticker}
# operationId: getMembersCustomStickersByIdMemberByIdCustomSticker
export def "get-members-custom-stickers-by-id-member-by-id-custom-sticker" [
  id_member: string
  id_custom_sticker: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: scaled or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/customStickers/{idCustomSticker}"
    path_params: [{name: idMember, var: id_member}, {name: idCustomSticker, var: id_custom_sticker}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_custom_sticker: $id_custom_sticker, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersDeltasByIdMember()
#
# GET /members/{idMember}/deltas
# operationId: getMembersDeltasByIdMember
export def "get-members-deltas-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing (required)
  --ix-last-update: string # a number from -1 to Infinity (required)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/deltas"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: tags, var: tags, required: true}, {name: ixLastUpdate, var: ix_last_update, required: true}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, tags: $tags, ix_last_update: $ix_last_update, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersFullNameByIdMember()
#
# PUT /members/{idMember}/fullName
# operationId: updateMembersFullNameByIdMember
export def "update-members-full-name-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A string with a length of at least 1. Cannot begin or end with a space.
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/fullName"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersInitialsByIdMember()
#
# PUT /members/{idMember}/initials
# operationId: updateMembersInitialsByIdMember
export def "update-members-initials-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A string with a length from 1 to 4. Cannot begin or end with a space
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/initials"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersNotificationsByIdMember()
#
# GET /members/{idMember}/notifications
# operationId: getMembersNotificationsByIdMember
export def "get-members-notifications-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAdminToBoard, addAdminToOrganization, addedAttachmentToCard, addedMemberToCard, addedToBoard, addedToCard, addedToOrganization, cardDueSoon, changeCard, closeBoard, commentCard, createdCard, declinedInvitationToBoard, declinedInvitationToOrganization, invitedToBoard, invitedToOrganization, makeAdminOfBoard, makeAdminOfOrganization, memberJoinedTrello, mentionedOnCard, removedFromBoard, removedFromCard, removedFromOrganization, removedMemberFromCard, unconfirmedInvitedToBoard, unconfirmedInvitedToOrganization or updateCheckItemStateOnCard (default: all)
  --read-filter: string # One of: all, read or unread (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --limit: string # a number from 1 to 1000 (default: 50)
  --page: string # a number from 0 to 100 (default: 0)
  --before: string # An id, or null
  --since: string # An id, or null
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/notifications"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: entities, var: entities}, {name: display, var: display}, {name: filter, var: filter}, {name: read_filter, var: read_filter}, {name: fields, var: fields}, {name: limit, var: limit}, {name: page, var: page}, {name: before, var: before}, {name: since, var: since}, {name: memberCreator, var: member_creator}, {name: memberCreator_fields, var: member_creator_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, entities: $entities, display: $display, filter: $filter, read_filter: $read_filter, fields: $fields, limit: $limit, page: $page, before: $before, since: $since, member_creator: $member_creator, member_creator_fields: $member_creator_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersNotificationsByIdMemberByFilter()
#
# GET /members/{idMember}/notifications/{filter}
# operationId: getMembersNotificationsByIdMemberByFilter
export def "get-members-notifications-by-id-member-by-filter" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/notifications/{filter}"
    path_params: [{name: idMember, var: id_member}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addMembersOneTimeMessagesDismissedByIdMember()
#
# POST /members/{idMember}/oneTimeMessagesDismissed
# operationId: addMembersOneTimeMessagesDismissedByIdMember
export def "add-members-one-time-messages-dismissed-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # Type of message dismissed
]: any -> any {
  $in | http-request {
    method: post
    path: "/members/{idMember}/oneTimeMessagesDismissed"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersOrganizationsByIdMember()
#
# GET /members/{idMember}/organizations
# operationId: getMembersOrganizationsByIdMember
export def "get-members-organizations-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all, members, none or public (default: all)
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --paid-account: string # true or false
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/organizations"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: filter, var: filter}, {name: fields, var: fields}, {name: paid_account, var: paid_account}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, fields: $fields, paid_account: $paid_account, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersOrganizationsByIdMemberByFilter()
#
# GET /members/{idMember}/organizations/{filter}
# operationId: getMembersOrganizationsByIdMemberByFilter
export def "get-members-organizations-by-id-member-by-filter" [
  id_member: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/organizations/{filter}"
    path_params: [{name: idMember, var: id_member}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersOrganizationsInvitedByIdMember()
#
# GET /members/{idMember}/organizationsInvited
# operationId: getMembersOrganizationsInvitedByIdMember
export def "get-members-organizations-invited-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/organizationsInvited"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersOrganizationsInvitedByIdMemberByField()
#
# GET /members/{idMember}/organizationsInvited/{field}
# operationId: getMembersOrganizationsInvitedByIdMemberByField
export def "get-members-organizations-invited-by-id-member-by-field" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/organizationsInvited/{field}"
    path_params: [{name: idMember, var: id_member}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersPrefsColorBlindByIdMember()
#
# PUT /members/{idMember}/prefs/colorBlind
# operationId: updateMembersPrefsColorBlindByIdMember
export def "update-members-prefs-color-blind-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/prefs/colorBlind"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersPrefsLocaleByIdMember()
#
# PUT /members/{idMember}/prefs/locale
# operationId: updateMembersPrefsLocaleByIdMember
export def "update-members-prefs-locale-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 255
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/prefs/locale"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersPrefsMinutesBetweenSummariesByIdMember()
#
# PUT /members/{idMember}/prefs/minutesBetweenSummaries
# operationId: updateMembersPrefsMinutesBetweenSummariesByIdMember
export def "update-members-prefs-minutes-between-summaries-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # -1 (disabled), 1 or 60
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/prefs/minutesBetweenSummaries"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersSavedSearchesByIdMember()
#
# GET /members/{idMember}/savedSearches
# operationId: getMembersSavedSearchesByIdMember
export def "get-members-saved-searches-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/savedSearches"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addMembersSavedSearchesByIdMember()
#
# POST /members/{idMember}/savedSearches
# operationId: addMembersSavedSearchesByIdMember
export def "add-members-saved-searches-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --name: string # A non-empty string with at least one non-space character
  --pos: string # A position. top , bottom , or a positive number.
  --query: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: post
    path: "/members/{idMember}/savedSearches"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: pos, var: pos}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, name: $name, pos: $pos, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# DELETE /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: deleteMembersSavedSearchesByIdMemberByIdSavedSearch
export def "delete-members-saved-searches-by-id-member-by-id-saved-search" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/members/{idMember}/savedSearches/{idSavedSearch}"
    path_params: [{name: idMember, var: id_member}, {name: idSavedSearch, var: id_saved_search}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_saved_search: $id_saved_search, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# GET /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: getMembersSavedSearchesByIdMemberByIdSavedSearch
export def "get-members-saved-searches-by-id-member-by-id-saved-search" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/savedSearches/{idSavedSearch}"
    path_params: [{name: idMember, var: id_member}, {name: idSavedSearch, var: id_saved_search}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_saved_search: $id_saved_search, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersSavedSearchesByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}
# operationId: updateMembersSavedSearchesByIdMemberByIdSavedSearch
export def "update-members-saved-searches-by-id-member-by-id-saved-search" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --name: string # A non-empty string with at least one non-space character
  --pos: string # A position. top , bottom , or a positive number.
  --query: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/savedSearches/{idSavedSearch}"
    path_params: [{name: idMember, var: id_member}, {name: idSavedSearch, var: id_saved_search}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: pos, var: pos}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_saved_search: $id_saved_search, key: $key, qp_token: $qp_token, name: $name, pos: $pos, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersSavedSearchesNameByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/name
# operationId: updateMembersSavedSearchesNameByIdMemberByIdSavedSearch
export def "update-members-saved-searches-name-by-id-member-by-id-saved-search" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A non-empty string with at least one non-space character
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/savedSearches/{idSavedSearch}/name"
    path_params: [{name: idMember, var: id_member}, {name: idSavedSearch, var: id_saved_search}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_saved_search: $id_saved_search, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersSavedSearchesPosByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/pos
# operationId: updateMembersSavedSearchesPosByIdMemberByIdSavedSearch
export def "update-members-saved-searches-pos-by-id-member-by-id-saved-search" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A position. top , bottom , or a positive number.
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/savedSearches/{idSavedSearch}/pos"
    path_params: [{name: idMember, var: id_member}, {name: idSavedSearch, var: id_saved_search}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_saved_search: $id_saved_search, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersSavedSearchesQueryByIdMemberByIdSavedSearch()
#
# PUT /members/{idMember}/savedSearches/{idSavedSearch}/query
# operationId: updateMembersSavedSearchesQueryByIdMemberByIdSavedSearch
export def "update-members-saved-searches-query-by-id-member-by-id-saved-search" [
  id_member: string
  id_saved_search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 1 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/savedSearches/{idSavedSearch}/query"
    path_params: [{name: idMember, var: id_member}, {name: idSavedSearch, var: id_saved_search}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, id_saved_search: $id_saved_search, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersTokensByIdMember()
#
# GET /members/{idMember}/tokens
# operationId: getMembersTokensByIdMember
export def "get-members-tokens-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: all or none (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/tokens"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: filter, var: filter}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateMembersUsernameByIdMember()
#
# PUT /members/{idMember}/username
# operationId: updateMembersUsernameByIdMember
export def "update-members-username-by-id-member" [
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A string with a length of at least 3. Only lowercase letters, underscores, and numbers are allowed. Must be unique.
]: any -> any {
  $in | http-request {
    method: put
    path: "/members/{idMember}/username"
    path_params: [{name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getMembersByIdMemberByField()
#
# GET /members/{idMember}/{field}
# operationId: getMembersByIdMemberByField
export def "get-members-by-id-member-by-field" [
  id_member: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/members/{idMember}/{field}"
    path_params: [{name: idMember, var: id_member}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_member: $id_member, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addNotificationsAllRead()
#
# POST /notifications/all/read
# operationId: addNotificationsAllRead
export def "add-notifications-all-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: post
    path: "/notifications/all/read"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsByIdNotification()
#
# GET /notifications/{idNotification}
# operationId: getNotificationsByIdNotification
export def "get-notifications-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display: string # true or false
  --entities: string # true or false
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator, type or unread (default: all)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name)
  --list: string # true or false
  --card: string # true or false
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: name)
  --organization: string # true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: displayName)
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: display, var: display}, {name: entities, var: entities}, {name: fields, var: fields}, {name: memberCreator, var: member_creator}, {name: memberCreator_fields, var: member_creator_fields}, {name: board, var: board}, {name: board_fields, var: board_fields}, {name: list, var: list}, {name: card, var: card}, {name: card_fields, var: card_fields}, {name: organization, var: organization}, {name: organization_fields, var: organization_fields}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, display: $display, entities: $entities, fields: $fields, member_creator: $member_creator, member_creator_fields: $member_creator_fields, board: $board, board_fields: $board_fields, list: $list, card: $card, card_fields: $card_fields, organization: $organization, organization_fields: $organization_fields, member: $member, member_fields: $member_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateNotificationsByIdNotification()
#
# PUT /notifications/{idNotification}
# operationId: updateNotificationsByIdNotification
export def "update-notifications-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --unread: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/notifications/{idNotification}"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: unread, var: unread}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, key: $key, qp_token: $qp_token, unread: $unread
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsBoardByIdNotification()
#
# GET /notifications/{idNotification}/board
# operationId: getNotificationsBoardByIdNotification
export def "get-notifications-board-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/board"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsBoardByIdNotificationByField()
#
# GET /notifications/{idNotification}/board/{field}
# operationId: getNotificationsBoardByIdNotificationByField
export def "get-notifications-board-by-id-notification-by-field" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/board/{field}"
    path_params: [{name: idNotification, var: id_notification}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsCardByIdNotification()
#
# GET /notifications/{idNotification}/card
# operationId: getNotificationsCardByIdNotification
export def "get-notifications-card-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/card"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsCardByIdNotificationByField()
#
# GET /notifications/{idNotification}/card/{field}
# operationId: getNotificationsCardByIdNotificationByField
export def "get-notifications-card-by-id-notification-by-field" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/card/{field}"
    path_params: [{name: idNotification, var: id_notification}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsDisplayByIdNotification()
#
# GET /notifications/{idNotification}/display
# operationId: getNotificationsDisplayByIdNotification
export def "get-notifications-display-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/display"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsEntitiesByIdNotification()
#
# GET /notifications/{idNotification}/entities
# operationId: getNotificationsEntitiesByIdNotification
export def "get-notifications-entities-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/entities"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsListByIdNotification()
#
# GET /notifications/{idNotification}/list
# operationId: getNotificationsListByIdNotification
export def "get-notifications-list-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/list"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsListByIdNotificationByField()
#
# GET /notifications/{idNotification}/list/{field}
# operationId: getNotificationsListByIdNotificationByField
export def "get-notifications-list-by-id-notification-by-field" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/list/{field}"
    path_params: [{name: idNotification, var: id_notification}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsMemberByIdNotification()
#
# GET /notifications/{idNotification}/member
# operationId: getNotificationsMemberByIdNotification
export def "get-notifications-member-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/member"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsMemberByIdNotificationByField()
#
# GET /notifications/{idNotification}/member/{field}
# operationId: getNotificationsMemberByIdNotificationByField
export def "get-notifications-member-by-id-notification-by-field" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/member/{field}"
    path_params: [{name: idNotification, var: id_notification}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsMemberCreatorByIdNotification()
#
# GET /notifications/{idNotification}/memberCreator
# operationId: getNotificationsMemberCreatorByIdNotification
export def "get-notifications-member-creator-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/memberCreator"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsMemberCreatorByIdNotificationByField()
#
# GET /notifications/{idNotification}/memberCreator/{field}
# operationId: getNotificationsMemberCreatorByIdNotificationByField
export def "get-notifications-member-creator-by-id-notification-by-field" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/memberCreator/{field}"
    path_params: [{name: idNotification, var: id_notification}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsOrganizationByIdNotification()
#
# GET /notifications/{idNotification}/organization
# operationId: getNotificationsOrganizationByIdNotification
export def "get-notifications-organization-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/organization"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsOrganizationByIdNotificationByField()
#
# GET /notifications/{idNotification}/organization/{field}
# operationId: getNotificationsOrganizationByIdNotificationByField
export def "get-notifications-organization-by-id-notification-by-field" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/organization/{field}"
    path_params: [{name: idNotification, var: id_notification}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateNotificationsUnreadByIdNotification()
#
# PUT /notifications/{idNotification}/unread
# operationId: updateNotificationsUnreadByIdNotification
export def "update-notifications-unread-by-id-notification" [
  id_notification: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/notifications/{idNotification}/unread"
    path_params: [{name: idNotification, var: id_notification}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getNotificationsByIdNotificationByField()
#
# GET /notifications/{idNotification}/{field}
# operationId: getNotificationsByIdNotificationByField
export def "get-notifications-by-id-notification-by-field" [
  id_notification: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/notifications/{idNotification}/{field}"
    path_params: [{name: idNotification, var: id_notification}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_notification: $id_notification, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addOrganizations()
#
# POST /organizations
# operationId: addOrganizations
export def "add-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --desc: string # a string with a length from 0 to 16384
  --display-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --name: string # a string with a length from 0 to 16384
  --prefs-associated-domain: string # The google apps domain to link this org to.
  --prefs-board-visibility-restrict-org: string # One of: admin, none or org
  --prefs-board-visibility-restrict-private: string # One of: admin, none or org
  --prefs-board-visibility-restrict-public: string # One of: admin, none or org
  --prefs-external-members-disabled: string # true or false
  --prefs-google-apps-version: string # a number from 1 to 2
  --prefs-org-invite-restrict: string # An email address with optional expansion tokens
  --prefs-permission-level: string # One of: private or public
  --website: string # A URL starting with http:// or https:// or null
]: any -> any {
  $in | http-request {
    method: post
    path: "/organizations"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: desc, var: desc}, {name: displayName, var: display_name}, {name: name, var: name}, {name: "prefs/associatedDomain", var: prefs_associated_domain}, {name: "prefs/boardVisibilityRestrict/org", var: prefs_board_visibility_restrict_org}, {name: "prefs/boardVisibilityRestrict/private", var: prefs_board_visibility_restrict_private}, {name: "prefs/boardVisibilityRestrict/public", var: prefs_board_visibility_restrict_public}, {name: "prefs/externalMembersDisabled", var: prefs_external_members_disabled}, {name: "prefs/googleAppsVersion", var: prefs_google_apps_version}, {name: "prefs/orgInviteRestrict", var: prefs_org_invite_restrict}, {name: "prefs/permissionLevel", var: prefs_permission_level}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, desc: $desc, display_name: $display_name, name: $name, prefs_associated_domain: $prefs_associated_domain, prefs_board_visibility_restrict_org: $prefs_board_visibility_restrict_org, prefs_board_visibility_restrict_private: $prefs_board_visibility_restrict_private, prefs_board_visibility_restrict_public: $prefs_board_visibility_restrict_public, prefs_external_members_disabled: $prefs_external_members_disabled, prefs_google_apps_version: $prefs_google_apps_version, prefs_org_invite_restrict: $prefs_org_invite_restrict, prefs_permission_level: $prefs_permission_level, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteOrganizationsByIdOrg()
#
# DELETE /organizations/{idOrg}
# operationId: deleteOrganizationsByIdOrg
export def "delete-organizations-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizations/{idOrg}"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsByIdOrg()
#
# GET /organizations/{idOrg}
# operationId: getOrganizationsByIdOrg
export def "get-organizations-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-display: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --memberships-member: string # true or false
  --memberships-member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --members: string # One of: admins, all, none, normal or owners (default: none)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials, username and confirmed)
  --member-activity: string # true or false ; works for premium organizations only.
  --members-invited: string # One of: admins, all, none, normal or owners (default: none)
  --members-invited-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, initials, fullName and username)
  --boards: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: none)
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --board-actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --board-actions-entities: string # true or false
  --board-actions-display: string # true or false
  --board-actions-format: string # One of: count, list or minimal (default: list)
  --board-actions-since: string # A date, null or lastView
  --board-actions-limit: string # a number from 0 to 1000 (default: 50)
  --board-action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --board-lists: string # One of: all, closed, none or open (default: none)
  --paid-account: string # true or false
  --fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name, displayName, desc, descData, url, website, logoHash, products and powerUps)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: actions, var: actions}, {name: actions_entities, var: actions_entities}, {name: actions_display, var: actions_display}, {name: actions_limit, var: actions_limit}, {name: action_fields, var: action_fields}, {name: memberships, var: memberships}, {name: memberships_member, var: memberships_member}, {name: memberships_member_fields, var: memberships_member_fields}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: member_activity, var: member_activity}, {name: membersInvited, var: members_invited}, {name: membersInvited_fields, var: members_invited_fields}, {name: boards, var: boards}, {name: board_fields, var: board_fields}, {name: board_actions, var: board_actions}, {name: board_actions_entities, var: board_actions_entities}, {name: board_actions_display, var: board_actions_display}, {name: board_actions_format, var: board_actions_format}, {name: board_actions_since, var: board_actions_since}, {name: board_actions_limit, var: board_actions_limit}, {name: board_action_fields, var: board_action_fields}, {name: board_lists, var: board_lists}, {name: paid_account, var: paid_account}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, actions: $actions, actions_entities: $actions_entities, actions_display: $actions_display, actions_limit: $actions_limit, action_fields: $action_fields, memberships: $memberships, memberships_member: $memberships_member, memberships_member_fields: $memberships_member_fields, members: $members, member_fields: $member_fields, member_activity: $member_activity, members_invited: $members_invited, members_invited_fields: $members_invited_fields, boards: $boards, board_fields: $board_fields, board_actions: $board_actions, board_actions_entities: $board_actions_entities, board_actions_display: $board_actions_display, board_actions_format: $board_actions_format, board_actions_since: $board_actions_since, board_actions_limit: $board_actions_limit, board_action_fields: $board_action_fields, board_lists: $board_lists, paid_account: $paid_account, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsByIdOrg()
#
# PUT /organizations/{idOrg}
# operationId: updateOrganizationsByIdOrg
export def "update-organizations-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --desc: string # a string with a length from 0 to 16384
  --display-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --name: string # a string with a length from 0 to 16384
  --prefs-associated-domain: string # The google apps domain to link this org to.
  --prefs-board-visibility-restrict-org: string # One of: admin, none or org
  --prefs-board-visibility-restrict-private: string # One of: admin, none or org
  --prefs-board-visibility-restrict-public: string # One of: admin, none or org
  --prefs-external-members-disabled: string # true or false
  --prefs-google-apps-version: string # a number from 1 to 2
  --prefs-org-invite-restrict: string # An email address with optional expansion tokens
  --prefs-permission-level: string # One of: private or public
  --website: string # A URL starting with http:// or https:// or null
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: desc, var: desc}, {name: displayName, var: display_name}, {name: name, var: name}, {name: "prefs/associatedDomain", var: prefs_associated_domain}, {name: "prefs/boardVisibilityRestrict/org", var: prefs_board_visibility_restrict_org}, {name: "prefs/boardVisibilityRestrict/private", var: prefs_board_visibility_restrict_private}, {name: "prefs/boardVisibilityRestrict/public", var: prefs_board_visibility_restrict_public}, {name: "prefs/externalMembersDisabled", var: prefs_external_members_disabled}, {name: "prefs/googleAppsVersion", var: prefs_google_apps_version}, {name: "prefs/orgInviteRestrict", var: prefs_org_invite_restrict}, {name: "prefs/permissionLevel", var: prefs_permission_level}, {name: website, var: website}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, desc: $desc, display_name: $display_name, name: $name, prefs_associated_domain: $prefs_associated_domain, prefs_board_visibility_restrict_org: $prefs_board_visibility_restrict_org, prefs_board_visibility_restrict_private: $prefs_board_visibility_restrict_private, prefs_board_visibility_restrict_public: $prefs_board_visibility_restrict_public, prefs_external_members_disabled: $prefs_external_members_disabled, prefs_google_apps_version: $prefs_google_apps_version, prefs_org_invite_restrict: $prefs_org_invite_restrict, prefs_permission_level: $prefs_permission_level, website: $website
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsActionsByIdOrg()
#
# GET /organizations/{idOrg}/actions
# operationId: getOrganizationsActionsByIdOrg
export def "get-organizations-actions-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entities: string # true or false
  --display: string # true or false
  --filter: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization (default: all)
  --fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --limit: string # a number from 0 to 1000 (default: 50)
  --format: string # One of: count, list or minimal (default: list)
  --since: string # A date, null or lastView
  --before: string # A date, or null
  --page: string # Page * limit must be less than 1000 (default: 0)
  --id-models: string # Only return actions related to these model ids
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --member-creator: string # true or false
  --member-creator-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/actions"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: entities, var: entities}, {name: display, var: display}, {name: filter, var: filter}, {name: fields, var: fields}, {name: limit, var: limit}, {name: format, var: format}, {name: since, var: since}, {name: before, var: before}, {name: page, var: page}, {name: idModels, var: id_models}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: memberCreator, var: member_creator}, {name: memberCreator_fields, var: member_creator_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, entities: $entities, display: $display, filter: $filter, fields: $fields, limit: $limit, format: $format, since: $since, before: $before, page: $page, id_models: $id_models, member: $member, member_fields: $member_fields, member_creator: $member_creator, member_creator_fields: $member_creator_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsBoardsByIdOrg()
#
# GET /organizations/{idOrg}/boards
# operationId: getOrganizationsBoardsByIdOrg
export def "get-organizations-boards-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: closed, members, open, organization, pinned, public, starred or unpinned (default: all)
  --fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: all)
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --actions-entities: string # true or false
  --actions-limit: string # a number from 0 to 1000 (default: 50)
  --actions-format: string # One of: count, list or minimal (default: list)
  --actions-since: string # A date, null or lastView
  --action-fields: string # all or a comma-separated list of: data, date, idMemberCreator or type (default: all)
  --memberships: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: none)
  --organization: string # true or false
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --lists: string # One of: all, closed, none or open (default: none)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/boards"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: filter, var: filter}, {name: fields, var: fields}, {name: actions, var: actions}, {name: actions_entities, var: actions_entities}, {name: actions_limit, var: actions_limit}, {name: actions_format, var: actions_format}, {name: actions_since, var: actions_since}, {name: action_fields, var: action_fields}, {name: memberships, var: memberships}, {name: organization, var: organization}, {name: organization_fields, var: organization_fields}, {name: lists, var: lists}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, filter: $filter, fields: $fields, actions: $actions, actions_entities: $actions_entities, actions_limit: $actions_limit, actions_format: $actions_format, actions_since: $actions_since, action_fields: $action_fields, memberships: $memberships, organization: $organization, organization_fields: $organization_fields, lists: $lists, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsBoardsByIdOrgByFilter()
#
# GET /organizations/{idOrg}/boards/{filter}
# operationId: getOrganizationsBoardsByIdOrgByFilter
export def "get-organizations-boards-by-id-org-by-filter" [
  id_org: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/boards/{filter}"
    path_params: [{name: idOrg, var: id_org}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsDeltasByIdOrg()
#
# GET /organizations/{idOrg}/deltas
# operationId: getOrganizationsDeltasByIdOrg
export def "get-organizations-deltas-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string # A valid tag for subscribing (required)
  --ix-last-update: string # a number from -1 to Infinity (required)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/deltas"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: tags, var: tags, required: true}, {name: ixLastUpdate, var: ix_last_update, required: true}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, tags: $tags, ix_last_update: $ix_last_update, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsDescByIdOrg()
#
# PUT /organizations/{idOrg}/desc
# operationId: updateOrganizationsDescByIdOrg
export def "update-organizations-desc-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/desc"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsDisplayNameByIdOrg()
#
# PUT /organizations/{idOrg}/displayName
# operationId: updateOrganizationsDisplayNameByIdOrg
export def "update-organizations-display-name-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A string with a length of at least 1. Cannot begin or end with a space.
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/displayName"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteOrganizationsLogoByIdOrg()
#
# DELETE /organizations/{idOrg}/logo
# operationId: deleteOrganizationsLogoByIdOrg
export def "delete-organizations-logo-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizations/{idOrg}/logo"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addOrganizationsLogoByIdOrg()
#
# POST /organizations/{idOrg}/logo
# operationId: addOrganizationsLogoByIdOrg
export def "add-organizations-logo-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --file: string # A file
]: any -> any {
  $in | http-request {
    method: post
    path: "/organizations/{idOrg}/logo"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: file, var: file}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsMembersByIdOrg()
#
# GET /organizations/{idOrg}/members
# operationId: getOrganizationsMembersByIdOrg
export def "get-organizations-members-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # One of: admins, all, none, normal or owners (default: all)
  --fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --activity: string # true or false ; works for premium organizations only.
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/members"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: filter, var: filter}, {name: fields, var: fields}, {name: activity, var: activity}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, filter: $filter, fields: $fields, activity: $activity, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsMembersByIdOrg()
#
# PUT /organizations/{idOrg}/members
# operationId: updateOrganizationsMembersByIdOrg
export def "update-organizations-members-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --email: string # An email address
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/members"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: fullName, var: full_name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, email: $email, full_name: $full_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsMembersByIdOrgByFilter()
#
# GET /organizations/{idOrg}/members/{filter}
# operationId: getOrganizationsMembersByIdOrgByFilter
export def "get-organizations-members-by-id-org-by-filter" [
  id_org: string
  filter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/members/{filter}"
    path_params: [{name: idOrg, var: id_org}, {name: filter, var: filter}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, filter: $filter, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteOrganizationsMembersByIdOrgByIdMember()
#
# DELETE /organizations/{idOrg}/members/{idMember}
# operationId: deleteOrganizationsMembersByIdOrgByIdMember
export def "delete-organizations-members-by-id-org-by-id-member" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizations/{idOrg}/members/{idMember}"
    path_params: [{name: idOrg, var: id_org}, {name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, id_member: $id_member, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsMembersByIdOrgByIdMember()
#
# PUT /organizations/{idOrg}/members/{idMember}
# operationId: updateOrganizationsMembersByIdOrgByIdMember
export def "update-organizations-members-by-id-org-by-id-member" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --email: string # An email address
  --full-name: string # A string with a length of at least 1. Cannot begin or end with a space.
  --type: string # One of: admin, normal or observer
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/members/{idMember}"
    path_params: [{name: idOrg, var: id_org}, {name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: fullName, var: full_name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, id_member: $id_member, key: $key, qp_token: $qp_token, email: $email, full_name: $full_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteOrganizationsMembersAllByIdOrgByIdMember()
#
# DELETE /organizations/{idOrg}/members/{idMember}/all
# operationId: deleteOrganizationsMembersAllByIdOrgByIdMember
export def "delete-organizations-members-all-by-id-org-by-id-member" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizations/{idOrg}/members/{idMember}/all"
    path_params: [{name: idOrg, var: id_org}, {name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, id_member: $id_member, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsMembersCardsByIdOrgByIdMember()
#
# GET /organizations/{idOrg}/members/{idMember}/cards
# operationId: getOrganizationsMembersCardsByIdOrgByIdMember
export def "get-organizations-members-cards-by-id-org-by-id-member" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: string # all or a comma-separated list of: addAttachmentToCard, addChecklistToCard, addMemberToBoard, addMemberToCard, addMemberToOrganization, addToOrganizationBoard, commentCard, convertToCardFromCheckItem, copyBoard, copyCard, copyCommentCard, createBoard, createCard, createList, createOrganization, deleteAttachmentFromCard, deleteBoardInvitation, deleteCard, deleteOrganizationInvitation, disablePowerUp, emailCard, enablePowerUp, makeAdminOfBoard, makeNormalMemberOfBoard, makeNormalMemberOfOrganization, makeObserverOfBoard, memberJoinedTrello, moveCardFromBoard, moveCardToBoard, moveListFromBoard, moveListToBoard, removeChecklistFromCard, removeFromOrganizationBoard, removeMemberFromCard, unconfirmedBoardInvitation, unconfirmedOrganizationInvitation, updateBoard, updateCard, updateCard:closed, updateCard:desc, updateCard:idList, updateCard:name, updateCheckItemStateOnCard, updateChecklist, updateList, updateList:closed, updateList:name, updateMember or updateOrganization
  --attachments: string # A boolean value or "cover" for only card cover attachments
  --attachment-fields: string # all or a comma-separated list of: bytes, date, edgeColor, idMember, isUpload, mimeType, name, previews or url (default: all)
  --members: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials and username)
  --check-item-states: string # true or false
  --checklists: string # One of: all or none (default: none)
  --board: string # true or false
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name, desc, closed, idOrganization, pinned, url and prefs)
  --list: string # true or false
  --list-fields: string # all or a comma-separated list of: closed, idBoard, name, pos or subscribed (default: all)
  --filter: string # One of: all, closed, none, open or visible (default: visible)
  --fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/members/{idMember}/cards"
    path_params: [{name: idOrg, var: id_org}, {name: idMember, var: id_member}]
    query: [{name: actions, var: actions}, {name: attachments, var: attachments}, {name: attachment_fields, var: attachment_fields}, {name: members, var: members}, {name: member_fields, var: member_fields}, {name: checkItemStates, var: check_item_states}, {name: checklists, var: checklists}, {name: board, var: board}, {name: board_fields, var: board_fields}, {name: list, var: list}, {name: list_fields, var: list_fields}, {name: filter, var: filter}, {name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, id_member: $id_member, actions: $actions, attachments: $attachments, attachment_fields: $attachment_fields, members: $members, member_fields: $member_fields, check_item_states: $check_item_states, checklists: $checklists, board: $board, board_fields: $board_fields, list: $list, list_fields: $list_fields, filter: $filter, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsMembersDeactivatedByIdOrgByIdMember()
#
# PUT /organizations/{idOrg}/members/{idMember}/deactivated
# operationId: updateOrganizationsMembersDeactivatedByIdOrgByIdMember
export def "update-organizations-members-deactivated-by-id-org-by-id-member" [
  id_org: string
  id_member: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/members/{idMember}/deactivated"
    path_params: [{name: idOrg, var: id_org}, {name: idMember, var: id_member}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, id_member: $id_member, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsMembersInvitedByIdOrg()
#
# GET /organizations/{idOrg}/membersInvited
# operationId: getOrganizationsMembersInvitedByIdOrg
export def "get-organizations-members-invited-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/membersInvited"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsMembersInvitedByIdOrgByField()
#
# GET /organizations/{idOrg}/membersInvited/{field}
# operationId: getOrganizationsMembersInvitedByIdOrgByField
export def "get-organizations-members-invited-by-id-org-by-field" [
  id_org: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/membersInvited/{field}"
    path_params: [{name: idOrg, var: id_org}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsMembershipsByIdOrg()
#
# GET /organizations/{idOrg}/memberships
# operationId: getOrganizationsMembershipsByIdOrg
export def "get-organizations-memberships-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # all or a comma-separated list of: active, admin, deactivated, me or normal (default: all)
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/memberships"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: filter, var: filter}, {name: member, var: member}, {name: member_fields, var: member_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, filter: $filter, member: $member, member_fields: $member_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsMembershipsByIdOrgByIdMembership()
#
# GET /organizations/{idOrg}/memberships/{idMembership}
# operationId: getOrganizationsMembershipsByIdOrgByIdMembership
export def "get-organizations-memberships-by-id-org-by-id-membership" [
  id_org: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --member: string # true or false
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: fullName and username)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/memberships/{idMembership}"
    path_params: [{name: idOrg, var: id_org}, {name: idMembership, var: id_membership}]
    query: [{name: member, var: member}, {name: member_fields, var: member_fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, id_membership: $id_membership, member: $member, member_fields: $member_fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsMembershipsByIdOrgByIdMembership()
#
# PUT /organizations/{idOrg}/memberships/{idMembership}
# operationId: updateOrganizationsMembershipsByIdOrgByIdMembership
export def "update-organizations-memberships-by-id-org-by-id-membership" [
  id_org: string
  id_membership: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username
  --type: string # One of: admin, normal or observer
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/memberships/{idMembership}"
    path_params: [{name: idOrg, var: id_org}, {name: idMembership, var: id_membership}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: member_fields, var: member_fields}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, id_membership: $id_membership, key: $key, qp_token: $qp_token, member_fields: $member_fields, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsNameByIdOrg()
#
# PUT /organizations/{idOrg}/name
# operationId: updateOrganizationsNameByIdOrg
export def "update-organizations-name-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A string with a length of at least 3. Only lowercase letters, underscores, and numbers are allowed. Must be unique.
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/name"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteOrganizationsPrefsAssociatedDomainByIdOrg()
#
# DELETE /organizations/{idOrg}/prefs/associatedDomain
# operationId: deleteOrganizationsPrefsAssociatedDomainByIdOrg
export def "delete-organizations-prefs-associated-domain-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizations/{idOrg}/prefs/associatedDomain"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsPrefsAssociatedDomainByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/associatedDomain
# operationId: updateOrganizationsPrefsAssociatedDomainByIdOrg
export def "update-organizations-prefs-associated-domain-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # The google apps domain to link this org to.
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/prefs/associatedDomain"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsPrefsBoardVisibilityRestrictOrgByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/boardVisibilityRestrict/org
# operationId: updateOrganizationsPrefsBoardVisibilityRestrictOrgByIdOrg
export def "update-organizations-prefs-board-visibility-restrict-org-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: admin, none or org
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/prefs/boardVisibilityRestrict/org"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsPrefsBoardVisibilityRestrictPrivateByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/boardVisibilityRestrict/private
# operationId: updateOrganizationsPrefsBoardVisibilityRestrictPrivateByIdOrg
export def "update-organizations-prefs-board-visibility-restrict-private-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: admin, none or org
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/prefs/boardVisibilityRestrict/private"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsPrefsBoardVisibilityRestrictPublicByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/boardVisibilityRestrict/public
# operationId: updateOrganizationsPrefsBoardVisibilityRestrictPublicByIdOrg
export def "update-organizations-prefs-board-visibility-restrict-public-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: admin, none or org
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/prefs/boardVisibilityRestrict/public"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsPrefsExternalMembersDisabledByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/externalMembersDisabled
# operationId: updateOrganizationsPrefsExternalMembersDisabledByIdOrg
export def "update-organizations-prefs-external-members-disabled-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/prefs/externalMembersDisabled"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsPrefsGoogleAppsVersionByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/googleAppsVersion
# operationId: updateOrganizationsPrefsGoogleAppsVersionByIdOrg
export def "update-organizations-prefs-google-apps-version-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a number from 1 to 2
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/prefs/googleAppsVersion"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteOrganizationsPrefsOrgInviteRestrictByIdOrg()
#
# DELETE /organizations/{idOrg}/prefs/orgInviteRestrict
# operationId: deleteOrganizationsPrefsOrgInviteRestrictByIdOrg
export def "delete-organizations-prefs-org-invite-restrict-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # An email address with optional expansion tokens (required)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/organizations/{idOrg}/prefs/orgInviteRestrict"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: value, var: value, required: true}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, value: $value, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsPrefsOrgInviteRestrictByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/orgInviteRestrict
# operationId: updateOrganizationsPrefsOrgInviteRestrictByIdOrg
export def "update-organizations-prefs-org-invite-restrict-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # An email address with optional expansion tokens
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/prefs/orgInviteRestrict"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsPrefsPermissionLevelByIdOrg()
#
# PUT /organizations/{idOrg}/prefs/permissionLevel
# operationId: updateOrganizationsPrefsPermissionLevelByIdOrg
export def "update-organizations-prefs-permission-level-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: private or public
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/prefs/permissionLevel"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateOrganizationsWebsiteByIdOrg()
#
# PUT /organizations/{idOrg}/website
# operationId: updateOrganizationsWebsiteByIdOrg
export def "update-organizations-website-by-id-org" [
  id_org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A URL starting with http:// or https:// or null
]: any -> any {
  $in | http-request {
    method: put
    path: "/organizations/{idOrg}/website"
    path_params: [{name: idOrg, var: id_org}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getOrganizationsByIdOrgByField()
#
# GET /organizations/{idOrg}/{field}
# operationId: getOrganizationsByIdOrgByField
export def "get-organizations-by-id-org-by-field" [
  id_org: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/organizations/{idOrg}/{field}"
    path_params: [{name: idOrg, var: id_org}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_org: $id_org, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSearch()
#
# GET /search
# operationId: getSearch
export def "get-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # a string with a length from 1 to 16384 (required)
  --id-boards: string # A comma-separated list of objectIds, 24-character hex strings (default: mine)
  --id-organizations: string # A comma-separated list of objectIds, 24-character hex strings (required)
  --id-cards: string # A comma-separated list of objectIds, 24-character hex strings
  --model-types: string # all or a comma-separated list of: actions, boards, cards, members or organizations (default: all)
  --board-fields: string # all or a comma-separated list of: closed, dateLastActivity, dateLastView, desc, descData, idOrganization, invitations, invited, labelNames, memberships, name, pinned, powerUps, prefs, shortLink, shortUrl, starred, subscribed or url (default: name and idOrganization)
  --boards-limit: string # a number from 1 to 1000 (default: 10)
  --card-fields: string # all or a comma-separated list of: badges, checkItemStates, closed, dateLastActivity, desc, descData, due, email, idAttachmentCover, idBoard, idChecklists, idLabels, idList, idMembers, idMembersVoted, idShort, labels, manualCoverAttachment, name, pos, shortLink, shortUrl, subscribed or url (default: all)
  --cards-limit: string # a number from 1 to 1000 (default: 10)
  --cards-page: string # a number from 0 to 100 (default: 0)
  --card-board: string # true or false
  --card-list: string # true or false
  --card-members: string # true or false
  --card-stickers: string # true or false
  --card-attachments: string # A boolean value or "cover" for only card cover attachments
  --organization-fields: string # all or a comma-separated list of: billableMemberCount, desc, descData, displayName, idBoards, invitations, invited, logoHash, memberships, name, powerUps, prefs, premiumFeatures, products, url or website (default: name and displayName)
  --organizations-limit: string # a number from 1 to 1000 (default: 10)
  --member-fields: string # all or a comma-separated list of: avatarHash, bio, bioData, confirmed, fullName, idPremOrgsAdmin, initials, memberType, products, status, url or username (default: avatarHash, fullName, initials, username and confirmed)
  --members-limit: string # a number from 1 to 1000 (default: 10)
  --partial: string # true or false
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/search"
    query: [{name: query, var: query, required: true}, {name: idBoards, var: id_boards}, {name: idOrganizations, var: id_organizations, required: true}, {name: idCards, var: id_cards}, {name: modelTypes, var: model_types}, {name: board_fields, var: board_fields}, {name: boards_limit, var: boards_limit}, {name: card_fields, var: card_fields}, {name: cards_limit, var: cards_limit}, {name: cards_page, var: cards_page}, {name: card_board, var: card_board}, {name: card_list, var: card_list}, {name: card_members, var: card_members}, {name: card_stickers, var: card_stickers}, {name: card_attachments, var: card_attachments}, {name: organization_fields, var: organization_fields}, {name: organizations_limit, var: organizations_limit}, {name: member_fields, var: member_fields}, {name: members_limit, var: members_limit}, {name: partial, var: partial}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    query: $query, id_boards: $id_boards, id_organizations: $id_organizations, id_cards: $id_cards, model_types: $model_types, board_fields: $board_fields, boards_limit: $boards_limit, card_fields: $card_fields, cards_limit: $cards_limit, cards_page: $cards_page, card_board: $card_board, card_list: $card_list, card_members: $card_members, card_stickers: $card_stickers, card_attachments: $card_attachments, organization_fields: $organization_fields, organizations_limit: $organizations_limit, member_fields: $member_fields, members_limit: $members_limit, partial: $partial, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSearchMembers()
#
# GET /search/members
# operationId: getSearchMembers
export def "get-search-members" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # a string with a length from 1 to 16384 (required)
  --limit: string # a number from 1 to 20 (default: 8)
  --id-board: string # An id, or null
  --id-organization: string # An id, or null
  --only-org-members: string # A boolean
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/search/members"
    query: [{name: query, var: query, required: true}, {name: limit, var: limit}, {name: idBoard, var: id_board}, {name: idOrganization, var: id_organization}, {name: onlyOrgMembers, var: only_org_members}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    query: $query, limit: $limit, id_board: $id_board, id_organization: $id_organization, only_org_members: $only_org_members, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addSessions()
#
# POST /sessions
# operationId: addSessions
export def "add-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-board: string # The id of the board you're viewing. Boards with no viewers will not get updates about members' statuses.
  --status: string # One of: active, disconnected or idle
]: any -> any {
  $in | http-request {
    method: post
    path: "/sessions"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idBoard, var: id_board}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, id_board: $id_board, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getSessionsSocket()
#
# GET /sessions/socket
# operationId: getSessionsSocket
export def "get-sessions-socket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/sessions/socket"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateSessionsByIdSession()
#
# PUT /sessions/{idSession}
# operationId: updateSessionsByIdSession
export def "update-sessions-by-id-session" [
  id_session: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --id-board: string # The id of the board you're viewing. Boards with no viewers will not get updates about members' statuses.
  --status: string # One of: active, disconnected or idle
]: any -> any {
  $in | http-request {
    method: put
    path: "/sessions/{idSession}"
    path_params: [{name: idSession, var: id_session}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: idBoard, var: id_board}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_session: $id_session, key: $key, qp_token: $qp_token, id_board: $id_board, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateSessionsStatusByIdSession()
#
# PUT /sessions/{idSession}/status
# operationId: updateSessionsStatusByIdSession
export def "update-sessions-status-by-id-session" [
  id_session: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # One of: active, disconnected or idle
]: any -> any {
  $in | http-request {
    method: put
    path: "/sessions/{idSession}/status"
    path_params: [{name: idSession, var: id_session}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_session: $id_session, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteTokensByToken()
#
# DELETE /tokens/{token}
# operationId: deleteTokensByToken
export def "delete-tokens-by-token" [
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
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/tokens/{token}"
    path_params: [{name: token, var: token_arg}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTokensByToken()
#
# GET /tokens/{token}
# operationId: getTokensByToken
export def "get-tokens-by-token" [
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
  --fields: string # all or a comma-separated list of: dateCreated, dateExpires, idMember, identifier or permissions (default: all)
  --webhooks: string # true or false
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/tokens/{token}"
    path_params: [{name: token, var: token_arg}]
    query: [{name: fields, var: fields}, {name: webhooks, var: webhooks}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, fields: $fields, webhooks: $webhooks, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTokensMemberByToken()
#
# GET /tokens/{token}/member
# operationId: getTokensMemberByToken
export def "get-tokens-member-by-token" [
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
  --fields: string # all or a comma-separated list of: avatarHash, avatarSource, bio, bioData, confirmed, email, fullName, gravatarHash, idBoards, idBoardsPinned, idOrganizations, idPremOrgsAdmin, initials, loginTypes, memberType, oneTimeMessagesDismissed, prefs, premiumFeatures, products, status, status, trophies, uploadedAvatarHash, url or username (default: all)
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/tokens/{token}/member"
    path_params: [{name: token, var: token_arg}]
    query: [{name: fields, var: fields}, {name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, fields: $fields, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTokensMemberByTokenByField()
#
# GET /tokens/{token}/member/{field}
# operationId: getTokensMemberByTokenByField
export def "get-tokens-member-by-token-by-field" [
  token_arg: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/tokens/{token}/member/{field}"
    path_params: [{name: token, var: token_arg}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTokensWebhooksByToken()
#
# GET /tokens/{token}/webhooks
# operationId: getTokensWebhooksByToken
export def "get-tokens-webhooks-by-token" [
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
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/tokens/{token}/webhooks"
    path_params: [{name: token, var: token_arg}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addTokensWebhooksByToken()
#
# POST /tokens/{token}/webhooks
# operationId: addTokensWebhooksByToken
export def "add-tokens-webhooks-by-token" [
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
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model to be monitored
]: any -> any {
  $in | http-request {
    method: post
    path: "/tokens/{token}/webhooks"
    path_params: [{name: token, var: token_arg}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: callbackURL, var: callback_url}, {name: description, var: description}, {name: idModel, var: id_model}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, key: $key, qp_token: $qp_token, callback_url: $callback_url, description: $description, id_model: $id_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateTokensWebhooksByToken()
#
# PUT /tokens/{token}/webhooks
# operationId: updateTokensWebhooksByToken
export def "update-tokens-webhooks-by-token" [
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
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model to be monitored
]: any -> any {
  $in | http-request {
    method: put
    path: "/tokens/{token}/webhooks"
    path_params: [{name: token, var: token_arg}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: callbackURL, var: callback_url}, {name: description, var: description}, {name: idModel, var: id_model}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, key: $key, qp_token: $qp_token, callback_url: $callback_url, description: $description, id_model: $id_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteTokensWebhooksByTokenByIdWebhook()
#
# DELETE /tokens/{token}/webhooks/{idWebhook}
# operationId: deleteTokensWebhooksByTokenByIdWebhook
export def "delete-tokens-webhooks-by-token-by-id-webhook" [
  token_arg: string
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/tokens/{token}/webhooks/{idWebhook}"
    path_params: [{name: token, var: token_arg}, {name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, id_webhook: $id_webhook, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTokensWebhooksByTokenByIdWebhook()
#
# GET /tokens/{token}/webhooks/{idWebhook}
# operationId: getTokensWebhooksByTokenByIdWebhook
export def "get-tokens-webhooks-by-token-by-id-webhook" [
  token_arg: string
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/tokens/{token}/webhooks/{idWebhook}"
    path_params: [{name: token, var: token_arg}, {name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, id_webhook: $id_webhook, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTokensByTokenByField()
#
# GET /tokens/{token}/{field}
# operationId: getTokensByTokenByField
export def "get-tokens-by-token-by-field" [
  token_arg: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/tokens/{token}/{field}"
    path_params: [{name: token, var: token_arg}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    token_arg: $token_arg, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getTypesById()
#
# GET /types/{id}
# operationId: getTypesById
export def "get-types-by-id" [
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
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/types/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id: $id, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# addWebhooks()
#
# POST /webhooks
# operationId: addWebhooks
export def "add-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --active: string # true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  $in | http-request {
    method: post
    path: "/webhooks"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: callbackURL, var: callback_url}, {name: description, var: description}, {name: idModel, var: id_model}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, active: $active, callback_url: $callback_url, description: $description, id_model: $id_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateWebhooks()
#
# PUT /webhooks/
# operationId: updateWebhooks
export def "update-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --active: string # true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  $in | http-request {
    method: put
    path: "/webhooks/"
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: callbackURL, var: callback_url}, {name: description, var: description}, {name: idModel, var: id_model}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    key: $key, qp_token: $qp_token, active: $active, callback_url: $callback_url, description: $description, id_model: $id_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deleteWebhooksByIdWebhook()
#
# DELETE /webhooks/{idWebhook}
# operationId: deleteWebhooksByIdWebhook
export def "delete-webhooks-by-id-webhook" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/webhooks/{idWebhook}"
    path_params: [{name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_webhook: $id_webhook, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getWebhooksByIdWebhook()
#
# GET /webhooks/{idWebhook}
# operationId: getWebhooksByIdWebhook
export def "get-webhooks-by-id-webhook" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/webhooks/{idWebhook}"
    path_params: [{name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_webhook: $id_webhook, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateWebhooksByIdWebhook()
#
# PUT /webhooks/{idWebhook}
# operationId: updateWebhooksByIdWebhook
export def "update-webhooks-by-id-webhook" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --active: string # true or false
  --callback-url: string # A valid URL that is reachable with a HEAD request
  --description: string # a string with a length from 0 to 16384
  --id-model: string # id of the model that should be hooked
]: any -> any {
  $in | http-request {
    method: put
    path: "/webhooks/{idWebhook}"
    path_params: [{name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: callbackURL, var: callback_url}, {name: description, var: description}, {name: idModel, var: id_model}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_webhook: $id_webhook, key: $key, qp_token: $qp_token, active: $active, callback_url: $callback_url, description: $description, id_model: $id_model
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateWebhooksActiveByIdWebhook()
#
# PUT /webhooks/{idWebhook}/active
# operationId: updateWebhooksActiveByIdWebhook
export def "update-webhooks-active-by-id-webhook" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # true or false
]: any -> any {
  $in | http-request {
    method: put
    path: "/webhooks/{idWebhook}/active"
    path_params: [{name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_webhook: $id_webhook, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateWebhooksCallbackURLByIdWebhook()
#
# PUT /webhooks/{idWebhook}/callbackURL
# operationId: updateWebhooksCallbackURLByIdWebhook
export def "update-webhooks-callback-url-by-id-webhook" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # A valid URL that is reachable with a HEAD request
]: any -> any {
  $in | http-request {
    method: put
    path: "/webhooks/{idWebhook}/callbackURL"
    path_params: [{name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_webhook: $id_webhook, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateWebhooksDescriptionByIdWebhook()
#
# PUT /webhooks/{idWebhook}/description
# operationId: updateWebhooksDescriptionByIdWebhook
export def "update-webhooks-description-by-id-webhook" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # a string with a length from 0 to 16384
]: any -> any {
  $in | http-request {
    method: put
    path: "/webhooks/{idWebhook}/description"
    path_params: [{name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_webhook: $id_webhook, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# updateWebhooksIdModelByIdWebhook()
#
# PUT /webhooks/{idWebhook}/idModel
# operationId: updateWebhooksIdModelByIdWebhook
export def "update-webhooks-id-model-by-id-webhook" [
  id_webhook: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
  --value: string # id of the model to be monitored
]: any -> any {
  $in | http-request {
    method: put
    path: "/webhooks/{idWebhook}/idModel"
    path_params: [{name: idWebhook, var: id_webhook}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_webhook: $id_webhook, key: $key, qp_token: $qp_token, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# getWebhooksByIdWebhookByField()
#
# GET /webhooks/{idWebhook}/{field}
# operationId: getWebhooksByIdWebhookByField
export def "get-webhooks-by-id-webhook-by-field" [
  id_webhook: string
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Generate your application key (https://trello.com/1/appKey/generate) (required)
  --qp-token: string # Getting a token from a user (https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user) (required) (spec name: token)
]: nothing -> any {
  http-request {
    method: get
    path: "/webhooks/{idWebhook}/{field}"
    path_params: [{name: idWebhook, var: id_webhook}, {name: field, var: field}]
    query: [{name: key, var: key, required: true}, {name: token, var: qp_token, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: query-key
  } {
    id_webhook: $id_webhook, field: $field, key: $key, qp_token: $qp_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
