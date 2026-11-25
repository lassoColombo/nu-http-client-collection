# Auto-generated client for Amazon QuickSight v2018-04-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/quicksight/2018-04-01/openapi.json
# Auth: --token flag or $env.AMAZON_QUICKSIGHT_TOKEN

const CLIENT = {
  base_url: "http://quicksight.us-east-1.amazonaws.com"
  token_env_var: "AMAZON_QUICKSIGHT_TOKEN"
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

def base-url-completer [] { ["http://quicksight.us-east-1.amazonaws.com" "http://quicksight.us-east-2.amazonaws.com" "http://quicksight.us-west-1.amazonaws.com" "http://quicksight.us-west-2.amazonaws.com" "http://quicksight.us-gov-west-1.amazonaws.com" "http://quicksight.us-gov-east-1.amazonaws.com" "http://quicksight.ca-central-1.amazonaws.com" "http://quicksight.eu-north-1.amazonaws.com" "http://quicksight.eu-west-1.amazonaws.com" "http://quicksight.eu-west-2.amazonaws.com" "http://quicksight.eu-west-3.amazonaws.com" "http://quicksight.eu-central-1.amazonaws.com" "http://quicksight.eu-south-1.amazonaws.com" "http://quicksight.af-south-1.amazonaws.com" "http://quicksight.ap-northeast-1.amazonaws.com" "http://quicksight.ap-northeast-2.amazonaws.com" "http://quicksight.ap-northeast-3.amazonaws.com" "http://quicksight.ap-southeast-1.amazonaws.com" "http://quicksight.ap-southeast-2.amazonaws.com" "http://quicksight.ap-east-1.amazonaws.com" "http://quicksight.ap-south-1.amazonaws.com" "http://quicksight.sa-east-1.amazonaws.com" "http://quicksight.me-south-1.amazonaws.com" "https://quicksight.us-east-1.amazonaws.com" "https://quicksight.us-east-2.amazonaws.com" "https://quicksight.us-west-1.amazonaws.com" "https://quicksight.us-west-2.amazonaws.com" "https://quicksight.us-gov-west-1.amazonaws.com" "https://quicksight.us-gov-east-1.amazonaws.com" "https://quicksight.ca-central-1.amazonaws.com" "https://quicksight.eu-north-1.amazonaws.com" "https://quicksight.eu-west-1.amazonaws.com" "https://quicksight.eu-west-2.amazonaws.com" "https://quicksight.eu-west-3.amazonaws.com" "https://quicksight.eu-central-1.amazonaws.com" "https://quicksight.eu-south-1.amazonaws.com" "https://quicksight.af-south-1.amazonaws.com" "https://quicksight.ap-northeast-1.amazonaws.com" "https://quicksight.ap-northeast-2.amazonaws.com" "https://quicksight.ap-northeast-3.amazonaws.com" "https://quicksight.ap-southeast-1.amazonaws.com" "https://quicksight.ap-southeast-2.amazonaws.com" "https://quicksight.ap-east-1.amazonaws.com" "https://quicksight.ap-south-1.amazonaws.com" "https://quicksight.sa-east-1.amazonaws.com" "https://quicksight.me-south-1.amazonaws.com" "http://quicksight.cn-north-1.amazonaws.com.cn" "http://quicksight.cn-northwest-1.amazonaws.com.cn" "https://quicksight.cn-north-1.amazonaws.com.cn" "https://quicksight.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ingestion-type-completer [] { ["FULL_REFRESH" "INCREMENTAL_REFRESH"] }
def edition-completer [] { ["ENTERPRISE" "ENTERPRISE_AND_Q" "STANDARD"] }
def authentication-method-completer [] { ["ACTIVE_DIRECTORY" "IAM_AND_QUICKSIGHT" "IAM_ONLY"] }
def import-mode-completer [] { ["DIRECT_QUERY" "SPICE"] }
def type-completer [] { ["ADOBE_ANALYTICS" "AMAZON_ELASTICSEARCH" "AMAZON_OPENSEARCH" "ATHENA" "AURORA" "AURORA_POSTGRESQL" "AWS_IOT_ANALYTICS" "DATABRICKS" "EXASOL" "GITHUB" "JIRA" "MARIADB" "MYSQL" "ORACLE" "POSTGRESQL" "PRESTO" "REDSHIFT" "S3" "SALESFORCE" "SERVICENOW" "SNOWFLAKE" "SPARK" "SQLSERVER" "TERADATA" "TIMESTREAM" "TWITTER"] }
def folder-type-completer [] { ["SHARED"] }
def member-type-completer [] { ["ANALYSIS" "DASHBOARD" "DATASET"] }
def assignment-status-completer [] { ["DISABLED" "DRAFT" "ENABLED"] }
def identity-store-completer [] { ["QUICKSIGHT"] }
def role-completer [] { ["ADMIN" "AUTHOR" "READER" "RESTRICTED_AUTHOR" "RESTRICTED_READER"] }
def creds-type-completer [] { ["ANONYMOUS" "IAM" "QUICKSIGHT"] }
def type-completer-1 [] { ["ALL" "CUSTOM" "QUICKSIGHT"] }
def identity-type-completer [] { ["IAM" "QUICKSIGHT"] }
def user-role-completer [] { ["ADMIN" "AUTHOR" "READER" "RESTRICTED_AUTHOR" "RESTRICTED_READER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    cancel-ingestion: "record<Arn: string, IngestionId: string, RequestId: string, Status: int>"
    create-ingestion: "record<Arn: string, IngestionId: string, IngestionStatus: string, RequestId: string, Status: int>"
    describe-ingestion: "record<Ingestion: record<Arn: string, IngestionId: string, IngestionStatus: string, ErrorInfo: record<Type: string, Message: string>, RowInfo: record<RowsIngested: int, RowsDropped: int, TotalRowsInDataset: int>, QueueInfo: record<WaitingOnIngestion: string, QueuedIngestion: string>, CreatedTime: string, IngestionTimeInSeconds: int, IngestionSizeInBytes: int, RequestSource: string, RequestType: string>, RequestId: string, Status: int>"
    create-account-customization: "record<Arn: string, AwsAccountId: string, Namespace: string, AccountCustomization: record<DefaultTheme: string, DefaultEmailCustomizationTemplate: string>, RequestId: string, Status: int>"
    delete-account-customization: "record<RequestId: string, Status: int>"
    describe-account-customization: "record<Arn: string, AwsAccountId: string, Namespace: string, AccountCustomization: record<DefaultTheme: string, DefaultEmailCustomizationTemplate: string>, RequestId: string, Status: int>"
    update-account-customization: "record<Arn: string, AwsAccountId: string, Namespace: string, AccountCustomization: record<DefaultTheme: string, DefaultEmailCustomizationTemplate: string>, RequestId: string, Status: int>"
    create-account-subscription: "record<SignupResponse: record<IAMUser: bool, userLoginName: string, accountName: string, directoryType: string>, Status: int, RequestId: string>"
    delete-account-subscription: "record<RequestId: string, Status: int>"
    describe-account-subscription: "record<AccountInfo: record<AccountName: string, Edition: string, NotificationEmail: string, AuthenticationType: string, AccountSubscriptionStatus: string>, Status: int, RequestId: string>"
    create-analysis: "record<Arn: string, AnalysisId: string, CreationStatus: string, Status: int, RequestId: string>"
    delete-analysis: "record<Status: int, Arn: string, AnalysisId: string, DeletionTime: string, RequestId: string>"
    describe-analysis: "record<Analysis: record<AnalysisId: string, Arn: string, Name: string, Status: string, Errors: list<record>, DataSetArns: list<string>, ThemeArn: string, CreatedTime: string, LastUpdatedTime: string, Sheets: list<record>>, Status: int, RequestId: string>"
    update-analysis: "record<Arn: string, AnalysisId: string, UpdateStatus: string, Status: int, RequestId: string>"
    create-dashboard: "record<Arn: string, VersionArn: string, DashboardId: string, CreationStatus: string, Status: int, RequestId: string>"
    delete-dashboard: "record<Status: int, Arn: string, DashboardId: string, RequestId: string>"
    describe-dashboard: "record<Dashboard: record<DashboardId: string, Arn: string, Name: string, Version: record<CreatedTime: string, Errors: list, VersionNumber: int, Status: string, Arn: string, SourceEntityArn: string, DataSetArns: list, Description: string, ThemeArn: string, Sheets: list>, CreatedTime: string, LastPublishedTime: string, LastUpdatedTime: string>, Status: int, RequestId: string>"
    update-dashboard: "record<Arn: string, VersionArn: string, DashboardId: string, CreationStatus: string, Status: int, RequestId: string>"
    create-data-set: "record<Arn: string, DataSetId: string, IngestionArn: string, IngestionId: string, RequestId: string, Status: int>"
    list-data-sets: "record<DataSetSummaries: table<Arn: string, DataSetId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, ImportMode: string, RowLevelPermissionDataSet: record, RowLevelPermissionTagConfigurationApplied: bool, ColumnLevelPermissionRulesApplied: bool>, NextToken: string, RequestId: string, Status: int>"
    create-data-source: "record<Arn: string, DataSourceId: string, CreationStatus: string, RequestId: string, Status: int>"
    list-data-sources: "record<DataSources: table<Arn: string, DataSourceId: string, Name: string, Type: string, Status: string, CreatedTime: string, LastUpdatedTime: string, DataSourceParameters: record, AlternateDataSourceParameters: list, VpcConnectionProperties: record, SslProperties: record, ErrorInfo: record, SecretArn: string>, NextToken: string, RequestId: string, Status: int>"
    create-folder: "record<Status: int, Arn: string, FolderId: string, RequestId: string>"
    delete-folder: "record<Status: int, Arn: string, FolderId: string, RequestId: string>"
    describe-folder: "record<Status: int, Folder: record<FolderId: string, Arn: string, Name: string, FolderType: string, FolderPath: list<string>, CreatedTime: string, LastUpdatedTime: string>, RequestId: string>"
    update-folder: "record<Status: int, Arn: string, FolderId: string, RequestId: string>"
    create-folder-membership: "record<Status: int, FolderMember: record<MemberId: string, MemberType: string>, RequestId: string>"
    delete-folder-membership: "record<Status: int, RequestId: string>"
    create-group: "record<Group: record<Arn: string, GroupName: string, Description: string, PrincipalId: string>, RequestId: string, Status: int>"
    list-groups: "record<GroupList: table<Arn: string, GroupName: string, Description: string, PrincipalId: string>, NextToken: string, RequestId: string, Status: int>"
    create-group-membership: "record<GroupMember: record<Arn: string, MemberName: string>, RequestId: string, Status: int>"
    delete-group-membership: "record<RequestId: string, Status: int>"
    describe-group-membership: "record<GroupMember: record<Arn: string, MemberName: string>, RequestId: string, Status: int>"
    create-iam-policy-assignment: "record<AssignmentName: string, AssignmentId: string, AssignmentStatus: string, PolicyArn: string, Identities: record, RequestId: string, Status: int>"
    create-namespace: "record<Arn: string, Name: string, CapacityRegion: string, CreationStatus: string, IdentityStore: string, RequestId: string, Status: int>"
    create-refresh-schedule: "record<Status: int, RequestId: string, ScheduleId: string, Arn: string>"
    list-refresh-schedules: "record<RefreshSchedules: table<ScheduleId: string, ScheduleFrequency: record, StartAfterDateTime: string, RefreshType: string, Arn: string>, Status: int, RequestId: string>"
    update-refresh-schedule: "record<Status: int, RequestId: string, ScheduleId: string, Arn: string>"
    create-template: "record<Arn: string, VersionArn: string, TemplateId: string, CreationStatus: string, Status: int, RequestId: string>"
    delete-template: "record<RequestId: string, Arn: string, TemplateId: string, Status: int>"
    describe-template: "record<Template: record<Arn: string, Name: string, Version: record<CreatedTime: string, Errors: list, VersionNumber: int, Status: string, DataSetConfigurations: list, Description: string, SourceEntityArn: string, ThemeArn: string, Sheets: list>, TemplateId: string, LastUpdatedTime: string, CreatedTime: string>, Status: int, RequestId: string>"
    update-template: "record<TemplateId: string, Arn: string, VersionArn: string, CreationStatus: string, Status: int, RequestId: string>"
    create-template-alias: "record<TemplateAlias: record<AliasName: string, Arn: string, TemplateVersionNumber: int>, Status: int, RequestId: string>"
    delete-template-alias: "record<Status: int, TemplateId: string, AliasName: string, Arn: string, RequestId: string>"
    describe-template-alias: "record<TemplateAlias: record<AliasName: string, Arn: string, TemplateVersionNumber: int>, Status: int, RequestId: string>"
    update-template-alias: "record<TemplateAlias: record<AliasName: string, Arn: string, TemplateVersionNumber: int>, Status: int, RequestId: string>"
    create-theme: "record<Arn: string, VersionArn: string, ThemeId: string, CreationStatus: string, Status: int, RequestId: string>"
    delete-theme: "record<Arn: string, RequestId: string, Status: int, ThemeId: string>"
    describe-theme: "record<Theme: record<Arn: string, Name: string, ThemeId: string, Version: record<VersionNumber: int, Arn: string, Description: string, BaseThemeId: string, CreatedTime: string, Configuration: record, Errors: list, Status: string>, CreatedTime: string, LastUpdatedTime: string, Type: string>, Status: int, RequestId: string>"
    update-theme: "record<ThemeId: string, Arn: string, VersionArn: string, CreationStatus: string, Status: int, RequestId: string>"
    create-theme-alias: "record<ThemeAlias: record<Arn: string, AliasName: string, ThemeVersionNumber: int>, Status: int, RequestId: string>"
    delete-theme-alias: "record<AliasName: string, Arn: string, RequestId: string, Status: int, ThemeId: string>"
    describe-theme-alias: "record<ThemeAlias: record<Arn: string, AliasName: string, ThemeVersionNumber: int>, Status: int, RequestId: string>"
    update-theme-alias: "record<ThemeAlias: record<Arn: string, AliasName: string, ThemeVersionNumber: int>, Status: int, RequestId: string>"
    delete-data-set: "record<Arn: string, DataSetId: string, RequestId: string, Status: int>"
    describe-data-set: "record<DataSet: record<Arn: string, DataSetId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, PhysicalTableMap: record, LogicalTableMap: record, OutputColumns: list<record>, ImportMode: string, ConsumedSpiceCapacityInBytes: int, ColumnGroups: list<record>, FieldFolders: record, RowLevelPermissionDataSet: record<Namespace: string, Arn: string, PermissionPolicy: string, FormatVersion: string, Status: string>, RowLevelPermissionTagConfiguration: record<Status: string, TagRules: list, TagRuleConfigurations: list>, ColumnLevelPermissionRules: list<record>, DataSetUsageConfiguration: record<DisableUseAsDirectQuerySource: bool, DisableUseAsImportedSource: bool>>, RequestId: string, Status: int>"
    update-data-set: "record<Arn: string, DataSetId: string, IngestionArn: string, IngestionId: string, RequestId: string, Status: int>"
    delete-data-set-refresh-properties: "record<RequestId: string, Status: int>"
    describe-data-set-refresh-properties: "record<RequestId: string, Status: int, DataSetRefreshProperties: record<RefreshConfiguration: record<IncrementalRefresh: record>>>"
    put-data-set-refresh-properties: "record<RequestId: string, Status: int>"
    delete-data-source: "record<Arn: string, DataSourceId: string, RequestId: string, Status: int>"
    describe-data-source: "record<DataSource: record<Arn: string, DataSourceId: string, Name: string, Type: string, Status: string, CreatedTime: string, LastUpdatedTime: string, DataSourceParameters: record<AmazonElasticsearchParameters: record, AthenaParameters: record, AuroraParameters: record, AuroraPostgreSqlParameters: record, AwsIotAnalyticsParameters: record, JiraParameters: record, MariaDbParameters: record, MySqlParameters: record, OracleParameters: record, PostgreSqlParameters: record, PrestoParameters: record, RdsParameters: record, RedshiftParameters: record, S3Parameters: record, ServiceNowParameters: record, SnowflakeParameters: record, SparkParameters: record, SqlServerParameters: record, TeradataParameters: record, TwitterParameters: record, AmazonOpenSearchParameters: record, ExasolParameters: record, DatabricksParameters: record>, AlternateDataSourceParameters: list<record>, VpcConnectionProperties: record<VpcConnectionArn: string>, SslProperties: record<DisableSsl: bool>, ErrorInfo: record<Type: string, Message: string>, SecretArn: string>, RequestId: string, Status: int>"
    update-data-source: "record<Arn: string, DataSourceId: string, UpdateStatus: string, RequestId: string, Status: int>"
    delete-group: "record<RequestId: string, Status: int>"
    describe-group: "record<Group: record<Arn: string, GroupName: string, Description: string, PrincipalId: string>, RequestId: string, Status: int>"
    update-group: "record<Group: record<Arn: string, GroupName: string, Description: string, PrincipalId: string>, RequestId: string, Status: int>"
    delete-iam-policy-assignment: "record<AssignmentName: string, RequestId: string, Status: int>"
    delete-namespace: "record<RequestId: string, Status: int>"
    describe-namespace: "record<Namespace: record<Name: string, Arn: string, CapacityRegion: string, CreationStatus: string, IdentityStore: string, NamespaceError: record<Type: string, Message: string>>, RequestId: string, Status: int>"
    delete-refresh-schedule: "record<Status: int, RequestId: string, ScheduleId: string, Arn: string>"
    describe-refresh-schedule: "record<RefreshSchedule: record<ScheduleId: string, ScheduleFrequency: record<Interval: string, RefreshOnDay: record, Timezone: string, TimeOfTheDay: string>, StartAfterDateTime: string, RefreshType: string, Arn: string>, Status: int, RequestId: string, Arn: string>"
    delete-user: "record<RequestId: string, Status: int>"
    describe-user: "record<User: record<Arn: string, UserName: string, Email: string, Role: string, IdentityType: string, Active: bool, PrincipalId: string, CustomPermissionsName: string, ExternalLoginFederationProviderType: string, ExternalLoginFederationProviderUrl: string, ExternalLoginId: string>, RequestId: string, Status: int>"
    update-user: "record<User: record<Arn: string, UserName: string, Email: string, Role: string, IdentityType: string, Active: bool, PrincipalId: string, CustomPermissionsName: string, ExternalLoginFederationProviderType: string, ExternalLoginFederationProviderUrl: string, ExternalLoginId: string>, RequestId: string, Status: int>"
    delete-user-by-principal-id: "record<RequestId: string, Status: int>"
    describe-account-settings: "record<AccountSettings: record<AccountName: string, Edition: string, DefaultNamespace: string, NotificationEmail: string, PublicSharingEnabled: bool, TerminationProtectionEnabled: bool>, RequestId: string, Status: int>"
    update-account-settings: "record<RequestId: string, Status: int>"
    describe-analysis-definition: "record<AnalysisId: string, Name: string, Errors: table<Type: string, Message: string, ViolatedEntities: list>, ResourceStatus: string, ThemeArn: string, Definition: record<DataSetIdentifierDeclarations: list<record>, Sheets: list<record>, CalculatedFields: list<record>, ParameterDeclarations: list<record>, FilterGroups: list<record>, ColumnConfigurations: list<record>, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: int, RequestId: string>"
    describe-analysis-permissions: "record<AnalysisId: string, AnalysisArn: string, Permissions: table<Principal: string, Actions: list>, Status: int, RequestId: string>"
    update-analysis-permissions: "record<AnalysisArn: string, AnalysisId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>"
    describe-dashboard-definition: "record<DashboardId: string, Errors: table<Type: string, Message: string, ViolatedEntities: list>, Name: string, ResourceStatus: string, ThemeArn: string, Definition: record<DataSetIdentifierDeclarations: list<record>, Sheets: list<record>, CalculatedFields: list<record>, ParameterDeclarations: list<record>, FilterGroups: list<record>, ColumnConfigurations: list<record>, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: int, RequestId: string, DashboardPublishOptions: record<AdHocFilteringOption: record<AvailabilityStatus: string>, ExportToCSVOption: record<AvailabilityStatus: string>, SheetControlsOption: record<VisibilityState: string>, VisualPublishOptions: record<ExportHiddenFieldsOption: record>, SheetLayoutElementMaximizationOption: record<AvailabilityStatus: string>, VisualMenuOption: record<AvailabilityStatus: string>, VisualAxisSortOption: record<AvailabilityStatus: string>, ExportWithHiddenFieldsOption: record<AvailabilityStatus: string>, DataPointDrillUpDownOption: record<AvailabilityStatus: string>, DataPointMenuLabelOption: record<AvailabilityStatus: string>, DataPointTooltipOption: record<AvailabilityStatus: string>>>"
    describe-dashboard-permissions: "record<DashboardId: string, DashboardArn: string, Permissions: table<Principal: string, Actions: list>, Status: int, RequestId: string, LinkSharingConfiguration: record<Permissions: list<record>>>"
    update-dashboard-permissions: "record<DashboardArn: string, DashboardId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int, LinkSharingConfiguration: record<Permissions: list<record>>>"
    describe-data-set-permissions: "record<DataSetArn: string, DataSetId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>"
    update-data-set-permissions: "record<DataSetArn: string, DataSetId: string, RequestId: string, Status: int>"
    describe-data-source-permissions: "record<DataSourceArn: string, DataSourceId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>"
    update-data-source-permissions: "record<DataSourceArn: string, DataSourceId: string, RequestId: string, Status: int>"
    describe-folder-permissions: "record<Status: int, FolderId: string, Arn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string>"
    update-folder-permissions: "record<Status: int, Arn: string, FolderId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string>"
    describe-folder-resolved-permissions: "record<Status: int, FolderId: string, Arn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string>"
    describe-iam-policy-assignment: "record<IAMPolicyAssignment: record<AwsAccountId: string, AssignmentId: string, AssignmentName: string, PolicyArn: string, Identities: record, AssignmentStatus: string>, RequestId: string, Status: int>"
    update-iam-policy-assignment: "record<AssignmentName: string, AssignmentId: string, PolicyArn: string, Identities: record, AssignmentStatus: string, RequestId: string, Status: int>"
    describe-ip-restriction: "record<AwsAccountId: string, IpRestrictionRuleMap: record, Enabled: bool, RequestId: string, Status: int>"
    update-ip-restriction: "record<AwsAccountId: string, RequestId: string, Status: int>"
    describe-template-definition: "record<Name: string, TemplateId: string, Errors: table<Type: string, Message: string, ViolatedEntities: list>, ResourceStatus: string, ThemeArn: string, Definition: record<DataSetConfigurations: list<record>, Sheets: list<record>, CalculatedFields: list<record>, ParameterDeclarations: list<record>, FilterGroups: list<record>, ColumnConfigurations: list<record>, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: int, RequestId: string>"
    describe-template-permissions: "record<TemplateId: string, TemplateArn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>"
    update-template-permissions: "record<TemplateId: string, TemplateArn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>"
    describe-theme-permissions: "record<ThemeId: string, ThemeArn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>"
    update-theme-permissions: "record<ThemeId: string, ThemeArn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>"
    generate-embed-url-for-anonymous-user: "record<EmbedUrl: string, Status: int, RequestId: string, AnonymousUserArn: string>"
    generate-embed-url-for-registered-user: "record<EmbedUrl: string, Status: int, RequestId: string>"
    get-dashboard-embed-url: "record<EmbedUrl: string, Status: int, RequestId: string>"
    get-session-embed-url: "record<EmbedUrl: string, Status: int, RequestId: string>"
    list-analyses: "record<AnalysisSummaryList: table<Arn: string, AnalysisId: string, Name: string, Status: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>"
    list-dashboard-versions: "record<DashboardVersionSummaryList: table<Arn: string, CreatedTime: string, VersionNumber: int, Status: string, SourceEntityArn: string, Description: string>, NextToken: string, Status: int, RequestId: string>"
    list-dashboards: "record<DashboardSummaryList: table<Arn: string, DashboardId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, PublishedVersionNumber: int, LastPublishedTime: string>, NextToken: string, Status: int, RequestId: string>"
    list-folder-members: "record<Status: int, FolderMemberList: table<MemberId: string, MemberArn: string>, NextToken: string, RequestId: string>"
    list-folders: "record<Status: int, FolderSummaryList: table<Arn: string, FolderId: string, Name: string, FolderType: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, RequestId: string>"
    list-group-memberships: "record<GroupMemberList: table<Arn: string, MemberName: string>, NextToken: string, RequestId: string, Status: int>"
    list-iam-policy-assignments: "record<IAMPolicyAssignments: table<AssignmentName: string, AssignmentStatus: string>, NextToken: string, RequestId: string, Status: int>"
    list-iam-policy-assignments-for-user: "record<ActiveAssignments: table<AssignmentName: string, PolicyArn: string>, RequestId: string, NextToken: string, Status: int>"
    list-ingestions: "record<Ingestions: table<Arn: string, IngestionId: string, IngestionStatus: string, ErrorInfo: record, RowInfo: record, QueueInfo: record, CreatedTime: string, IngestionTimeInSeconds: int, IngestionSizeInBytes: int, RequestSource: string, RequestType: string>, NextToken: string, RequestId: string, Status: int>"
    list-namespaces: "record<Namespaces: table<Name: string, Arn: string, CapacityRegion: string, CreationStatus: string, IdentityStore: string, NamespaceError: record>, NextToken: string, RequestId: string, Status: int>"
    list-tags-for-resource: "record<Tags: table<Key: string, Value: string>, RequestId: string, Status: int>"
    tag-resource: "record<RequestId: string, Status: int>"
    list-template-aliases: "record<TemplateAliasList: table<AliasName: string, Arn: string, TemplateVersionNumber: int>, Status: int, RequestId: string, NextToken: string>"
    list-template-versions: "record<TemplateVersionSummaryList: table<Arn: string, VersionNumber: int, CreatedTime: string, Status: string, Description: string>, NextToken: string, Status: int, RequestId: string>"
    list-templates: "record<TemplateSummaryList: table<Arn: string, TemplateId: string, Name: string, LatestVersionNumber: int, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>"
    list-theme-aliases: "record<ThemeAliasList: table<Arn: string, AliasName: string, ThemeVersionNumber: int>, Status: int, RequestId: string, NextToken: string>"
    list-theme-versions: "record<ThemeVersionSummaryList: table<VersionNumber: int, Arn: string, Description: string, CreatedTime: string, Status: string>, NextToken: string, Status: int, RequestId: string>"
    list-themes: "record<ThemeSummaryList: table<Arn: string, Name: string, ThemeId: string, LatestVersionNumber: int, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>"
    list-user-groups: "record<GroupList: table<Arn: string, GroupName: string, Description: string, PrincipalId: string>, NextToken: string, RequestId: string, Status: int>"
    list-users: "record<UserList: table<Arn: string, UserName: string, Email: string, Role: string, IdentityType: string, Active: bool, PrincipalId: string, CustomPermissionsName: string, ExternalLoginFederationProviderType: string, ExternalLoginFederationProviderUrl: string, ExternalLoginId: string>, NextToken: string, RequestId: string, Status: int>"
    register-user: "record<User: record<Arn: string, UserName: string, Email: string, Role: string, IdentityType: string, Active: bool, PrincipalId: string, CustomPermissionsName: string, ExternalLoginFederationProviderType: string, ExternalLoginFederationProviderUrl: string, ExternalLoginId: string>, UserInvitationUrl: string, RequestId: string, Status: int>"
    restore-analysis: "record<Status: int, Arn: string, AnalysisId: string, RequestId: string>"
    search-analyses: "record<AnalysisSummaryList: table<Arn: string, AnalysisId: string, Name: string, Status: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>"
    search-dashboards: "record<DashboardSummaryList: table<Arn: string, DashboardId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, PublishedVersionNumber: int, LastPublishedTime: string>, NextToken: string, Status: int, RequestId: string>"
    search-data-sets: "record<DataSetSummaries: table<Arn: string, DataSetId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, ImportMode: string, RowLevelPermissionDataSet: record, RowLevelPermissionTagConfigurationApplied: bool, ColumnLevelPermissionRulesApplied: bool>, NextToken: string, Status: int, RequestId: string>"
    search-data-sources: "record<DataSourceSummaries: table<Arn: string, DataSourceId: string, Name: string, Type: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>"
    search-folders: "record<Status: int, FolderSummaryList: table<Arn: string, FolderId: string, Name: string, FolderType: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, RequestId: string>"
    search-groups: "record<GroupList: table<Arn: string, GroupName: string, Description: string, PrincipalId: string>, NextToken: string, RequestId: string, Status: int>"
    untag-resource: "record<RequestId: string, Status: int>"
    update-dashboard-published-version: "record<DashboardId: string, DashboardArn: string, Status: int, RequestId: string>"
    update-public-sharing-settings: "record<RequestId: string, Status: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["cancel-ingestion" "create-ingestion" "describe-ingestion" "create-account-customization" "delete-account-customization" "describe-account-customization" "update-account-customization" "create-account-subscription" "delete-account-subscription" "describe-account-subscription" "create-analysis" "delete-analysis" "describe-analysis" "update-analysis" "create-dashboard" "delete-dashboard" "describe-dashboard" "update-dashboard" "create-data-set" "list-data-sets" "create-data-source" "list-data-sources" "create-folder" "delete-folder" "describe-folder" "update-folder" "create-folder-membership" "delete-folder-membership" "create-group" "list-groups" "create-group-membership" "delete-group-membership" "describe-group-membership" "create-iam-policy-assignment" "create-namespace" "create-refresh-schedule" "list-refresh-schedules" "update-refresh-schedule" "create-template" "delete-template" "describe-template" "update-template" "create-template-alias" "delete-template-alias" "describe-template-alias" "update-template-alias" "create-theme" "delete-theme" "describe-theme" "update-theme" "create-theme-alias" "delete-theme-alias" "describe-theme-alias" "update-theme-alias" "delete-data-set" "describe-data-set" "update-data-set" "delete-data-set-refresh-properties" "describe-data-set-refresh-properties" "put-data-set-refresh-properties" "delete-data-source" "describe-data-source" "update-data-source" "delete-group" "describe-group" "update-group" "delete-iam-policy-assignment" "delete-namespace" "describe-namespace" "delete-refresh-schedule" "describe-refresh-schedule" "delete-user" "describe-user" "update-user" "delete-user-by-principal-id" "describe-account-settings" "update-account-settings" "describe-analysis-definition" "describe-analysis-permissions" "update-analysis-permissions" "describe-dashboard-definition" "describe-dashboard-permissions" "update-dashboard-permissions" "describe-data-set-permissions" "update-data-set-permissions" "describe-data-source-permissions" "update-data-source-permissions" "describe-folder-permissions" "update-folder-permissions" "describe-folder-resolved-permissions" "describe-iam-policy-assignment" "update-iam-policy-assignment" "describe-ip-restriction" "update-ip-restriction" "describe-template-definition" "describe-template-permissions" "update-template-permissions" "describe-theme-permissions" "update-theme-permissions" "generate-embed-url-for-anonymous-user" "generate-embed-url-for-registered-user" "get-dashboard-embed-url" "get-session-embed-url" "list-analyses" "list-dashboard-versions" "list-dashboards" "list-folder-members" "list-folders" "list-group-memberships" "list-iam-policy-assignments" "list-iam-policy-assignments-for-user" "list-ingestions" "list-namespaces" "list-tags-for-resource" "tag-resource" "list-template-aliases" "list-template-versions" "list-templates" "list-theme-aliases" "list-theme-versions" "list-themes" "list-user-groups" "list-users" "register-user" "restore-analysis" "search-analyses" "search-dashboards" "search-data-sets" "search-data-sources" "search-folders" "search-groups" "untag-resource" "update-dashboard-published-version" "update-public-sharing-settings" "commands"] | sort) } | get name | first)
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

# Cancels an ongoing ingestion of data into SPICE.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}
# Returns: record<Arn: string, IngestionId: string, RequestId: string, Status: int>
# operationId: CancelIngestion
export def "cancel-ingestion" [
  aws_account_id: string
  data_set_id: string
  ingestion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}, {name: IngestionId, var: ingestion_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, ingestion_id: $ingestion_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates and starts a new SPICE ingestion for a dataset. You can manually refresh datasets in an Enterprise edition account 32 times in a 24-hour period. You can manually refresh datasets in a Standard edition account 8 times in a 24-hour period. Each 24-hour period is measured starting 24 hours before the current date and time. Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see How do I create an IAM policy to control access to Amazon EC2 resources using tags? (http://aws.amazon.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/) in the Amazon Web Services Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}
# Returns: record<Arn: string, IngestionId: string, IngestionStatus: string, RequestId: string, Status: int>
# operationId: CreateIngestion
export def "create-ingestion" [
  aws_account_id: string
  data_set_id: string
  ingestion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --ingestion-type: string@ingestion-type-completer # This defines the type of ingestion user wants to trigger. This is part of create ingestion request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}, {name: IngestionId, var: ingestion_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: IngestionType, var: ingestion_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, ingestion_id: $ingestion_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, ingestion_type: $ingestion_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a SPICE ingestion.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}
# Returns: record<Ingestion: record<Arn: string, IngestionId: string, IngestionStatus: string, ErrorInfo: record<Type: string, Message: string>, RowInfo: record<RowsIngested: int, RowsDropped: int, TotalRowsInDataset: int>, QueueInfo: record<WaitingOnIngestion: string, QueuedIngestion: string>, CreatedTime: string, IngestionTimeInSeconds: int, IngestionSizeInBytes: int, RequestSource: string, RequestType: string>, RequestId: string, Status: int>
# operationId: DescribeIngestion
export def "describe-ingestion" [
  aws_account_id: string
  data_set_id: string
  ingestion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}, {name: IngestionId, var: ingestion_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, ingestion_id: $ingestion_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates Amazon QuickSight customizations for the current Amazon Web Services Region. Currently, you can add a custom default theme by using the CreateAccountCustomization or UpdateAccountCustomization API operation. To further customize Amazon QuickSight by removing Amazon QuickSight sample assets and videos for all new users, see Customizing Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/customizing-quicksight.html) in the Amazon QuickSight User Guide. You can create customizations for your Amazon Web Services account or, if you specify a namespace, for a QuickSight namespace instead. Customizations that apply to a namespace always override customizations that apply to an Amazon Web Services account. To find out which customizations apply, use the DescribeAccountCustomization API operation. Before you use the CreateAccountCustomization API operation to add a theme as the namespace default, make sure that you first share the theme with the namespace. If you don't share it with the namespace, the theme isn't visible to your users even if you make it the default theme. To check if the theme is shared, view the current permissions by using the DescribeThemePermissions (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeThemePermissions.html) API operation. To share the theme, grant permissions by using the UpdateThemePermissions (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateThemePermissions.html) API operation.
#
# POST /accounts/{AwsAccountId}/customizations
# Returns: record<Arn: string, AwsAccountId: string, Namespace: string, AccountCustomization: record<DefaultTheme: string, DefaultEmailCustomizationTemplate: string>, RequestId: string, Status: int>
# operationId: CreateAccountCustomization
export def "create-account-customization" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you want to add customizations to.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  account_customization: record # The Amazon QuickSight customizations associated with your Amazon Web Services account or a QuickSight namespace in a specific Amazon Web Services Region. — shape: {DefaultTheme?: string, DefaultEmailCustomizationTemplate?: string}
  --tags: list # A list of the tags that you want to attach to this resource. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/customizations"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: namespace, var: namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountCustomization, var: account_customization}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, account_customization: $account_customization, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes all Amazon QuickSight customizations in this Amazon Web Services Region for the specified Amazon Web Services account and Amazon QuickSight namespace.
#
# DELETE /accounts/{AwsAccountId}/customizations
# Returns: record<RequestId: string, Status: int>
# operationId: DeleteAccountCustomization
export def "delete-account-customization" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you're deleting the customizations from.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/customizations"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: namespace, var: namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the customizations associated with the provided Amazon Web Services account and Amazon Amazon QuickSight namespace in an Amazon Web Services Region. The Amazon QuickSight console evaluates which customizations to apply by running this API operation with the Resolved flag included. To determine what customizations display when you run this command, it can help to visualize the relationship of the entities involved. Amazon Web Services account - The Amazon Web Services account exists at the top of the hierarchy. It has the potential to use all of the Amazon Web Services Regions and Amazon Web Services Services. When you subscribe to Amazon QuickSight, you choose one Amazon Web Services Region to use as your home Region. That's where your free SPICE capacity is located. You can use Amazon QuickSight in any supported Amazon Web Services Region. Amazon Web Services Region - In each Amazon Web Services Region where you sign in to Amazon QuickSight at least once, Amazon QuickSight acts as a separate instance of the same service. If you have a user directory, it resides in us-east-1, which is the US East (N. Virginia). Generally speaking, these users have access to Amazon QuickSight in any Amazon Web Services Region, unless they are constrained to a namespace. To run the command in a different Amazon Web Services Region, you change your Region settings. If you're using the CLI, you can use one of the following options: Use command line options (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-options.html). Use named profiles (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html). Run aws configure to change your default Amazon Web Services Region. Use Enter to key the same settings for your keys. For more information, see Configuring the CLI (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html). Namespace - A QuickSight namespace is a partition that contains users and assets (data sources, datasets, dashboards, and so on). To access assets that are in a specific namespace, users and groups must also be part of the same namespace. People who share a namespace are completely isolated from users and assets in other namespaces, even if they are in the same Amazon Web Services account and Amazon Web Services Region. Applied customizations - Within an Amazon Web Services Region, a set of Amazon QuickSight customizations can apply to an Amazon Web Services account or to a namespace. Settings that you apply to a namespace override settings that you apply to an Amazon Web Services account. All settings are isolated to a single Amazon Web Services Region. To apply them in other Amazon Web Services Regions, run the CreateAccountCustomization command in each Amazon Web Services Region where you want to apply the same customizations.
#
# GET /accounts/{AwsAccountId}/customizations
# Returns: record<Arn: string, AwsAccountId: string, Namespace: string, AccountCustomization: record<DefaultTheme: string, DefaultEmailCustomizationTemplate: string>, RequestId: string, Status: int>
# operationId: DescribeAccountCustomization
export def "describe-account-customization" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The Amazon QuickSight namespace that you want to describe Amazon QuickSight customizations for.
  --resolved: oneof<nothing, bool> # The Resolved flag works with the other parameters to determine which view of Amazon QuickSight customizations is returned. You can add this flag to your command to use the same view that Amazon QuickSight uses to identify which customizations to apply to the console. Omit this flag, or set it to no-resolved, to reveal customizations that are configured at different levels.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/customizations"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: namespace, var: namespace}, {name: resolved, var: resolved}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, resolved: $resolved, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates Amazon QuickSight customizations for the current Amazon Web Services Region. Currently, the only customization that you can use is a theme. You can use customizations for your Amazon Web Services account or, if you specify a namespace, for a Amazon QuickSight namespace instead. Customizations that apply to a namespace override customizations that apply to an Amazon Web Services account. To find out which customizations apply, use the DescribeAccountCustomization API operation.
#
# PUT /accounts/{AwsAccountId}/customizations
# Returns: record<Arn: string, AwsAccountId: string, Namespace: string, AccountCustomization: record<DefaultTheme: string, DefaultEmailCustomizationTemplate: string>, RequestId: string, Status: int>
# operationId: UpdateAccountCustomization
export def "update-account-customization" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The namespace that you want to update Amazon QuickSight customizations for.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  account_customization: record # The Amazon QuickSight customizations associated with your Amazon Web Services account or a QuickSight namespace in a specific Amazon Web Services Region. — shape: {DefaultTheme?: string, DefaultEmailCustomizationTemplate?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/customizations"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: namespace, var: namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccountCustomization, var: account_customization}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, account_customization: $account_customization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon QuickSight account, or subscribes to Amazon QuickSight Q. The Amazon Web Services Region for the account is derived from what is configured in the CLI or SDK. This operation isn't supported in the US East (Ohio) Region, South America (Sao Paulo) Region, or Asia Pacific (Singapore) Region. Before you use this operation, make sure that you can connect to an existing Amazon Web Services account. If you don't have an Amazon Web Services account, see Sign up for Amazon Web Services (https://docs.aws.amazon.com/quicksight/latest/user/setting-up-aws-sign-up.html) in the Amazon QuickSight User Guide. The person who signs up for Amazon QuickSight needs to have the correct Identity and Access Management (IAM) permissions. For more information, see IAM Policy Examples for Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/iam-policy-examples.html) in the Amazon QuickSight User Guide. If your IAM policy includes both the Subscribe and CreateAccountSubscription actions, make sure that both actions are set to Allow. If either action is set to Deny, the Deny action prevails and your API call fails. You can't pass an existing IAM role to access other Amazon Web Services services using this API operation. To pass your existing IAM role to Amazon QuickSight, see Passing IAM roles to Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/security_iam_service-with-iam.html#security-create-iam-role) in the Amazon QuickSight User Guide. You can't set default resource access on the new account from the Amazon QuickSight API. Instead, add default resource access from the Amazon QuickSight console. For more information about setting default resource access to Amazon Web Services services, see Setting default resource access to Amazon Web Services services (https://docs.aws.amazon.com/quicksight/latest/user/scoping-policies-defaults.html) in the Amazon QuickSight User Guide.
#
# POST /account/{AwsAccountId}
# Returns: record<SignupResponse: record<IAMUser: bool, userLoginName: string, accountName: string, directoryType: string>, Status: int, RequestId: string>
# operationId: CreateAccountSubscription
export def "create-account-subscription" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  edition: string@edition-completer # The edition of Amazon QuickSight that you want your account to have. Currently, you can choose from ENTERPRISE or ENTERPRISE_AND_Q. If you choose ENTERPRISE_AND_Q, the following parameters are required: FirstName LastName EmailAddress ContactNumber
  authentication_method: string@authentication-method-completer # The method that you want to use to authenticate your Amazon QuickSight account. Currently, the valid values for this parameter are IAM_AND_QUICKSIGHT, IAM_ONLY, and ACTIVE_DIRECTORY. If you choose ACTIVE_DIRECTORY, provide an ActiveDirectoryName and an AdminGroup associated with your Active Directory.
  account_name: string # The name of your Amazon QuickSight account. This name is unique over all of Amazon Web Services, and it appears only when users sign in. You can't change AccountName value after the Amazon QuickSight account is created.
  notification_email: string # The email address that you want Amazon QuickSight to send notifications to regarding your Amazon QuickSight account or Amazon QuickSight subscription.
  --active-directory-name: string # The name of your Active Directory. This field is required if ACTIVE_DIRECTORY is the selected authentication method of the new Amazon QuickSight account.
  --realm: string # The realm of the Active Directory that is associated with your Amazon QuickSight account. This field is required if ACTIVE_DIRECTORY is the selected authentication method of the new Amazon QuickSight account.
  --directory-id: string # The ID of the Active Directory that is associated with your Amazon QuickSight account.
  --admin-group: list<string> # The admin group associated with your Active Directory. This field is required if ACTIVE_DIRECTORY is the selected authentication method of the new Amazon QuickSight account. For more information about using Active Directory in Amazon QuickSight, see Using Active Directory with Amazon QuickSight Enterprise Edition (https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html) in the Amazon QuickSight User Guide.
  --author-group: list<string> # The author group associated with your Active Directory. For more information about using Active Directory in Amazon QuickSight, see Using Active Directory with Amazon QuickSight Enterprise Edition (https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html) in the Amazon QuickSight User Guide.
  --reader-group: list<string> # The reader group associated with your Active Direcrtory. For more information about using Active Directory in Amazon QuickSight, see Using Active Directory with Amazon QuickSight Enterprise Edition (https://docs.aws.amazon.com/quicksight/latest/user/aws-directory-service.html) in the Amazon QuickSight User Guide.
  --first-name: string # The first name of the author of the Amazon QuickSight account to use for future communications. This field is required if ENTERPPRISE_AND_Q is the selected edition of the new Amazon QuickSight account.
  --last-name: string # The last name of the author of the Amazon QuickSight account to use for future communications. This field is required if ENTERPPRISE_AND_Q is the selected edition of the new Amazon QuickSight account.
  --email-address: string # The email address of the author of the Amazon QuickSight account to use for future communications. This field is required if ENTERPPRISE_AND_Q is the selected edition of the new Amazon QuickSight account.
  --contact-number: string # A 10-digit phone number for the author of the Amazon QuickSight account to use for future communications. This field is required if ENTERPPRISE_AND_Q is the selected edition of the new Amazon QuickSight account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/account/{AwsAccountId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Edition, var: edition}, {name: AuthenticationMethod, var: authentication_method}, {name: AccountName, var: account_name}, {name: NotificationEmail, var: notification_email}, {name: ActiveDirectoryName, var: active_directory_name}, {name: Realm, var: realm}, {name: DirectoryId, var: directory_id}, {name: AdminGroup, var: admin_group}, {name: AuthorGroup, var: author_group}, {name: ReaderGroup, var: reader_group}, {name: FirstName, var: first_name}, {name: LastName, var: last_name}, {name: EmailAddress, var: email_address}, {name: ContactNumber, var: contact_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, edition: $edition, authentication_method: $authentication_method, account_name: $account_name, notification_email: $notification_email, active_directory_name: $active_directory_name, realm: $realm, directory_id: $directory_id, admin_group: $admin_group, author_group: $author_group, reader_group: $reader_group, first_name: $first_name, last_name: $last_name, email_address: $email_address, contact_number: $contact_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the DeleteAccountSubscription operation to delete an Amazon QuickSight account. This operation will result in an error message if you have configured your account termination protection settings to True. To change this setting and delete your account, call the UpdateAccountSettings API and set the value of the TerminationProtectionEnabled parameter to False, then make another call to the DeleteAccountSubscription API.
#
# DELETE /account/{AwsAccountId}
# Returns: record<RequestId: string, Status: int>
# operationId: DeleteAccountSubscription
export def "delete-account-subscription" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/account/{AwsAccountId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the DescribeAccountSubscription operation to receive a description of an Amazon QuickSight account's subscription. A successful API call returns an AccountInfo object that includes an account's name, subscription status, authentication type, edition, and notification email address.
#
# GET /account/{AwsAccountId}
# Returns: record<AccountInfo: record<AccountName: string, Edition: string, NotificationEmail: string, AuthenticationType: string, AccountSubscriptionStatus: string>, Status: int, RequestId: string>
# operationId: DescribeAccountSubscription
export def "describe-account-subscription" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/account/{AwsAccountId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an analysis in Amazon QuickSight. Analyses can be created either from a template or from an AnalysisDefinition.
#
# POST /accounts/{AwsAccountId}/analyses/{AnalysisId}
# Returns: record<Arn: string, AnalysisId: string, CreationStatus: string, Status: int, RequestId: string>
# operationId: CreateAnalysis
export def "create-analysis" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A descriptive name for the analysis that you're creating. This name displays for the analysis in the Amazon QuickSight console.
  --parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: list, IntegerParameters?: list, DecimalParameters?: list, DateTimeParameters?: list}
  --permissions: list # A structure that describes the principals and the resource-level permissions on an analysis. You can use the Permissions structure to grant permissions by providing a list of Identity and Access Management (IAM) action information for each principal listed by Amazon Resource Name (ARN). To specify no permissions, omit Permissions. — item shape: {Principal: string, Actions: list<string>}
  --source-entity: record # The source entity of an analysis. — shape: {SourceTemplate?: record}
  --theme-arn: string # The ARN for the theme to apply to the analysis that you're creating. To see the theme in the Amazon QuickSight console, make sure that you have access to it.
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the analysis. — item shape: {Key: string, Value: string}
  --definition: record # The definition of an analysis. — shape: {DataSetIdentifierDeclarations?: list, Sheets?: list, CalculatedFields?: list, ParameterDeclarations?: list, FilterGroups?: list, ColumnConfigurations?: list, AnalysisDefaults?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/analyses/{AnalysisId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: AnalysisId, var: analysis_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Parameters, var: parameters}, {name: Permissions, var: permissions}, {name: SourceEntity, var: source_entity}, {name: ThemeArn, var: theme_arn}, {name: Tags, var: tags}, {name: Definition, var: definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, analysis_id: $analysis_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, parameters: $parameters, permissions: $permissions, source_entity: $source_entity, theme_arn: $theme_arn, tags: $tags, definition: $definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an analysis from Amazon QuickSight. You can optionally include a recovery window during which you can restore the analysis. If you don't specify a recovery window value, the operation defaults to 30 days. Amazon QuickSight attaches a DeletionTime stamp to the response that specifies the end of the recovery window. At the end of the recovery window, Amazon QuickSight deletes the analysis permanently. At any time before recovery window ends, you can use the RestoreAnalysis API operation to remove the DeletionTime stamp and cancel the deletion of the analysis. The analysis remains visible in the API until it's deleted, so you can describe it but you can't make a template from it. An analysis that's scheduled for deletion isn't accessible in the Amazon QuickSight console. To access it in the console, restore it. Deleting an analysis doesn't delete the dashboards that you publish from it.
#
# DELETE /accounts/{AwsAccountId}/analyses/{AnalysisId}
# Returns: record<Status: int, Arn: string, AnalysisId: string, DeletionTime: string, RequestId: string>
# operationId: DeleteAnalysis
export def "delete-analysis" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recovery-window-in-days: int # A value that specifies the number of days that Amazon QuickSight waits before it deletes the analysis. You can't use this parameter with the ForceDeleteWithoutRecovery option in the same API call. The default value is 30.
  --force-delete-without-recovery: oneof<nothing, bool> # This option defaults to the value NoForceDeleteWithoutRecovery. To immediately delete the analysis, add the ForceDeleteWithoutRecovery option. You can't restore an analysis after it's deleted.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/analyses/{AnalysisId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: AnalysisId, var: analysis_id}]
    query: [{name: recovery-window-in-days, var: recovery_window_in_days}, {name: force-delete-without-recovery, var: force_delete_without_recovery}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, analysis_id: $analysis_id, recovery_window_in_days: $recovery_window_in_days, force_delete_without_recovery: $force_delete_without_recovery, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a summary of the metadata for an analysis.
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}
# Returns: record<Analysis: record<AnalysisId: string, Arn: string, Name: string, Status: string, Errors: list<record>, DataSetArns: list<string>, ThemeArn: string, CreatedTime: string, LastUpdatedTime: string, Sheets: list<record>>, Status: int, RequestId: string>
# operationId: DescribeAnalysis
export def "describe-analysis" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/analyses/{AnalysisId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: AnalysisId, var: analysis_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, analysis_id: $analysis_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an analysis in Amazon QuickSight
#
# PUT /accounts/{AwsAccountId}/analyses/{AnalysisId}
# Returns: record<Arn: string, AnalysisId: string, UpdateStatus: string, Status: int, RequestId: string>
# operationId: UpdateAnalysis
export def "update-analysis" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A descriptive name for the analysis that you're updating. This name displays for the analysis in the Amazon QuickSight console.
  --parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: list, IntegerParameters?: list, DecimalParameters?: list, DateTimeParameters?: list}
  --source-entity: record # The source entity of an analysis. — shape: {SourceTemplate?: record}
  --theme-arn: string # The Amazon Resource Name (ARN) for the theme to apply to the analysis that you're creating. To see the theme in the Amazon QuickSight console, make sure that you have access to it.
  --definition: record # The definition of an analysis. — shape: {DataSetIdentifierDeclarations?: list, Sheets?: list, CalculatedFields?: list, ParameterDeclarations?: list, FilterGroups?: list, ColumnConfigurations?: list, AnalysisDefaults?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/analyses/{AnalysisId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: AnalysisId, var: analysis_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Parameters, var: parameters}, {name: SourceEntity, var: source_entity}, {name: ThemeArn, var: theme_arn}, {name: Definition, var: definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, analysis_id: $analysis_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, parameters: $parameters, source_entity: $source_entity, theme_arn: $theme_arn, definition: $definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a dashboard from either a template or directly with a DashboardDefinition. To first create a template, see the CreateTemplate (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_CreateTemplate.html) API operation. A dashboard is an entity in Amazon QuickSight that identifies Amazon QuickSight reports, created from analyses. You can share Amazon QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. If you have the correct permissions, you can create a dashboard from a template that exists in a different Amazon Web Services account.
#
# POST /accounts/{AwsAccountId}/dashboards/{DashboardId}
# Returns: record<Arn: string, VersionArn: string, DashboardId: string, CreationStatus: string, Status: int, RequestId: string>
# operationId: CreateDashboard
export def "create-dashboard" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The display name of the dashboard.
  --parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: list, IntegerParameters?: list, DecimalParameters?: list, DateTimeParameters?: list}
  --permissions: list # A structure that contains the permissions of the dashboard. You can use this structure for granting permissions by providing a list of IAM action information for each principal ARN. To specify no permissions, omit the permissions list. — item shape: {Principal: string, Actions: list<string>}
  --source-entity: record # Dashboard source entity. — shape: {SourceTemplate?: record}
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the dashboard. — item shape: {Key: string, Value: string}
  --version-description: string # A description for the first version of the dashboard being created.
  --dashboard-publish-options: record # Dashboard publish options. — shape: {AdHocFilteringOption?: record, ExportToCSVOption?: record, SheetControlsOption?: record, VisualPublishOptions?: record, SheetLayoutElementMaximizationOption?: record, VisualMenuOption?: record, VisualAxisSortOption?: record, ExportWithHiddenFieldsOption?: record, DataPointDrillUpDownOption?: record, DataPointMenuLabelOption?: record, DataPointTooltipOption?: record}
  --theme-arn: string # The Amazon Resource Name (ARN) of the theme that is being used for this dashboard. If you add a value for this field, it overrides the value that is used in the source entity. The theme ARN must exist in the same Amazon Web Services account where you create the dashboard.
  --definition: record # The contents of a dashboard. — shape: {DataSetIdentifierDeclarations?: list, Sheets?: list, CalculatedFields?: list, ParameterDeclarations?: list, FilterGroups?: list, ColumnConfigurations?: list, AnalysisDefaults?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Parameters, var: parameters}, {name: Permissions, var: permissions}, {name: SourceEntity, var: source_entity}, {name: Tags, var: tags}, {name: VersionDescription, var: version_description}, {name: DashboardPublishOptions, var: dashboard_publish_options}, {name: ThemeArn, var: theme_arn}, {name: Definition, var: definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, parameters: $parameters, permissions: $permissions, source_entity: $source_entity, tags: $tags, version_description: $version_description, dashboard_publish_options: $dashboard_publish_options, theme_arn: $theme_arn, definition: $definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dashboard.
#
# DELETE /accounts/{AwsAccountId}/dashboards/{DashboardId}
# Returns: record<Status: int, Arn: string, DashboardId: string, RequestId: string>
# operationId: DeleteDashboard
export def "delete-dashboard" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    query: [{name: version-number, var: version_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, version_number: $version_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a summary for a dashboard.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}
# Returns: record<Dashboard: record<DashboardId: string, Arn: string, Name: string, Version: record<CreatedTime: string, Errors: list, VersionNumber: int, Status: string, Arn: string, SourceEntityArn: string, DataSetArns: list, Description: string, ThemeArn: string, Sheets: list>, CreatedTime: string, LastPublishedTime: string, LastUpdatedTime: string>, Status: int, RequestId: string>
# operationId: DescribeDashboard
export def "describe-dashboard" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described.
  --alias-name: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    query: [{name: version-number, var: version_number}, {name: alias-name, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, version_number: $version_number, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a dashboard in an Amazon Web Services account. Updating a Dashboard creates a new dashboard version but does not immediately publish the new version. You can update the published version of a dashboard by using the UpdateDashboardPublishedVersion (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateDashboardPublishedVersion.html) API operation.
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}
# Returns: record<Arn: string, VersionArn: string, DashboardId: string, CreationStatus: string, Status: int, RequestId: string>
# operationId: UpdateDashboard
export def "update-dashboard" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The display name of the dashboard.
  --source-entity: record # Dashboard source entity. — shape: {SourceTemplate?: record}
  --parameters: record # A list of Amazon QuickSight parameters and the list's override values. — shape: {StringParameters?: list, IntegerParameters?: list, DecimalParameters?: list, DateTimeParameters?: list}
  --version-description: string # A description for the first version of the dashboard being created.
  --dashboard-publish-options: record # Dashboard publish options. — shape: {AdHocFilteringOption?: record, ExportToCSVOption?: record, SheetControlsOption?: record, VisualPublishOptions?: record, SheetLayoutElementMaximizationOption?: record, VisualMenuOption?: record, VisualAxisSortOption?: record, ExportWithHiddenFieldsOption?: record, DataPointDrillUpDownOption?: record, DataPointMenuLabelOption?: record, DataPointTooltipOption?: record}
  --theme-arn: string # The Amazon Resource Name (ARN) of the theme that is being used for this dashboard. If you add a value for this field, it overrides the value that was originally associated with the entity. The theme ARN must exist in the same Amazon Web Services account where you create the dashboard.
  --definition: record # The contents of a dashboard. — shape: {DataSetIdentifierDeclarations?: list, Sheets?: list, CalculatedFields?: list, ParameterDeclarations?: list, FilterGroups?: list, ColumnConfigurations?: list, AnalysisDefaults?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: SourceEntity, var: source_entity}, {name: Parameters, var: parameters}, {name: VersionDescription, var: version_description}, {name: DashboardPublishOptions, var: dashboard_publish_options}, {name: ThemeArn, var: theme_arn}, {name: Definition, var: definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, source_entity: $source_entity, parameters: $parameters, version_description: $version_description, dashboard_publish_options: $dashboard_publish_options, theme_arn: $theme_arn, definition: $definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a dataset. This operation doesn't support datasets that include uploaded files as a source.
#
# POST /accounts/{AwsAccountId}/data-sets
# Returns: record<Arn: string, DataSetId: string, IngestionArn: string, IngestionId: string, RequestId: string, Status: int>
# operationId: CreateDataSet
export def "create-data-set" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  data_set_id: string # An ID for the dataset that you want to create. This ID is unique per Amazon Web Services Region for each Amazon Web Services account.
  name: string # The display name for the dataset.
  physical_table_map: record # Declares the physical tables that are available in the underlying data sources.
  --logical-table-map: record # Configures the combination and transformation of the data from the physical tables.
  import_mode: string@import-mode-completer # Indicates whether you want to import the data into SPICE.
  --column-groups: list # Groupings of columns that work together in certain Amazon QuickSight features. Currently, only geospatial hierarchy is supported. — item shape: {GeoSpatialColumnGroup?: record}
  --field-folders: record # The folder that contains fields and nested subfolders for your dataset.
  --permissions: list # A list of resource permissions on the dataset. — item shape: {Principal: string, Actions: list<string>}
  --row-level-permission-data-set: record # Information about a dataset that contains permissions for row-level security (RLS). The permissions dataset maps fields to users or groups. For more information, see Using Row-Level Security (RLS) to Restrict Access to a Dataset (https://docs.aws.amazon.com/quicksight/latest/user/restrict-access-to-a-data-set-using-row-level-security.html) in the Amazon QuickSight User Guide. The option to deny permissions by setting PermissionPolicy to DENY_ACCESS is not supported for new RLS datasets. — shape: {Namespace?: string, Arn?: string, PermissionPolicy?: "GRANT_ACCESS"|"DENY_ACCESS", FormatVersion?: "VERSION_1"|"VERSION_2", Status?: "ENABLED"|"DISABLED"}
  --row-level-permission-tag-configuration: record # The configuration of tags on a dataset to set row-level security. — shape: {Status?: "ENABLED"|"DISABLED", TagRules?: list, TagRuleConfigurations?: list}
  --column-level-permission-rules: list # A set of one or more definitions of a ColumnLevelPermissionRule (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_ColumnLevelPermissionRule.html) . — item shape: {Principals?: list<string>, ColumnNames?: list<string>}
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the dataset. — item shape: {Key: string, Value: string}
  --data-set-usage-configuration: record # The usage configuration to apply to child datasets that reference this dataset as a source. — shape: {DisableUseAsDirectQuerySource?: bool, DisableUseAsImportedSource?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/data-sets"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSetId, var: data_set_id}, {name: Name, var: name}, {name: PhysicalTableMap, var: physical_table_map}, {name: LogicalTableMap, var: logical_table_map}, {name: ImportMode, var: import_mode}, {name: ColumnGroups, var: column_groups}, {name: FieldFolders, var: field_folders}, {name: Permissions, var: permissions}, {name: RowLevelPermissionDataSet, var: row_level_permission_data_set}, {name: RowLevelPermissionTagConfiguration, var: row_level_permission_tag_configuration}, {name: ColumnLevelPermissionRules, var: column_level_permission_rules}, {name: Tags, var: tags}, {name: DataSetUsageConfiguration, var: data_set_usage_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, data_set_id: $data_set_id, name: $name, physical_table_map: $physical_table_map, logical_table_map: $logical_table_map, import_mode: $import_mode, column_groups: $column_groups, field_folders: $field_folders, permissions: $permissions, row_level_permission_data_set: $row_level_permission_data_set, row_level_permission_tag_configuration: $row_level_permission_tag_configuration, column_level_permission_rules: $column_level_permission_rules, tags: $tags, data_set_usage_configuration: $data_set_usage_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all of the datasets belonging to the current Amazon Web Services account in an Amazon Web Services Region. The permissions resource is arn:aws:quicksight:region:aws-account-id:dataset/*.
#
# GET /accounts/{AwsAccountId}/data-sets
# Returns: record<DataSetSummaries: table<Arn: string, DataSetId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, ImportMode: string, RowLevelPermissionDataSet: record, RowLevelPermissionTagConfigurationApplied: bool, ColumnLevelPermissionRulesApplied: bool>, NextToken: string, RequestId: string, Status: int>
# operationId: ListDataSets
export def "list-data-sets" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sets"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a data source.
#
# POST /accounts/{AwsAccountId}/data-sources
# Returns: record<Arn: string, DataSourceId: string, CreationStatus: string, RequestId: string, Status: int>
# operationId: CreateDataSource
export def "create-data-source" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  data_source_id: string # An ID for the data source. This ID is unique per Amazon Web Services Region for each Amazon Web Services account.
  name: string # A display name for the data source.
  type: string@type-completer # The type of the data source. To return a list of all data sources, use ListDataSources. Use AMAZON_ELASTICSEARCH for Amazon OpenSearch Service.
  --data-source-parameters: record # The parameters that Amazon QuickSight uses to connect to your underlying data source. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {AmazonElasticsearchParameters?: record, AthenaParameters?: record, AuroraParameters?: record, AuroraPostgreSqlParameters?: record, AwsIotAnalyticsParameters?: record, JiraParameters?: record, MariaDbParameters?: record, MySqlParameters?: record, OracleParameters?: record, PostgreSqlParameters?: record, PrestoParameters?: record, RdsParameters?: record, RedshiftParameters?: record, S3Parameters?: record, ServiceNowParameters?: record, SnowflakeParameters?: record, SparkParameters?: record, ... (6 more fields)}
  --credentials: record # Data source credentials. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {CredentialPair?: record, CopySourceArn?: string, SecretArn?: string}
  --permissions: list # A list of resource permissions on the data source. — item shape: {Principal: string, Actions: list<string>}
  --vpc-connection-properties: record # VPC connection properties. — shape: {VpcConnectionArn?: string}
  --ssl-properties: record # Secure Socket Layer (SSL) properties that apply when Amazon QuickSight connects to your underlying data source. — shape: {DisableSsl?: bool}
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the data source. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/data-sources"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSourceId, var: data_source_id}, {name: Name, var: name}, {name: Type, var: type}, {name: DataSourceParameters, var: data_source_parameters}, {name: Credentials, var: credentials}, {name: Permissions, var: permissions}, {name: VpcConnectionProperties, var: vpc_connection_properties}, {name: SslProperties, var: ssl_properties}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, data_source_id: $data_source_id, name: $name, type: $type, data_source_parameters: $data_source_parameters, credentials: $credentials, permissions: $permissions, vpc_connection_properties: $vpc_connection_properties, ssl_properties: $ssl_properties, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists data sources in current Amazon Web Services Region that belong to this Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/data-sources
# Returns: record<DataSources: table<Arn: string, DataSourceId: string, Name: string, Type: string, Status: string, CreatedTime: string, LastUpdatedTime: string, DataSourceParameters: record, AlternateDataSourceParameters: list, VpcConnectionProperties: record, SslProperties: record, ErrorInfo: record, SecretArn: string>, NextToken: string, RequestId: string, Status: int>
# operationId: ListDataSources
export def "list-data-sources" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sources"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an empty shared folder.
#
# POST /accounts/{AwsAccountId}/folders/{FolderId}
# Returns: record<Status: int, Arn: string, FolderId: string, RequestId: string>
# operationId: CreateFolder
export def "create-folder" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --name: string # The name of the folder.
  --folder-type: string@folder-type-completer # The type of folder. By default, folderType is SHARED.
  --parent-folder-arn: string # The Amazon Resource Name (ARN) for the parent folder. ParentFolderArn can be null. An empty parentFolderArn creates a root-level folder.
  --permissions: list # A structure that describes the principals and the resource-level permissions of a folder. To specify no permissions, omit Permissions. — item shape: {Principal: string, Actions: list<string>}
  --tags: list # Tags for the folder. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/folders/{FolderId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: FolderType, var: folder_type}, {name: ParentFolderArn, var: parent_folder_arn}, {name: Permissions, var: permissions}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, folder_type: $folder_type, parent_folder_arn: $parent_folder_arn, permissions: $permissions, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an empty folder.
#
# DELETE /accounts/{AwsAccountId}/folders/{FolderId}
# Returns: record<Status: int, Arn: string, FolderId: string, RequestId: string>
# operationId: DeleteFolder
export def "delete-folder" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/folders/{FolderId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a folder.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}
# Returns: record<Status: int, Folder: record<FolderId: string, Arn: string, Name: string, FolderType: string, FolderPath: list<string>, CreatedTime: string, LastUpdatedTime: string>, RequestId: string>
# operationId: DescribeFolder
export def "describe-folder" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/folders/{FolderId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the name of a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}
# Returns: record<Status: int, Arn: string, FolderId: string, RequestId: string>
# operationId: UpdateFolder
export def "update-folder" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The name of the folder.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/folders/{FolderId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an asset, such as a dashboard, analysis, or dataset into a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}/members/{MemberType}/{MemberId}
# Returns: record<Status: int, FolderMember: record<MemberId: string, MemberType: string>, RequestId: string>
# operationId: CreateFolderMembership
export def "create-folder-membership" [
  aws_account_id: string
  folder_id: string
  member_type: string@member-type-completer
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/accounts/{AwsAccountId}/folders/{FolderId}/members/{MemberType}/{MemberId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}, {name: MemberType, var: member_type}, {name: MemberId, var: member_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, member_type: $member_type, member_id: $member_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes an asset, such as a dashboard, analysis, or dataset, from a folder.
#
# DELETE /accounts/{AwsAccountId}/folders/{FolderId}/members/{MemberType}/{MemberId}
# Returns: record<Status: int, RequestId: string>
# operationId: DeleteFolderMembership
export def "delete-folder-membership" [
  aws_account_id: string
  folder_id: string
  member_type: string@member-type-completer
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/folders/{FolderId}/members/{MemberType}/{MemberId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}, {name: MemberType, var: member_type}, {name: MemberId, var: member_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, member_type: $member_type, member_id: $member_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the CreateGroup operation to create a group in Amazon QuickSight. You can create up to 10,000 groups in a namespace. If you want to create more than 10,000 groups in a namespace, contact AWS Support. The permissions resource is arn:aws:quicksight:<your-region>:<relevant-aws-account-id>:group/default/<group-name> . The response is a group object.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/groups
# Returns: record<Group: record<Arn: string, GroupName: string, Description: string, PrincipalId: string>, RequestId: string, Status: int>
# operationId: CreateGroup
export def "create-group" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  group_name: string # A name for the group that you want to create.
  --description: string # A description for the group that you want to create.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GroupName, var: group_name}, {name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, group_name: $group_name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all user groups in Amazon QuickSight.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups
# Returns: record<GroupList: table<Arn: string, GroupName: string, Description: string, PrincipalId: string>, NextToken: string, RequestId: string, Status: int>
# operationId: ListGroups
export def "list-groups" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds an Amazon QuickSight user to an Amazon QuickSight group.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# Returns: record<GroupMember: record<Arn: string, MemberName: string>, RequestId: string, Status: int>
# operationId: CreateGroupMembership
export def "create-group-membership" [
  aws_account_id: string
  namespace: string
  group_name: string
  member_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: GroupName, var: group_name}, {name: MemberName, var: member_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, group_name: $group_name, member_name: $member_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from a group so that the user is no longer a member of the group.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# Returns: record<RequestId: string, Status: int>
# operationId: DeleteGroupMembership
export def "delete-group-membership" [
  aws_account_id: string
  namespace: string
  group_name: string
  member_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: GroupName, var: group_name}, {name: MemberName, var: member_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, group_name: $group_name, member_name: $member_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the DescribeGroupMembership operation to determine if a user is a member of the specified group. If the user exists and is a member of the specified group, an associated GroupMember object is returned.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}
# Returns: record<GroupMember: record<Arn: string, MemberName: string>, RequestId: string, Status: int>
# operationId: DescribeGroupMembership
export def "describe-group-membership" [
  aws_account_id: string
  namespace: string
  group_name: string
  member_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: GroupName, var: group_name}, {name: MemberName, var: member_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, group_name: $group_name, member_name: $member_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy assignment is attached to the specified groups or users of Amazon QuickSight. Assignment names are unique per Amazon Web Services account. To avoid overwriting rules in other namespaces, use assignment names that are unique.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/
# Returns: record<AssignmentName: string, AssignmentId: string, AssignmentStatus: string, PolicyArn: string, Identities: record, RequestId: string, Status: int>
# operationId: CreateIAMPolicyAssignment
export def "create-iam-policy-assignment" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  assignment_name: string # The name of the assignment, also called a rule. It must be unique within an Amazon Web Services account.
  assignment_status: string@assignment-status-completer # The status of the assignment. Possible values are as follows: ENABLED - Anything specified in this assignment is used when creating the data source. DISABLED - This assignment isn't used when creating the data source. DRAFT - This assignment is an unfinished draft and isn't used when creating the data source.
  --policy-arn: string # The ARN for the IAM policy to apply to the Amazon QuickSight users and groups specified in this assignment.
  --identities: record # The Amazon QuickSight users, groups, or both that you want to assign the policy to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssignmentName, var: assignment_name}, {name: AssignmentStatus, var: assignment_status}, {name: PolicyArn, var: policy_arn}, {name: Identities, var: identities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, assignment_name: $assignment_name, assignment_status: $assignment_status, policy_arn: $policy_arn, identities: $identities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# (Enterprise edition only) Creates a new namespace for you to use with Amazon QuickSight. A namespace allows you to isolate the Amazon QuickSight users and groups that are registered for that namespace. Users that access the namespace can share assets only with other users or groups in the same namespace. They can't see users and groups in other namespaces. You can create a namespace after your Amazon Web Services account is subscribed to Amazon QuickSight. The namespace must be unique within the Amazon Web Services account. By default, there is a limit of 100 namespaces per Amazon Web Services account. To increase your limit, create a ticket with Amazon Web Services Support.
#
# POST /accounts/{AwsAccountId}
# Returns: record<Arn: string, Name: string, CapacityRegion: string, CreationStatus: string, IdentityStore: string, RequestId: string, Status: int>
# operationId: CreateNamespace
export def "create-namespace" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  namespace: string # The name that you want to use to describe the new namespace.
  identity_store: string@identity-store-completer # Specifies the type of your user identity directory. Currently, this supports users with an identity type of QUICKSIGHT.
  --tags: list # The tags that you want to associate with the namespace that you're creating. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Namespace, var: namespace}, {name: IdentityStore, var: identity_store}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, namespace: $namespace, identity_store: $identity_store, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a refresh schedule for a dataset. You can create up to 5 different schedules for a single dataset.
#
# POST /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# Returns: record<Status: int, RequestId: string, ScheduleId: string, Arn: string>
# operationId: CreateRefreshSchedule
export def "create-refresh-schedule" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  schedule: record # The refresh schedule of a dataset. — shape: {ScheduleId?: string, ScheduleFrequency?: record, StartAfterDateTime?: string, RefreshType?: "INCREMENTAL_REFRESH"|"FULL_REFRESH", Arn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the refresh schedules of a dataset. Each dataset can have up to 5 schedules.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# Returns: record<RefreshSchedules: table<ScheduleId: string, ScheduleFrequency: record, StartAfterDateTime: string, RefreshType: string, Arn: string>, Status: int, RequestId: string>
# operationId: ListRefreshSchedules
export def "list-refresh-schedules" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a refresh schedule for a dataset.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules
# Returns: record<Status: int, RequestId: string, ScheduleId: string, Arn: string>
# operationId: UpdateRefreshSchedule
export def "update-refresh-schedule" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  schedule: record # The refresh schedule of a dataset. — shape: {ScheduleId?: string, ScheduleFrequency?: record, StartAfterDateTime?: string, RefreshType?: "INCREMENTAL_REFRESH"|"FULL_REFRESH", Arn?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Schedule, var: schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, schedule: $schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a template either from a TemplateDefinition or from an existing Amazon QuickSight analysis or template. You can use the resulting template to create additional dashboards, templates, or analyses. A template is an entity in Amazon QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.
#
# POST /accounts/{AwsAccountId}/templates/{TemplateId}
# Returns: record<Arn: string, VersionArn: string, TemplateId: string, CreationStatus: string, Status: int, RequestId: string>
# operationId: CreateTemplate
export def "create-template" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --name: string # A display name for the template.
  --permissions: list # A list of resource permissions to be set on the template. — item shape: {Principal: string, Actions: list<string>}
  --source-entity: record # The source entity of the template. — shape: {SourceAnalysis?: record, SourceTemplate?: record}
  --tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the resource. — item shape: {Key: string, Value: string}
  --version-description: string # A description of the current template version being created. This API operation creates the first version of the template. Every time UpdateTemplate is called, a new version is created. Each version of the template maintains a description of the version in the VersionDescription field.
  --definition: record # The detailed definition of a template. — shape: {DataSetConfigurations?: list, Sheets?: list, CalculatedFields?: list, ParameterDeclarations?: list, FilterGroups?: list, ColumnConfigurations?: list, AnalysisDefaults?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: Permissions, var: permissions}, {name: SourceEntity, var: source_entity}, {name: Tags, var: tags}, {name: VersionDescription, var: version_description}, {name: Definition, var: definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, permissions: $permissions, source_entity: $source_entity, tags: $tags, version_description: $version_description, definition: $definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a template.
#
# DELETE /accounts/{AwsAccountId}/templates/{TemplateId}
# Returns: record<RequestId: string, Arn: string, TemplateId: string, Status: int>
# operationId: DeleteTemplate
export def "delete-template" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # Specifies the version of the template that you want to delete. If you don't provide a version number, DeleteTemplate deletes all versions of the template.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    query: [{name: version-number, var: version_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, version_number: $version_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a template's metadata.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}
# Returns: record<Template: record<Arn: string, Name: string, Version: record<CreatedTime: string, Errors: list, VersionNumber: int, Status: string, DataSetConfigurations: list, Description: string, SourceEntityArn: string, ThemeArn: string, Sheets: list>, TemplateId: string, LastUpdatedTime: string, CreatedTime: string>, Status: int, RequestId: string>
# operationId: DescribeTemplate
export def "describe-template" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # (Optional) The number for the version to describe. If a VersionNumber parameter value isn't provided, the latest version of the template is described.
  --alias-name: string # The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword $LATEST in the AliasName parameter. The keyword $PUBLISHED doesn't apply to templates.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    query: [{name: version-number, var: version_number}, {name: alias-name, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, version_number: $version_number, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a template from an existing Amazon QuickSight analysis or another template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}
# Returns: record<TemplateId: string, Arn: string, VersionArn: string, CreationStatus: string, Status: int, RequestId: string>
# operationId: UpdateTemplate
export def "update-template" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --source-entity: record # The source entity of the template. — shape: {SourceAnalysis?: record, SourceTemplate?: record}
  --version-description: string # A description of the current template version that is being updated. Every time you call UpdateTemplate, you create a new version of the template. Each version of the template maintains a description of the version in the VersionDescription field.
  --name: string # The name for the template.
  --definition: record # The detailed definition of a template. — shape: {DataSetConfigurations?: list, Sheets?: list, CalculatedFields?: list, ParameterDeclarations?: list, FilterGroups?: list, ColumnConfigurations?: list, AnalysisDefaults?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SourceEntity, var: source_entity}, {name: VersionDescription, var: version_description}, {name: Name, var: name}, {name: Definition, var: definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_entity: $source_entity, version_description: $version_description, name: $name, definition: $definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a template alias for a template.
#
# POST /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# Returns: record<TemplateAlias: record<AliasName: string, Arn: string, TemplateVersionNumber: int>, Status: int, RequestId: string>
# operationId: CreateTemplateAlias
export def "create-template-alias" [
  aws_account_id: string
  template_id: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  template_version_number: int # The version number of the template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}, {name: AliasName, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TemplateVersionNumber, var: template_version_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, template_version_number: $template_version_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
#
# DELETE /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# Returns: record<Status: int, TemplateId: string, AliasName: string, Arn: string, RequestId: string>
# operationId: DeleteTemplateAlias
export def "delete-template-alias" [
  aws_account_id: string
  template_id: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}, {name: AliasName, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the template alias for a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# Returns: record<TemplateAlias: record<AliasName: string, Arn: string, TemplateVersionNumber: int>, Status: int, RequestId: string>
# operationId: DescribeTemplateAlias
export def "describe-template-alias" [
  aws_account_id: string
  template_id: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}, {name: AliasName, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the template alias of a template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}
# Returns: record<TemplateAlias: record<AliasName: string, Arn: string, TemplateVersionNumber: int>, Status: int, RequestId: string>
# operationId: UpdateTemplateAlias
export def "update-template-alias" [
  aws_account_id: string
  template_id: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  template_version_number: int # The version number of the template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}, {name: AliasName, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: TemplateVersionNumber, var: template_version_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, template_version_number: $template_version_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a theme. A theme is set of configuration options for color and layout. Themes apply to analyses and dashboards. For more information, see Using Themes in Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/themes-in-quicksight.html) in the Amazon QuickSight User Guide.
#
# POST /accounts/{AwsAccountId}/themes/{ThemeId}
# Returns: record<Arn: string, VersionArn: string, ThemeId: string, CreationStatus: string, Status: int, RequestId: string>
# operationId: CreateTheme
export def "create-theme" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A display name for the theme.
  base_theme_id: string # The ID of the theme that a custom theme will inherit from. All themes inherit from one of the starting themes defined by Amazon QuickSight. For a list of the starting themes, use ListThemes or choose Themes from within an analysis.
  --version-description: string # A description of the first version of the theme that you're creating. Every time UpdateTheme is called, a new version is created. Each version of the theme has a description of the version in the VersionDescription field.
  configuration: record # The theme configuration. This configuration contains all of the display properties for a theme. — shape: {DataColorPalette?: record, UIColorPalette?: record, Sheet?: record, Typography?: record}
  --permissions: list # A valid grouping of resource permissions to apply to the new theme. — item shape: {Principal: string, Actions: list<string>}
  --tags: list # A map of the key-value pairs for the resource tag or tags that you want to add to the resource. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: BaseThemeId, var: base_theme_id}, {name: VersionDescription, var: version_description}, {name: Configuration, var: configuration}, {name: Permissions, var: permissions}, {name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, base_theme_id: $base_theme_id, version_description: $version_description, configuration: $configuration, permissions: $permissions, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a theme.
#
# DELETE /accounts/{AwsAccountId}/themes/{ThemeId}
# Returns: record<Arn: string, RequestId: string, Status: int, ThemeId: string>
# operationId: DeleteTheme
export def "delete-theme" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version of the theme that you want to delete. Note: If you don't provide a version number, you're using this call to DeleteTheme to delete all versions of the theme.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}]
    query: [{name: version-number, var: version_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, version_number: $version_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}
# Returns: record<Theme: record<Arn: string, Name: string, ThemeId: string, Version: record<VersionNumber: int, Arn: string, Description: string, BaseThemeId: string, CreatedTime: string, Configuration: record, Errors: list, Status: string>, CreatedTime: string, LastUpdatedTime: string, Type: string>, Status: int, RequestId: string>
# operationId: DescribeTheme
export def "describe-theme" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the version to describe. If a VersionNumber parameter value isn't provided, the latest version of the theme is described.
  --alias-name: string # The alias of the theme that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the theme by providing the keyword $LATEST in the AliasName parameter. The keyword $PUBLISHED doesn't apply to themes.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}]
    query: [{name: version-number, var: version_number}, {name: alias-name, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, version_number: $version_number, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a theme.
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}
# Returns: record<ThemeId: string, Arn: string, VersionArn: string, CreationStatus: string, Status: int, RequestId: string>
# operationId: UpdateTheme
export def "update-theme" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --name: string # The name for the theme.
  base_theme_id: string # The theme ID, defined by Amazon QuickSight, that a custom theme inherits from. All themes initially inherit from a default Amazon QuickSight theme.
  --version-description: string # A description of the theme version that you're updating Every time that you call UpdateTheme, you create a new version of the theme. Each version of the theme maintains a description of the version in VersionDescription.
  --configuration: record # The theme configuration. This configuration contains all of the display properties for a theme. — shape: {DataColorPalette?: record, UIColorPalette?: record, Sheet?: record, Typography?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: BaseThemeId, var: base_theme_id}, {name: VersionDescription, var: version_description}, {name: Configuration, var: configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, base_theme_id: $base_theme_id, version_description: $version_description, configuration: $configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a theme alias for a theme.
#
# POST /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# Returns: record<ThemeAlias: record<Arn: string, AliasName: string, ThemeVersionNumber: int>, Status: int, RequestId: string>
# operationId: CreateThemeAlias
export def "create-theme-alias" [
  aws_account_id: string
  theme_id: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  theme_version_number: int # The version number of the theme.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}, {name: AliasName, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ThemeVersionNumber, var: theme_version_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, theme_version_number: $theme_version_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the version of the theme that the specified theme alias points to. If you provide a specific alias, you delete the version of the theme that the alias points to.
#
# DELETE /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# Returns: record<AliasName: string, Arn: string, RequestId: string, Status: int, ThemeId: string>
# operationId: DeleteThemeAlias
export def "delete-theme-alias" [
  aws_account_id: string
  theme_id: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}, {name: AliasName, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the alias for a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# Returns: record<ThemeAlias: record<Arn: string, AliasName: string, ThemeVersionNumber: int>, Status: int, RequestId: string>
# operationId: DescribeThemeAlias
export def "describe-theme-alias" [
  aws_account_id: string
  theme_id: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}, {name: AliasName, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an alias of a theme.
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}
# Returns: record<ThemeAlias: record<Arn: string, AliasName: string, ThemeVersionNumber: int>, Status: int, RequestId: string>
# operationId: UpdateThemeAlias
export def "update-theme-alias" [
  aws_account_id: string
  theme_id: string
  alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  theme_version_number: int # The version number of the theme that the alias should reference.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}/aliases/{AliasName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}, {name: AliasName, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ThemeVersionNumber, var: theme_version_number}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, theme_version_number: $theme_version_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}
# Returns: record<Arn: string, DataSetId: string, RequestId: string, Status: int>
# operationId: DeleteDataSet
export def "delete-data-set" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a dataset. This operation doesn't support datasets that include uploaded files as a source.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}
# Returns: record<DataSet: record<Arn: string, DataSetId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, PhysicalTableMap: record, LogicalTableMap: record, OutputColumns: list<record>, ImportMode: string, ConsumedSpiceCapacityInBytes: int, ColumnGroups: list<record>, FieldFolders: record, RowLevelPermissionDataSet: record<Namespace: string, Arn: string, PermissionPolicy: string, FormatVersion: string, Status: string>, RowLevelPermissionTagConfiguration: record<Status: string, TagRules: list, TagRuleConfigurations: list>, ColumnLevelPermissionRules: list<record>, DataSetUsageConfiguration: record<DisableUseAsDirectQuerySource: bool, DisableUseAsImportedSource: bool>>, RequestId: string, Status: int>
# operationId: DescribeDataSet
export def "describe-data-set" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a dataset. This operation doesn't support datasets that include uploaded files as a source. Partial updates are not supported by this operation.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}
# Returns: record<Arn: string, DataSetId: string, IngestionArn: string, IngestionId: string, RequestId: string, Status: int>
# operationId: UpdateDataSet
export def "update-data-set" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # The display name for the dataset.
  physical_table_map: record # Declares the physical tables that are available in the underlying data sources.
  --logical-table-map: record # Configures the combination and transformation of the data from the physical tables.
  import_mode: string@import-mode-completer # Indicates whether you want to import the data into SPICE.
  --column-groups: list # Groupings of columns that work together in certain Amazon QuickSight features. Currently, only geospatial hierarchy is supported. — item shape: {GeoSpatialColumnGroup?: record}
  --field-folders: record # The folder that contains fields and nested subfolders for your dataset.
  --row-level-permission-data-set: record # Information about a dataset that contains permissions for row-level security (RLS). The permissions dataset maps fields to users or groups. For more information, see Using Row-Level Security (RLS) to Restrict Access to a Dataset (https://docs.aws.amazon.com/quicksight/latest/user/restrict-access-to-a-data-set-using-row-level-security.html) in the Amazon QuickSight User Guide. The option to deny permissions by setting PermissionPolicy to DENY_ACCESS is not supported for new RLS datasets. — shape: {Namespace?: string, Arn?: string, PermissionPolicy?: "GRANT_ACCESS"|"DENY_ACCESS", FormatVersion?: "VERSION_1"|"VERSION_2", Status?: "ENABLED"|"DISABLED"}
  --row-level-permission-tag-configuration: record # The configuration of tags on a dataset to set row-level security. — shape: {Status?: "ENABLED"|"DISABLED", TagRules?: list, TagRuleConfigurations?: list}
  --column-level-permission-rules: list # A set of one or more definitions of a ColumnLevelPermissionRule (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_ColumnLevelPermissionRule.html) . — item shape: {Principals?: list<string>, ColumnNames?: list<string>}
  --data-set-usage-configuration: record # The usage configuration to apply to child datasets that reference this dataset as a source. — shape: {DisableUseAsDirectQuerySource?: bool, DisableUseAsImportedSource?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: PhysicalTableMap, var: physical_table_map}, {name: LogicalTableMap, var: logical_table_map}, {name: ImportMode, var: import_mode}, {name: ColumnGroups, var: column_groups}, {name: FieldFolders, var: field_folders}, {name: RowLevelPermissionDataSet, var: row_level_permission_data_set}, {name: RowLevelPermissionTagConfiguration, var: row_level_permission_tag_configuration}, {name: ColumnLevelPermissionRules, var: column_level_permission_rules}, {name: DataSetUsageConfiguration, var: data_set_usage_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, physical_table_map: $physical_table_map, logical_table_map: $logical_table_map, import_mode: $import_mode, column_groups: $column_groups, field_folders: $field_folders, row_level_permission_data_set: $row_level_permission_data_set, row_level_permission_tag_configuration: $row_level_permission_tag_configuration, column_level_permission_rules: $column_level_permission_rules, data_set_usage_configuration: $data_set_usage_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the dataset refresh properties of the dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# Returns: record<RequestId: string, Status: int>
# operationId: DeleteDataSetRefreshProperties
export def "delete-data-set-refresh-properties" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the refresh properties of a dataset.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# Returns: record<RequestId: string, Status: int, DataSetRefreshProperties: record<RefreshConfiguration: record<IncrementalRefresh: record>>>
# operationId: DescribeDataSetRefreshProperties
export def "describe-data-set-refresh-properties" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates the dataset refresh properties for the dataset.
#
# PUT /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties
# Returns: record<RequestId: string, Status: int>
# operationId: PutDataSetRefreshProperties
export def "put-data-set-refresh-properties" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  data_set_refresh_properties: record # The refresh properties of a dataset. — shape: {RefreshConfiguration?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-properties"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DataSetRefreshProperties, var: data_set_refresh_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, data_set_refresh_properties: $data_set_refresh_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the data source permanently. This operation breaks all the datasets that reference the deleted data source.
#
# DELETE /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# Returns: record<Arn: string, DataSourceId: string, RequestId: string, Status: int>
# operationId: DeleteDataSource
export def "delete-data-source" [
  aws_account_id: string
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSourceId, var: data_source_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_source_id: $data_source_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a data source.
#
# GET /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# Returns: record<DataSource: record<Arn: string, DataSourceId: string, Name: string, Type: string, Status: string, CreatedTime: string, LastUpdatedTime: string, DataSourceParameters: record<AmazonElasticsearchParameters: record, AthenaParameters: record, AuroraParameters: record, AuroraPostgreSqlParameters: record, AwsIotAnalyticsParameters: record, JiraParameters: record, MariaDbParameters: record, MySqlParameters: record, OracleParameters: record, PostgreSqlParameters: record, PrestoParameters: record, RdsParameters: record, RedshiftParameters: record, S3Parameters: record, ServiceNowParameters: record, SnowflakeParameters: record, SparkParameters: record, SqlServerParameters: record, TeradataParameters: record, TwitterParameters: record, AmazonOpenSearchParameters: record, ExasolParameters: record, DatabricksParameters: record>, AlternateDataSourceParameters: list<record>, VpcConnectionProperties: record<VpcConnectionArn: string>, SslProperties: record<DisableSsl: bool>, ErrorInfo: record<Type: string, Message: string>, SecretArn: string>, RequestId: string, Status: int>
# operationId: DescribeDataSource
export def "describe-data-source" [
  aws_account_id: string
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSourceId, var: data_source_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_source_id: $data_source_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a data source.
#
# PUT /accounts/{AwsAccountId}/data-sources/{DataSourceId}
# Returns: record<Arn: string, DataSourceId: string, UpdateStatus: string, RequestId: string, Status: int>
# operationId: UpdateDataSource
export def "update-data-source" [
  aws_account_id: string
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  name: string # A display name for the data source.
  --data-source-parameters: record # The parameters that Amazon QuickSight uses to connect to your underlying data source. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {AmazonElasticsearchParameters?: record, AthenaParameters?: record, AuroraParameters?: record, AuroraPostgreSqlParameters?: record, AwsIotAnalyticsParameters?: record, JiraParameters?: record, MariaDbParameters?: record, MySqlParameters?: record, OracleParameters?: record, PostgreSqlParameters?: record, PrestoParameters?: record, RdsParameters?: record, RedshiftParameters?: record, S3Parameters?: record, ServiceNowParameters?: record, SnowflakeParameters?: record, SparkParameters?: record, ... (6 more fields)}
  --credentials: record # Data source credentials. This is a variant type structure. For this structure to be valid, only one of the attributes can be non-null. — shape: {CredentialPair?: record, CopySourceArn?: string, SecretArn?: string}
  --vpc-connection-properties: record # VPC connection properties. — shape: {VpcConnectionArn?: string}
  --ssl-properties: record # Secure Socket Layer (SSL) properties that apply when Amazon QuickSight connects to your underlying data source. — shape: {DisableSsl?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSourceId, var: data_source_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Name, var: name}, {name: DataSourceParameters, var: data_source_parameters}, {name: Credentials, var: credentials}, {name: VpcConnectionProperties, var: vpc_connection_properties}, {name: SslProperties, var: ssl_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_source_id: $data_source_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, name: $name, data_source_parameters: $data_source_parameters, credentials: $credentials, vpc_connection_properties: $vpc_connection_properties, ssl_properties: $ssl_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user group from Amazon QuickSight.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# Returns: record<RequestId: string, Status: int>
# operationId: DeleteGroup
export def "delete-group" [
  aws_account_id: string
  namespace: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: GroupName, var: group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, group_name: $group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN).
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# Returns: record<Group: record<Arn: string, GroupName: string, Description: string, PrincipalId: string>, RequestId: string, Status: int>
# operationId: DescribeGroup
export def "describe-group" [
  aws_account_id: string
  namespace: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: GroupName, var: group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, group_name: $group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Changes a group description.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}
# Returns: record<Group: record<Arn: string, GroupName: string, Description: string, PrincipalId: string>, RequestId: string, Status: int>
# operationId: UpdateGroup
export def "update-group" [
  aws_account_id: string
  namespace: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # The description for the group that you want to update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: GroupName, var: group_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, group_name: $group_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing IAM policy assignment.
#
# DELETE /accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}
# Returns: record<AssignmentName: string, RequestId: string, Status: int>
# operationId: DeleteIAMPolicyAssignment
export def "delete-iam-policy-assignment" [
  aws_account_id: string
  namespace: string
  assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: AssignmentName, var: assignment_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, assignment_name: $assignment_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a namespace and the users and groups that are associated with the namespace. This is an asynchronous process. Assets including dashboards, analyses, datasets and data sources are not deleted. To delete these assets, you use the API operations for the relevant asset.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}
# Returns: record<RequestId: string, Status: int>
# operationId: DeleteNamespace
export def "delete-namespace" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the current namespace.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}
# Returns: record<Namespace: record<Name: string, Arn: string, CapacityRegion: string, CreationStatus: string, IdentityStore: string, NamespaceError: record<Type: string, Message: string>>, RequestId: string, Status: int>
# operationId: DescribeNamespace
export def "describe-namespace" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a refresh schedule from a dataset.
#
# DELETE /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules/{ScheduleId}
# Returns: record<Status: int, RequestId: string, ScheduleId: string, Arn: string>
# operationId: DeleteRefreshSchedule
export def "delete-refresh-schedule" [
  aws_account_id: string
  data_set_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules/{ScheduleId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}, {name: ScheduleId, var: schedule_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, schedule_id: $schedule_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a summary of a refresh schedule.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules/{ScheduleId}
# Returns: record<RefreshSchedule: record<ScheduleId: string, ScheduleFrequency: record<Interval: string, RefreshOnDay: record, Timezone: string, TimeOfTheDay: string>, StartAfterDateTime: string, RefreshType: string, Arn: string>, Status: int, RequestId: string, Arn: string>
# operationId: DescribeRefreshSchedule
export def "describe-refresh-schedule" [
  aws_account_id: string
  data_set_id: string
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/refresh-schedules/{ScheduleId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}, {name: ScheduleId, var: schedule_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, schedule_id: $schedule_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the Amazon QuickSight user that is associated with the identity of the IAM user or role that's making the call. The IAM user isn't deleted as a result of this call.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# Returns: record<RequestId: string, Status: int>
# operationId: DeleteUser
export def "delete-user" [
  aws_account_id: string
  namespace: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: UserName, var: user_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, user_name: $user_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about a user, given the user name.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# Returns: record<User: record<Arn: string, UserName: string, Email: string, Role: string, IdentityType: string, Active: bool, PrincipalId: string, CustomPermissionsName: string, ExternalLoginFederationProviderType: string, ExternalLoginFederationProviderUrl: string, ExternalLoginId: string>, RequestId: string, Status: int>
# operationId: DescribeUser
export def "describe-user" [
  aws_account_id: string
  namespace: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: UserName, var: user_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, user_name: $user_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an Amazon QuickSight user.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}
# Returns: record<User: record<Arn: string, UserName: string, Email: string, Role: string, IdentityType: string, Active: bool, PrincipalId: string, CustomPermissionsName: string, ExternalLoginFederationProviderType: string, ExternalLoginFederationProviderUrl: string, ExternalLoginId: string>, RequestId: string, Status: int>
# operationId: UpdateUser
export def "update-user" [
  aws_account_id: string
  namespace: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  email: string # The email address of the user that you want to update.
  role: string@role-completer # The Amazon QuickSight role of the user. The role can be one of the following default security cohorts: READER: A user who has read-only access to dashboards. AUTHOR: A user who can create data sources, datasets, analyses, and dashboards. ADMIN: A user who is an author, who can also manage Amazon QuickSight settings. The name of the Amazon QuickSight role is invisible to the user except for the console screens dealing with permissions.
  --custom-permissions-name: string # (Enterprise edition only) The name of the custom permissions profile that you want to assign to this user. Customized permissions allows you to control a user's access by restricting access the following operations: Create and update data sources Create and update datasets Create and update email reports Subscribe to email reports A set of custom permissions includes any combination of these restrictions. Currently, you need to create the profile names for custom permission sets by using the Amazon QuickSight console. Then, you use the RegisterUser API operation to assign the named set of permissions to a Amazon QuickSight user. Amazon QuickSight custom permissions are applied through IAM policies. Therefore, they override the permissions typically granted by assigning Amazon QuickSight users to one of the default security cohorts in Amazon QuickSight (admin, author, reader). This feature is available only to Amazon QuickSight Enterprise edition subscriptions.
  --unapply-custom-permissions: oneof<nothing, bool> # A flag that you use to indicate that you want to remove all custom permissions from this user. Using this parameter resets the user to the state it was in before a custom permissions profile was applied. This parameter defaults to NULL and it doesn't accept any other value.
  --external-login-federation-provider-type: string # The type of supported external login provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. The type of supported external login provider can be one of the following. COGNITO: Amazon Cognito. The provider URL is cognito-identity.amazonaws.com. When choosing the COGNITO provider type, don’t use the "CustomFederationProviderUrl" parameter which is only needed when the external provider is custom. CUSTOM_OIDC: Custom OpenID Connect (OIDC) provider. When choosing CUSTOM_OIDC type, use the CustomFederationProviderUrl parameter to provide the custom OIDC provider URL. NONE: This clears all the previously saved external login information for a user. Use the DescribeUser (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeUser.html) API operation to check the external login information.
  --custom-federation-provider-url: string # The URL of the custom OpenID Connect (OIDC) provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. This parameter should only be used when ExternalLoginFederationProviderType parameter is set to CUSTOM_OIDC.
  --external-login-id: string # The identity ID for a user in the external login provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: UserName, var: user_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Email, var: email}, {name: Role, var: role}, {name: CustomPermissionsName, var: custom_permissions_name}, {name: UnapplyCustomPermissions, var: unapply_custom_permissions}, {name: ExternalLoginFederationProviderType, var: external_login_federation_provider_type}, {name: CustomFederationProviderUrl, var: custom_federation_provider_url}, {name: ExternalLoginId, var: external_login_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, user_name: $user_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, email: $email, role: $role, custom_permissions_name: $custom_permissions_name, unapply_custom_permissions: $unapply_custom_permissions, external_login_federation_provider_type: $external_login_federation_provider_type, custom_federation_provider_url: $custom_federation_provider_url, external_login_id: $external_login_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a user identified by its principal ID.
#
# DELETE /accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}
# Returns: record<RequestId: string, Status: int>
# operationId: DeleteUserByPrincipalId
export def "delete-user-by-principal-id" [
  aws_account_id: string
  namespace: string
  principal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: PrincipalId, var: principal_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, principal_id: $principal_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the settings that were used when your Amazon QuickSight subscription was first created in this Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/settings
# Returns: record<AccountSettings: record<AccountName: string, Edition: string, DefaultNamespace: string, NotificationEmail: string, PublicSharingEnabled: bool, TerminationProtectionEnabled: bool>, RequestId: string, Status: int>
# operationId: DescribeAccountSettings
export def "describe-account-settings" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/settings"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the Amazon QuickSight settings in your Amazon Web Services account.
#
# PUT /accounts/{AwsAccountId}/settings
# Returns: record<RequestId: string, Status: int>
# operationId: UpdateAccountSettings
export def "update-account-settings" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  default_namespace: string # The default namespace for this Amazon Web Services account. Currently, the default is default. IAM users that register for the first time with Amazon QuickSight provide an email address that becomes associated with the default namespace.
  --notification-email: string # The email address that you want Amazon QuickSight to send notifications to regarding your Amazon Web Services account or Amazon QuickSight subscription.
  --termination-protection-enabled: oneof<nothing, bool> # A boolean value that determines whether or not an Amazon QuickSight account can be deleted. A True value doesn't allow the account to be deleted and results in an error message if a user tries to make a DeleteAccountSubscription request. A False value will allow the account to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/settings"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: DefaultNamespace, var: default_namespace}, {name: NotificationEmail, var: notification_email}, {name: TerminationProtectionEnabled, var: termination_protection_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, default_namespace: $default_namespace, notification_email: $notification_email, termination_protection_enabled: $termination_protection_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a detailed description of the definition of an analysis. If you do not need to know details about the content of an Analysis, for instance if you are trying to check the status of a recently created or updated Analysis, use the DescribeAnalysis (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeAnalysis.html) instead.
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}/definition
# Returns: record<AnalysisId: string, Name: string, Errors: table<Type: string, Message: string, ViolatedEntities: list>, ResourceStatus: string, ThemeArn: string, Definition: record<DataSetIdentifierDeclarations: list<record>, Sheets: list<record>, CalculatedFields: list<record>, ParameterDeclarations: list<record>, FilterGroups: list<record>, ColumnConfigurations: list<record>, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: int, RequestId: string>
# operationId: DescribeAnalysisDefinition
export def "describe-analysis-definition" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/analyses/{AnalysisId}/definition"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: AnalysisId, var: analysis_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, analysis_id: $analysis_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides the read and write permissions for an analysis.
#
# GET /accounts/{AwsAccountId}/analyses/{AnalysisId}/permissions
# Returns: record<AnalysisId: string, AnalysisArn: string, Permissions: table<Principal: string, Actions: list>, Status: int, RequestId: string>
# operationId: DescribeAnalysisPermissions
export def "describe-analysis-permissions" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/analyses/{AnalysisId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: AnalysisId, var: analysis_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, analysis_id: $analysis_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the read and write permissions for an analysis.
#
# PUT /accounts/{AwsAccountId}/analyses/{AnalysisId}/permissions
# Returns: record<AnalysisArn: string, AnalysisId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>
# operationId: UpdateAnalysisPermissions
export def "update-analysis-permissions" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --grant-permissions: list # A structure that describes the permissions to add and the principal to add them to. — item shape: {Principal: string, Actions: list<string>}
  --revoke-permissions: list # A structure that describes the permissions to remove and the principal to remove them from. — item shape: {Principal: string, Actions: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/analyses/{AnalysisId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: AnalysisId, var: analysis_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantPermissions, var: grant_permissions}, {name: RevokePermissions, var: revoke_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, analysis_id: $analysis_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, grant_permissions: $grant_permissions, revoke_permissions: $revoke_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a detailed description of the definition of a dashboard. If you do not need to know details about the content of a dashboard, for instance if you are trying to check the status of a recently created or updated dashboard, use the DescribeDashboard (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeDashboard.html) instead.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/definition
# Returns: record<DashboardId: string, Errors: table<Type: string, Message: string, ViolatedEntities: list>, Name: string, ResourceStatus: string, ThemeArn: string, Definition: record<DataSetIdentifierDeclarations: list<record>, Sheets: list<record>, CalculatedFields: list<record>, ParameterDeclarations: list<record>, FilterGroups: list<record>, ColumnConfigurations: list<record>, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: int, RequestId: string, DashboardPublishOptions: record<AdHocFilteringOption: record<AvailabilityStatus: string>, ExportToCSVOption: record<AvailabilityStatus: string>, SheetControlsOption: record<VisibilityState: string>, VisualPublishOptions: record<ExportHiddenFieldsOption: record>, SheetLayoutElementMaximizationOption: record<AvailabilityStatus: string>, VisualMenuOption: record<AvailabilityStatus: string>, VisualAxisSortOption: record<AvailabilityStatus: string>, ExportWithHiddenFieldsOption: record<AvailabilityStatus: string>, DataPointDrillUpDownOption: record<AvailabilityStatus: string>, DataPointMenuLabelOption: record<AvailabilityStatus: string>, DataPointTooltipOption: record<AvailabilityStatus: string>>>
# operationId: DescribeDashboardDefinition
export def "describe-dashboard-definition" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described.
  --alias-name: string # The alias name.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/definition"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    query: [{name: version-number, var: version_number}, {name: alias-name, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, version_number: $version_number, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes read and write permissions for a dashboard.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions
# Returns: record<DashboardId: string, DashboardArn: string, Permissions: table<Principal: string, Actions: list>, Status: int, RequestId: string, LinkSharingConfiguration: record<Permissions: list<record>>>
# operationId: DescribeDashboardPermissions
export def "describe-dashboard-permissions" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates read and write permissions on a dashboard.
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions
# Returns: record<DashboardArn: string, DashboardId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int, LinkSharingConfiguration: record<Permissions: list<record>>>
# operationId: UpdateDashboardPermissions
export def "update-dashboard-permissions" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --grant-permissions: list # The permissions that you want to grant on this resource. — item shape: {Principal: string, Actions: list<string>}
  --revoke-permissions: list # The permissions that you want to revoke from this resource. — item shape: {Principal: string, Actions: list<string>}
  --grant-link-permissions: list # Grants link permissions to all users in a defined namespace. — item shape: {Principal: string, Actions: list<string>}
  --revoke-link-permissions: list # Revokes link permissions from all users in a defined namespace. — item shape: {Principal: string, Actions: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantPermissions, var: grant_permissions}, {name: RevokePermissions, var: revoke_permissions}, {name: GrantLinkPermissions, var: grant_link_permissions}, {name: RevokeLinkPermissions, var: revoke_link_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, grant_permissions: $grant_permissions, revoke_permissions: $revoke_permissions, grant_link_permissions: $grant_link_permissions, revoke_link_permissions: $revoke_link_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the permissions on a dataset. The permissions resource is arn:aws:quicksight:region:aws-account-id:dataset/data-set-id.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions
# Returns: record<DataSetArn: string, DataSetId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>
# operationId: DescribeDataSetPermissions
export def "describe-data-set-permissions" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the permissions on a dataset. The permissions resource is arn:aws:quicksight:region:aws-account-id:dataset/data-set-id.
#
# POST /accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions
# Returns: record<DataSetArn: string, DataSetId: string, RequestId: string, Status: int>
# operationId: UpdateDataSetPermissions
export def "update-data-set-permissions" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --grant-permissions: list # The resource permissions that you want to grant to the dataset. — item shape: {Principal: string, Actions: list<string>}
  --revoke-permissions: list # The resource permissions that you want to revoke from the dataset. — item shape: {Principal: string, Actions: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantPermissions, var: grant_permissions}, {name: RevokePermissions, var: revoke_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, grant_permissions: $grant_permissions, revoke_permissions: $revoke_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the resource permissions for a data source.
#
# GET /accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions
# Returns: record<DataSourceArn: string, DataSourceId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>
# operationId: DescribeDataSourcePermissions
export def "describe-data-source-permissions" [
  aws_account_id: string
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSourceId, var: data_source_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_source_id: $data_source_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the permissions to a data source.
#
# POST /accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions
# Returns: record<DataSourceArn: string, DataSourceId: string, RequestId: string, Status: int>
# operationId: UpdateDataSourcePermissions
export def "update-data-source-permissions" [
  aws_account_id: string
  data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --grant-permissions: list # A list of resource permissions that you want to grant on the data source. — item shape: {Principal: string, Actions: list<string>}
  --revoke-permissions: list # A list of resource permissions that you want to revoke on the data source. — item shape: {Principal: string, Actions: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSourceId, var: data_source_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantPermissions, var: grant_permissions}, {name: RevokePermissions, var: revoke_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_source_id: $data_source_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, grant_permissions: $grant_permissions, revoke_permissions: $revoke_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes permissions for a folder.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/permissions
# Returns: record<Status: int, FolderId: string, Arn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string>
# operationId: DescribeFolderPermissions
export def "describe-folder-permissions" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/folders/{FolderId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates permissions of a folder.
#
# PUT /accounts/{AwsAccountId}/folders/{FolderId}/permissions
# Returns: record<Status: int, Arn: string, FolderId: string, Permissions: table<Principal: string, Actions: list>, RequestId: string>
# operationId: UpdateFolderPermissions
export def "update-folder-permissions" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --grant-permissions: list # The permissions that you want to grant on a resource. — item shape: {Principal: string, Actions: list<string>}
  --revoke-permissions: list # The permissions that you want to revoke from a resource. — item shape: {Principal: string, Actions: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/folders/{FolderId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantPermissions, var: grant_permissions}, {name: RevokePermissions, var: revoke_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, grant_permissions: $grant_permissions, revoke_permissions: $revoke_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the folder resolved permissions. Permissions consists of both folder direct permissions and the inherited permissions from the ancestor folders.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/resolved-permissions
# Returns: record<Status: int, FolderId: string, Arn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string>
# operationId: DescribeFolderResolvedPermissions
export def "describe-folder-resolved-permissions" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/folders/{FolderId}/resolved-permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes an existing IAM policy assignment, as specified by the assignment name.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}
# Returns: record<IAMPolicyAssignment: record<AwsAccountId: string, AssignmentId: string, AssignmentName: string, PolicyArn: string, Identities: record, AssignmentStatus: string>, RequestId: string, Status: int>
# operationId: DescribeIAMPolicyAssignment
export def "describe-iam-policy-assignment" [
  aws_account_id: string
  namespace: string
  assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: AssignmentName, var: assignment_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, assignment_name: $assignment_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request. This overwrites all of the users included in Identities.
#
# PUT /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}
# Returns: record<AssignmentName: string, AssignmentId: string, PolicyArn: string, Identities: record, AssignmentStatus: string, RequestId: string, Status: int>
# operationId: UpdateIAMPolicyAssignment
export def "update-iam-policy-assignment" [
  aws_account_id: string
  namespace: string
  assignment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --assignment-status: string@assignment-status-completer # The status of the assignment. Possible values are as follows: ENABLED - Anything specified in this assignment is used when creating the data source. DISABLED - This assignment isn't used when creating the data source. DRAFT - This assignment is an unfinished draft and isn't used when creating the data source.
  --policy-arn: string # The ARN for the IAM policy to apply to the Amazon QuickSight users and groups specified in this assignment.
  --identities: record # The Amazon QuickSight users, groups, or both that you want to assign the policy to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: AssignmentName, var: assignment_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AssignmentStatus, var: assignment_status}, {name: PolicyArn, var: policy_arn}, {name: Identities, var: identities}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, assignment_name: $assignment_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, assignment_status: $assignment_status, policy_arn: $policy_arn, identities: $identities
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a summary and status of IP rules.
#
# GET /accounts/{AwsAccountId}/ip-restriction
# Returns: record<AwsAccountId: string, IpRestrictionRuleMap: record, Enabled: bool, RequestId: string, Status: int>
# operationId: DescribeIpRestriction
export def "describe-ip-restriction" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/ip-restriction"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the content and status of IP rules. To use this operation, you need to provide the entire map of rules. You can use the DescribeIpRestriction operation to get the current rule map.
#
# POST /accounts/{AwsAccountId}/ip-restriction
# Returns: record<AwsAccountId: string, RequestId: string, Status: int>
# operationId: UpdateIpRestriction
export def "update-ip-restriction" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --ip-restriction-rule-map: record # A map that describes the updated IP rules with CIDR ranges and descriptions.
  --enabled: oneof<nothing, bool> # A value that specifies whether IP rules are turned on.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/ip-restriction"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: IpRestrictionRuleMap, var: ip_restriction_rule_map}, {name: Enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, ip_restriction_rule_map: $ip_restriction_rule_map, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a detailed description of the definition of a template. If you do not need to know details about the content of a template, for instance if you are trying to check the status of a recently created or updated template, use the DescribeTemplate (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_DescribeTemplate.html) instead.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/definition
# Returns: record<Name: string, TemplateId: string, Errors: table<Type: string, Message: string, ViolatedEntities: list>, ResourceStatus: string, ThemeArn: string, Definition: record<DataSetConfigurations: list<record>, Sheets: list<record>, CalculatedFields: list<record>, ParameterDeclarations: list<record>, FilterGroups: list<record>, ColumnConfigurations: list<record>, AnalysisDefaults: record<DefaultNewSheetConfiguration: record>>, Status: int, RequestId: string>
# operationId: DescribeTemplateDefinition
export def "describe-template-definition" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-number: int # The version number of the template.
  --alias-name: string # The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword $LATEST in the AliasName parameter. The keyword $PUBLISHED doesn't apply to templates.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/definition"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    query: [{name: version-number, var: version_number}, {name: alias-name, var: alias_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, version_number: $version_number, alias_name: $alias_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes read and write permissions on a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/permissions
# Returns: record<TemplateId: string, TemplateArn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>
# operationId: DescribeTemplatePermissions
export def "describe-template-permissions" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the resource permissions for a template.
#
# PUT /accounts/{AwsAccountId}/templates/{TemplateId}/permissions
# Returns: record<TemplateId: string, TemplateArn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>
# operationId: UpdateTemplatePermissions
export def "update-template-permissions" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --grant-permissions: list # A list of resource permissions to be granted on the template. — item shape: {Principal: string, Actions: list<string>}
  --revoke-permissions: list # A list of resource permissions to be revoked from the template. — item shape: {Principal: string, Actions: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantPermissions, var: grant_permissions}, {name: RevokePermissions, var: revoke_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, grant_permissions: $grant_permissions, revoke_permissions: $revoke_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the read and write permissions for a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/permissions
# Returns: record<ThemeId: string, ThemeArn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>
# operationId: DescribeThemePermissions
export def "describe-theme-permissions" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the resource permissions for a theme. Permissions apply to the action to grant or revoke permissions on, for example "quicksight:DescribeTheme". Theme permissions apply in groupings. Valid groupings include the following for the three levels of permissions, which are user, owner, or no permissions: User "quicksight:DescribeTheme" "quicksight:DescribeThemeAlias" "quicksight:ListThemeAliases" "quicksight:ListThemeVersions" Owner "quicksight:DescribeTheme" "quicksight:DescribeThemeAlias" "quicksight:ListThemeAliases" "quicksight:ListThemeVersions" "quicksight:DeleteTheme" "quicksight:UpdateTheme" "quicksight:CreateThemeAlias" "quicksight:DeleteThemeAlias" "quicksight:UpdateThemeAlias" "quicksight:UpdateThemePermissions" "quicksight:DescribeThemePermissions" To specify no permissions, omit the permissions list.
#
# PUT /accounts/{AwsAccountId}/themes/{ThemeId}/permissions
# Returns: record<ThemeId: string, ThemeArn: string, Permissions: table<Principal: string, Actions: list>, RequestId: string, Status: int>
# operationId: UpdateThemePermissions
export def "update-theme-permissions" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --grant-permissions: list # A list of resource permissions to be granted for the theme. — item shape: {Principal: string, Actions: list<string>}
  --revoke-permissions: list # A list of resource permissions to be revoked from the theme. — item shape: {Principal: string, Actions: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}/permissions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: GrantPermissions, var: grant_permissions}, {name: RevokePermissions, var: revoke_permissions}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, grant_permissions: $grant_permissions, revoke_permissions: $revoke_permissions
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates an embed URL that you can use to embed an Amazon QuickSight dashboard or visual in your website, without having to register any reader users. Before you use this action, make sure that you have configured the dashboards and permissions. The following rules apply to the generated URL: It contains a temporary bearer token. It is valid for 5 minutes after it is generated. Once redeemed within this period, it cannot be re-used again. The URL validity period should not be confused with the actual session lifetime that can be customized using the SessionLifetimeInMinutes (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_GenerateEmbedUrlForAnonymousUser.html#QS-GenerateEmbedUrlForAnonymousUser-request-SessionLifetimeInMinutes) parameter. The resulting user session is valid for 15 minutes (minimum) to 10 hours (maximum). The default session duration is 10 hours. You are charged only when the URL is used or there is interaction with Amazon QuickSight. For more information, see Embedded Analytics (https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html) in the Amazon QuickSight User Guide. For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the Amazon QuickSight Developer Portal (https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html).
#
# POST /accounts/{AwsAccountId}/embed-url/anonymous-user
# Returns: record<EmbedUrl: string, Status: int, RequestId: string, AnonymousUserArn: string>
# operationId: GenerateEmbedUrlForAnonymousUser
export def "generate-embed-url-for-anonymous-user" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --session-lifetime-in-minutes: int # How many minutes the session is valid. The session lifetime must be in [15-600] minutes range.
  namespace: string # The Amazon QuickSight namespace that the anonymous user virtually belongs to. If you are not using an Amazon QuickSight custom namespace, set this to default.
  --session-tags: list # The session tags used for row-level security. Before you use this parameter, make sure that you have configured the relevant datasets using the DataSet$RowLevelPermissionTagConfiguration parameter so that session tags can be used to provide row-level security. These are not the tags used for the Amazon Web Services resource tagging feature. For more information, see Using Row-Level Security (RLS) with Tags (https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-rls-tags.html)in the Amazon QuickSight User Guide. — item shape: {Key: string, Value: string}
  authorized_resource_arns: list<string> # The Amazon Resource Names (ARNs) for the Amazon QuickSight resources that the user is authorized to access during the lifetime of the session. If you choose Dashboard embedding experience, pass the list of dashboard ARNs in the account that you want the user to be able to view. Currently, you can pass up to 25 dashboard ARNs in each API call.
  experience_configuration: record # The type of experience you want to embed. For anonymous users, you can embed Amazon QuickSight dashboards. — shape: {Dashboard?: record, DashboardVisual?: record, QSearchBar?: record}
  --allowed-domains: list<string> # The domains that you want to add to the allow list for access to the generated URL that is then embedded. This optional parameter overrides the static domains that are configured in the Manage QuickSight menu in the Amazon QuickSight console. Instead, it allows only the domains that you include in this parameter. You can list up to three domains or subdomains in each API call. To include all subdomains under a specific domain to the allow list, use *. For example, https://*.sapp.amazon.com includes all subdomains under https://sapp.amazon.com.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/embed-url/anonymous-user"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionLifetimeInMinutes, var: session_lifetime_in_minutes}, {name: Namespace, var: namespace}, {name: SessionTags, var: session_tags}, {name: AuthorizedResourceArns, var: authorized_resource_arns}, {name: ExperienceConfiguration, var: experience_configuration}, {name: AllowedDomains, var: allowed_domains}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, session_lifetime_in_minutes: $session_lifetime_in_minutes, namespace: $namespace, session_tags: $session_tags, authorized_resource_arns: $authorized_resource_arns, experience_configuration: $experience_configuration, allowed_domains: $allowed_domains
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates an embed URL that you can use to embed an Amazon QuickSight experience in your website. This action can be used for any type of user registered in an Amazon QuickSight account. Before you use this action, make sure that you have configured the relevant Amazon QuickSight resource and permissions. The following rules apply to the generated URL: It contains a temporary bearer token. It is valid for 5 minutes after it is generated. Once redeemed within this period, it cannot be re-used again. The URL validity period should not be confused with the actual session lifetime that can be customized using the SessionLifetimeInMinutes (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_GenerateEmbedUrlForRegisteredUser.html#QS-GenerateEmbedUrlForRegisteredUser-request-SessionLifetimeInMinutes) parameter. The resulting user session is valid for 15 minutes (minimum) to 10 hours (maximum). The default session duration is 10 hours. You are charged only when the URL is used or there is interaction with Amazon QuickSight. For more information, see Embedded Analytics (https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html) in the Amazon QuickSight User Guide. For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the Amazon QuickSight Developer Portal (https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html).
#
# POST /accounts/{AwsAccountId}/embed-url/registered-user
# Returns: record<EmbedUrl: string, Status: int, RequestId: string>
# operationId: GenerateEmbedUrlForRegisteredUser
export def "generate-embed-url-for-registered-user" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --session-lifetime-in-minutes: int # How many minutes the session is valid. The session lifetime must be in [15-600] minutes range.
  user_arn: string # The Amazon Resource Name for the registered user.
  experience_configuration: record # The type of experience you want to embed. For registered users, you can embed Amazon QuickSight dashboards or the Amazon QuickSight console. Exactly one of the experience configurations is required. You can choose Dashboard or QuickSightConsole. You cannot choose more than one experience configuration. — shape: {Dashboard?: record, QuickSightConsole?: record, QSearchBar?: record, DashboardVisual?: record}
  --allowed-domains: list<string> # The domains that you want to add to the allow list for access to the generated URL that is then embedded. This optional parameter overrides the static domains that are configured in the Manage QuickSight menu in the Amazon QuickSight console. Instead, it allows only the domains that you include in this parameter. You can list up to three domains or subdomains in each API call. To include all subdomains under a specific domain to the allow list, use *. For example, https://*.sapp.amazon.com includes all subdomains under https://sapp.amazon.com.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/embed-url/registered-user"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: SessionLifetimeInMinutes, var: session_lifetime_in_minutes}, {name: UserArn, var: user_arn}, {name: ExperienceConfiguration, var: experience_configuration}, {name: AllowedDomains, var: allowed_domains}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, session_lifetime_in_minutes: $session_lifetime_in_minutes, user_arn: $user_arn, experience_configuration: $experience_configuration, allowed_domains: $allowed_domains
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a temporary session URL and authorization code(bearer token) that you can use to embed an Amazon QuickSight read-only dashboard in your website or application. Before you use this command, make sure that you have configured the dashboards and permissions. Currently, you can use GetDashboardEmbedURL only from the server, not from the user's browser. The following rules apply to the generated URL: They must be used together. They can be used one time only. They are valid for 5 minutes after you run this command. You are charged only when the URL is used or there is interaction with Amazon QuickSight. The resulting user session is valid for 15 minutes (default) up to 10 hours (maximum). You can use the optional SessionLifetimeInMinutes parameter to customize session duration. For more information, see Embedding Analytics Using GetDashboardEmbedUrl (https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics-deprecated.html) in the Amazon QuickSight User Guide. For more information about the high-level steps for embedding and for an interactive demo of the ways you can customize embedding, visit the Amazon QuickSight Developer Portal (https://docs.aws.amazon.com/quicksight/latest/user/quicksight-dev-portal.html).
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url
# Returns: record<EmbedUrl: string, Status: int, RequestId: string>
# operationId: GetDashboardEmbedUrl
export def "get-dashboard-embed-url" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --creds-type: string@creds-type-completer # The authentication method that the user uses to sign in. (required)
  --session-lifetime: int # How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  --undo-redo-disabled: oneof<nothing, bool> # Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  --reset-disabled: oneof<nothing, bool> # Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  --state-persistence-enabled: oneof<nothing, bool> # Adds persistence of state for the user session in an embedded dashboard. Persistence applies to the sheet and the parameter settings. These are control settings that the dashboard subscriber (Amazon QuickSight reader) chooses while viewing the dashboard. If this is set to TRUE, the settings are the same when the subscriber reopens the same dashboard URL. The state is stored in Amazon QuickSight, not in a browser cookie. If this is set to FALSE, the state of the user session is not persisted. The default is FALSE.
  --user-arn: string # The Amazon QuickSight user's Amazon Resource Name (ARN), for use with QUICKSIGHT identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following: Active Directory (AD) users or group members Invited nonfederated users IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation. Omit this parameter for users in the third group – IAM users and IAM role-based sessions.
  --namespace: string # The Amazon QuickSight namespace that contains the dashboard IDs in this request. If you're not using a custom namespace, set Namespace = default.
  --additional-dashboard-ids: list<string> # A list of one or more dashboard IDs that you want anonymous users to have tempporary access to. Currently, the IdentityType parameter must be set to ANONYMOUS because other identity types authenticate as Amazon QuickSight or IAM users. For example, if you set "--dashboard-id dash_id1 --dashboard-id dash_id2 dash_id3 identity-type ANONYMOUS", the session can access all three dashboards.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    query: [{name: creds-type, var: creds_type, required: true}, {name: session-lifetime, var: session_lifetime}, {name: undo-redo-disabled, var: undo_redo_disabled}, {name: reset-disabled, var: reset_disabled}, {name: state-persistence-enabled, var: state_persistence_enabled}, {name: user-arn, var: user_arn}, {name: namespace, var: namespace}, {name: additional-dashboard-ids, var: additional_dashboard_ids, style: multi}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, creds_type: $creds_type, session_lifetime: $session_lifetime, undo_redo_disabled: $undo_redo_disabled, reset_disabled: $reset_disabled, state_persistence_enabled: $state_persistence_enabled, user_arn: $user_arn, namespace: $namespace, additional_dashboard_ids: $additional_dashboard_ids, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generates a session URL and authorization code that you can use to embed the Amazon Amazon QuickSight console in your web server code. Use GetSessionEmbedUrl where you want to provide an authoring portal that allows users to create data sources, datasets, analyses, and dashboards. The users who access an embedded Amazon QuickSight console need belong to the author or admin security cohort. If you want to restrict permissions to some of these features, add a custom permissions profile to the user with the UpdateUser (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateUser.html) API operation. Use RegisterUser (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_RegisterUser.html) API operation to add a new user with a custom permission profile attached. For more information, see the following sections in the Amazon QuickSight User Guide: Embedding Analytics (https://docs.aws.amazon.com/quicksight/latest/user/embedded-analytics.html) Customizing Access to the Amazon QuickSight Console (https://docs.aws.amazon.com/quicksight/latest/user/customizing-permissions-to-the-quicksight-console.html)
#
# GET /accounts/{AwsAccountId}/session-embed-url
# Returns: record<EmbedUrl: string, Status: int, RequestId: string>
# operationId: GetSessionEmbedUrl
export def "get-session-embed-url" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entry-point: string # The URL you use to access the embedded session. The entry point URL is constrained to the following paths: /start /start/analyses /start/dashboards /start/favorites /dashboards/DashboardId - where DashboardId is the actual ID key from the Amazon QuickSight console URL of the dashboard /analyses/AnalysisId - where AnalysisId is the actual ID key from the Amazon QuickSight console URL of the analysis
  --session-lifetime: int # How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  --user-arn: string # The Amazon QuickSight user's Amazon Resource Name (ARN), for use with QUICKSIGHT identity type. You can use this for any type of Amazon QuickSight users in your account (readers, authors, or admins). They need to be authenticated as one of the following: Active Directory (AD) users or group members Invited nonfederated users IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation Omit this parameter for users in the third group, IAM users and IAM role-based sessions.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/session-embed-url"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: entry-point, var: entry_point}, {name: session-lifetime, var: session_lifetime}, {name: user-arn, var: user_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, entry_point: $entry_point, session_lifetime: $session_lifetime, user_arn: $user_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists Amazon QuickSight analyses that exist in the specified Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/analyses
# Returns: record<AnalysisSummaryList: table<Arn: string, AnalysisId: string, Name: string, Status: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>
# operationId: ListAnalyses
export def "list-analyses" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/analyses"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the versions of the dashboards in the Amazon QuickSight subscription.
#
# GET /accounts/{AwsAccountId}/dashboards/{DashboardId}/versions
# Returns: record<DashboardVersionSummaryList: table<Arn: string, CreatedTime: string, VersionNumber: int, Status: string, SourceEntityArn: string, Description: string>, NextToken: string, Status: int, RequestId: string>
# operationId: ListDashboardVersions
export def "list-dashboard-versions" [
  aws_account_id: string
  dashboard_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists dashboards in an Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/dashboards
# Returns: record<DashboardSummaryList: table<Arn: string, DashboardId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, PublishedVersionNumber: int, LastPublishedTime: string>, NextToken: string, Status: int, RequestId: string>
# operationId: ListDashboards
export def "list-dashboards" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/dashboards"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all assets (DASHBOARD, ANALYSIS, and DATASET) in a folder.
#
# GET /accounts/{AwsAccountId}/folders/{FolderId}/members
# Returns: record<Status: int, FolderMemberList: table<MemberId: string, MemberArn: string>, NextToken: string, RequestId: string>
# operationId: ListFolderMembers
export def "list-folder-members" [
  aws_account_id: string
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/folders/{FolderId}/members"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: FolderId, var: folder_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, folder_id: $folder_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all folders in an account.
#
# GET /accounts/{AwsAccountId}/folders
# Returns: record<Status: int, FolderSummaryList: table<Arn: string, FolderId: string, Name: string, FolderType: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, RequestId: string>
# operationId: ListFolders
export def "list-folders" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/folders"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists member users in a group.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members
# Returns: record<GroupMemberList: table<Arn: string, MemberName: string>, NextToken: string, RequestId: string, Status: int>
# operationId: ListGroupMemberships
export def "list-group-memberships" [
  aws_account_id: string
  namespace: string
  group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: GroupName, var: group_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, group_name: $group_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists IAM policy assignments in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments
# Returns: record<IAMPolicyAssignments: table<AssignmentName: string, AssignmentStatus: string>, NextToken: string, RequestId: string, Status: int>
# operationId: ListIAMPolicyAssignments
export def "list-iam-policy-assignments" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments
# Returns: record<ActiveAssignments: table<AssignmentName: string, PolicyArn: string>, RequestId: string, NextToken: string, Status: int>
# operationId: ListIAMPolicyAssignmentsForUser
export def "list-iam-policy-assignments-for-user" [
  aws_account_id: string
  namespace: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: UserName, var: user_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, user_name: $user_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the history of SPICE ingestions for a dataset.
#
# GET /accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions
# Returns: record<Ingestions: table<Arn: string, IngestionId: string, IngestionStatus: string, ErrorInfo: record, RowInfo: record, QueueInfo: record, CreatedTime: string, IngestionTimeInSeconds: int, IngestionSizeInBytes: int, RequestSource: string, RequestType: string>, NextToken: string, RequestId: string, Status: int>
# operationId: ListIngestions
export def "list-ingestions" [
  aws_account_id: string
  data_set_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DataSetId, var: data_set_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, data_set_id: $data_set_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the namespaces for the specified Amazon Web Services account. This operation doesn't list deleted namespaces.
#
# GET /accounts/{AwsAccountId}/namespaces
# Returns: record<Namespaces: table<Name: string, Arn: string, CapacityRegion: string, CreationStatus: string, IdentityStore: string, NamespaceError: record>, NextToken: string, RequestId: string, Status: int>
# operationId: ListNamespaces
export def "list-namespaces" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A unique pagination token that can be used in a subsequent request. You will receive a pagination token in the response body of a previous ListNameSpaces API call if there is more data that can be returned. To receive the data, make another ListNamespaces API call with the returned token to retrieve the next page of data. Each token is valid for 24 hours. If you try to make a ListNamespaces API call with an expired token, you will receive a HTTP 400 InvalidNextTokenException error.
  --max-results: int # The maximum number of results to return.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the tags assigned to a resource.
#
# GET /resources/{ResourceArn}/tags
# Returns: record<Tags: table<Key: string, Value: string>, RequestId: string, Status: int>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/{ResourceArn}/tags"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assigns one or more tags (key-value pairs) to the specified Amazon QuickSight resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the TagResource operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag. You can associate as many as 50 tags with a resource. Amazon QuickSight supports tagging on data set, data source, dashboard, and template. Tagging for Amazon QuickSight works in a similar way to tagging for other Amazon Web Services services, except for the following: You can't use tags to track costs for Amazon QuickSight. This isn't possible because you can't tag the resources that Amazon QuickSight costs are based on, for example Amazon QuickSight storage capacity (SPICE), number of users, type of users, and usage metrics. Amazon QuickSight doesn't currently support the tag editor for Resource Groups.
#
# POST /resources/{ResourceArn}/tags
# Returns: record<RequestId: string, Status: int>
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: list # Contains a map of the key-value pairs for the resource tag or tags assigned to the resource. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/resources/{ResourceArn}/tags"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the aliases of a template.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/aliases
# Returns: record<TemplateAliasList: table<AliasName: string, Arn: string, TemplateVersionNumber: int>, Status: int, RequestId: string, NextToken: string>
# operationId: ListTemplateAliases
export def "list-template-aliases" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    query: [{name: next-token, var: next_token}, {name: max-result, var: max_result}, {name: MaxResults, var: max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, next_token: $next_token, max_result: $max_result, max_results: $max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the versions of the templates in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/templates/{TemplateId}/versions
# Returns: record<TemplateVersionSummaryList: table<Arn: string, VersionNumber: int, CreatedTime: string, Status: string, Description: string>, NextToken: string, Status: int, RequestId: string>
# operationId: ListTemplateVersions
export def "list-template-versions" [
  aws_account_id: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/templates/{TemplateId}/versions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: TemplateId, var: template_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, template_id: $template_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the templates in the current Amazon QuickSight account.
#
# GET /accounts/{AwsAccountId}/templates
# Returns: record<TemplateSummaryList: table<Arn: string, TemplateId: string, Name: string, LatestVersionNumber: int, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>
# operationId: ListTemplates
export def "list-templates" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --max-results: string # Pagination limit
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/templates"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: next-token, var: next_token}, {name: max-result, var: max_result}, {name: MaxResults, var: max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, next_token: $next_token, max_result: $max_result, max_results: $max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the aliases of a theme.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/aliases
# Returns: record<ThemeAliasList: table<Arn: string, AliasName: string, ThemeVersionNumber: int>, Status: int, RequestId: string, NextToken: string>
# operationId: ListThemeAliases
export def "list-theme-aliases" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-result: int # The maximum number of results to be returned per request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}/aliases"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}]
    query: [{name: next-token, var: next_token}, {name: max-result, var: max_result}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, next_token: $next_token, max_result: $max_result, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the versions of the themes in the current Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/themes/{ThemeId}/versions
# Returns: record<ThemeVersionSummaryList: table<VersionNumber: int, Arn: string, Description: string, CreatedTime: string, Status: string>, NextToken: string, Status: int, RequestId: string>
# operationId: ListThemeVersions
export def "list-theme-versions" [
  aws_account_id: string
  theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/themes/{ThemeId}/versions"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: ThemeId, var: theme_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, theme_id: $theme_id, next_token: $next_token, max_results: $max_results, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all the themes in the current Amazon Web Services account.
#
# GET /accounts/{AwsAccountId}/themes
# Returns: record<ThemeSummaryList: table<Arn: string, Name: string, ThemeId: string, LatestVersionNumber: int, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>
# operationId: ListThemes
export def "list-themes" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
  --type: string@type-completer-1 # The type of themes that you want to list. Valid options include the following: ALL (default)- Display all existing themes. CUSTOM - Display only the themes created by people using Amazon QuickSight. QUICKSIGHT - Display only the starting themes defined by Amazon QuickSight.
  --qp-max-results: string # Pagination limit (spec name: MaxResults)
  --qp-next-token: string # Pagination token (spec name: NextToken)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/themes"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}, {name: type, var: type}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, next_token: $next_token, max_results: $max_results, type: $type, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups
# Returns: record<GroupList: table<Arn: string, GroupName: string, Description: string, PrincipalId: string>, NextToken: string, RequestId: string, Status: int>
# operationId: ListUserGroups
export def "list-user-groups" [
  aws_account_id: string
  namespace: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}, {name: UserName, var: user_name}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, user_name: $user_name, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of all of the Amazon QuickSight users belonging to this account.
#
# GET /accounts/{AwsAccountId}/namespaces/{Namespace}/users
# Returns: record<UserList: table<Arn: string, UserName: string, Email: string, Role: string, IdentityType: string, Active: bool, PrincipalId: string, CustomPermissionsName: string, ExternalLoginFederationProviderType: string, ExternalLoginFederationProviderUrl: string, ExternalLoginId: string>, NextToken: string, RequestId: string, Status: int>
# operationId: ListUsers
export def "list-users" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an Amazon QuickSight user whose identity is associated with the Identity and Access Management (IAM) identity or role specified in the request. When you register a new user from the Amazon QuickSight API, Amazon QuickSight generates a registration URL. The user accesses this registration URL to create their account. Amazon QuickSight doesn't send a registration email to users who are registered from the Amazon QuickSight API. If you want new users to receive a registration email, then add those users in the Amazon QuickSight console. For more information on registering a new user in the Amazon QuickSight console, see Inviting users to access Amazon QuickSight (https://docs.aws.amazon.com/quicksight/latest/user/managing-users.html#inviting-users).
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/users
# Returns: record<User: record<Arn: string, UserName: string, Email: string, Role: string, IdentityType: string, Active: bool, PrincipalId: string, CustomPermissionsName: string, ExternalLoginFederationProviderType: string, ExternalLoginFederationProviderUrl: string, ExternalLoginId: string>, UserInvitationUrl: string, RequestId: string, Status: int>
# operationId: RegisterUser
export def "register-user" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  identity_type: string@identity-type-completer # Amazon QuickSight supports several ways of managing the identity of users. This parameter accepts two values: IAM: A user whose identity maps to an existing IAM user or role. QUICKSIGHT: A user whose identity is owned and managed internally by Amazon QuickSight.
  email: string # The email address of the user that you want to register.
  user_role: string@user-role-completer # The Amazon QuickSight role for the user. The user role can be one of the following: READER: A user who has read-only access to dashboards. AUTHOR: A user who can create data sources, datasets, analyses, and dashboards. ADMIN: A user who is an author, who can also manage Amazon QuickSight settings. RESTRICTED_READER: This role isn't currently available for use. RESTRICTED_AUTHOR: This role isn't currently available for use.
  --iam-arn: string # The ARN of the IAM user or role that you are registering with Amazon QuickSight.
  --session-name: string # You need to use this parameter only when you register one or more users using an assumed IAM role. You don't need to provide the session name for other scenarios, for example when you are registering an IAM user or an Amazon QuickSight user. You can register multiple users using the same IAM role if each user has a different session name. For more information on assuming IAM roles, see assume-role (https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role.html) in the CLI Reference.
  --user-name: string # The Amazon QuickSight user name that you want to create for the user you are registering.
  --custom-permissions-name: string # (Enterprise edition only) The name of the custom permissions profile that you want to assign to this user. Customized permissions allows you to control a user's access by restricting access the following operations: Create and update data sources Create and update datasets Create and update email reports Subscribe to email reports To add custom permissions to an existing user, use UpdateUser (https://docs.aws.amazon.com/quicksight/latest/APIReference/API_UpdateUser.html) instead. A set of custom permissions includes any combination of these restrictions. Currently, you need to create the profile names for custom permission sets by using the Amazon QuickSight console. Then, you use the RegisterUser API operation to assign the named set of permissions to a Amazon QuickSight user. Amazon QuickSight custom permissions are applied through IAM policies. Therefore, they override the permissions typically granted by assigning Amazon QuickSight users to one of the default security cohorts in Amazon QuickSight (admin, author, reader). This feature is available only to Amazon QuickSight Enterprise edition subscriptions.
  --external-login-federation-provider-type: string # The type of supported external login provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. The type of supported external login provider can be one of the following. COGNITO: Amazon Cognito. The provider URL is cognito-identity.amazonaws.com. When choosing the COGNITO provider type, don’t use the "CustomFederationProviderUrl" parameter which is only needed when the external provider is custom. CUSTOM_OIDC: Custom OpenID Connect (OIDC) provider. When choosing CUSTOM_OIDC type, use the CustomFederationProviderUrl parameter to provide the custom OIDC provider URL.
  --custom-federation-provider-url: string # The URL of the custom OpenID Connect (OIDC) provider that provides identity to let a user federate into Amazon QuickSight with an associated Identity and Access Management(IAM) role. This parameter should only be used when ExternalLoginFederationProviderType parameter is set to CUSTOM_OIDC.
  --external-login-id: string # The identity ID for a user in the external login provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: IdentityType, var: identity_type}, {name: Email, var: email}, {name: UserRole, var: user_role}, {name: IamArn, var: iam_arn}, {name: SessionName, var: session_name}, {name: UserName, var: user_name}, {name: CustomPermissionsName, var: custom_permissions_name}, {name: ExternalLoginFederationProviderType, var: external_login_federation_provider_type}, {name: CustomFederationProviderUrl, var: custom_federation_provider_url}, {name: ExternalLoginId, var: external_login_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, identity_type: $identity_type, email: $email, user_role: $user_role, iam_arn: $iam_arn, session_name: $session_name, user_name: $user_name, custom_permissions_name: $custom_permissions_name, external_login_federation_provider_type: $external_login_federation_provider_type, custom_federation_provider_url: $custom_federation_provider_url, external_login_id: $external_login_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restores an analysis.
#
# POST /accounts/{AwsAccountId}/restore/analyses/{AnalysisId}
# Returns: record<Status: int, Arn: string, AnalysisId: string, RequestId: string>
# operationId: RestoreAnalysis
export def "restore-analysis" [
  aws_account_id: string
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/accounts/{AwsAccountId}/restore/analyses/{AnalysisId}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: AnalysisId, var: analysis_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, analysis_id: $analysis_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for analyses that belong to the user specified in the filter. This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.
#
# POST /accounts/{AwsAccountId}/search/analyses
# Returns: record<AnalysisSummaryList: table<Arn: string, AnalysisId: string, Name: string, Status: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>
# operationId: SearchAnalyses
export def "search-analyses" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  filters: list # The structure for the search filters that you want to apply to your search. — item shape: {Operator?: "StringEquals"|"StringLike", Name?: "QUICKSIGHT_USER"|"QUICKSIGHT_VIEWER_OR_OWNER"|"DIRECT_QUICKSIGHT_VIEWER_OR_OWNER"|"QUICKSIGHT_OWNER"|"DIRECT_QUICKSIGHT_OWNER"|"DIRECT_QUICKSIGHT_SOLE_OWNER"|"ANALYSIS_NAME", Value?: string}
  --body-next-token: string # A pagination token that can be used in a subsequent request. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to return. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/search/analyses"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for dashboards that belong to a user. This operation is eventually consistent. The results are best effort and may not reflect very recent updates and changes.
#
# POST /accounts/{AwsAccountId}/search/dashboards
# Returns: record<DashboardSummaryList: table<Arn: string, DashboardId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, PublishedVersionNumber: int, LastPublishedTime: string>, NextToken: string, Status: int, RequestId: string>
# operationId: SearchDashboards
export def "search-dashboards" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  filters: list # The filters to apply to the search. Currently, you can search only by user name, for example, "Filters": [ { "Name": "QUICKSIGHT_USER", "Operator": "StringEquals", "Value": "arn:aws:quicksight:us-east-1:1:user/default/UserName1" } ] — item shape: {Operator: "StringEquals"|"StringLike", Name?: "QUICKSIGHT_USER"|"QUICKSIGHT_VIEWER_OR_OWNER"|"DIRECT_QUICKSIGHT_VIEWER_OR_OWNER"|"QUICKSIGHT_OWNER"|"DIRECT_QUICKSIGHT_OWNER"|"DIRECT_QUICKSIGHT_SOLE_OWNER"|"DASHBOARD_NAME", Value?: string}
  --body-next-token: string # The token for the next set of results, or null if there are no more results. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to be returned per request. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/search/dashboards"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the SearchDataSets operation to search for datasets that belong to an account.
#
# POST /accounts/{AwsAccountId}/search/data-sets
# Returns: record<DataSetSummaries: table<Arn: string, DataSetId: string, Name: string, CreatedTime: string, LastUpdatedTime: string, ImportMode: string, RowLevelPermissionDataSet: record, RowLevelPermissionTagConfigurationApplied: bool, ColumnLevelPermissionRulesApplied: bool>, NextToken: string, Status: int, RequestId: string>
# operationId: SearchDataSets
export def "search-data-sets" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  filters: list # The filters to apply to the search. — item shape: {Operator: "StringEquals"|"StringLike", Name: "QUICKSIGHT_VIEWER_OR_OWNER"|"QUICKSIGHT_OWNER"|"DIRECT_QUICKSIGHT_VIEWER_OR_OWNER"|"DIRECT_QUICKSIGHT_OWNER"|"DIRECT_QUICKSIGHT_SOLE_OWNER"|"DATASET_NAME", Value: string}
  --body-next-token: string # A pagination token that can be used in a subsequent request. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to be returned per request. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/search/data-sets"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the SearchDataSources operation to search for data sources that belong to an account.
#
# POST /accounts/{AwsAccountId}/search/data-sources
# Returns: record<DataSourceSummaries: table<Arn: string, DataSourceId: string, Name: string, Type: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, Status: int, RequestId: string>
# operationId: SearchDataSources
export def "search-data-sources" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  filters: list # The filters to apply to the search. — item shape: {Operator: "StringEquals"|"StringLike", Name: "DIRECT_QUICKSIGHT_VIEWER_OR_OWNER"|"DIRECT_QUICKSIGHT_OWNER"|"DIRECT_QUICKSIGHT_SOLE_OWNER"|"DATASOURCE_NAME", Value: string}
  --body-next-token: string # A pagination token that can be used in a subsequent request. (spec name: NextToken)
  --body-max-results: int # The maximum number of results to be returned per request. (spec name: MaxResults)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/search/data-sources"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: body_next_token}, {name: MaxResults, var: body_max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_next_token: $body_next_token, body_max_results: $body_max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches the subfolders in a folder.
#
# POST /accounts/{AwsAccountId}/search/folders
# Returns: record<Status: int, FolderSummaryList: table<Arn: string, FolderId: string, Name: string, FolderType: string, CreatedTime: string, LastUpdatedTime: string>, NextToken: string, RequestId: string>
# operationId: SearchFolders
export def "search-folders" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  filters: list # The filters to apply to the search. Currently, you can search only by the parent folder ARN. For example, "Filters": [ { "Name": "PARENT_FOLDER_ARN", "Operator": "StringEquals", "Value": "arn:aws:quicksight:us-east-1:1:folder/folderId" } ]. — item shape: {Operator?: "StringEquals"|"StringLike", Name?: "PARENT_FOLDER_ARN"|"DIRECT_QUICKSIGHT_OWNER"|"DIRECT_QUICKSIGHT_SOLE_OWNER"|"DIRECT_QUICKSIGHT_VIEWER_OR_OWNER"|"QUICKSIGHT_OWNER"|"QUICKSIGHT_VIEWER_OR_OWNER"|"FOLDER_NAME", Value?: string}
  --next-token: string # The token for the next set of results, or null if there are no more results.
  --max-results: int # The maximum number of results to be returned per request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/search/folders"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}, {name: NextToken, var: next_token}, {name: MaxResults, var: max_results}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, next_token: $next_token, max_results: $max_results
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the SearchGroups operation to search groups in a specified Amazon QuickSight namespace using the supplied filters.
#
# POST /accounts/{AwsAccountId}/namespaces/{Namespace}/groups-search
# Returns: record<GroupList: table<Arn: string, GroupName: string, Description: string, PrincipalId: string>, NextToken: string, RequestId: string, Status: int>
# operationId: SearchGroups
export def "search-groups" [
  aws_account_id: string
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # A pagination token that can be used in a subsequent request.
  --max-results: int # The maximum number of results to return from this request.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  filters: list # The structure for the search filters that you want to apply to your search. — item shape: {Operator: "StartsWith", Name: "GROUP_NAME", Value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups-search"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: Namespace, var: namespace}]
    query: [{name: next-token, var: next_token}, {name: max-results, var: max_results}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Filters, var: filters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, namespace: $namespace, next_token: $next_token, max_results: $max_results, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a tag or tags from a resource.
#
# DELETE /resources/{ResourceArn}/tags
# Returns: record<RequestId: string, Status: int>
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keys: list<string> # The keys of the key-value pairs for the resource tag or tags assigned to the resource. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/resources/{ResourceArn}/tags"
    path_params: [{name: ResourceArn, var: resource_arn}]
    query: [{name: keys, var: keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, keys: $keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the published version of a dashboard.
#
# PUT /accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}
# Returns: record<DashboardId: string, DashboardArn: string, Status: int, RequestId: string>
# operationId: UpdateDashboardPublishedVersion
export def "update-dashboard-published-version" [
  aws_account_id: string
  dashboard_id: string
  version_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}"
    path_params: [{name: AwsAccountId, var: aws_account_id}, {name: DashboardId, var: dashboard_id}, {name: VersionNumber, var: version_number}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, dashboard_id: $dashboard_id, version_number: $version_number, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Use the UpdatePublicSharingSettings operation to turn on or turn off the public sharing settings of an Amazon QuickSight dashboard. To use this operation, turn on session capacity pricing for your Amazon QuickSight account. Before you can turn on public sharing on your account, make sure to give public sharing permissions to an administrative user in the Identity and Access Management (IAM) console. For more information on using IAM with Amazon QuickSight, see Using Amazon QuickSight with IAM (https://docs.aws.amazon.com/quicksight/latest/user/security_iam_service-with-iam.html) in the Amazon QuickSight User Guide.
#
# PUT /accounts/{AwsAccountId}/public-sharing-settings
# Returns: record<RequestId: string, Status: int>
# operationId: UpdatePublicSharingSettings
export def "update-public-sharing-settings" [
  aws_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --public-sharing-enabled: oneof<nothing, bool> # A Boolean value that indicates whether public sharing is turned on for an Amazon QuickSight account.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/accounts/{AwsAccountId}/public-sharing-settings"
    path_params: [{name: AwsAccountId, var: aws_account_id}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PublicSharingEnabled, var: public_sharing_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_account_id: $aws_account_id, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, public_sharing_enabled: $public_sharing_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
