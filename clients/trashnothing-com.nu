# Auto-generated client for trash nothing v1.3
# Source: https://api.apis.guru/v2/specs/trashnothing.com/1.3/openapi.json
# Auth: --token flag or $env.TRASH_NOTHING_TOKEN

const CLIENT = {
  base_url: "https://trashnothing.com/api/v1.3"
  token_env_var: "TRASH_NOTHING_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-api_key, in: query, header_name: api_key, prefix: ""}
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

def base-url-completer [] { ["https://trashnothing.com/api/v1.3"] }
def auth-scheme-completer [] { ["query-api_key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-conversations: "record<conversations: table<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list, num_unread_messages: int, user: record>, num_unread: int, page: int, per_page: int>"
    search-conversations: "record<conversations: table<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list, num_unread_messages: int, user: record>, page: int, per_page: int, search: string>"
    get-conversation-messages: "record<conversation: record<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list<record>, num_unread_messages: int, user: record<about_me: string, country: string, feedback: record, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>>, messages: table<content: string, date: string, email_attachments: list, from_user_id: string, message_id: string, photos: list, post: record, subject: string, to_user_id: string>, page: int, per_page: int>"
    reply-to-conversation: "record<content: string, date: string, email_attachments: list<string>, from_user_id: string, message_id: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list<record>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, subject: string, to_user_id: string>"
    search-groups: "record<end_index: int, groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, num_groups: int, num_pages: int, page: int, per_page: int, start_index: int>"
    get-groups-by-ids: "table<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>"
    join-groups: "record<groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, over_group_limit: bool>"
    get-group: "record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>"
    submit-answers: "record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>"
    leave-group: "record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>"
    upload-photo: "record<photo_id: string, thumbnail: record<height: int, url: string, width: int>>"
    get-photos-by-ids: "table<photo_id: string, thumbnail: record<height: int, url: string, width: int>>"
    rotate-photo: "record<photo_id: string, thumbnail: record<height: int, url: string, width: int>>"
    get-posts: "record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int>"
    submit-post: "record<identifier: string, message: string, preference_key: string, result: string, session: record>"
    get-all-posts: "record<posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>>"
    get-all-posts-changes: "record<changes: table<date: string, post_id: string, type: string>>"
    get-posts-by-ids: "record<forbidden: list<string>, not_found: list<string>, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>>"
    search-posts: "record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int>"
    get-post: "record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>"
    update-post: "record<identifier: string, message: string, preference_key: string, result: string, session: record>"
    get-post-and-related-data: "record<author: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, author_offer_count: int, author_posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, author_wanted_count: int, bookmarked: bool, feedback: table<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, post: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list<record>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, replied: bool, user_can_reply: bool, viewed: bool>"
    promise-post: "record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>"
    satisfy-post: "record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>"
    unpromise-post: "record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>"
    withdraw-post: "record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>"
    get-stories: "record<stories: table<content: string, date: string, like_count: int, photos: list, share_url: string, story_id: string, title: string, user: record, user_liked: bool>>"
    submit-story: "record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool>"
    get-story: "record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool>"
    like-story: "record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool>"
    unlike-story: "record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool>"
    get-current-user: "record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>"
    update-current-user: "record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>"
    get-alerts: "table<alert_id: string, last_sent: string, search: string, send_count: int, types: list<string>, user_id: string>"
    create-alert: "record<alert_id: string, last_sent: string, search: string, send_count: int, types: list<string>, user_id: string>"
    set-email-not-bouncing: "record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>"
    get-current-user-groups: "table<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>"
    update-location: "record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>"
    get-user-group-notices: "table<content: string, date: string, group_id: string, notice_id: string, title: string>"
    get-post-locations: "table<latitude: float, longitude: float, name: string>"
    save-post-location: "table<latitude: float, longitude: float, name: string>"
    get-current-user-posts: "record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int>"
    search-current-user-posts: "record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int>"
    set-profile-image: "record<photo: record<photo_id: string, thumbnail: record<height: int, url: string, width: int>>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>>"
    get-profile-images: "table<image: string, source: string>"
    get-user: "record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>"
    get-user-and-related-data: "record<feedback: table<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, offer_count: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, wanted_count: int>"
    remove-user-feedback: "record<user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>>"
    submit-user-feedback: "record<feedback: record<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>>"
    get-user-posts: "record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int>"
    search-user-posts: "record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-conversations" "archive-all-conversations" "mark-all-conversations-read" "search-conversations" "delete-conversation" "archive-conversation" "block-conversation" "mark-conversation-read" "get-conversation-messages" "reply-to-conversation" "report-conversation" "unarchive-conversation" "unblock-conversation" "send-feedback" "search-groups" "get-groups-by-ids" "join-groups" "get-group" "submit-answers" "contact-moderators" "leave-group" "upload-photo" "get-photos-by-ids" "delete-photo" "rotate-photo" "get-posts" "submit-post" "get-all-posts" "get-all-posts-changes" "get-posts-by-ids" "search-posts" "delete-post" "get-post" "update-post" "delete-bookmark" "bookmark-post" "get-post-and-related-data" "promise-post" "reply-to-post" "report-post" "satisfy-post" "share-post" "unpromise-post" "withdraw-post" "get-stories" "submit-story" "get-story" "like-story" "unlike-story" "viewed-story" "get-current-user" "update-current-user" "get-alerts" "create-alert" "delete-alert" "change-email" "set-email-not-bouncing" "get-current-user-groups" "update-location" "get-user-group-notices" "get-post-locations" "save-post-location" "get-current-user-posts" "search-current-user-posts" "set-profile-image" "get-profile-images" "resend-account-verification-email" "send-password-reset-email" "report-user" "get-user" "get-user-and-related-data" "remove-user-feedback" "submit-user-feedback" "get-user-posts" "search-user-posts" "get-profile-image-file" "commands"] | sort) } | get name | first)
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

# List conversations
#
# GET /conversations
# Returns: record<conversations: table<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list, num_unread_messages: int, user: record>, num_unread: int, page: int, per_page: int>
# operationId: get_conversations
export def "get-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # Used to filter messases by category. Must be set to one of the following three categories: inbox, archived, blocked (default: inbox)
  --page: int # The page of conversations to return. (default: 1)
  --per-page: int # The number of conversations to return per page (must be >= 1 and <= 30). (default: 10)
  --num-messages: int # The number of recent messages to return with each conversation. Additional messages can be retrieved using get conversation messages endpoint. (default: 10)
  --include-num-unread: int # If set to 1, the num_unread field in the response will be set to the count of the total number of conversations that have unread messages. This is useful for showing users the total number of unread messages that they have in their inbox. Calculating the count will slow the request down a bit so setting this should be avoided for requests where it's not needed (eg. requesting archived or blocked conversations or requests that are just paging through older conversations). (default: 0)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations"
    query: [{name: category, var: category}, {name: page, var: page}, {name: per_page, var: per_page}, {name: num_messages, var: num_messages}, {name: include_num_unread, var: include_num_unread}, {name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    category: $category, page: $page, per_page: $per_page, num_messages: $num_messages, include_num_unread: $include_num_unread, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive all conversations
#
# PUT /conversations/archive-all
# operationId: archive_all_conversations
export def "archive-all-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message_id: string # The message_id of the most recent message from the conversations that the client has downloaded.
]: any -> any {
  $in | http-request {
    method: put
    path: "/conversations/archive-all"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: message_id, var: message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark all conversations as read
#
# PUT /conversations/mark-all-read
# operationId: mark_all_conversations_read
export def "mark-all-conversations-read" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message_id: string # The message_id of the most recent message from the conversations that the client has downloaded.
]: any -> any {
  $in | http-request {
    method: put
    path: "/conversations/mark-all-read"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: message_id, var: message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search conversations
#
# GET /conversations/search
# Returns: record<conversations: table<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list, num_unread_messages: int, user: record>, page: int, per_page: int, search: string>
# operationId: search_conversations
export def "search-conversations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search query used to find conversations and messages. (required)
  --page: int # The page of conversations to return. (default: 1)
  --per-page: int # The number of conversations to return per page (must be >= 1 and <= 30). (default: 10)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/search"
    query: [{name: search, var: search, required: true}, {name: page, var: page}, {name: per_page, var: per_page}, {name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, page: $page, per_page: $per_page, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete conversation
#
# DELETE /conversations/{conversation_id}
# operationId: delete_conversation
export def "delete-conversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message-id: string # The ID of the newest message in the conversation that the client has downloaded. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/conversations/{conversation_id}"
    path_params: [{name: conversation_id, var: conversation_id}]
    query: [{name: message_id, var: message_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive conversation
#
# PUT /conversations/{conversation_id}/archive
# operationId: archive_conversation
export def "archive-conversation" [
  conversation_id: string
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
    path: "/conversations/{conversation_id}/archive"
    path_params: [{name: conversation_id, var: conversation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Block conversation
#
# PUT /conversations/{conversation_id}/block
# operationId: block_conversation
export def "block-conversation" [
  conversation_id: string
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
    path: "/conversations/{conversation_id}/block"
    path_params: [{name: conversation_id, var: conversation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark conversation as read
#
# PUT /conversations/{conversation_id}/mark-read
# operationId: mark_conversation_read
export def "mark-conversation-read" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message_id: string # The ID of the newest message in the conversation that the current user has read.
]: any -> any {
  $in | http-request {
    method: put
    path: "/conversations/{conversation_id}/mark-read"
    path_params: [{name: conversation_id, var: conversation_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: message_id, var: message_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id, message_id: $message_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List conversation messages
#
# GET /conversations/{conversation_id}/messages
# Returns: record<conversation: record<archived: bool, blocked: bool, conversation_id: string, last_message_date: string, messages: list<record>, num_unread_messages: int, user: record<about_me: string, country: string, feedback: record, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>>, messages: table<content: string, date: string, email_attachments: list, from_user_id: string, message_id: string, photos: list, post: record, subject: string, to_user_id: string>, page: int, per_page: int>
# operationId: get_conversation_messages
export def "get-conversation-messages" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of messages to return. (default: 1)
  --per-page: int # The number of messages to return per page (must be >= 1 and <= 30). (default: 10)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --include-conversation: int # If set to 1, the conversation will be returned along with the messages. (default: 0)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/conversations/{conversation_id}/messages"
    path_params: [{name: conversation_id, var: conversation_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: include_conversation, var: include_conversation}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id, page: $page, per_page: $per_page, device_pixel_ratio: $device_pixel_ratio, include_conversation: $include_conversation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reply to conversation
#
# POST /conversations/{conversation_id}/reply
# Returns: record<content: string, date: string, email_attachments: list<string>, from_user_id: string, message_id: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list<record>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, subject: string, to_user_id: string>
# operationId: reply_to_conversation
export def "reply-to-conversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The content of the reply.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this message.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/conversations/{conversation_id}/reply"
    path_params: [{name: conversation_id, var: conversation_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: content, var: content}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: photo_ids, var: photo_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id, content: $content, device_pixel_ratio: $device_pixel_ratio, photo_ids: $photo_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report conversation
#
# POST /conversations/{conversation_id}/report
# operationId: report_conversation
export def "report-conversation" [
  conversation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # A user provided reason why the conversation is being reported.
]: any -> any {
  $in | http-request {
    method: post
    path: "/conversations/{conversation_id}/report"
    path_params: [{name: conversation_id, var: conversation_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive conversation
#
# PUT /conversations/{conversation_id}/unarchive
# operationId: unarchive_conversation
export def "unarchive-conversation" [
  conversation_id: string
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
    path: "/conversations/{conversation_id}/unarchive"
    path_params: [{name: conversation_id, var: conversation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unblock conversation
#
# PUT /conversations/{conversation_id}/unblock
# operationId: unblock_conversation
export def "unblock-conversation" [
  conversation_id: string
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
    path: "/conversations/{conversation_id}/unblock"
    path_params: [{name: conversation_id, var: conversation_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    conversation_id: $conversation_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send feedback
#
# POST /feedback
# operationId: send_feedback
export def "send-feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # The message.
  --meta: string # Extra information set by the client that may be useful to contextualize the feedback (eg. operating system details, browser details, app details, device details).
  subject: string # The subject.
]: any -> any {
  $in | http-request {
    method: post
    path: "/feedback"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: message, var: message}, {name: meta, var: meta}, {name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    message: $message, meta: $meta, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search groups
#
# GET /groups
# Returns: record<end_index: int, groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, num_groups: int, num_pages: int, page: int, per_page: int, start_index: int>
# operationId: search_groups
export def "search-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Find groups that have the given text somewhere in their name (case insensitive).
  --latitude: float # Find groups near the given latitude and longitude.
  --longitude: float # Find groups near the given latitude and longitude.
  --distance: float # When latitude and longitude are passed, distance can optionally be passed to only return groups within a certain distance (in kilometers) from the point specified by the latitude and longitude. The distance must be > 0 and <= 150 and will default to 100. (default: 100)
  --country: string # Find groups in the given country where country is a 2 letter country code for the country (see https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 ).
  --region: string # For countries with regions (AU, CA, GB, US), search groups in a specific region as specified by the region abbreviation. The supported regions and their abbreviations are listed below. NOTE: The region and postal_code parameters cannot be used at the same time and if both are passed then the postal_code will take priority. --- **AU** - QLD: Queensland - SA: South Australia - TAS: Tasmania - VIC: Victoria - WA: Western Australia - NT: Northern Territory - NSW: New South Wales - ACT **CA** - AB: Alberta - BC: British Columbia - MB: Manitoba - NB: New Brunswick - NL: Newfoundland and Labrador - NS: Nova Scotia - ON: Ontario - QC: Quebec - SK: Saskatchewan - PE: Prince Edward Island **GB** - E: East - EM: East Midlands - LDN: London - NE: North East - NW: North West - NI: Northern Ireland - SC: Scotland - SE: South East - SW: South West - WA: Wales - WM: West Midlands - YH: Yorkshire and the Humber **US** All 50 states and the District of Columbia are supported. For the abbreviations, see: https://github.com/jasonong/List-of-US-States/blob/master/states.csv
  --postal-code: string # Find groups in the given postal code. Only a few countries support postal code searches (US, CA, AU, GB). The country parameter must be passed when the postal_code parameter is set. NOTE: The region and postal_code parameters cannot be used at the same time and if both are passed then the postal_code will take priority.
  --page: int # The page of groups to return. (default: 1)
  --per-page: int # The number of groups to return per page (must be >= 1 and <= 100). (default: 20)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/groups"
    query: [{name: name, var: name}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: distance, var: distance}, {name: country, var: country}, {name: region, var: region}, {name: postal_code, var: postal_code}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, latitude: $latitude, longitude: $longitude, distance: $distance, country: $country, region: $region, postal_code: $postal_code, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve multiple groups
#
# GET /groups/multiple
# Returns: table<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>
# operationId: get_groups_by_ids
export def "get-groups-by-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-ids: string # The IDs of the groups to retrieve. If more than 20 group IDs are passed, only the first 20 groups will be returned. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/groups/multiple"
    query: [{name: group_ids, var: group_ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_ids: $group_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Join groups
#
# POST /groups/subscribe
# Returns: record<groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, over_group_limit: bool>
# operationId: join_groups
export def "join-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  group_ids: string # A comma separated list of the IDs of the groups to join.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/subscribe"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: group_ids, var: group_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_ids: $group_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a group
#
# GET /groups/{group_id}
# Returns: record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>
# operationId: get_group
export def "get-group" [
  group_id: string
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
    path: "/groups/{group_id}"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit group answers
#
# POST /groups/{group_id}/answers
# Returns: record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>
# operationId: submit_answers
export def "submit-answers" [
  group_id: string
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
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/groups/{group_id}/answers"
    path_params: [{name: group_id, var: group_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Contact group moderators
#
# POST /groups/{group_id}/contact
# operationId: contact_moderators
export def "contact-moderators" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # The body of the message.
  subject: string # The subject of the message.
]: any -> any {
  $in | http-request {
    method: post
    path: "/groups/{group_id}/contact"
    path_params: [{name: group_id, var: group_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: message, var: message}, {name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, message: $message, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Leave a group
#
# POST /groups/{group_id}/unsubscribe
# Returns: record<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record<message: string, questions: list>, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>
# operationId: leave_group
export def "leave-group" [
  group_id: string
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
    path: "/groups/{group_id}/unsubscribe"
    path_params: [{name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a photo
#
# POST /photos
# Returns: record<photo_id: string, thumbnail: record<height: int, url: string, width: int>>
# operationId: upload_photo
export def "upload-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  photo: string # Photo to upload. (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/photos"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: device_pixel_ratio, var: device_pixel_ratio}, {name: photo, var: photo}], files: [photo]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    device_pixel_ratio: $device_pixel_ratio, photo: $photo
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve multiple photos
#
# GET /photos/multiple
# Returns: table<photo_id: string, thumbnail: record<height: int, url: string, width: int>>
# operationId: get_photos_by_ids
export def "get-photos-by-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --photo-ids: string # The IDs of the photos to retrieve. If more than 50 photo IDs are passed, only the first 50 photos will be returned. (required)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/photos/multiple"
    query: [{name: photo_ids, var: photo_ids, required: true}, {name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    photo_ids: $photo_ids, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a photo
#
# DELETE /photos/{photo_id}
# operationId: delete_photo
export def "delete-photo" [
  photo_id: string
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
    path: "/photos/{photo_id}"
    path_params: [{name: photo_id, var: photo_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    photo_id: $photo_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rotate a photo
#
# POST /photos/{photo_id}/rotate
# Returns: record<photo_id: string, thumbnail: record<height: int, url: string, width: int>>
# operationId: rotate_photo
export def "rotate-photo" [
  photo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --degrees: int # Rotation in degrees - currently only 90, 180 and 270 are supported which correspond to rotate left, rotate upside down and rotate right. (required)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/photos/{photo_id}/rotate"
    path_params: [{name: photo_id, var: photo_id}]
    query: [{name: degrees, var: degrees, required: true}, {name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    photo_id: $photo_id, degrees: $degrees, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List posts
#
# GET /posts
# Returns: record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int>
# operationId: get_posts
export def "get-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string # How to sort the posts that are returned. One of: date, active, distance Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: date)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin (required)
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or the current users' location if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required. (required)
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. If unset, defaults to the current date and time minus 90 days. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. If unset, defaults to the current date and time. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: "")
  --user-state: string # If user_state is set, only posts matching the state specified will be returned. Only one state may be passed and it must be one of the following: viewed, replied, bookmarked NOTE: This option will only work with oauth requests. (default: "")
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts"
    query: [{name: sort_by, var: sort_by}, {name: types, var: types, required: true}, {name: sources, var: sources, required: true}, {name: group_ids, var: group_ids}, {name: per_page, var: per_page}, {name: page, var: page}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: date_min, var: date_min}, {name: date_max, var: date_max}, {name: outcomes, var: outcomes}, {name: user_state, var: user_state}, {name: include_reposts, var: include_reposts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort_by: $sort_by, types: $types, sources: $sources, group_ids: $group_ids, per_page: $per_page, page: $page, device_pixel_ratio: $device_pixel_ratio, latitude: $latitude, longitude: $longitude, radius: $radius, date_min: $date_min, date_max: $date_max, outcomes: $outcomes, user_state: $user_state, include_reposts: $include_reposts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a post
#
# POST /posts
# Returns: record<identifier: string, message: string, preference_key: string, result: string, session: record>
# operationId: submit_post
export def "submit-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # A longer description of the item(s).
  --expires-in: string # When the post should expire. Defaults to 90 days. Any amount of time from 1 hour to 90 days can be provided. To pass a number of hours, provide the number of hours prefixed by 'h' (eg. 1hr 24hr). To pass a number of days, provide the number of days prefixed by 'd' (eg. 1d 90d). Note that posts may not appear instantly after submission because the volunteer moderators of many groups may have additional automatic or manual review processes in place that can cause delays. So with short expirations (eg. < 8 hours), there is a chance that the post may expire before it's approved and so it will never be published.
  --fair-offer: int # If set to 1, the post will be posted with the Fair Offer Policy (only valid for offer posts - see https://trashnothing.com/fair_offer_policy ). (default: 0)
  --group-ids: string # A comma separated list of group IDs to submit the post to (if any).
  --latitude: float # The latitude corresponding to the location description provided. If latitude and longitude are not provided, an attempt will be made to automatically geocode the location. If the location is unable to be geocoded, the post will be rejected* and will have to be resubmitted with a latitude and longitude corresponding to the location or resubmitted with a different location that can be automatically geocoded. NOTE: The latitude and longitude should NOT be the users' exact location because we don't want to publicize their exact location unless their location description is their full address (which is not recommended). *When a post is rejected because it can't be geocoded, the returned error will have its identifier property set to 'unknown-location'.
  location: string # A short location description.
  --longitude: float # The longitude corresponding to the location description provided. (see the NOTE in latitude description)
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this post.
  --preferences: string # A JSON string representing a permanent object that the client persists and modifies based on warnings returned by the post submission process and user input. Some warnings returned after submitting a post have a preference_key string property so that users can opt out of those warnings in the future. To save this opt-out preference, set the property indicated by the preference_key in the preferences object (eg. preferences[preference_key] = 1). The preferences object is never modified by the server - it is up to the client to initialize, modify and persist the preferences object.
  --repost: string # If the post is a repost of an existing post, this should be set to the post_id of the post that is being reposted.
  --reselling: string # For wanted posts only. If set to 1, the wanted post will show that the poster intends to resell any items that they receive in response to this post. Posters must declare if they intend to resell items.
  session: string # A JSON string representing a temporary object that is used to store data about the submission process for a single post. The first time a post is submitted, session should be a new empty object (eg. '{}'). The session object should be persisted by the client until that post is successfully submitted and then it can be discarded so that the next post will start over with a new empty session object. Every time a post is submitted and the response indicates that the submission was not successful, the session object returned in the response should override the clients copy of the session.
  title: string # A short description of the item(s).
  type: string # The type of post. One of: offer, wanted
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/posts"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: content, var: content}, {name: expires_in, var: expires_in}, {name: fair_offer, var: fair_offer}, {name: group_ids, var: group_ids}, {name: latitude, var: latitude}, {name: location, var: location}, {name: longitude, var: longitude}, {name: photo_ids, var: photo_ids}, {name: preferences, var: preferences}, {name: repost, var: repost}, {name: reselling, var: reselling}, {name: session, var: session}, {name: title, var: title}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content: $content, expires_in: $expires_in, fair_offer: $fair_offer, group_ids: $group_ids, latitude: $latitude, location: $location, longitude: $longitude, photo_ids: $photo_ids, preferences: $preferences, repost: $repost, reselling: $reselling, session: $session, title: $title, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all posts
#
# GET /posts/all
# Returns: record<posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>>
# operationId: get_all_posts
export def "get-all-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --types: string # A comma separated list of the post types to return. The available post types are: offer, wanted (required)
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. The UTC date and time used must be within a day or less of date_max. And the date and time must be within the last 30 days. And the date and time must be rounded to the nearest second. (required, format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. The UTC date and time used must be within a day or less of date_min. And the date and time must be rounded to the nearest second. (required, format: date-time)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 50). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts/all"
    query: [{name: types, var: types, required: true}, {name: date_min, var: date_min, required: true}, {name: date_max, var: date_max, required: true}, {name: per_page, var: per_page}, {name: page, var: page}, {name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    types: $types, date_min: $date_min, date_max: $date_max, per_page: $per_page, page: $page, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all post changes
#
# GET /posts/all/changes
# Returns: record<changes: table<date: string, post_id: string, type: string>>
# operationId: get_all_posts_changes
export def "get-all-posts-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-min: string # Only changes newer than or equal to this UTC date and time will be returned. The UTC date and time used must be within a day or less of date_max. And the date and time must be within the last 30 days. And the date and time must be rounded to the nearest second. (required, format: date-time)
  --date-max: string # Only changes older than this UTC date and time will be returned. The UTC date and time used must be within a day or less of date_min. And the date and time must be rounded to the nearest second. (required, format: date-time)
  --per-page: int # The number of changes to return per page (must be >= 1 and <= 50). (default: 20)
  --page: int # The page of changes to return. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts/all/changes"
    query: [{name: date_min, var: date_min, required: true}, {name: date_max, var: date_max, required: true}, {name: per_page, var: per_page}, {name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    date_min: $date_min, date_max: $date_max, per_page: $per_page, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve multiple posts
#
# GET /posts/multiple
# Returns: record<forbidden: list<string>, not_found: list<string>, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>>
# operationId: get_posts_by_ids
export def "get-posts-by-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --post-ids: string # A comma separated list of the post IDs. If more than 10 post IDs are passed, only the first 10 posts will be returned. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts/multiple"
    query: [{name: post_ids, var: post_ids, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_ids: $post_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search posts
#
# GET /posts/search
# Returns: record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int>
# operationId: search_posts
export def "search-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search query used to find posts. (required)
  --sort-by: string # How to sort the posts that are returned. One of: relevance, date, active, distance Relevance sorting will sort the posts that best match the search query first. Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: relevance)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin (required)
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or the current users' location if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required. (required)
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. If unset, defaults to the current date and time minus 90 days. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. If unset, defaults to the current date and time. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: "")
  --user-state: string # If user_state is set, only posts matching the state specified will be returned. Only one state may be passed and it must be one of the following: viewed, replied, bookmarked NOTE: This option will only work with oauth requests. (default: "")
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/posts/search"
    query: [{name: search, var: search, required: true}, {name: sort_by, var: sort_by}, {name: types, var: types, required: true}, {name: sources, var: sources, required: true}, {name: group_ids, var: group_ids}, {name: per_page, var: per_page}, {name: page, var: page}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: date_min, var: date_min}, {name: date_max, var: date_max}, {name: outcomes, var: outcomes}, {name: user_state, var: user_state}, {name: include_reposts, var: include_reposts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, sort_by: $sort_by, types: $types, sources: $sources, group_ids: $group_ids, per_page: $per_page, page: $page, device_pixel_ratio: $device_pixel_ratio, latitude: $latitude, longitude: $longitude, radius: $radius, date_min: $date_min, date_max: $date_max, outcomes: $outcomes, user_state: $user_state, include_reposts: $include_reposts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a post
#
# DELETE /posts/{post_id}
# operationId: delete_post
export def "delete-post" [
  post_id: string
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
    path: "/posts/{post_id}"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a post
#
# GET /posts/{post_id}
# Returns: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>
# operationId: get_post
export def "get-post" [
  post_id: string
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
    path: "/posts/{post_id}"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a post
#
# PUT /posts/{post_id}
# Returns: record<identifier: string, message: string, preference_key: string, result: string, session: record>
# operationId: update_post
export def "update-post" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # A longer description of the item(s).
  --expires-in: string # When the post should expire. Any amount of time from 1 hour to 90 days can be provided. To pass a number of hours, provide the number of hours prefixed by 'h' (eg. 1hr 24hr). To pass a number of days, provide the number of days prefixed by 'd' (eg. 1d 90d). Note that updates may not appear instantly after submission because the volunteer moderators of many groups may have additional automatic or manual review processes in place that can cause delays. So with short expirations (eg. < 8 hours), there is a chance that the post may expire before the update is approved and so it will never be published. NOTE: The max expiration for a post is 90 days after the post is published. So updates to posts that try to set an longer expiration will be silently changed to just apply the max expiration.
  --fair-offer: int # If set to 1, the post will be posted with the Fair Offer Policy (only valid for offer posts - see https://trashnothing.com/fair_offer_policy ). (default: 0)
  --latitude: float # The latitude corresponding to the location description provided. If latitude and longitude are not provided, an attempt will be made to automatically geocode the location. If the location is unable to be geocoded, the post will be rejected* and will have to be resubmitted with a latitude and longitude corresponding to the location or resubmitted with a different location that can be automatically geocoded. NOTE: The latitude and longitude should NOT be the users' exact location because we don't want to publicize their exact location unless their location description is their full address (which is not recommended). *When a post is rejected because it can't be geocoded, the returned error will have its identifier property set to 'unknown-location'.
  location: string # A short location description.
  --longitude: float # The longitude corresponding to the location description provided. (see the NOTE in latitude description)
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this post.
  --preferences: string # A JSON string representing a permanent object that the client persists and modifies based on warnings returned by the update submission process and user input. Some warnings returned after submitting an update have a preference_key string property so that users can opt out of those warnings in the future. To save this opt-out preference, set the property indicated by the preference_key in the preferences object (eg. preferences[preference_key] = 1). The preferences object is never modified by the server - it is up to the client to initialize, modify and persist the preferences object.
  --reselling: string # For wanted posts only. If set to 1, the wanted post will show that the poster intends to resell any items that they receive in response to this post. Posters must declare if they intend to resell items.
  session: string # A JSON string representing a temporary object that is used to store data about the update process for a single post. The first time a post update is submitted, session should be a new empty object (eg. '{}'). The session object should be persisted by the client until that update is successfully submitted and then it can be discarded so that the next update will start over with a new empty session object. Every time an update is submitted and the response indicates that the submission was not successful, the session object returned in the response should override the clients copy of the session.
  title: string # A short description of the item(s).
  type: string # The type of post. One of: offer, wanted
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/posts/{post_id}"
    path_params: [{name: post_id, var: post_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: content, var: content}, {name: expires_in, var: expires_in}, {name: fair_offer, var: fair_offer}, {name: latitude, var: latitude}, {name: location, var: location}, {name: longitude, var: longitude}, {name: photo_ids, var: photo_ids}, {name: preferences, var: preferences}, {name: reselling, var: reselling}, {name: session, var: session}, {name: title, var: title}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id, content: $content, expires_in: $expires_in, fair_offer: $fair_offer, latitude: $latitude, location: $location, longitude: $longitude, photo_ids: $photo_ids, preferences: $preferences, reselling: $reselling, session: $session, title: $title, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a post bookmark
#
# DELETE /posts/{post_id}/bookmark
# operationId: delete_bookmark
export def "delete-bookmark" [
  post_id: string
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
    path: "/posts/{post_id}/bookmark"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Bookmark a post
#
# PUT /posts/{post_id}/bookmark
# operationId: bookmark_post
export def "bookmark-post" [
  post_id: string
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
    path: "/posts/{post_id}/bookmark"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve post display data
#
# GET /posts/{post_id}/display
# Returns: record<author: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, author_offer_count: int, author_posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, author_wanted_count: int, bookmarked: bool, feedback: table<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, groups: table<country: record, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record, name: string, open_archives: bool, open_membership: bool, region: record, timezone: string>, post: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list<record>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, replied: bool, user_can_reply: bool, viewed: bool>
# operationId: get_post_and_related_data
export def "get-post-and-related-data" [
  post_id: string
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
    path: "/posts/{post_id}/display"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Promise an offer post
#
# PUT /posts/{post_id}/promise
# Returns: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>
# operationId: promise_post
export def "promise-post" [
  post_id: string
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
    path: "/posts/{post_id}/promise"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reply to a post
#
# POST /posts/{post_id}/reply
# operationId: reply_to_post
export def "reply-to-post" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # The message to send to the post author.
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this reply.
]: any -> any {
  $in | http-request {
    method: post
    path: "/posts/{post_id}/reply"
    path_params: [{name: post_id, var: post_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: message, var: message}, {name: photo_ids, var: photo_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id, message: $message, photo_ids: $photo_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report a post
#
# POST /posts/{post_id}/report
# operationId: report_post
export def "report-post" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: string # An explanation from the current user for why they are reporting this post. This is useful for users to provide evidence or explain why there is a problem with the post. NOTE: If reason is set to 'other', details are required.
  reason: string # The reason that this post is being reported. Must be one of: 'spam', 'not free (for sale/trade/borrow)', 'illegal item', 'not family-friendly', 'other', 'mislabeled: is a Want', 'mislabeled: is an Offer'. NOTE: If reason is set to 'other', the details parameter is required to be set.
]: any -> any {
  $in | http-request {
    method: post
    path: "/posts/{post_id}/report"
    path_params: [{name: post_id, var: post_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: details, var: details}, {name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id, details: $details, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Satisfy a post
#
# PUT /posts/{post_id}/satisfy
# Returns: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>
# operationId: satisfy_post
export def "satisfy-post" [
  post_id: string
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
    path: "/posts/{post_id}/satisfy"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Share a post
#
# POST /posts/{post_id}/share
# operationId: share_post
export def "share-post" [
  post_id: string
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
    method: post
    path: "/posts/{post_id}/share"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unpromise an offer post
#
# PUT /posts/{post_id}/unpromise
# Returns: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>
# operationId: unpromise_post
export def "unpromise-post" [
  post_id: string
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
    path: "/posts/{post_id}/unpromise"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Withdraw a post
#
# PUT /posts/{post_id}/withdraw
# Returns: record<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>
# operationId: withdraw_post
export def "withdraw-post" [
  post_id: string
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
    path: "/posts/{post_id}/withdraw"
    path_params: [{name: post_id, var: post_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    post_id: $post_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List stories
#
# GET /stories
# Returns: record<stories: table<content: string, date: string, like_count: int, photos: list, share_url: string, story_id: string, title: string, user: record, user_liked: bool>>
# operationId: get_stories
export def "get-stories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of stories to return. (default: 1)
  --per-page: int # The number of stories to return per page (must be >= 1 and <= 50). (default: 20)
  --sort-by: string # How to sort the stories that are returned. One of: date, distance, likes, views Setting sort_by to date will sort posts from newest to oldest. Setting sort_by to distance will sort posts from nearest to farthest. Setting sort_by to likes will sort posts with the most likes first. Setting sort_by to views will show the posts with the most views first. (default: date)
  --latitude: float # Find groups near the given latitude and longitude.
  --longitude: float # Find groups near the given latitude and longitude.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stories"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: sort_by, var: sort_by}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    page: $page, per_page: $per_page, sort_by: $sort_by, latitude: $latitude, longitude: $longitude, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a story
#
# POST /stories
# Returns: record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool>
# operationId: submit_story
export def "submit-story" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The content of the story.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --photo-ids: string # A comma separated list of the IDs of the photos that should be attached to this story.
  sharing: string # Must be set to one of the following two options: public, members When sharing is set to public, anyone will be able to view the story. When sharing is set to members, only other members will be able to view the story.
  title: string # The title of the story.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/stories"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: content, var: content}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: photo_ids, var: photo_ids}, {name: sharing, var: sharing}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    content: $content, device_pixel_ratio: $device_pixel_ratio, photo_ids: $photo_ids, sharing: $sharing, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a story
#
# GET /stories/{story_id}
# Returns: record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool>
# operationId: get_story
export def "get-story" [
  story_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stories/{story_id}"
    path_params: [{name: story_id, var: story_id}]
    query: [{name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    story_id: $story_id, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Like a story
#
# PUT /stories/{story_id}/like
# Returns: record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool>
# operationId: like_story
export def "like-story" [
  story_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/stories/{story_id}/like"
    path_params: [{name: story_id, var: story_id}]
    query: [{name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    story_id: $story_id, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlike a story
#
# PUT /stories/{story_id}/unlike
# Returns: record<content: string, date: string, like_count: int, photos: table<blurhash: string, images: list, photo_id: string, thumbnail: string, url: string>, share_url: string, story_id: string, title: string, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, user_liked: bool>
# operationId: unlike_story
export def "unlike-story" [
  story_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/stories/{story_id}/unlike"
    path_params: [{name: story_id, var: story_id}]
    query: [{name: device_pixel_ratio, var: device_pixel_ratio}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    story_id: $story_id, device_pixel_ratio: $device_pixel_ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Record story viewed
#
# POST /stories/{story_id}/viewed
# operationId: viewed_story
export def "viewed-story" [
  story_id: string
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
    method: post
    path: "/stories/{story_id}/viewed"
    path_params: [{name: story_id, var: story_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    story_id: $story_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve current user
#
# GET /users/me
# Returns: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>
# operationId: get_current_user
export def "get-current-user" [
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
    path: "/users/me"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update current user
#
# PUT /users/me
# Returns: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>
# operationId: update_current_user
export def "update-current-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --about-me: string # A short bio a user has written about themselves to help other members get to know them better.
  --digest-photos: int # Whether or not to include photos in the digest emails. Set to 1 to enable photos and 0 to disable photos.
  --email-message-delay: string # How quickly new messages from other users are emailed to this user. One of: immediate, 30_minutes, 1_hour, 2_hours, 4_hours, 6_hours, 8_hours If set to anything other than immediate, the user will receive a digest email summarizing all of the new messages that they haven't viewed.
  --email-newsletters: string # If set to 1, the user will receive occasional email newsletters from trash nothing. To disable, set to 0.
  --email-post-reminders: int # If set to 1, the user will receive emails to remind them to handle their old posts. To disable, set to 0.
  --email-posts-frequency: string # How often new post email notifications are sent to the user. One of: weekly, twice_weekly, daily, 12_hours, 8_hours, 6_hours, 4_hours, 2_hours, hourly To turn off new post email notifications, set this to an empty string.
  --email-search-alerts: int # If set to 1, the user will receive emails when new posts that match one of their search alerts. To disable, set to 0.
  --firstname: string # The first name of the user.
  --last-listings-view: string # The UTC date and time when the user last viewed the newest posts on the All Posts page. (format: date-time)
  --lastname: string # The last name of the user.
  --notify-about-reposts: int # If set to 1, the user will be notified about reposts. This affects digests and search alerts. If set to 0, the user will not be notified about reposts. This does not affect the posts that are returned by the /posts endpoint which has an include_reposts option for this purpose. See the repost_count field of post objects for details about how reposts are identified.
  --old-password: string # The users current password. This is required when the user is changing their password.
  --password: string # A new password for the users' account. When setting a new password, the old_password parameter must be passed and set to the users' current password. NOTE: The password and old_password properties can NOT be used when the user property has_password is false. Instead, use the password reset endpoint to have a new password emailed to the user.
  --profile-image-source: string # The source of the users' profile image. The values this can be set to change dynamically based on the users' account. To get the values that can be used, use the source properties returned by the profile images endpoint.
  --public-name: int # Whether or not the users' first and last name will be visible to other users. Set to 1 to enable and 0 to disable.
  --public-post-sources: string # A comma separated list of the sources to show public posts from. Currently only 'trashnothing' is supported. If not passed, all sources will be enabled. If set to an empty string, no sources will be enabled which effectively disables public posts for the user so that the user will only see posts from the groups they are a member of. Setting to an empty string is only allowed if the user is a member of one or more groups.
  --show-all-group-posts: int # Set to 1 to show all group posts on the main posts page and in the digests. Set to 0 to only show group posts in the area defined by the users' location. Can only be set to 0 if the users' location is already set.
  --special-notices: int # Whether or not the user wants to receive special notice emails from the groups they are a member of. Special notices are admin posts that the group moderators choose to send out by email. Set to 1 to enable and 0 to disable.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/me"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: about_me, var: about_me}, {name: digest_photos, var: digest_photos}, {name: email_message_delay, var: email_message_delay}, {name: email_newsletters, var: email_newsletters}, {name: email_post_reminders, var: email_post_reminders}, {name: email_posts_frequency, var: email_posts_frequency}, {name: email_search_alerts, var: email_search_alerts}, {name: firstname, var: firstname}, {name: last_listings_view, var: last_listings_view}, {name: lastname, var: lastname}, {name: notify_about_reposts, var: notify_about_reposts}, {name: old_password, var: old_password}, {name: password, var: password}, {name: profile_image_source, var: profile_image_source}, {name: public_name, var: public_name}, {name: public_post_sources, var: public_post_sources}, {name: show_all_group_posts, var: show_all_group_posts}, {name: special_notices, var: special_notices}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    about_me: $about_me, digest_photos: $digest_photos, email_message_delay: $email_message_delay, email_newsletters: $email_newsletters, email_post_reminders: $email_post_reminders, email_posts_frequency: $email_posts_frequency, email_search_alerts: $email_search_alerts, firstname: $firstname, last_listings_view: $last_listings_view, lastname: $lastname, notify_about_reposts: $notify_about_reposts, old_password: $old_password, password: $password, profile_image_source: $profile_image_source, public_name: $public_name, public_post_sources: $public_post_sources, show_all_group_posts: $show_all_group_posts, special_notices: $special_notices
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List current users' email alerts
#
# GET /users/me/alerts
# Returns: table<alert_id: string, last_sent: string, search: string, send_count: int, types: list<string>, user_id: string>
# operationId: get_alerts
export def "get-alerts" [
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
    path: "/users/me/alerts"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an email alert
#
# PUT /users/me/alerts
# Returns: record<alert_id: string, last_sent: string, search: string, send_count: int, types: list<string>, user_id: string>
# operationId: create_alert
export def "create-alert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  search: string # When a post matches this search query, an email alert will be sent. Must have a length >= 2 and < 255 characters.
  types: string # A comma separated list of the post types that the alert should match against. The available post types are: offer, wanted
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/me/alerts"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: search, var: search}, {name: types, var: types}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, types: $types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an email alert
#
# DELETE /users/me/alerts/{alert_id}
# operationId: delete_alert
export def "delete-alert" [
  alert_id: string
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
    path: "/users/me/alerts/{alert_id}"
    path_params: [{name: alert_id, var: alert_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    alert_id: $alert_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change email address
#
# POST /users/me/email
# operationId: change_email
export def "change-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The new email address.
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/me/email"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: address, var: address}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set users' email address as not bouncing
#
# PUT /users/me/email/not-bouncing
# Returns: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>
# operationId: set_email_not_bouncing
export def "set-email-not-bouncing" [
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
    path: "/users/me/email/not-bouncing"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List current users' groups
#
# GET /users/me/groups
# Returns: table<country: record<abbreviation: string, name: string>, group_id: string, has_questions: bool, homepage: string, identifier: string, latitude: float, longitude: float, member_count: int, membership: record<date: string, questionnaire: record, status: string>, name: string, open_archives: bool, open_membership: bool, region: record<abbreviation: string, name: string>, timezone: string>
# operationId: get_current_user_groups
export def "get-current-user-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --membership: string # Set the membership parameter to only return certain groups. The options are: - **subscribed**: Only return groups the user is a member of. - **pending-questions**: Only return groups where the user needs to respond to a new member questionnaire. - **pending**: Only return groups where the user is waiting for their membership request to be approved (excludes groups which are pending-questions). If unset, all groups the user is a member of and pending membership on will be returned.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/me/groups"
    query: [{name: membership, var: membership}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    membership: $membership
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update location
#
# PUT /users/me/location
# Returns: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>
# operationId: update_location
export def "update-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  latitude: float
  longitude: float
  name: string # A name that describes the location specified by the given latitude and longitude (must be <= 128 characters).
  radius: float # A radius in meters that defines a circle around the point specified by latitude and longitude. Only posts within the area specified by this circle will be shown. If set to 0, effectively disables public posts for the user.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/me/location"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: name, var: name}, {name: radius, var: radius}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    latitude: $latitude, longitude: $longitude, name: $name, radius: $radius
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List current users' group notices
#
# GET /users/me/notices
# Returns: table<content: string, date: string, group_id: string, notice_id: string, title: string>
# operationId: get_user_group_notices
export def "get-user-group-notices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-ids: string # A comma separated list of group IDs to return notices for. If unset, notices for all the users groups will be returned.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/me/notices"
    query: [{name: group_ids, var: group_ids}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_ids: $group_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List current users' post locations
#
# GET /users/me/post-locations
# Returns: table<latitude: float, longitude: float, name: string>
# operationId: get_post_locations
export def "get-post-locations" [
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
    path: "/users/me/post-locations"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Save a post location for the current user
#
# PUT /users/me/post-locations
# Returns: table<latitude: float, longitude: float, name: string>
# operationId: save_post_location
export def "save-post-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  latitude: float
  longitude: float
  name: string # A name that describes the location specified by the given latitude and longitude (must be >= 2 characters and <= 30 characters).
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: put
    path: "/users/me/post-locations"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    latitude: $latitude, longitude: $longitude, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List current users' posts
#
# GET /users/me/posts
# Returns: record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int>
# operationId: get_current_user_posts
export def "get-current-user-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string # How to sort the posts that are returned. One of: date, active, distance Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: date)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin (required)
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or the current users' location if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required. (required)
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: "")
  --user-state: string # If user_state is set, only posts matching the state specified will be returned. Only one state may be passed and it must be one of the following: viewed, replied, bookmarked NOTE: This option will only work with oauth requests. (default: "")
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/me/posts"
    query: [{name: sort_by, var: sort_by}, {name: types, var: types, required: true}, {name: sources, var: sources, required: true}, {name: group_ids, var: group_ids}, {name: per_page, var: per_page}, {name: page, var: page}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: date_min, var: date_min}, {name: date_max, var: date_max}, {name: outcomes, var: outcomes}, {name: user_state, var: user_state}, {name: include_reposts, var: include_reposts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort_by: $sort_by, types: $types, sources: $sources, group_ids: $group_ids, per_page: $per_page, page: $page, device_pixel_ratio: $device_pixel_ratio, latitude: $latitude, longitude: $longitude, radius: $radius, date_min: $date_min, date_max: $date_max, outcomes: $outcomes, user_state: $user_state, include_reposts: $include_reposts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search current users' posts
#
# GET /users/me/posts/search
# Returns: record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int>
# operationId: search_current_user_posts
export def "search-current-user-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search query used to find posts. (required)
  --sort-by: string # How to sort the posts that are returned. One of: relevance, date, active, distance Relevance sorting will sort the posts that best match the search query first. Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: relevance)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin (required)
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or the current users' location if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required. (required)
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: "")
  --user-state: string # If user_state is set, only posts matching the state specified will be returned. Only one state may be passed and it must be one of the following: viewed, replied, bookmarked NOTE: This option will only work with oauth requests. (default: "")
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/me/posts/search"
    query: [{name: search, var: search, required: true}, {name: sort_by, var: sort_by}, {name: types, var: types, required: true}, {name: sources, var: sources, required: true}, {name: group_ids, var: group_ids}, {name: per_page, var: per_page}, {name: page, var: page}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: date_min, var: date_min}, {name: date_max, var: date_max}, {name: outcomes, var: outcomes}, {name: user_state, var: user_state}, {name: include_reposts, var: include_reposts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    search: $search, sort_by: $sort_by, types: $types, sources: $sources, group_ids: $group_ids, per_page: $per_page, page: $page, device_pixel_ratio: $device_pixel_ratio, latitude: $latitude, longitude: $longitude, radius: $radius, date_min: $date_min, date_max: $date_max, outcomes: $outcomes, user_state: $user_state, include_reposts: $include_reposts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a profile image
#
# POST /users/me/profile-image
# Returns: record<photo: record<photo_id: string, thumbnail: record<height: int, url: string, width: int>>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string, digest_photos: bool, email: record<address: string, bouncing: bool, spam_stop: bool>, email_message_delay: string, email_post_reminders: bool, email_posts_frequency: string, email_search_alerts: bool, has_password: bool, last_listings_view: string, location: record<latitude: float, longitude: float, name: string, radius: float>, profile_image_source: string, public_name: bool, public_post_sources: list<string>, show_all_group_posts: bool, signup: string, special_notices: bool, uses_fair_offer_policy: bool, verified: bool>>
# operationId: set_profile_image
export def "set-profile-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --crop: string # If the photo needs to be cropped, a JSON encoded object with the crop arguments can be passed. The supported crop arguments are below. All arguments except rotate are required. - **original_width**: Original width of the photo before being cropped or rotated (in pixels). - **original_height**: Original height of the photo before being cropped or rotated (in pixels). - **x**: The x-coordinate of the top left corner of the cropped area. - **y**: The y-coordinate of the top left corner of the cropped area. - **size**: The size of the square cropped area. - **rotate**: (optional) The number of degrees to rotate the image before cropping. Currently only 90, 180 and 270 are supported which correspond to rotate left, rotate upside down and rotate right.
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --photo: string # Photo to upload. (format: binary)
  --photo-id: string # Photo to use (if already uploaded).
  --set-default: int # Whether or not to set the photo as the users' default profile image. Set to 1 to enable and 0 to disable. (default: 1)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/me/profile-image"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: crop, var: crop}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: photo, var: photo}, {name: photo_id, var: photo_id}, {name: set_default, var: set_default}], files: [photo]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    crop: $crop, device_pixel_ratio: $device_pixel_ratio, photo: $photo, photo_id: $photo_id, set_default: $set_default
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List current users' profile images
#
# GET /users/me/profile-images
# Returns: table<image: string, source: string>
# operationId: get_profile_images
export def "get-profile-images" [
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
    path: "/users/me/profile-images"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend account verification email
#
# POST /users/me/resend-verification
# operationId: resend_account_verification_email
export def "resend-account-verification-email" [
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
    method: post
    path: "/users/me/resend-verification"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send password reset email
#
# POST /users/me/reset-password
# operationId: send_password_reset_email
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
]: nothing -> any {
  http-request {
    method: post
    path: "/users/me/reset-password"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report a user
#
# POST /users/report
# operationId: report_user
export def "report-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string # The ID of the group to report the user to. This may be disregarded in cases where user_email is set and can be used to automatically identify which group the user should be reported to (because some email addresses are specific to certain groups).
  message: string # The body of the message.
  --subject: string # The subject of the message.
  --user-email: string # The email of the user to report. Often users only know to identify other users by their email addresses so allowing users to enter an email address can be easier in certain cases.
  --user-id: string # The ID of the user to report. One of user_id or user_email must be passed but only user_id will be used if both are passed.
]: any -> any {
  $in | http-request {
    method: post
    path: "/users/report"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: group_id, var: group_id}, {name: message, var: message}, {name: subject, var: subject}, {name: user_email, var: user_email}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    group_id: $group_id, message: $message, subject: $subject, user_email: $user_email, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a user
#
# GET /users/{user_id}
# Returns: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>
# operationId: get_user
export def "get-user" [
  user_id: string
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
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve user display info
#
# GET /users/{user_id}/display
# Returns: record<feedback: table<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, offer_count: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>, wanted_count: int>
# operationId: get_user_and_related_data
export def "get-user-and-related-data" [
  user_id: string
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
    path: "/users/{user_id}/display"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove feedback on a user
#
# DELETE /users/{user_id}/feedback
# Returns: record<user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>>
# operationId: remove_user_feedback
export def "remove-user-feedback" [
  user_id: string
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
    path: "/users/{user_id}/feedback"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit feedback on a user
#
# POST /users/{user_id}/feedback
# Returns: record<feedback: record<content: string, date: string, feedback_id: string, positive: bool, reviewer_user_id: string, user_id: string>, user: record<about_me: string, country: string, feedback: record<percent_positive: float, restriction: string, score: int>, firstname: string, lastname: string, member_since: string, profile_image: string, reply_time: int, user_id: string, username: string>>
# operationId: submit_user_feedback
export def "submit-user-feedback" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # For positive feedback, category should not be set. For negative feedback, category should be set to one of: NO_SHOW, UNRESPONSIVE, LATE_OR_TOO_EARLY, ITEM_NOT_AS_DESCRIBED, BROKEN_PROMISE, RUDE, RESELLER, SELLING, UNWANTED_MESSAGES, COMMUNICATION, OTHER Below are descriptions for each of these categories: **NO_SHOW** - The user did not show up when they said they would. **UNRESPONSIVE** - The user failed to respond when a response was expected. **LATE_OR_TOO_EARLY** - The user showed up later than they said they would (or too early). **ITEM_NOT_AS_DESCRIBED** - The user gave away an item that had a misleading on incomplete description. **BROKEN_PROMISE** - The user broke a promise. **RUDE** - The user was rude or impolite. **RESELLER** - The user is obtaining free items to sell on other sites without disclosing their intent to resell. **SELLING** - The user is selling items on trash nothing. **UNWANTED_MESSAGES** - The user is sending off-topic or unrelated messages. **COMMUNICATION** - The users' communication is unclear, confusing or bad. **OTHER** - This category is for anything that does not fit in any of the above categories.
  --content: string # A comment written by the current user about the user they are leaving feedback on. This is optional for positive feedback but is required for negative feedback.
  positive: int # If set to 1, the feedback is positive. If set to 0, the feedback is negative.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/feedback"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: category, var: category}, {name: content, var: content}, {name: positive, var: positive}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, category: $category, content: $content, positive: $positive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List posts by a user
#
# GET /users/{user_id}/posts
# Returns: record<end_index: int, group_ids: list<string>, last_listings_view: string, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string>, start_index: int>
# operationId: get_user_posts
export def "get-user-posts" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string # How to sort the posts that are returned. One of: date, active, distance Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: date)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin (required)
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or all the open archive groups the requested user has posted to if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required. (required)
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: "")
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/posts"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: sort_by, var: sort_by}, {name: types, var: types, required: true}, {name: sources, var: sources, required: true}, {name: group_ids, var: group_ids}, {name: per_page, var: per_page}, {name: page, var: page}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: date_min, var: date_min}, {name: date_max, var: date_max}, {name: outcomes, var: outcomes}, {name: include_reposts, var: include_reposts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, sort_by: $sort_by, types: $types, sources: $sources, group_ids: $group_ids, per_page: $per_page, page: $page, device_pixel_ratio: $device_pixel_ratio, latitude: $latitude, longitude: $longitude, radius: $radius, date_min: $date_min, date_max: $date_max, outcomes: $outcomes, include_reposts: $include_reposts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search posts by a user
#
# GET /users/{user_id}/posts/search
# Returns: record<end_index: int, group_ids: list<string>, num_pages: int, num_posts: int, page: int, per_page: int, posts: table<content: string, date: string, expiration: string, footer: string, group_id: string, latitude: float, longitude: float, outcome: string, photos: list, post_id: string, repost_count: int, reselling: bool, source: string, title: string, type: string, url: string, user_id: string, search_content: string, search_title: string>, start_index: int>
# operationId: search_user_posts
export def "search-user-posts" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search query used to find posts. (required)
  --sort-by: string # How to sort the posts that are returned. One of: relevance, date, active, distance Relevance sorting will sort the posts that best match the search query first. Date sorting will sort posts from newest to oldest. Active sorting will sort active posts before satisfied, withdrawn and expired posts and then sort by date. Distance sorting will sort the closest posts first. (default: relevance)
  --types: string # A comma separated list of the post types to return. The available post types are: offer, taken, wanted, received, admin (required)
  --sources: string # A comma separated list of the post sources to retrieve posts from. The available sources are: groups, trashnothing, open_archive_groups. The trashnothing source is for public posts that are posted on trash nothing but are not associated with any group. The open_archive_groups source provides a way to easily request posts from groups that have open_archives set to true without having to pass a group_ids parameter. When passed, it will automatically return posts from open archive groups that are within the area specified by the latitude, longitude and radius parameters (or all the open archive groups the requested user has posted to if latitude, longitude and radius aren't passed). NOTE: For requests using an api key instead of oauth, passing the trashnothing source or the open_archive_groups source makes the latitude, longitude and radius parameters required. (required)
  --group-ids: string # A comma separated list of the group IDs to retrieve posts from. This parameter is only used if the 'groups' source is passed in the sources parameter and only groups that the current user is a member of or that are open archives groups will be used (the group IDs of other groups will be silently discarded*). NOTE: For requests using an api key instead of oauth, this field is required if the 'groups' source is passed. In addition, only posts from groups that have open_archives set to true will be used (the group IDS of other groups will be silently discarded*). *To determine which group IDs were used and which were discarded, use the group_ids field in the response. (default: The group IDs of every group the current user is a member of.)
  --per-page: int # The number of posts to return per page (must be >= 1 and <= 100). (default: 20)
  --page: int # The page of posts to return. (default: 1)
  --device-pixel-ratio: float # Client device pixel ratio used to determine thumbnail size (default 1.0). (default: 1)
  --latitude: float # The latitude of a point around which to return posts.
  --longitude: float # The longitude of a point around which to return posts.
  --radius: float # The radius in meters of a circle centered at the point defined by the latitude and longitude parameters. When latitude, longitude and radius are passed, only posts within the circle defined by these parameters will be returned.
  --date-min: string # Only posts newer than or equal to this UTC date and time will be returned. (format: date-time)
  --date-max: string # Only posts older than this UTC date and time will be returned. (format: date-time)
  --outcomes: string # A comma separated list of the post outcomes to return. The available post outcomes are: satisfied, withdrawn There are also a couple special values that can be passed. If set to an empty string (the default), only posts that are not satisfied and not withdrawn and not expired are returned. If set to 'all', all posts will be returned no matter what outcome the posts have. If set to 'not-promised', only posts that are not satisfied ant not withdrawn and not expired and not promised are returned. (default: "")
  --include-reposts: int # If set to 1 (the default), posts that are reposts will be included. If set to 0, reposts will be excluded. See the repost_count field of post objects for details about how reposts are identified. (default: 1)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/posts/search"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: search, var: search, required: true}, {name: sort_by, var: sort_by}, {name: types, var: types, required: true}, {name: sources, var: sources, required: true}, {name: group_ids, var: group_ids}, {name: per_page, var: per_page}, {name: page, var: page}, {name: device_pixel_ratio, var: device_pixel_ratio}, {name: latitude, var: latitude}, {name: longitude, var: longitude}, {name: radius, var: radius}, {name: date_min, var: date_min}, {name: date_max, var: date_max}, {name: outcomes, var: outcomes}, {name: include_reposts, var: include_reposts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, search: $search, sort_by: $sort_by, types: $types, sources: $sources, group_ids: $group_ids, per_page: $per_page, page: $page, device_pixel_ratio: $device_pixel_ratio, latitude: $latitude, longitude: $longitude, radius: $radius, date_min: $date_min, date_max: $date_max, outcomes: $outcomes, include_reposts: $include_reposts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a users' profile image
#
# GET /users/{user_id}/profile-image
# operationId: get_profile_image_file
export def "get-profile-image-file" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: string # A default image URL to use when the user has no profile image. Or to use one of the Gravatar default images, you can set default to any one of (404, mm, identicon, monsterid, wavatar, retro, blank). To learn how the Gravatar default images options work, see the Default Image section on the page at: https://en.gravatar.com/site/implement/images/
]: nothing -> any {
  http-request {
    method: get
    path: "/users/{user_id}/profile-image"
    path_params: [{name: user_id, var: user_id}]
    query: [{name: default, var: default}]
    accept: ["application/json"]
    ok: [302]
    auth: bearer
  } {
    user_id: $user_id, default: $default
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
