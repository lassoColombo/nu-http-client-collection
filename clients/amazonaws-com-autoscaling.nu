# Auto-generated client for Auto Scaling v2011-01-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/autoscaling/2011-01-01/openapi.json
# Auth: --token flag or $env.AUTO_SCALING_TOKEN

const CLIENT = {
  base_url: "http://autoscaling.us-east-1.amazonaws.com"
  token_env_var: "AUTO_SCALING_TOKEN"
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

def base-url-completer [] { ["http://autoscaling.us-east-1.amazonaws.com" "http://autoscaling.us-east-2.amazonaws.com" "http://autoscaling.us-west-1.amazonaws.com" "http://autoscaling.us-west-2.amazonaws.com" "http://autoscaling.us-gov-west-1.amazonaws.com" "http://autoscaling.us-gov-east-1.amazonaws.com" "http://autoscaling.ca-central-1.amazonaws.com" "http://autoscaling.eu-north-1.amazonaws.com" "http://autoscaling.eu-west-1.amazonaws.com" "http://autoscaling.eu-west-2.amazonaws.com" "http://autoscaling.eu-west-3.amazonaws.com" "http://autoscaling.eu-central-1.amazonaws.com" "http://autoscaling.eu-south-1.amazonaws.com" "http://autoscaling.af-south-1.amazonaws.com" "http://autoscaling.ap-northeast-1.amazonaws.com" "http://autoscaling.ap-northeast-2.amazonaws.com" "http://autoscaling.ap-northeast-3.amazonaws.com" "http://autoscaling.ap-southeast-1.amazonaws.com" "http://autoscaling.ap-southeast-2.amazonaws.com" "http://autoscaling.ap-east-1.amazonaws.com" "http://autoscaling.ap-south-1.amazonaws.com" "http://autoscaling.sa-east-1.amazonaws.com" "http://autoscaling.me-south-1.amazonaws.com" "https://autoscaling.us-east-1.amazonaws.com" "https://autoscaling.us-east-2.amazonaws.com" "https://autoscaling.us-west-1.amazonaws.com" "https://autoscaling.us-west-2.amazonaws.com" "https://autoscaling.us-gov-west-1.amazonaws.com" "https://autoscaling.us-gov-east-1.amazonaws.com" "https://autoscaling.ca-central-1.amazonaws.com" "https://autoscaling.eu-north-1.amazonaws.com" "https://autoscaling.eu-west-1.amazonaws.com" "https://autoscaling.eu-west-2.amazonaws.com" "https://autoscaling.eu-west-3.amazonaws.com" "https://autoscaling.eu-central-1.amazonaws.com" "https://autoscaling.eu-south-1.amazonaws.com" "https://autoscaling.af-south-1.amazonaws.com" "https://autoscaling.ap-northeast-1.amazonaws.com" "https://autoscaling.ap-northeast-2.amazonaws.com" "https://autoscaling.ap-northeast-3.amazonaws.com" "https://autoscaling.ap-southeast-1.amazonaws.com" "https://autoscaling.ap-southeast-2.amazonaws.com" "https://autoscaling.ap-east-1.amazonaws.com" "https://autoscaling.ap-south-1.amazonaws.com" "https://autoscaling.sa-east-1.amazonaws.com" "https://autoscaling.me-south-1.amazonaws.com" "http://autoscaling.amazonaws.com" "https://autoscaling.amazonaws.com" "http://autoscaling.cn-north-1.amazonaws.com.cn" "http://autoscaling.cn-northwest-1.amazonaws.com.cn" "https://autoscaling.cn-north-1.amazonaws.com.cn" "https://autoscaling.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["AttachInstances"] }
def version-completer [] { ["2011-01-01"] }
def action-completer-1 [] { ["AttachLoadBalancerTargetGroups"] }
def action-completer-2 [] { ["AttachLoadBalancers"] }
def action-completer-3 [] { ["AttachTrafficSources"] }
def action-completer-4 [] { ["BatchDeleteScheduledAction"] }
def action-completer-5 [] { ["BatchPutScheduledUpdateGroupAction"] }
def action-completer-6 [] { ["CancelInstanceRefresh"] }
def action-completer-7 [] { ["CompleteLifecycleAction"] }
def action-completer-8 [] { ["CreateAutoScalingGroup"] }
def action-completer-9 [] { ["CreateLaunchConfiguration"] }
def action-completer-10 [] { ["CreateOrUpdateTags"] }
def action-completer-11 [] { ["DeleteAutoScalingGroup"] }
def action-completer-12 [] { ["DeleteLaunchConfiguration"] }
def action-completer-13 [] { ["DeleteLifecycleHook"] }
def action-completer-14 [] { ["DeleteNotificationConfiguration"] }
def action-completer-15 [] { ["DeletePolicy"] }
def action-completer-16 [] { ["DeleteScheduledAction"] }
def action-completer-17 [] { ["DeleteTags"] }
def action-completer-18 [] { ["DeleteWarmPool"] }
def action-completer-19 [] { ["DescribeAccountLimits"] }
def action-completer-20 [] { ["DescribeAdjustmentTypes"] }
def action-completer-21 [] { ["DescribeAutoScalingGroups"] }
def action-completer-22 [] { ["DescribeAutoScalingInstances"] }
def action-completer-23 [] { ["DescribeAutoScalingNotificationTypes"] }
def action-completer-24 [] { ["DescribeInstanceRefreshes"] }
def action-completer-25 [] { ["DescribeLaunchConfigurations"] }
def action-completer-26 [] { ["DescribeLifecycleHookTypes"] }
def action-completer-27 [] { ["DescribeLifecycleHooks"] }
def action-completer-28 [] { ["DescribeLoadBalancerTargetGroups"] }
def action-completer-29 [] { ["DescribeLoadBalancers"] }
def action-completer-30 [] { ["DescribeMetricCollectionTypes"] }
def action-completer-31 [] { ["DescribeNotificationConfigurations"] }
def action-completer-32 [] { ["DescribePolicies"] }
def action-completer-33 [] { ["DescribeScalingActivities"] }
def action-completer-34 [] { ["DescribeScalingProcessTypes"] }
def action-completer-35 [] { ["DescribeScheduledActions"] }
def action-completer-36 [] { ["DescribeTags"] }
def action-completer-37 [] { ["DescribeTerminationPolicyTypes"] }
def action-completer-38 [] { ["DescribeTrafficSources"] }
def action-completer-39 [] { ["DescribeWarmPool"] }
def action-completer-40 [] { ["DetachInstances"] }
def action-completer-41 [] { ["DetachLoadBalancerTargetGroups"] }
def action-completer-42 [] { ["DetachLoadBalancers"] }
def action-completer-43 [] { ["DetachTrafficSources"] }
def action-completer-44 [] { ["DisableMetricsCollection"] }
def action-completer-45 [] { ["EnableMetricsCollection"] }
def action-completer-46 [] { ["EnterStandby"] }
def action-completer-47 [] { ["ExecutePolicy"] }
def action-completer-48 [] { ["ExitStandby"] }
def action-completer-49 [] { ["GetPredictiveScalingForecast"] }
def action-completer-50 [] { ["PutLifecycleHook"] }
def action-completer-51 [] { ["PutNotificationConfiguration"] }
def action-completer-52 [] { ["PutScalingPolicy"] }
def action-completer-53 [] { ["PutScheduledUpdateGroupAction"] }
def pool-state-completer [] { ["Hibernated" "Running" "Stopped"] }
def action-completer-54 [] { ["PutWarmPool"] }
def action-completer-55 [] { ["RecordLifecycleActionHeartbeat"] }
def action-completer-56 [] { ["ResumeProcesses"] }
def action-completer-57 [] { ["RollbackInstanceRefresh"] }
def action-completer-58 [] { ["SetDesiredCapacity"] }
def action-completer-59 [] { ["SetInstanceHealth"] }
def action-completer-60 [] { ["SetInstanceProtection"] }
def strategy-completer [] { ["Rolling"] }
def action-completer-61 [] { ["StartInstanceRefresh"] }
def action-completer-62 [] { ["SuspendProcesses"] }
def action-completer-63 [] { ["TerminateInstanceInAutoScalingGroup"] }
def action-completer-64 [] { ["UpdateAutoScalingGroup"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-attach-instances" "post-attach-instances" "get-attach-load-balancer-target-groups" "post-attach-load-balancer-target-groups" "get-attach-load-balancers" "post-attach-load-balancers" "get-attach-traffic-sources" "post-attach-traffic-sources" "get-batch-delete-scheduled-action" "post-batch-delete-scheduled-action" "get-batch-put-scheduled-update-group-action" "post-batch-put-scheduled-update-group-action" "get-cancel-instance-refresh" "post-cancel-instance-refresh" "get-complete-lifecycle-action" "post-complete-lifecycle-action" "get-create-auto-scaling-group" "post-create-auto-scaling-group" "get-create-launch-configuration" "post-create-launch-configuration" "get-create-or-update-tags" "post-create-or-update-tags" "get-delete-auto-scaling-group" "post-delete-auto-scaling-group" "get-delete-launch-configuration" "post-delete-launch-configuration" "get-delete-lifecycle-hook" "post-delete-lifecycle-hook" "get-delete-notification-configuration" "post-delete-notification-configuration" "get-delete-policy" "post-delete-policy" "get-delete-scheduled-action" "post-delete-scheduled-action" "get-delete-tags" "post-delete-tags" "get-delete-warm-pool" "post-delete-warm-pool" "get-describe-account-limits" "post-describe-account-limits" "get-describe-adjustment-types" "post-describe-adjustment-types" "get-describe-auto-scaling-groups" "post-describe-auto-scaling-groups" "get-describe-auto-scaling-instances" "post-describe-auto-scaling-instances" "get-describe-auto-scaling-notification-types" "post-describe-auto-scaling-notification-types" "get-describe-instance-refreshes" "post-describe-instance-refreshes" "get-describe-launch-configurations" "post-describe-launch-configurations" "get-describe-lifecycle-hook-types" "post-describe-lifecycle-hook-types" "get-describe-lifecycle-hooks" "post-describe-lifecycle-hooks" "get-describe-load-balancer-target-groups" "post-describe-load-balancer-target-groups" "get-describe-load-balancers" "post-describe-load-balancers" "get-describe-metric-collection-types" "post-describe-metric-collection-types" "get-describe-notification-configurations" "post-describe-notification-configurations" "get-describe-policies" "post-describe-policies" "get-describe-scaling-activities" "post-describe-scaling-activities" "get-describe-scaling-process-types" "post-describe-scaling-process-types" "get-describe-scheduled-actions" "post-describe-scheduled-actions" "get-describe-tags" "post-describe-tags" "get-describe-termination-policy-types" "post-describe-termination-policy-types" "get-describe-traffic-sources" "post-describe-traffic-sources" "get-describe-warm-pool" "post-describe-warm-pool" "get-detach-instances" "post-detach-instances" "get-detach-load-balancer-target-groups" "post-detach-load-balancer-target-groups" "get-detach-load-balancers" "post-detach-load-balancers" "get-detach-traffic-sources" "post-detach-traffic-sources" "get-disable-metrics-collection" "post-disable-metrics-collection" "get-enable-metrics-collection" "post-enable-metrics-collection" "get-enter-standby" "post-enter-standby" "get-execute-policy" "post-execute-policy" "get-exit-standby" "post-exit-standby" "get-get-predictive-scaling-forecast" "post-get-predictive-scaling-forecast" "get-put-lifecycle-hook" "post-put-lifecycle-hook" "get-put-notification-configuration" "post-put-notification-configuration" "get-put-scaling-policy" "post-put-scaling-policy" "get-put-scheduled-update-group-action" "post-put-scheduled-update-group-action" "get-put-warm-pool" "post-put-warm-pool" "get-record-lifecycle-action-heartbeat" "post-record-lifecycle-action-heartbeat" "get-resume-processes" "post-resume-processes" "get-rollback-instance-refresh" "post-rollback-instance-refresh" "get-set-desired-capacity" "post-set-desired-capacity" "get-set-instance-health" "post-set-instance-health" "get-set-instance-protection" "post-set-instance-protection" "get-start-instance-refresh" "post-start-instance-refresh" "get-suspend-processes" "post-suspend-processes" "get-terminate-instance-in-auto-scaling-group" "post-terminate-instance-in-auto-scaling-group" "get-update-auto-scaling-group" "post-update-auto-scaling-group" "commands"] | sort) } | get name | first)
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

# Attaches one or more EC2 instances to the specified Auto Scaling group. When you attach instances, Amazon EC2 Auto Scaling increases the desired capacity of the group by the number of instances being attached. If the number of instances being attached plus the desired capacity of the group exceeds the maximum size of the group, the operation fails. If there is a Classic Load Balancer attached to your Auto Scaling group, the instances are also registered with the load balancer. If there are target groups attached to your Auto Scaling group, the instances are also registered with the target groups. For more information, see Attach EC2 instances to your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/attach-instance-asg.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_AttachInstances
export def "get-attach-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list<string> # The IDs of the instances. You can specify up to 20 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --action: string@action-completer # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: InstanceIds, var: instance_ids, style: multi}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: Action, var: action, required: true, default: AttachInstances}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_ids: $instance_ids, auto_scaling_group_name: $auto_scaling_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches one or more EC2 instances to the specified Auto Scaling group. When you attach instances, Amazon EC2 Auto Scaling increases the desired capacity of the group by the number of instances being attached. If the number of instances being attached plus the desired capacity of the group exceeds the maximum size of the group, the operation fails. If there is a Classic Load Balancer attached to your Auto Scaling group, the instances are also registered with the load balancer. If there are target groups attached to your Auto Scaling group, the instances are also registered with the target groups. For more information, see Attach EC2 instances to your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/attach-instance-asg.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_AttachInstances
export def "post-attach-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: AttachInstances}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by AttachTrafficSources, which can attach multiple traffic sources types. We recommend using AttachTrafficSources to simplify how you manage traffic sources. However, we continue to support AttachLoadBalancerTargetGroups. You can use both the original AttachLoadBalancerTargetGroups API operation and AttachTrafficSources on the same Auto Scaling group. Attaches one or more target groups to the specified Auto Scaling group. This operation is used with the following load balancer types: Application Load Balancer - Operates at the application layer (layer 7) and supports HTTP and HTTPS. Network Load Balancer - Operates at the transport layer (layer 4) and supports TCP, TLS, and UDP. Gateway Load Balancer - Operates at the network layer (layer 3). To describe the target groups for an Auto Scaling group, call the DescribeLoadBalancerTargetGroups API. To detach the target group from the Auto Scaling group, call the DetachLoadBalancerTargetGroups API. This operation is additive and does not detach existing target groups or Classic Load Balancers from the Auto Scaling group. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_AttachLoadBalancerTargetGroups
export def "get-attach-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --target-group-ar-ns: list<string> # The Amazon Resource Names (ARNs) of the target groups. You can specify up to 10 target groups. To get the ARN of a target group, use the Elastic Load Balancing DescribeTargetGroups (https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_DescribeTargetGroups.html) API operation. (required)
  --action: string@action-completer-1 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: TargetGroupARNs, var: target_group_ar_ns, style: multi, required: true}, {name: Action, var: action, required: true, default: AttachLoadBalancerTargetGroups}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, target_group_ar_ns: $target_group_ar_ns, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by AttachTrafficSources, which can attach multiple traffic sources types. We recommend using AttachTrafficSources to simplify how you manage traffic sources. However, we continue to support AttachLoadBalancerTargetGroups. You can use both the original AttachLoadBalancerTargetGroups API operation and AttachTrafficSources on the same Auto Scaling group. Attaches one or more target groups to the specified Auto Scaling group. This operation is used with the following load balancer types: Application Load Balancer - Operates at the application layer (layer 7) and supports HTTP and HTTPS. Network Load Balancer - Operates at the transport layer (layer 4) and supports TCP, TLS, and UDP. Gateway Load Balancer - Operates at the network layer (layer 3). To describe the target groups for an Auto Scaling group, call the DescribeLoadBalancerTargetGroups API. To detach the target group from the Auto Scaling group, call the DetachLoadBalancerTargetGroups API. This operation is additive and does not detach existing target groups or Classic Load Balancers from the Auto Scaling group. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_AttachLoadBalancerTargetGroups
export def "post-attach-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: AttachLoadBalancerTargetGroups}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by AttachTrafficSources, which can attach multiple traffic sources types. We recommend using AttachTrafficSources to simplify how you manage traffic sources. However, we continue to support AttachLoadBalancers. You can use both the original AttachLoadBalancers API operation and AttachTrafficSources on the same Auto Scaling group. Attaches one or more Classic Load Balancers to the specified Auto Scaling group. Amazon EC2 Auto Scaling registers the running instances with these Classic Load Balancers. To describe the load balancers for an Auto Scaling group, call the DescribeLoadBalancers API. To detach a load balancer from the Auto Scaling group, call the DetachLoadBalancers API. This operation is additive and does not detach existing Classic Load Balancers or target groups from the Auto Scaling group. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_AttachLoadBalancers
export def "get-attach-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --load-balancer-names: list<string> # The names of the load balancers. You can specify up to 10 load balancers. (required)
  --action: string@action-completer-2 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: LoadBalancerNames, var: load_balancer_names, style: multi, required: true}, {name: Action, var: action, required: true, default: AttachLoadBalancers}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, load_balancer_names: $load_balancer_names, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by AttachTrafficSources, which can attach multiple traffic sources types. We recommend using AttachTrafficSources to simplify how you manage traffic sources. However, we continue to support AttachLoadBalancers. You can use both the original AttachLoadBalancers API operation and AttachTrafficSources on the same Auto Scaling group. Attaches one or more Classic Load Balancers to the specified Auto Scaling group. Amazon EC2 Auto Scaling registers the running instances with these Classic Load Balancers. To describe the load balancers for an Auto Scaling group, call the DescribeLoadBalancers API. To detach a load balancer from the Auto Scaling group, call the DetachLoadBalancers API. This operation is additive and does not detach existing Classic Load Balancers or target groups from the Auto Scaling group. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_AttachLoadBalancers
export def "post-attach-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: AttachLoadBalancers}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches one or more traffic sources to the specified Auto Scaling group. You can use any of the following as traffic sources for an Auto Scaling group: Application Load Balancer Classic Load Balancer Gateway Load Balancer Network Load Balancer VPC Lattice This operation is additive and does not detach existing traffic sources from the Auto Scaling group. After the operation completes, use the DescribeTrafficSources API to return details about the state of the attachments between traffic sources and your Auto Scaling group. To detach a traffic source from the Auto Scaling group, call the DetachTrafficSources API.
#
# GET /
# operationId: GET_AttachTrafficSources
export def "get-attach-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --traffic-sources: list # The unique identifiers of one or more traffic sources. You can specify up to 10 traffic sources. (required)
  --action: string@action-completer-3 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: TrafficSources, var: traffic_sources, style: multi, required: true}, {name: Action, var: action, required: true, default: AttachTrafficSources}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, traffic_sources: $traffic_sources, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attaches one or more traffic sources to the specified Auto Scaling group. You can use any of the following as traffic sources for an Auto Scaling group: Application Load Balancer Classic Load Balancer Gateway Load Balancer Network Load Balancer VPC Lattice This operation is additive and does not detach existing traffic sources from the Auto Scaling group. After the operation completes, use the DescribeTrafficSources API to return details about the state of the attachments between traffic sources and your Auto Scaling group. To detach a traffic source from the Auto Scaling group, call the DetachTrafficSources API.
#
# POST /
# operationId: POST_AttachTrafficSources
export def "post-attach-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: AttachTrafficSources}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes one or more scheduled actions for the specified Auto Scaling group.
#
# GET /
# operationId: GET_BatchDeleteScheduledAction
export def "get-batch-delete-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --scheduled-action-names: list<string> # The names of the scheduled actions to delete. The maximum number allowed is 50. (required)
  --action: string@action-completer-4 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ScheduledActionNames, var: scheduled_action_names, style: multi, required: true}, {name: Action, var: action, required: true, default: BatchDeleteScheduledAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, scheduled_action_names: $scheduled_action_names, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes one or more scheduled actions for the specified Auto Scaling group.
#
# POST /
# operationId: POST_BatchDeleteScheduledAction
export def "post-batch-delete-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-4 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: BatchDeleteScheduledAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates one or more scheduled scaling actions for an Auto Scaling group.
#
# GET /
# operationId: GET_BatchPutScheduledUpdateGroupAction
export def "get-batch-put-scheduled-update-group-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --scheduled-update-group-actions: list # One or more scheduled actions. The maximum number allowed is 50. (required)
  --action: string@action-completer-5 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ScheduledUpdateGroupActions, var: scheduled_update_group_actions, style: multi, required: true}, {name: Action, var: action, required: true, default: BatchPutScheduledUpdateGroupAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, scheduled_update_group_actions: $scheduled_update_group_actions, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates one or more scheduled scaling actions for an Auto Scaling group.
#
# POST /
# operationId: POST_BatchPutScheduledUpdateGroupAction
export def "post-batch-put-scheduled-update-group-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: BatchPutScheduledUpdateGroupAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an instance refresh or rollback that is in progress. If an instance refresh or rollback is not in progress, an ActiveInstanceRefreshNotFound error occurs. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. When you cancel an instance refresh, this does not roll back any changes that it made. Use the RollbackInstanceRefresh API to roll back instead.
#
# GET /
# operationId: GET_CancelInstanceRefresh
export def "get-cancel-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --action: string@action-completer-6 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: Action, var: action, required: true, default: CancelInstanceRefresh}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an instance refresh or rollback that is in progress. If an instance refresh or rollback is not in progress, an ActiveInstanceRefreshNotFound error occurs. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. When you cancel an instance refresh, this does not roll back any changes that it made. Use the RollbackInstanceRefresh API to roll back instead.
#
# POST /
# operationId: POST_CancelInstanceRefresh
export def "post-cancel-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-6 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CancelInstanceRefresh}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completes the lifecycle action for the specified token or instance with the specified result. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_CompleteLifecycleAction
export def "get-complete-lifecycle-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lifecycle-hook-name: string # The name of the lifecycle hook. (required)
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --lifecycle-action-token: string # A universally unique identifier (UUID) that identifies a specific lifecycle action associated with an instance. Amazon EC2 Auto Scaling sends this token to the notification target you specified when you created the lifecycle hook.
  --lifecycle-action-result: string # The action for the group to take. You can specify either CONTINUE or ABANDON. (required)
  --instance-id: string # The ID of the instance.
  --action: string@action-completer-7 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: LifecycleHookName, var: lifecycle_hook_name, required: true}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: LifecycleActionToken, var: lifecycle_action_token}, {name: LifecycleActionResult, var: lifecycle_action_result, required: true}, {name: InstanceId, var: instance_id}, {name: Action, var: action, required: true, default: CompleteLifecycleAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    lifecycle_hook_name: $lifecycle_hook_name, auto_scaling_group_name: $auto_scaling_group_name, lifecycle_action_token: $lifecycle_action_token, lifecycle_action_result: $lifecycle_action_result, instance_id: $instance_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completes the lifecycle action for the specified token or instance with the specified result. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_CompleteLifecycleAction
export def "post-complete-lifecycle-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-7 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CompleteLifecycleAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# We strongly recommend using a launch template when calling this operation to ensure full functionality for Amazon EC2 Auto Scaling and Amazon EC2. Creates an Auto Scaling group with the specified name and attributes. If you exceed your maximum limit of Auto Scaling groups, the call fails. To query this limit, call the DescribeAccountLimits API. For information about updating this limit, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide. For introductory exercises for creating an Auto Scaling group, see Getting started with Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/GettingStartedTutorial.html) and Tutorial: Set up a scaled and load-balanced application (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-register-lbs-with-asg.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Auto Scaling groups (https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) in the Amazon EC2 Auto Scaling User Guide. Every Auto Scaling group has three size properties (DesiredCapacity, MaxSize, and MinSize). Usually, you set these sizes based on a specific number of instances. However, if you configure a mixed instances policy that defines weights for the instance types, you must specify these sizes with the same units that you use for weighting instances.
#
# GET /
# operationId: GET_CreateAutoScalingGroup
export def "get-create-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. This name must be unique per Region per account. The name can contain any ASCII character 33 to 126 including most punctuation characters, digits, and upper and lowercased letters. You cannot use a colon (:) in the name. (required)
  --launch-configuration-name: string # The name of the launch configuration to use to launch instances. Conditional: You must specify either a launch template (LaunchTemplate or MixedInstancesPolicy) or a launch configuration (LaunchConfigurationName or InstanceId).
  --launch-template: record # Information used to specify the launch template and version to use to launch instances. Conditional: You must specify either a launch template (LaunchTemplate or MixedInstancesPolicy) or a launch configuration (LaunchConfigurationName or InstanceId). The launch template that is specified must be configured for use with an Auto Scaling group. For more information, see Creating a launch template for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-launch-template.html) in the Amazon EC2 Auto Scaling User Guide.
  --mixed-instances-policy: record # The mixed instances policy. For more information, see Auto Scaling groups with multiple instance types and purchase options (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-mixed-instances-groups.html) in the Amazon EC2 Auto Scaling User Guide.
  --instance-id: string # The ID of the instance used to base the launch configuration on. If specified, Amazon EC2 Auto Scaling uses the configuration values from the specified instance to create a new launch configuration. To get the instance ID, use the Amazon EC2 DescribeInstances (https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html) API operation. For more information, see Creating an Auto Scaling group using an EC2 instance (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-asg-from-instance.html) in the Amazon EC2 Auto Scaling User Guide.
  --min-size: int # The minimum size of the group. (required)
  --max-size: int # The maximum size of the group. With a mixed instances policy that uses instance weighting, Amazon EC2 Auto Scaling may need to go above MaxSize to meet your capacity requirements. In this event, Amazon EC2 Auto Scaling will never go above MaxSize by more than your largest instance weight (weights that define how many units each instance contributes to the desired capacity of the group). (required)
  --desired-capacity: int # The desired capacity is the initial capacity of the Auto Scaling group at the time of its creation and the capacity it attempts to maintain. It can scale beyond this capacity if you configure auto scaling. This number must be greater than or equal to the minimum size of the group and less than or equal to the maximum size of the group. If you do not specify a desired capacity, the default is the minimum size of the group.
  --default-cooldown: int # Only needed if you use simple scaling policies. The amount of time, in seconds, between one scaling activity ending and another one starting due to simple scaling policies. For more information, see Scaling cooldowns for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/Cooldown.html) in the Amazon EC2 Auto Scaling User Guide. Default: 300 seconds
  --availability-zones: list<string> # A list of Availability Zones where instances in the Auto Scaling group can be created. Used for launching into the default VPC subnet in each Availability Zone when not using the VPCZoneIdentifier property, or for attaching a network interface when an existing network interface ID is specified in a launch template.
  --load-balancer-names: list<string> # A list of Classic Load Balancers associated with this Auto Scaling group. For Application Load Balancers, Network Load Balancers, and Gateway Load Balancers, specify the TargetGroupARNs property instead.
  --target-group-ar-ns: list<string> # The Amazon Resource Names (ARN) of the Elastic Load Balancing target groups to associate with the Auto Scaling group. Instances are registered as targets with the target groups. The target groups receive incoming traffic and route requests to one or more registered targets. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
  --health-check-type: string # A comma-separated value string of one or more health check types. The valid values are EC2, ELB, and VPC_LATTICE. EC2 is the default health check and cannot be disabled. For more information, see Health checks for Auto Scaling instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) in the Amazon EC2 Auto Scaling User Guide. Only specify EC2 if you must clear a value that was previously set.
  --health-check-grace-period: int # The amount of time, in seconds, that Amazon EC2 Auto Scaling waits before checking the health status of an EC2 instance that has come into service and marking it unhealthy due to a failed health check. This is useful if your instances do not immediately pass their health checks after they enter the InService state. For more information, see Set the health check grace period for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/health-check-grace-period.html) in the Amazon EC2 Auto Scaling User Guide. Default: 0 seconds
  --placement-group: string # The name of the placement group into which to launch your instances. For more information, see Placement groups (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/placement-groups.html) in the Amazon EC2 User Guide for Linux Instances. A cluster placement group is a logical grouping of instances within a single Availability Zone. You cannot specify multiple Availability Zones and a cluster placement group.
  --vpc-zone-identifier: string # A comma-separated list of subnet IDs for a virtual private cloud (VPC) where instances in the Auto Scaling group can be created. If you specify VPCZoneIdentifier with AvailabilityZones, the subnets that you specify must reside in those Availability Zones.
  --termination-policies: list<string> # A policy or a list of policies that are used to select the instance to terminate. These policies are executed in the order that you list them. For more information, see Work with Amazon EC2 Auto Scaling termination policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html) in the Amazon EC2 Auto Scaling User Guide. Valid values: Default | AllocationStrategy | ClosestToNextInstanceHour | NewestInstance | OldestInstance | OldestLaunchConfiguration | OldestLaunchTemplate | arn:aws:lambda:region:account-id:function:my-function:my-alias
  --new-instances-protected-from-scale-in: oneof<nothing, bool> # Indicates whether newly launched instances are protected from termination by Amazon EC2 Auto Scaling when scaling in. For more information about preventing instances from terminating on scale in, see Using instance scale-in protection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-instance-protection.html) in the Amazon EC2 Auto Scaling User Guide.
  --capacity-rebalance: oneof<nothing, bool> # Indicates whether Capacity Rebalancing is enabled. Otherwise, Capacity Rebalancing is disabled. When you turn on Capacity Rebalancing, Amazon EC2 Auto Scaling attempts to launch a Spot Instance whenever Amazon EC2 notifies that a Spot Instance is at an elevated risk of interruption. After launching a new instance, it then terminates an old instance. For more information, see Use Capacity Rebalancing to handle Amazon EC2 Spot Interruptions (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html) in the in the Amazon EC2 Auto Scaling User Guide.
  --lifecycle-hook-specification-list: list # One or more lifecycle hooks to add to the Auto Scaling group before instances are launched.
  --tags: list # One or more tags. You can tag your Auto Scaling group and propagate the tags to the Amazon EC2 instances it launches. Tags are not propagated to Amazon EBS volumes. To add tags to Amazon EBS volumes, specify the tags in a launch template but use caution. If the launch template specifies an instance tag with a key that is also specified for the Auto Scaling group, Amazon EC2 Auto Scaling overrides the value of that instance tag with the value specified by the Auto Scaling group. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
  --service-linked-role-arn: string # The Amazon Resource Name (ARN) of the service-linked role that the Auto Scaling group uses to call other Amazon Web Services service on your behalf. By default, Amazon EC2 Auto Scaling uses a service-linked role named AWSServiceRoleForAutoScaling, which it creates if it does not exist. For more information, see Service-linked roles (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-service-linked-role.html) in the Amazon EC2 Auto Scaling User Guide.
  --max-instance-lifetime: int # The maximum amount of time, in seconds, that an instance can be in service. The default is null. If specified, the value must be either 0 or a number equal to or greater than 86,400 seconds (1 day). For more information, see Replacing Auto Scaling instances based on maximum instance lifetime (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-max-instance-lifetime.html) in the Amazon EC2 Auto Scaling User Guide.
  --context: string # Reserved.
  --desired-capacity-type: string # The unit of measurement for the value specified for desired capacity. Amazon EC2 Auto Scaling supports DesiredCapacityType for attribute-based instance type selection only. For more information, see Creating an Auto Scaling group using attribute-based instance type selection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-asg-instance-type-requirements.html) in the Amazon EC2 Auto Scaling User Guide. By default, Amazon EC2 Auto Scaling specifies units, which translates into number of instances. Valid values: units | vcpu | memory-mib
  --default-instance-warmup: int # The amount of time, in seconds, until a new instance is considered to have finished initializing and resource consumption to become stable after it enters the InService state. During an instance refresh, Amazon EC2 Auto Scaling waits for the warm-up period after it replaces an instance before it moves on to replacing the next instance. Amazon EC2 Auto Scaling also waits for the warm-up period before aggregating the metrics for new instances with existing instances in the Amazon CloudWatch metrics that are used for scaling, resulting in more reliable usage data. For more information, see Set the default instance warmup for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-default-instance-warmup.html) in the Amazon EC2 Auto Scaling User Guide. To manage various warm-up settings at the group level, we recommend that you set the default instance warmup, even if it is set to 0 seconds. To remove a value that you previously set, include the property but specify -1 for the value. However, we strongly recommend keeping the default instance warmup enabled by specifying a value of 0 or other nominal value. Default: None
  --traffic-sources: list # The list of traffic sources to attach to this Auto Scaling group. You can use any of the following as traffic sources for an Auto Scaling group: Classic Load Balancer, Application Load Balancer, Gateway Load Balancer, Network Load Balancer, and VPC Lattice.
  --action: string@action-completer-8 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: LaunchConfigurationName, var: launch_configuration_name}, {name: LaunchTemplate, var: launch_template, style: multi}, {name: MixedInstancesPolicy, var: mixed_instances_policy, style: multi}, {name: InstanceId, var: instance_id}, {name: MinSize, var: min_size, required: true}, {name: MaxSize, var: max_size, required: true}, {name: DesiredCapacity, var: desired_capacity}, {name: DefaultCooldown, var: default_cooldown}, {name: AvailabilityZones, var: availability_zones, style: multi}, {name: LoadBalancerNames, var: load_balancer_names, style: multi}, {name: TargetGroupARNs, var: target_group_ar_ns, style: multi}, {name: HealthCheckType, var: health_check_type}, {name: HealthCheckGracePeriod, var: health_check_grace_period}, {name: PlacementGroup, var: placement_group}, {name: VPCZoneIdentifier, var: vpc_zone_identifier}, {name: TerminationPolicies, var: termination_policies, style: multi}, {name: NewInstancesProtectedFromScaleIn, var: new_instances_protected_from_scale_in}, {name: CapacityRebalance, var: capacity_rebalance}, {name: LifecycleHookSpecificationList, var: lifecycle_hook_specification_list, style: multi}, {name: Tags, var: tags, style: multi}, {name: ServiceLinkedRoleARN, var: service_linked_role_arn}, {name: MaxInstanceLifetime, var: max_instance_lifetime}, {name: Context, var: context}, {name: DesiredCapacityType, var: desired_capacity_type}, {name: DefaultInstanceWarmup, var: default_instance_warmup}, {name: TrafficSources, var: traffic_sources, style: multi}, {name: Action, var: action, required: true, default: CreateAutoScalingGroup}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, launch_configuration_name: $launch_configuration_name, launch_template: $launch_template, mixed_instances_policy: $mixed_instances_policy, instance_id: $instance_id, min_size: $min_size, max_size: $max_size, desired_capacity: $desired_capacity, default_cooldown: $default_cooldown, availability_zones: $availability_zones, load_balancer_names: $load_balancer_names, target_group_ar_ns: $target_group_ar_ns, health_check_type: $health_check_type, health_check_grace_period: $health_check_grace_period, placement_group: $placement_group, vpc_zone_identifier: $vpc_zone_identifier, termination_policies: $termination_policies, new_instances_protected_from_scale_in: $new_instances_protected_from_scale_in, capacity_rebalance: $capacity_rebalance, lifecycle_hook_specification_list: $lifecycle_hook_specification_list, tags: $tags, service_linked_role_arn: $service_linked_role_arn, max_instance_lifetime: $max_instance_lifetime, context: $context, desired_capacity_type: $desired_capacity_type, default_instance_warmup: $default_instance_warmup, traffic_sources: $traffic_sources, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# We strongly recommend using a launch template when calling this operation to ensure full functionality for Amazon EC2 Auto Scaling and Amazon EC2. Creates an Auto Scaling group with the specified name and attributes. If you exceed your maximum limit of Auto Scaling groups, the call fails. To query this limit, call the DescribeAccountLimits API. For information about updating this limit, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide. For introductory exercises for creating an Auto Scaling group, see Getting started with Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/GettingStartedTutorial.html) and Tutorial: Set up a scaled and load-balanced application (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-register-lbs-with-asg.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Auto Scaling groups (https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) in the Amazon EC2 Auto Scaling User Guide. Every Auto Scaling group has three size properties (DesiredCapacity, MaxSize, and MinSize). Usually, you set these sizes based on a specific number of instances. However, if you configure a mixed instances policy that defines weights for the instance types, you must specify these sizes with the same units that you use for weighting instances.
#
# POST /
# operationId: POST_CreateAutoScalingGroup
export def "post-create-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-8 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateAutoScalingGroup}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a launch configuration. If you exceed your maximum limit of launch configurations, the call fails. To query this limit, call the DescribeAccountLimits API. For information about updating this limit, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Launch configurations (https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html) in the Amazon EC2 Auto Scaling User Guide. Amazon EC2 Auto Scaling configures instances launched as part of an Auto Scaling group using either a launch template or a launch configuration. We strongly recommend that you do not use launch configurations. They do not provide full functionality for Amazon EC2 Auto Scaling or Amazon EC2. For information about using launch templates, see Launch templates (https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-templates.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_CreateLaunchConfiguration
export def "get-create-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --launch-configuration-name: string # The name of the launch configuration. This name must be unique per Region per account. (required)
  --image-id: string # The ID of the Amazon Machine Image (AMI) that was assigned during registration. For more information, see Finding a Linux AMI (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html) in the Amazon EC2 User Guide for Linux Instances. If you specify InstanceId, an ImageId is not required.
  --key-name: string # The name of the key pair. For more information, see Amazon EC2 key pairs and Linux instances (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) in the Amazon EC2 User Guide for Linux Instances.
  --security-groups: list<string> # A list that contains the security group IDs to assign to the instances in the Auto Scaling group. For more information, see Control traffic to resources using security groups (https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_SecurityGroups.html) in the Amazon Virtual Private Cloud User Guide.
  --classic-link-vpc-id: string # Available for backward compatibility.
  --classic-link-vpc-security-groups: list<string> # Available for backward compatibility.
  --user-data: string # The user data to make available to the launched EC2 instances. For more information, see Instance metadata and user data (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) (Linux) and Instance metadata and user data (https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-instance-metadata.html) (Windows). If you are using a command line tool, base64-encoding is performed for you, and you can load the text from a file. Otherwise, you must provide base64-encoded text. User data is limited to 16 KB.
  --instance-id: string # The ID of the instance to use to create the launch configuration. The new launch configuration derives attributes from the instance, except for the block device mapping. To create a launch configuration with a block device mapping or override any other instance attributes, specify them as part of the same request. For more information, see Creating a launch configuration using an EC2 instance (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-lc-with-instanceID.html) in the Amazon EC2 Auto Scaling User Guide.
  --instance-type: string # Specifies the instance type of the EC2 instance. For information about available instance types, see Available instance types (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#AvailableInstanceTypes) in the Amazon EC2 User Guide for Linux Instances. If you specify InstanceId, an InstanceType is not required.
  --kernel-id: string # The ID of the kernel associated with the AMI. We recommend that you use PV-GRUB instead of kernels and RAM disks. For more information, see User provided kernels (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html) in the Amazon EC2 User Guide for Linux Instances.
  --ramdisk-id: string # The ID of the RAM disk to select. We recommend that you use PV-GRUB instead of kernels and RAM disks. For more information, see User provided kernels (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html) in the Amazon EC2 User Guide for Linux Instances.
  --block-device-mappings: list # The block device mapping entries that define the block devices to attach to the instances at launch. By default, the block devices specified in the block device mapping for the AMI are used. For more information, see Block device mappings (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/block-device-mapping-concepts.html) in the Amazon EC2 User Guide for Linux Instances.
  --instance-monitoring: record # Controls whether instances in this group are launched with detailed (true) or basic (false) monitoring. The default value is true (enabled). When detailed monitoring is enabled, Amazon CloudWatch generates metrics every minute and your account is charged a fee. When you disable detailed monitoring, CloudWatch generates metrics every 5 minutes. For more information, see Configure Monitoring for Auto Scaling Instances (https://docs.aws.amazon.com/autoscaling/latest/userguide/enable-as-instance-metrics.html) in the Amazon EC2 Auto Scaling User Guide.
  --spot-price: string # The maximum hourly price to be paid for any Spot Instance launched to fulfill the request. Spot Instances are launched when the price you specify exceeds the current Spot price. For more information, see Request Spot Instances for fault-tolerant and flexible applications (https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-template-spot-instances.html) in the Amazon EC2 Auto Scaling User Guide. Valid Range: Minimum value of 0.001 When you change your maximum price by creating a new launch configuration, running instances will continue to run as long as the maximum price for those running instances is higher than the current Spot price.
  --iam-instance-profile: string # The name or the Amazon Resource Name (ARN) of the instance profile associated with the IAM role for the instance. The instance profile contains the IAM role. For more information, see IAM role for applications that run on Amazon EC2 instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/us-iam-role.html) in the Amazon EC2 Auto Scaling User Guide.
  --ebs-optimized: oneof<nothing, bool> # Specifies whether the launch configuration is optimized for EBS I/O (true) or not (false). The optimization provides dedicated throughput to Amazon EBS and an optimized configuration stack to provide optimal I/O performance. This optimization is not available with all instance types. Additional fees are incurred when you enable EBS optimization for an instance type that is not EBS-optimized by default. For more information, see Amazon EBS-optimized instances (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSOptimized.html) in the Amazon EC2 User Guide for Linux Instances. The default value is false.
  --associate-public-ip-address: oneof<nothing, bool> # Specifies whether to assign a public IPv4 address to the group's instances. If the instance is launched into a default subnet, the default is to assign a public IPv4 address, unless you disabled the option to assign a public IPv4 address on the subnet. If the instance is launched into a nondefault subnet, the default is not to assign a public IPv4 address, unless you enabled the option to assign a public IPv4 address on the subnet. If you specify true, each instance in the Auto Scaling group receives a unique public IPv4 address. For more information, see Launching Auto Scaling instances in a VPC (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-in-vpc.html) in the Amazon EC2 Auto Scaling User Guide. If you specify this property, you must specify at least one subnet for VPCZoneIdentifier when you create your group.
  --placement-tenancy: string # The tenancy of the instance, either default or dedicated. An instance with dedicated tenancy runs on isolated, single-tenant hardware and can only be launched into a VPC. To launch dedicated instances into a shared tenancy VPC (a VPC with the instance placement tenancy attribute set to default), you must set the value of this property to dedicated. For more information, see Configuring instance tenancy with Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-dedicated-instances.html) in the Amazon EC2 Auto Scaling User Guide. If you specify PlacementTenancy, you must specify at least one subnet for VPCZoneIdentifier when you create your group. Valid values: default | dedicated
  --metadata-options: record # The metadata options for the instances. For more information, see Configuring the Instance Metadata Options (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-launch-config.html#launch-configurations-imds) in the Amazon EC2 Auto Scaling User Guide.
  --action: string@action-completer-9 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: LaunchConfigurationName, var: launch_configuration_name, required: true}, {name: ImageId, var: image_id}, {name: KeyName, var: key_name}, {name: SecurityGroups, var: security_groups, style: multi}, {name: ClassicLinkVPCId, var: classic_link_vpc_id}, {name: ClassicLinkVPCSecurityGroups, var: classic_link_vpc_security_groups, style: multi}, {name: UserData, var: user_data}, {name: InstanceId, var: instance_id}, {name: InstanceType, var: instance_type}, {name: KernelId, var: kernel_id}, {name: RamdiskId, var: ramdisk_id}, {name: BlockDeviceMappings, var: block_device_mappings, style: multi}, {name: InstanceMonitoring, var: instance_monitoring, style: multi}, {name: SpotPrice, var: spot_price}, {name: IamInstanceProfile, var: iam_instance_profile}, {name: EbsOptimized, var: ebs_optimized}, {name: AssociatePublicIpAddress, var: associate_public_ip_address}, {name: PlacementTenancy, var: placement_tenancy}, {name: MetadataOptions, var: metadata_options, style: multi}, {name: Action, var: action, required: true, default: CreateLaunchConfiguration}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    launch_configuration_name: $launch_configuration_name, image_id: $image_id, key_name: $key_name, security_groups: $security_groups, classic_link_vpc_id: $classic_link_vpc_id, classic_link_vpc_security_groups: $classic_link_vpc_security_groups, user_data: $user_data, instance_id: $instance_id, instance_type: $instance_type, kernel_id: $kernel_id, ramdisk_id: $ramdisk_id, block_device_mappings: $block_device_mappings, instance_monitoring: $instance_monitoring, spot_price: $spot_price, iam_instance_profile: $iam_instance_profile, ebs_optimized: $ebs_optimized, associate_public_ip_address: $associate_public_ip_address, placement_tenancy: $placement_tenancy, metadata_options: $metadata_options, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a launch configuration. If you exceed your maximum limit of launch configurations, the call fails. To query this limit, call the DescribeAccountLimits API. For information about updating this limit, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Launch configurations (https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html) in the Amazon EC2 Auto Scaling User Guide. Amazon EC2 Auto Scaling configures instances launched as part of an Auto Scaling group using either a launch template or a launch configuration. We strongly recommend that you do not use launch configurations. They do not provide full functionality for Amazon EC2 Auto Scaling or Amazon EC2. For information about using launch templates, see Launch templates (https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-templates.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_CreateLaunchConfiguration
export def "post-create-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-9 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateLaunchConfiguration}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates tags for the specified Auto Scaling group. When you specify a tag with a key that already exists, the operation overwrites the previous tag definition, and you do not get an error message. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_CreateOrUpdateTags
export def "get-create-or-update-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list # One or more tags. (required)
  --action: string@action-completer-10 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Tags, var: tags, style: multi, required: true}, {name: Action, var: action, required: true, default: CreateOrUpdateTags}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates tags for the specified Auto Scaling group. When you specify a tag with a key that already exists, the operation overwrites the previous tag definition, and you do not get an error message. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_CreateOrUpdateTags
export def "post-create-or-update-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-10 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: CreateOrUpdateTags}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Auto Scaling group. If the group has instances or scaling activities in progress, you must specify the option to force the deletion in order for it to succeed. The force delete operation will also terminate the EC2 instances. If the group has a warm pool, the force delete option also deletes the warm pool. To remove instances from the Auto Scaling group before deleting it, call the DetachInstances API with the list of instances and the option to decrement the desired capacity. This ensures that Amazon EC2 Auto Scaling does not launch replacement instances. To terminate all instances before deleting the Auto Scaling group, call the UpdateAutoScalingGroup API and set the minimum size and desired capacity of the Auto Scaling group to zero. If the group has scaling policies, deleting the group deletes the policies, the underlying alarm actions, and any alarm that no longer has an associated action. For more information, see Delete your Auto Scaling infrastructure (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-process-shutdown.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DeleteAutoScalingGroup
export def "get-delete-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --force-delete: oneof<nothing, bool> # Specifies that the group is to be deleted along with all instances associated with the group, without waiting for all instances to be terminated. This action also deletes any outstanding lifecycle actions associated with the group.
  --action: string@action-completer-11 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ForceDelete, var: force_delete}, {name: Action, var: action, required: true, default: DeleteAutoScalingGroup}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, force_delete: $force_delete, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified Auto Scaling group. If the group has instances or scaling activities in progress, you must specify the option to force the deletion in order for it to succeed. The force delete operation will also terminate the EC2 instances. If the group has a warm pool, the force delete option also deletes the warm pool. To remove instances from the Auto Scaling group before deleting it, call the DetachInstances API with the list of instances and the option to decrement the desired capacity. This ensures that Amazon EC2 Auto Scaling does not launch replacement instances. To terminate all instances before deleting the Auto Scaling group, call the UpdateAutoScalingGroup API and set the minimum size and desired capacity of the Auto Scaling group to zero. If the group has scaling policies, deleting the group deletes the policies, the underlying alarm actions, and any alarm that no longer has an associated action. For more information, see Delete your Auto Scaling infrastructure (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-process-shutdown.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DeleteAutoScalingGroup
export def "post-delete-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-11 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteAutoScalingGroup}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified launch configuration. The launch configuration must not be attached to an Auto Scaling group. When this call completes, the launch configuration is no longer available for use.
#
# GET /
# operationId: GET_DeleteLaunchConfiguration
export def "get-delete-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --launch-configuration-name: string # The name of the launch configuration. (required)
  --action: string@action-completer-12 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: LaunchConfigurationName, var: launch_configuration_name, required: true}, {name: Action, var: action, required: true, default: DeleteLaunchConfiguration}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    launch_configuration_name: $launch_configuration_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified launch configuration. The launch configuration must not be attached to an Auto Scaling group. When this call completes, the launch configuration is no longer available for use.
#
# POST /
# operationId: POST_DeleteLaunchConfiguration
export def "post-delete-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-12 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteLaunchConfiguration}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified lifecycle hook. If there are any outstanding lifecycle actions, they are completed first (ABANDON for launching instances, CONTINUE for terminating instances).
#
# GET /
# operationId: GET_DeleteLifecycleHook
export def "get-delete-lifecycle-hook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lifecycle-hook-name: string # The name of the lifecycle hook. (required)
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --action: string@action-completer-13 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: LifecycleHookName, var: lifecycle_hook_name, required: true}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: Action, var: action, required: true, default: DeleteLifecycleHook}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    lifecycle_hook_name: $lifecycle_hook_name, auto_scaling_group_name: $auto_scaling_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified lifecycle hook. If there are any outstanding lifecycle actions, they are completed first (ABANDON for launching instances, CONTINUE for terminating instances).
#
# POST /
# operationId: POST_DeleteLifecycleHook
export def "post-delete-lifecycle-hook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-13 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteLifecycleHook}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified notification.
#
# GET /
# operationId: GET_DeleteNotificationConfiguration
export def "get-delete-notification-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic. (required)
  --action: string@action-completer-14 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: TopicARN, var: topic_arn, required: true}, {name: Action, var: action, required: true, default: DeleteNotificationConfiguration}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, topic_arn: $topic_arn, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified notification.
#
# POST /
# operationId: POST_DeleteNotificationConfiguration
export def "post-delete-notification-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-14 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteNotificationConfiguration}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified scaling policy. Deleting either a step scaling policy or a simple scaling policy deletes the underlying alarm action, but does not delete the alarm, even if it no longer has an associated action. For more information, see Deleting a scaling policy (https://docs.aws.amazon.com/autoscaling/ec2/userguide/deleting-scaling-policy.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DeletePolicy
export def "get-delete-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --policy-name: string # The name or Amazon Resource Name (ARN) of the policy. (required)
  --action: string@action-completer-15 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name}, {name: PolicyName, var: policy_name, required: true}, {name: Action, var: action, required: true, default: DeletePolicy}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, policy_name: $policy_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified scaling policy. Deleting either a step scaling policy or a simple scaling policy deletes the underlying alarm action, but does not delete the alarm, even if it no longer has an associated action. For more information, see Deleting a scaling policy (https://docs.aws.amazon.com/autoscaling/ec2/userguide/deleting-scaling-policy.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DeletePolicy
export def "post-delete-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-15 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeletePolicy}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified scheduled action.
#
# GET /
# operationId: GET_DeleteScheduledAction
export def "get-delete-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --scheduled-action-name: string # The name of the action to delete. (required)
  --action: string@action-completer-16 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ScheduledActionName, var: scheduled_action_name, required: true}, {name: Action, var: action, required: true, default: DeleteScheduledAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, scheduled_action_name: $scheduled_action_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified scheduled action.
#
# POST /
# operationId: POST_DeleteScheduledAction
export def "post-delete-scheduled-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-16 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteScheduledAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified tags.
#
# GET /
# operationId: GET_DeleteTags
export def "get-delete-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list # One or more tags. (required)
  --action: string@action-completer-17 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Tags, var: tags, style: multi, required: true}, {name: Action, var: action, required: true, default: DeleteTags}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tags: $tags, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified tags.
#
# POST /
# operationId: POST_DeleteTags
export def "post-delete-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-17 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteTags}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the warm pool for the specified Auto Scaling group. For more information, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DeleteWarmPool
export def "get-delete-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --force-delete: oneof<nothing, bool> # Specifies that the warm pool is to be deleted along with all of its associated instances, without waiting for all instances to be terminated. This parameter also deletes any outstanding lifecycle actions associated with the warm pool instances.
  --action: string@action-completer-18 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ForceDelete, var: force_delete}, {name: Action, var: action, required: true, default: DeleteWarmPool}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, force_delete: $force_delete, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the warm pool for the specified Auto Scaling group. For more information, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DeleteWarmPool
export def "post-delete-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-18 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DeleteWarmPool}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the current Amazon EC2 Auto Scaling resource quotas for your account. When you establish an Amazon Web Services account, the account has initial quotas on the maximum number of Auto Scaling groups and launch configurations that you can create in a given Region. For more information, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeAccountLimits
export def "get-describe-account-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-19 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeAccountLimits}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the current Amazon EC2 Auto Scaling resource quotas for your account. When you establish an Amazon Web Services account, the account has initial quotas on the maximum number of Auto Scaling groups and launch configurations that you can create in a given Region. For more information, see Quotas for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-quotas.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeAccountLimits
export def "post-describe-account-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-19 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeAccountLimits}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the available adjustment types for step scaling and simple scaling policies. The following adjustment types are supported: ChangeInCapacity ExactCapacity PercentChangeInCapacity
#
# GET /
# operationId: GET_DescribeAdjustmentTypes
export def "get-describe-adjustment-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-20 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeAdjustmentTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the available adjustment types for step scaling and simple scaling policies. The following adjustment types are supported: ChangeInCapacity ExactCapacity PercentChangeInCapacity
#
# POST /
# operationId: POST_DescribeAdjustmentTypes
export def "post-describe-adjustment-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-20 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeAdjustmentTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Auto Scaling groups in the account and Region. If you specify Auto Scaling group names, the output includes information for only the specified Auto Scaling groups. If you specify filters, the output includes information for only those Auto Scaling groups that meet the filter criteria. If you do not specify group names or filters, the output includes information for all Auto Scaling groups. This operation also returns information about instances in Auto Scaling groups. To retrieve information about the instances in a warm pool, you must call the DescribeWarmPool API.
#
# GET /
# operationId: GET_DescribeAutoScalingGroups
export def "get-describe-auto-scaling-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-names: list<string> # The names of the Auto Scaling groups. By default, you can only specify up to 50 names. You can optionally increase this limit using the MaxRecords property. If you omit this property, all Auto Scaling groups are described.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --filters: list # One or more filters to limit the results based on specific tags.
  --action: string@action-completer-21 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupNames, var: auto_scaling_group_names, style: multi}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Filters, var: filters, style: multi}, {name: Action, var: action, required: true, default: DescribeAutoScalingGroups}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_names: $auto_scaling_group_names, next_token: $next_token, max_records: $max_records, filters: $filters, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Auto Scaling groups in the account and Region. If you specify Auto Scaling group names, the output includes information for only the specified Auto Scaling groups. If you specify filters, the output includes information for only those Auto Scaling groups that meet the filter criteria. If you do not specify group names or filters, the output includes information for all Auto Scaling groups. This operation also returns information about instances in Auto Scaling groups. To retrieve information about the instances in a warm pool, you must call the DescribeWarmPool API.
#
# POST /
# operationId: POST_DescribeAutoScalingGroups
export def "post-describe-auto-scaling-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-21 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeAutoScalingGroups}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Auto Scaling instances in the account and Region.
#
# GET /
# operationId: GET_DescribeAutoScalingInstances
export def "get-describe-auto-scaling-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list<string> # The IDs of the instances. If you omit this property, all Auto Scaling instances are described. If you specify an ID that does not exist, it is ignored with no error. Array Members: Maximum number of 50 items.
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 50.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --action: string@action-completer-22 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: InstanceIds, var: instance_ids, style: multi}, {name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeAutoScalingInstances}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    instance_ids: $instance_ids, max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Auto Scaling instances in the account and Region.
#
# POST /
# operationId: POST_DescribeAutoScalingInstances
export def "post-describe-auto-scaling-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-22 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeAutoScalingInstances}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the notification types that are supported by Amazon EC2 Auto Scaling.
#
# GET /
# operationId: GET_DescribeAutoScalingNotificationTypes
export def "get-describe-auto-scaling-notification-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-23 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeAutoScalingNotificationTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the notification types that are supported by Amazon EC2 Auto Scaling.
#
# POST /
# operationId: POST_DescribeAutoScalingNotificationTypes
export def "post-describe-auto-scaling-notification-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-23 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeAutoScalingNotificationTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the instance refreshes for the specified Auto Scaling group. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. To help you determine the status of an instance refresh, Amazon EC2 Auto Scaling returns information about the instance refreshes you previously initiated, including their status, start time, end time, the percentage of the instance refresh that is complete, and the number of instances remaining to update before the instance refresh is complete. If a rollback is initiated while an instance refresh is in progress, Amazon EC2 Auto Scaling also returns information about the rollback of the instance refresh.
#
# GET /
# operationId: GET_DescribeInstanceRefreshes
export def "get-describe-instance-refreshes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --instance-refresh-ids: list<string> # One or more instance refresh IDs.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-24 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: InstanceRefreshIds, var: instance_refresh_ids, style: multi}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribeInstanceRefreshes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, instance_refresh_ids: $instance_refresh_ids, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the instance refreshes for the specified Auto Scaling group. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. To help you determine the status of an instance refresh, Amazon EC2 Auto Scaling returns information about the instance refreshes you previously initiated, including their status, start time, end time, the percentage of the instance refresh that is complete, and the number of instances remaining to update before the instance refresh is complete. If a rollback is initiated while an instance refresh is in progress, Amazon EC2 Auto Scaling also returns information about the rollback of the instance refresh.
#
# POST /
# operationId: POST_DescribeInstanceRefreshes
export def "post-describe-instance-refreshes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-24 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeInstanceRefreshes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the launch configurations in the account and Region.
#
# GET /
# operationId: GET_DescribeLaunchConfigurations
export def "get-describe-launch-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --launch-configuration-names: list<string> # The launch configuration names. If you omit this property, all launch configurations are described. Array Members: Maximum number of 50 items.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-25 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: LaunchConfigurationNames, var: launch_configuration_names, style: multi}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribeLaunchConfigurations}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    launch_configuration_names: $launch_configuration_names, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the launch configurations in the account and Region.
#
# POST /
# operationId: POST_DescribeLaunchConfigurations
export def "post-describe-launch-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-25 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeLaunchConfigurations}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the available types of lifecycle hooks. The following hook types are supported: autoscaling:EC2_INSTANCE_LAUNCHING autoscaling:EC2_INSTANCE_TERMINATING
#
# GET /
# operationId: GET_DescribeLifecycleHookTypes
export def "get-describe-lifecycle-hook-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-26 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeLifecycleHookTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the available types of lifecycle hooks. The following hook types are supported: autoscaling:EC2_INSTANCE_LAUNCHING autoscaling:EC2_INSTANCE_TERMINATING
#
# POST /
# operationId: POST_DescribeLifecycleHookTypes
export def "post-describe-lifecycle-hook-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-26 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeLifecycleHookTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the lifecycle hooks for the specified Auto Scaling group.
#
# GET /
# operationId: GET_DescribeLifecycleHooks
export def "get-describe-lifecycle-hooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --lifecycle-hook-names: list<string> # The names of one or more lifecycle hooks. If you omit this property, all lifecycle hooks are described.
  --action: string@action-completer-27 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: LifecycleHookNames, var: lifecycle_hook_names, style: multi}, {name: Action, var: action, required: true, default: DescribeLifecycleHooks}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, lifecycle_hook_names: $lifecycle_hook_names, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the lifecycle hooks for the specified Auto Scaling group.
#
# POST /
# operationId: POST_DescribeLifecycleHooks
export def "post-describe-lifecycle-hooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-27 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeLifecycleHooks}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by DescribeTrafficSources, which can describe multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DescribeLoadBalancerTargetGroups. You can use both the original DescribeLoadBalancerTargetGroups API operation and DescribeTrafficSources on the same Auto Scaling group. Gets information about the Elastic Load Balancing target groups for the specified Auto Scaling group. To determine the attachment status of the target group, use the State element in the response. When you attach a target group to an Auto Scaling group, the initial State value is Adding. The state transitions to Added after all Auto Scaling instances are registered with the target group. If Elastic Load Balancing health checks are enabled for the Auto Scaling group, the state transitions to InService after at least one Auto Scaling instance passes the health check. When the target group is in the InService state, Amazon EC2 Auto Scaling can terminate and replace any instances that are reported as unhealthy. If no registered instances pass the health checks, the target group doesn't enter the InService state. Target groups also have an InService state if you attach them in the CreateAutoScalingGroup API call. If your target group state is InService, but it is not working properly, check the scaling activities by calling DescribeScalingActivities and take any corrective actions necessary. For help with failed health checks, see Troubleshooting Amazon EC2 Auto Scaling: Health checks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ts-as-healthchecks.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide. You can use this operation to describe target groups that were attached by using AttachLoadBalancerTargetGroups, but not for target groups that were attached by using AttachTrafficSources.
#
# GET /
# operationId: GET_DescribeLoadBalancerTargetGroups
export def "get-describe-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 100 and the maximum value is 100.
  --action: string@action-completer-28 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribeLoadBalancerTargetGroups}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by DescribeTrafficSources, which can describe multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DescribeLoadBalancerTargetGroups. You can use both the original DescribeLoadBalancerTargetGroups API operation and DescribeTrafficSources on the same Auto Scaling group. Gets information about the Elastic Load Balancing target groups for the specified Auto Scaling group. To determine the attachment status of the target group, use the State element in the response. When you attach a target group to an Auto Scaling group, the initial State value is Adding. The state transitions to Added after all Auto Scaling instances are registered with the target group. If Elastic Load Balancing health checks are enabled for the Auto Scaling group, the state transitions to InService after at least one Auto Scaling instance passes the health check. When the target group is in the InService state, Amazon EC2 Auto Scaling can terminate and replace any instances that are reported as unhealthy. If no registered instances pass the health checks, the target group doesn't enter the InService state. Target groups also have an InService state if you attach them in the CreateAutoScalingGroup API call. If your target group state is InService, but it is not working properly, check the scaling activities by calling DescribeScalingActivities and take any corrective actions necessary. For help with failed health checks, see Troubleshooting Amazon EC2 Auto Scaling: Health checks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ts-as-healthchecks.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide. You can use this operation to describe target groups that were attached by using AttachLoadBalancerTargetGroups, but not for target groups that were attached by using AttachTrafficSources.
#
# POST /
# operationId: POST_DescribeLoadBalancerTargetGroups
export def "post-describe-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-28 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeLoadBalancerTargetGroups}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by DescribeTrafficSources, which can describe multiple traffic sources types. We recommend using DescribeTrafficSources to simplify how you manage traffic sources. However, we continue to support DescribeLoadBalancers. You can use both the original DescribeLoadBalancers API operation and DescribeTrafficSources on the same Auto Scaling group. Gets information about the load balancers for the specified Auto Scaling group. This operation describes only Classic Load Balancers. If you have Application Load Balancers, Network Load Balancers, or Gateway Load Balancers, use the DescribeLoadBalancerTargetGroups API instead. To determine the attachment status of the load balancer, use the State element in the response. When you attach a load balancer to an Auto Scaling group, the initial State value is Adding. The state transitions to Added after all Auto Scaling instances are registered with the load balancer. If Elastic Load Balancing health checks are enabled for the Auto Scaling group, the state transitions to InService after at least one Auto Scaling instance passes the health check. When the load balancer is in the InService state, Amazon EC2 Auto Scaling can terminate and replace any instances that are reported as unhealthy. If no registered instances pass the health checks, the load balancer doesn't enter the InService state. Load balancers also have an InService state if you attach them in the CreateAutoScalingGroup API call. If your load balancer state is InService, but it is not working properly, check the scaling activities by calling DescribeScalingActivities and take any corrective actions necessary. For help with failed health checks, see Troubleshooting Amazon EC2 Auto Scaling: Health checks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ts-as-healthchecks.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeLoadBalancers
export def "get-describe-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 100 and the maximum value is 100.
  --action: string@action-completer-29 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribeLoadBalancers}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by DescribeTrafficSources, which can describe multiple traffic sources types. We recommend using DescribeTrafficSources to simplify how you manage traffic sources. However, we continue to support DescribeLoadBalancers. You can use both the original DescribeLoadBalancers API operation and DescribeTrafficSources on the same Auto Scaling group. Gets information about the load balancers for the specified Auto Scaling group. This operation describes only Classic Load Balancers. If you have Application Load Balancers, Network Load Balancers, or Gateway Load Balancers, use the DescribeLoadBalancerTargetGroups API instead. To determine the attachment status of the load balancer, use the State element in the response. When you attach a load balancer to an Auto Scaling group, the initial State value is Adding. The state transitions to Added after all Auto Scaling instances are registered with the load balancer. If Elastic Load Balancing health checks are enabled for the Auto Scaling group, the state transitions to InService after at least one Auto Scaling instance passes the health check. When the load balancer is in the InService state, Amazon EC2 Auto Scaling can terminate and replace any instances that are reported as unhealthy. If no registered instances pass the health checks, the load balancer doesn't enter the InService state. Load balancers also have an InService state if you attach them in the CreateAutoScalingGroup API call. If your load balancer state is InService, but it is not working properly, check the scaling activities by calling DescribeScalingActivities and take any corrective actions necessary. For help with failed health checks, see Troubleshooting Amazon EC2 Auto Scaling: Health checks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ts-as-healthchecks.html) in the Amazon EC2 Auto Scaling User Guide. For more information, see Use Elastic Load Balancing to distribute traffic across the instances in your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-load-balancer.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeLoadBalancers
export def "post-describe-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-29 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeLoadBalancers}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the available CloudWatch metrics for Amazon EC2 Auto Scaling.
#
# GET /
# operationId: GET_DescribeMetricCollectionTypes
export def "get-describe-metric-collection-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-30 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeMetricCollectionTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the available CloudWatch metrics for Amazon EC2 Auto Scaling.
#
# POST /
# operationId: POST_DescribeMetricCollectionTypes
export def "post-describe-metric-collection-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-30 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeMetricCollectionTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Amazon SNS notifications that are configured for one or more Auto Scaling groups.
#
# GET /
# operationId: GET_DescribeNotificationConfigurations
export def "get-describe-notification-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-names: list<string> # The name of the Auto Scaling group.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-31 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupNames, var: auto_scaling_group_names, style: multi}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribeNotificationConfigurations}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_names: $auto_scaling_group_names, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the Amazon SNS notifications that are configured for one or more Auto Scaling groups.
#
# POST /
# operationId: POST_DescribeNotificationConfigurations
export def "post-describe-notification-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-31 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeNotificationConfigurations}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the scaling policies in the account and Region.
#
# GET /
# operationId: GET_DescribePolicies
export def "get-describe-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --policy-names: list<string> # The names of one or more policies. If you omit this property, all policies are described. If a group name is provided, the results are limited to that group. If you specify an unknown policy name, it is ignored with no error. Array Members: Maximum number of 50 items.
  --policy-types: list<string> # One or more policy types. The valid values are SimpleScaling, StepScaling, TargetTrackingScaling, and PredictiveScaling.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to be returned with each call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-32 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name}, {name: PolicyNames, var: policy_names, style: multi}, {name: PolicyTypes, var: policy_types, style: multi}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribePolicies}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, policy_names: $policy_names, policy_types: $policy_types, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the scaling policies in the account and Region.
#
# POST /
# operationId: POST_DescribePolicies
export def "post-describe-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-32 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribePolicies}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the scaling activities in the account and Region. When scaling events occur, you see a record of the scaling activity in the scaling activities. For more information, see Verifying a scaling activity for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-verify-scaling-activity.html) in the Amazon EC2 Auto Scaling User Guide. If the scaling event succeeds, the value of the StatusCode element in the response is Successful. If an attempt to launch instances failed, the StatusCode value is Failed or Cancelled and the StatusMessage element in the response indicates the cause of the failure. For help interpreting the StatusMessage, see Troubleshooting Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/CHAP_Troubleshooting.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeScalingActivities
export def "get-describe-scaling-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-ids: list<string> # The activity IDs of the desired scaling activities. If you omit this property, all activities for the past six weeks are described. If unknown activities are requested, they are ignored with no error. If you specify an Auto Scaling group, the results are limited to that group. Array Members: Maximum number of 50 IDs.
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --include-deleted-groups: oneof<nothing, bool> # Indicates whether to include scaling activity from deleted Auto Scaling groups.
  --max-records: int # The maximum number of items to return with this call. The default value is 100 and the maximum value is 100.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --action: string@action-completer-33 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: ActivityIds, var: activity_ids, style: multi}, {name: AutoScalingGroupName, var: auto_scaling_group_name}, {name: IncludeDeletedGroups, var: include_deleted_groups}, {name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeScalingActivities}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    activity_ids: $activity_ids, auto_scaling_group_name: $auto_scaling_group_name, include_deleted_groups: $include_deleted_groups, max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the scaling activities in the account and Region. When scaling events occur, you see a record of the scaling activity in the scaling activities. For more information, see Verifying a scaling activity for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-verify-scaling-activity.html) in the Amazon EC2 Auto Scaling User Guide. If the scaling event succeeds, the value of the StatusCode element in the response is Successful. If an attempt to launch instances failed, the StatusCode value is Failed or Cancelled and the StatusMessage element in the response indicates the cause of the failure. For help interpreting the StatusMessage, see Troubleshooting Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/CHAP_Troubleshooting.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeScalingActivities
export def "post-describe-scaling-activities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-33 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeScalingActivities}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the scaling process types for use with the ResumeProcesses and SuspendProcesses APIs.
#
# GET /
# operationId: GET_DescribeScalingProcessTypes
export def "get-describe-scaling-process-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-34 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeScalingProcessTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the scaling process types for use with the ResumeProcesses and SuspendProcesses APIs.
#
# POST /
# operationId: POST_DescribeScalingProcessTypes
export def "post-describe-scaling-process-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-34 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeScalingProcessTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the scheduled actions that haven't run or that have not reached their end time. To describe the scaling activities for scheduled actions that have already run, call the DescribeScalingActivities API.
#
# GET /
# operationId: GET_DescribeScheduledActions
export def "get-describe-scheduled-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --scheduled-action-names: list<string> # The names of one or more scheduled actions. If you omit this property, all scheduled actions are described. If you specify an unknown scheduled action, it is ignored with no error. Array Members: Maximum number of 50 actions.
  --start-time: string # The earliest scheduled start time to return. If scheduled action names are provided, this property is ignored. (format: date-time)
  --end-time: string # The latest scheduled start time to return. If scheduled action names are provided, this property is ignored. (format: date-time)
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-35 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name}, {name: ScheduledActionNames, var: scheduled_action_names, style: multi}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribeScheduledActions}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, scheduled_action_names: $scheduled_action_names, start_time: $start_time, end_time: $end_time, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the scheduled actions that haven't run or that have not reached their end time. To describe the scaling activities for scheduled actions that have already run, call the DescribeScalingActivities API.
#
# POST /
# operationId: POST_DescribeScheduledActions
export def "post-describe-scheduled-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-35 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeScheduledActions}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified tags. You can use filters to limit the results. For example, you can query for the tags for a specific Auto Scaling group. You can specify multiple values for a filter. A tag must match at least one of the specified values for it to be included in the results. You can also specify multiple filters. The result includes information for a particular tag only if it matches all the filters. If there's no match, no special message is returned. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeTags
export def "get-describe-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list # One or more filters to scope the tags to return. The maximum number of filters per filter type (for example, auto-scaling-group) is 1000.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The default value is 50 and the maximum value is 100.
  --action: string@action-completer-36 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Filters, var: filters, style: multi}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribeTags}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    filters: $filters, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the specified tags. You can use filters to limit the results. For example, you can query for the tags for a specific Auto Scaling group. You can specify multiple values for a filter. A tag must match at least one of the specified values for it to be included in the results. You can also specify multiple filters. The result includes information for a particular tag only if it matches all the filters. If there's no match, no special message is returned. For more information, see Tag Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-tagging.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeTags
export def "post-describe-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-36 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeTags}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the termination policies supported by Amazon EC2 Auto Scaling. For more information, see Work with Amazon EC2 Auto Scaling termination policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeTerminationPolicyTypes
export def "get-describe-termination-policy-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-37 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeTerminationPolicyTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes the termination policies supported by Amazon EC2 Auto Scaling. For more information, see Work with Amazon EC2 Auto Scaling termination policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeTerminationPolicyTypes
export def "post-describe-termination-policy-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-37 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeTerminationPolicyTypes}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the traffic sources for the specified Auto Scaling group. You can optionally provide a traffic source type. If you provide a traffic source type, then the results only include that traffic source type. If you do not provide a traffic source type, then the results include all the traffic sources for the specified Auto Scaling group.
#
# GET /
# operationId: GET_DescribeTrafficSources
export def "get-describe-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --traffic-source-type: string # The traffic source type that you want to describe. The following lists the valid values: elb if the traffic source is a Classic Load Balancer. elbv2 if the traffic source is a Application Load Balancer, Gateway Load Balancer, or Network Load Balancer. vpc-lattice if the traffic source is VPC Lattice.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-records: int # The maximum number of items to return with this call. The maximum value is 50.
  --action: string@action-completer-38 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: TrafficSourceType, var: traffic_source_type}, {name: NextToken, var: next_token}, {name: MaxRecords, var: max_records}, {name: Action, var: action, required: true, default: DescribeTrafficSources}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, traffic_source_type: $traffic_source_type, next_token: $next_token, max_records: $max_records, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about the traffic sources for the specified Auto Scaling group. You can optionally provide a traffic source type. If you provide a traffic source type, then the results only include that traffic source type. If you do not provide a traffic source type, then the results include all the traffic sources for the specified Auto Scaling group.
#
# POST /
# operationId: POST_DescribeTrafficSources
export def "post-describe-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-38 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeTrafficSources}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a warm pool and its instances. For more information, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DescribeWarmPool
export def "get-describe-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --max-records: int # The maximum number of instances to return with this call. The maximum value is 50.
  --next-token: string # The token for the next set of instances to return. (You received this token from a previous call.)
  --action: string@action-completer-39 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: MaxRecords, var: max_records}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: DescribeWarmPool}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, max_records: $max_records, next_token: $next_token, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets information about a warm pool and its instances. For more information, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DescribeWarmPool
export def "post-describe-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-39 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DescribeWarmPool}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more instances from the specified Auto Scaling group. After the instances are detached, you can manage them independent of the Auto Scaling group. If you do not specify the option to decrement the desired capacity, Amazon EC2 Auto Scaling launches instances to replace the ones that are detached. If there is a Classic Load Balancer attached to the Auto Scaling group, the instances are deregistered from the load balancer. If there are target groups attached to the Auto Scaling group, the instances are deregistered from the target groups. For more information, see Detach EC2 instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/detach-instance-asg.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_DetachInstances
export def "get-detach-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list<string> # The IDs of the instances. You can specify up to 20 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --should-decrement-desired-capacity: oneof<nothing, bool> # Indicates whether the Auto Scaling group decrements the desired capacity value by the number of instances detached. (required)
  --action: string@action-completer-40 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: InstanceIds, var: instance_ids, style: multi}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ShouldDecrementDesiredCapacity, var: should_decrement_desired_capacity, required: true}, {name: Action, var: action, required: true, default: DetachInstances}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    instance_ids: $instance_ids, auto_scaling_group_name: $auto_scaling_group_name, should_decrement_desired_capacity: $should_decrement_desired_capacity, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes one or more instances from the specified Auto Scaling group. After the instances are detached, you can manage them independent of the Auto Scaling group. If you do not specify the option to decrement the desired capacity, Amazon EC2 Auto Scaling launches instances to replace the ones that are detached. If there is a Classic Load Balancer attached to the Auto Scaling group, the instances are deregistered from the load balancer. If there are target groups attached to the Auto Scaling group, the instances are deregistered from the target groups. For more information, see Detach EC2 instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/detach-instance-asg.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_DetachInstances
export def "post-detach-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-40 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DetachInstances}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by DetachTrafficSources, which can detach multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DetachLoadBalancerTargetGroups. You can use both the original DetachLoadBalancerTargetGroups API operation and DetachTrafficSources on the same Auto Scaling group. Detaches one or more target groups from the specified Auto Scaling group. When you detach a target group, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the target group using the DescribeLoadBalancerTargetGroups API call. The instances remain running. You can use this operation to detach target groups that were attached by using AttachLoadBalancerTargetGroups, but not for target groups that were attached by using AttachTrafficSources.
#
# GET /
# operationId: GET_DetachLoadBalancerTargetGroups
export def "get-detach-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --target-group-ar-ns: list<string> # The Amazon Resource Names (ARN) of the target groups. You can specify up to 10 target groups. (required)
  --action: string@action-completer-41 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: TargetGroupARNs, var: target_group_ar_ns, style: multi, required: true}, {name: Action, var: action, required: true, default: DetachLoadBalancerTargetGroups}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, target_group_ar_ns: $target_group_ar_ns, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by DetachTrafficSources, which can detach multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DetachLoadBalancerTargetGroups. You can use both the original DetachLoadBalancerTargetGroups API operation and DetachTrafficSources on the same Auto Scaling group. Detaches one or more target groups from the specified Auto Scaling group. When you detach a target group, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the target group using the DescribeLoadBalancerTargetGroups API call. The instances remain running. You can use this operation to detach target groups that were attached by using AttachLoadBalancerTargetGroups, but not for target groups that were attached by using AttachTrafficSources.
#
# POST /
# operationId: POST_DetachLoadBalancerTargetGroups
export def "post-detach-load-balancer-target-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-41 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DetachLoadBalancerTargetGroups}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by DetachTrafficSources, which can detach multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DetachLoadBalancers. You can use both the original DetachLoadBalancers API operation and DetachTrafficSources on the same Auto Scaling group. Detaches one or more Classic Load Balancers from the specified Auto Scaling group. This operation detaches only Classic Load Balancers. If you have Application Load Balancers, Network Load Balancers, or Gateway Load Balancers, use the DetachLoadBalancerTargetGroups API instead. When you detach a load balancer, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the load balancer using the DescribeLoadBalancers API call. The instances remain running.
#
# GET /
# operationId: GET_DetachLoadBalancers
export def "get-detach-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --load-balancer-names: list<string> # The names of the load balancers. You can specify up to 10 load balancers. (required)
  --action: string@action-completer-42 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: LoadBalancerNames, var: load_balancer_names, style: multi, required: true}, {name: Action, var: action, required: true, default: DetachLoadBalancers}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, load_balancer_names: $load_balancer_names, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This API operation is superseded by DetachTrafficSources, which can detach multiple traffic sources types. We recommend using DetachTrafficSources to simplify how you manage traffic sources. However, we continue to support DetachLoadBalancers. You can use both the original DetachLoadBalancers API operation and DetachTrafficSources on the same Auto Scaling group. Detaches one or more Classic Load Balancers from the specified Auto Scaling group. This operation detaches only Classic Load Balancers. If you have Application Load Balancers, Network Load Balancers, or Gateway Load Balancers, use the DetachLoadBalancerTargetGroups API instead. When you detach a load balancer, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the load balancer using the DescribeLoadBalancers API call. The instances remain running.
#
# POST /
# operationId: POST_DetachLoadBalancers
export def "post-detach-load-balancers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-42 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DetachLoadBalancers}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches one or more traffic sources from the specified Auto Scaling group. When you detach a taffic, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the traffic source using the DescribeTrafficSources API call. The instances continue to run.
#
# GET /
# operationId: GET_DetachTrafficSources
export def "get-detach-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --traffic-sources: list # The unique identifiers of one or more traffic sources. You can specify up to 10 traffic sources. (required)
  --action: string@action-completer-43 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: TrafficSources, var: traffic_sources, style: multi, required: true}, {name: Action, var: action, required: true, default: DetachTrafficSources}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, traffic_sources: $traffic_sources, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detaches one or more traffic sources from the specified Auto Scaling group. When you detach a taffic, it enters the Removing state while deregistering the instances in the group. When all instances are deregistered, then you can no longer describe the traffic source using the DescribeTrafficSources API call. The instances continue to run.
#
# POST /
# operationId: POST_DetachTrafficSources
export def "post-detach-traffic-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-43 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DetachTrafficSources}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables group metrics collection for the specified Auto Scaling group.
#
# GET /
# operationId: GET_DisableMetricsCollection
export def "get-disable-metrics-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --metrics: list<string> # Identifies the metrics to disable. You can specify one or more of the following metrics: GroupMinSize GroupMaxSize GroupDesiredCapacity GroupInServiceInstances GroupPendingInstances GroupStandbyInstances GroupTerminatingInstances GroupTotalInstances GroupInServiceCapacity GroupPendingCapacity GroupStandbyCapacity GroupTerminatingCapacity GroupTotalCapacity WarmPoolDesiredCapacity WarmPoolWarmedCapacity WarmPoolPendingCapacity WarmPoolTerminatingCapacity WarmPoolTotalCapacity GroupAndWarmPoolDesiredCapacity GroupAndWarmPoolTotalCapacity If you omit this property, all metrics are disabled. For more information, see Auto Scaling group metrics (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-cloudwatch-monitoring.html#as-group-metrics) in the Amazon EC2 Auto Scaling User Guide.
  --action: string@action-completer-44 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: Metrics, var: metrics, style: multi}, {name: Action, var: action, required: true, default: DisableMetricsCollection}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, metrics: $metrics, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disables group metrics collection for the specified Auto Scaling group.
#
# POST /
# operationId: POST_DisableMetricsCollection
export def "post-disable-metrics-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-44 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: DisableMetricsCollection}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables group metrics collection for the specified Auto Scaling group. You can use these metrics to track changes in an Auto Scaling group and to set alarms on threshold values. You can view group metrics using the Amazon EC2 Auto Scaling console or the CloudWatch console. For more information, see Monitor CloudWatch metrics for your Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-cloudwatch-monitoring.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_EnableMetricsCollection
export def "get-enable-metrics-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --metrics: list<string> # Identifies the metrics to enable. You can specify one or more of the following metrics: GroupMinSize GroupMaxSize GroupDesiredCapacity GroupInServiceInstances GroupPendingInstances GroupStandbyInstances GroupTerminatingInstances GroupTotalInstances GroupInServiceCapacity GroupPendingCapacity GroupStandbyCapacity GroupTerminatingCapacity GroupTotalCapacity WarmPoolDesiredCapacity WarmPoolWarmedCapacity WarmPoolPendingCapacity WarmPoolTerminatingCapacity WarmPoolTotalCapacity GroupAndWarmPoolDesiredCapacity GroupAndWarmPoolTotalCapacity If you specify Granularity and don't specify any metrics, all metrics are enabled. For more information, see Auto Scaling group metrics (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-cloudwatch-monitoring.html#as-group-metrics) in the Amazon EC2 Auto Scaling User Guide.
  --granularity: string # The frequency at which Amazon EC2 Auto Scaling sends aggregated data to CloudWatch. The only valid value is 1Minute. (required)
  --action: string@action-completer-45 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: Metrics, var: metrics, style: multi}, {name: Granularity, var: granularity, required: true}, {name: Action, var: action, required: true, default: EnableMetricsCollection}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, metrics: $metrics, granularity: $granularity, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enables group metrics collection for the specified Auto Scaling group. You can use these metrics to track changes in an Auto Scaling group and to set alarms on threshold values. You can view group metrics using the Amazon EC2 Auto Scaling console or the CloudWatch console. For more information, see Monitor CloudWatch metrics for your Auto Scaling groups and instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-cloudwatch-monitoring.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_EnableMetricsCollection
export def "post-enable-metrics-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-45 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: EnableMetricsCollection}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves the specified instances into the standby state. If you choose to decrement the desired capacity of the Auto Scaling group, the instances can enter standby as long as the desired capacity of the Auto Scaling group after the instances are placed into standby is equal to or greater than the minimum capacity of the group. If you choose not to decrement the desired capacity of the Auto Scaling group, the Auto Scaling group launches new instances to replace the instances on standby. For more information, see Temporarily removing instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enter-exit-standby.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_EnterStandby
export def "get-enter-standby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list<string> # The IDs of the instances. You can specify up to 20 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --should-decrement-desired-capacity: oneof<nothing, bool> # Indicates whether to decrement the desired capacity of the Auto Scaling group by the number of instances moved to Standby mode. (required)
  --action: string@action-completer-46 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: InstanceIds, var: instance_ids, style: multi}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ShouldDecrementDesiredCapacity, var: should_decrement_desired_capacity, required: true}, {name: Action, var: action, required: true, default: EnterStandby}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    instance_ids: $instance_ids, auto_scaling_group_name: $auto_scaling_group_name, should_decrement_desired_capacity: $should_decrement_desired_capacity, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves the specified instances into the standby state. If you choose to decrement the desired capacity of the Auto Scaling group, the instances can enter standby as long as the desired capacity of the Auto Scaling group after the instances are placed into standby is equal to or greater than the minimum capacity of the group. If you choose not to decrement the desired capacity of the Auto Scaling group, the Auto Scaling group launches new instances to replace the instances on standby. For more information, see Temporarily removing instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enter-exit-standby.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_EnterStandby
export def "post-enter-standby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-46 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: EnterStandby}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes the specified policy. This can be useful for testing the design of your scaling policy.
#
# GET /
# operationId: GET_ExecutePolicy
export def "get-execute-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --policy-name: string # The name or ARN of the policy. (required)
  --honor-cooldown: oneof<nothing, bool> # Indicates whether Amazon EC2 Auto Scaling waits for the cooldown period to complete before executing the policy. Valid only if the policy type is SimpleScaling. For more information, see Scaling cooldowns for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/Cooldown.html) in the Amazon EC2 Auto Scaling User Guide.
  --metric-value: float # The metric value to compare to BreachThreshold. This enables you to execute a policy of type StepScaling and determine which step adjustment to use. For example, if the breach threshold is 50 and you want to use a step adjustment with a lower bound of 0 and an upper bound of 10, you can set the metric value to 59. If you specify a metric value that doesn't correspond to a step adjustment for the policy, the call returns an error. Required if the policy type is StepScaling and not supported otherwise. (format: double)
  --breach-threshold: float # The breach threshold for the alarm. Required if the policy type is StepScaling and not supported otherwise. (format: double)
  --action: string@action-completer-47 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name}, {name: PolicyName, var: policy_name, required: true}, {name: HonorCooldown, var: honor_cooldown}, {name: MetricValue, var: metric_value}, {name: BreachThreshold, var: breach_threshold}, {name: Action, var: action, required: true, default: ExecutePolicy}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, policy_name: $policy_name, honor_cooldown: $honor_cooldown, metric_value: $metric_value, breach_threshold: $breach_threshold, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes the specified policy. This can be useful for testing the design of your scaling policy.
#
# POST /
# operationId: POST_ExecutePolicy
export def "post-execute-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-47 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ExecutePolicy}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves the specified instances out of the standby state. After you put the instances back in service, the desired capacity is incremented. For more information, see Temporarily removing instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enter-exit-standby.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_ExitStandby
export def "get-exit-standby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list<string> # The IDs of the instances. You can specify up to 20 instances.
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --action: string@action-completer-48 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: InstanceIds, var: instance_ids, style: multi}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: Action, var: action, required: true, default: ExitStandby}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    instance_ids: $instance_ids, auto_scaling_group_name: $auto_scaling_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves the specified instances out of the standby state. After you put the instances back in service, the desired capacity is incremented. For more information, see Temporarily removing instances from your Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enter-exit-standby.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_ExitStandby
export def "post-exit-standby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-48 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ExitStandby}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the forecast data for a predictive scaling policy. Load forecasts are predictions of the hourly load values using historical load data from CloudWatch and an analysis of historical trends. Capacity forecasts are represented as predicted values for the minimum capacity that is needed on an hourly basis, based on the hourly load forecast. A minimum of 24 hours of data is required to create the initial forecasts. However, having a full 14 days of historical data results in more accurate forecasts. For more information, see Predictive scaling for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_GetPredictiveScalingForecast
export def "get-get-predictive-scaling-forecast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --policy-name: string # The name of the policy. (required)
  --start-time: string # The inclusive start time of the time range for the forecast data to get. At most, the date and time can be one year before the current date and time. (required, format: date-time)
  --end-time: string # The exclusive end time of the time range for the forecast data to get. The maximum time duration between the start and end time is 30 days. Although this parameter can accept a date and time that is more than two days in the future, the availability of forecast data has limits. Amazon EC2 Auto Scaling only issues forecasts for periods of two days in advance. (required, format: date-time)
  --action: string@action-completer-49 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: PolicyName, var: policy_name, required: true}, {name: StartTime, var: start_time, required: true}, {name: EndTime, var: end_time, required: true}, {name: Action, var: action, required: true, default: GetPredictiveScalingForecast}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, policy_name: $policy_name, start_time: $start_time, end_time: $end_time, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the forecast data for a predictive scaling policy. Load forecasts are predictions of the hourly load values using historical load data from CloudWatch and an analysis of historical trends. Capacity forecasts are represented as predicted values for the minimum capacity that is needed on an hourly basis, based on the hourly load forecast. A minimum of 24 hours of data is required to create the initial forecasts. However, having a full 14 days of historical data results in more accurate forecasts. For more information, see Predictive scaling for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_GetPredictiveScalingForecast
export def "post-get-predictive-scaling-forecast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-49 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: GetPredictiveScalingForecast}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a lifecycle hook for the specified Auto Scaling group. Lifecycle hooks let you create solutions that are aware of events in the Auto Scaling instance lifecycle, and then perform a custom action on instances when the corresponding lifecycle event occurs. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state using the RecordLifecycleActionHeartbeat API call. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of lifecycle hooks, which by default is 50 per Auto Scaling group, the call fails. You can view the lifecycle hooks for an Auto Scaling group using the DescribeLifecycleHooks API call. If you are no longer using a lifecycle hook, you can delete it by calling the DeleteLifecycleHook API.
#
# GET /
# operationId: GET_PutLifecycleHook
export def "get-put-lifecycle-hook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lifecycle-hook-name: string # The name of the lifecycle hook. (required)
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --lifecycle-transition: string # The lifecycle transition. For Auto Scaling groups, there are two major lifecycle transitions. To create a lifecycle hook for scale-out events, specify autoscaling:EC2_INSTANCE_LAUNCHING. To create a lifecycle hook for scale-in events, specify autoscaling:EC2_INSTANCE_TERMINATING. Required for new lifecycle hooks, but optional when updating existing hooks.
  --role-arn: string # The ARN of the IAM role that allows the Auto Scaling group to publish to the specified notification target. Valid only if the notification target is an Amazon SNS topic or an Amazon SQS queue. Required for new lifecycle hooks, but optional when updating existing hooks.
  --notification-target-arn: string # The Amazon Resource Name (ARN) of the notification target that Amazon EC2 Auto Scaling uses to notify you when an instance is in a wait state for the lifecycle hook. You can specify either an Amazon SNS topic or an Amazon SQS queue. If you specify an empty string, this overrides the current ARN. This operation uses the JSON format when sending notifications to an Amazon SQS queue, and an email key-value pair format when sending notifications to an Amazon SNS topic. When you specify a notification target, Amazon EC2 Auto Scaling sends it a test message. Test messages contain the following additional key-value pair: "Event": "autoscaling:TEST_NOTIFICATION".
  --notification-metadata: string # Additional information that you want to include any time Amazon EC2 Auto Scaling sends a message to the notification target.
  --heartbeat-timeout: int # The maximum time, in seconds, that can elapse before the lifecycle hook times out. The range is from 30 to 7200 seconds. The default value is 3600 seconds (1 hour).
  --default-result: string # The action the Auto Scaling group takes when the lifecycle hook timeout elapses or if an unexpected failure occurs. The default value is ABANDON. Valid values: CONTINUE | ABANDON
  --action: string@action-completer-50 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: LifecycleHookName, var: lifecycle_hook_name, required: true}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: LifecycleTransition, var: lifecycle_transition}, {name: RoleARN, var: role_arn}, {name: NotificationTargetARN, var: notification_target_arn}, {name: NotificationMetadata, var: notification_metadata}, {name: HeartbeatTimeout, var: heartbeat_timeout}, {name: DefaultResult, var: default_result}, {name: Action, var: action, required: true, default: PutLifecycleHook}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    lifecycle_hook_name: $lifecycle_hook_name, auto_scaling_group_name: $auto_scaling_group_name, lifecycle_transition: $lifecycle_transition, role_arn: $role_arn, notification_target_arn: $notification_target_arn, notification_metadata: $notification_metadata, heartbeat_timeout: $heartbeat_timeout, default_result: $default_result, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a lifecycle hook for the specified Auto Scaling group. Lifecycle hooks let you create solutions that are aware of events in the Auto Scaling instance lifecycle, and then perform a custom action on instances when the corresponding lifecycle event occurs. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state using the RecordLifecycleActionHeartbeat API call. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of lifecycle hooks, which by default is 50 per Auto Scaling group, the call fails. You can view the lifecycle hooks for an Auto Scaling group using the DescribeLifecycleHooks API call. If you are no longer using a lifecycle hook, you can delete it by calling the DeleteLifecycleHook API.
#
# POST /
# operationId: POST_PutLifecycleHook
export def "post-put-lifecycle-hook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-50 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: PutLifecycleHook}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures an Auto Scaling group to send notifications when specified events take place. Subscribers to the specified topic can have messages delivered to an endpoint such as a web server or an email address. This configuration overwrites any existing configuration. For more information, see Getting Amazon SNS notifications when your Auto Scaling group scales (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ASGettingNotifications.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of SNS topics, which is 10 per Auto Scaling group, the call fails.
#
# GET /
# operationId: GET_PutNotificationConfiguration
export def "get-put-notification-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --topic-arn: string # The Amazon Resource Name (ARN) of the Amazon SNS topic. (required)
  --notification-types: list<string> # The type of event that causes the notification to be sent. To query the notification types supported by Amazon EC2 Auto Scaling, call the DescribeAutoScalingNotificationTypes API. (required)
  --action: string@action-completer-51 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: TopicARN, var: topic_arn, required: true}, {name: NotificationTypes, var: notification_types, style: multi, required: true}, {name: Action, var: action, required: true, default: PutNotificationConfiguration}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, topic_arn: $topic_arn, notification_types: $notification_types, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configures an Auto Scaling group to send notifications when specified events take place. Subscribers to the specified topic can have messages delivered to an endpoint such as a web server or an email address. This configuration overwrites any existing configuration. For more information, see Getting Amazon SNS notifications when your Auto Scaling group scales (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ASGettingNotifications.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of SNS topics, which is 10 per Auto Scaling group, the call fails.
#
# POST /
# operationId: POST_PutNotificationConfiguration
export def "post-put-notification-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-51 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: PutNotificationConfiguration}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a scaling policy for an Auto Scaling group. Scaling policies are used to scale an Auto Scaling group based on configurable metrics. If no policies are defined, the dynamic scaling and predictive scaling features are not used. For more information about using dynamic scaling, see Target tracking scaling policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html) and Step and simple scaling policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html) in the Amazon EC2 Auto Scaling User Guide. For more information about using predictive scaling, see Predictive scaling for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html) in the Amazon EC2 Auto Scaling User Guide. You can view the scaling policies for an Auto Scaling group using the DescribePolicies API call. If you are no longer using a scaling policy, you can delete it by calling the DeletePolicy API.
#
# GET /
# operationId: GET_PutScalingPolicy
export def "get-put-scaling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --policy-name: string # The name of the policy. (required)
  --policy-type: string # One of the following policy types: TargetTrackingScaling StepScaling SimpleScaling (default) PredictiveScaling
  --adjustment-type: string # Specifies how the scaling adjustment is interpreted (for example, an absolute number or a percentage). The valid values are ChangeInCapacity, ExactCapacity, and PercentChangeInCapacity. Required if the policy type is StepScaling or SimpleScaling. For more information, see Scaling adjustment types (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#as-scaling-adjustment) in the Amazon EC2 Auto Scaling User Guide.
  --min-adjustment-step: int # Available for backward compatibility. Use MinAdjustmentMagnitude instead.
  --min-adjustment-magnitude: int # The minimum value to scale by when the adjustment type is PercentChangeInCapacity. For example, suppose that you create a step scaling policy to scale out an Auto Scaling group by 25 percent and you specify a MinAdjustmentMagnitude of 2. If the group has 4 instances and the scaling policy is performed, 25 percent of 4 is 1. However, because you specified a MinAdjustmentMagnitude of 2, Amazon EC2 Auto Scaling scales out the group by 2 instances. Valid only if the policy type is StepScaling or SimpleScaling. For more information, see Scaling adjustment types (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#as-scaling-adjustment) in the Amazon EC2 Auto Scaling User Guide. Some Auto Scaling groups use instance weights. In this case, set the MinAdjustmentMagnitude to a value that is at least as large as your largest instance weight.
  --scaling-adjustment: int # The amount by which to scale, based on the specified adjustment type. A positive value adds to the current capacity while a negative number removes from the current capacity. For exact capacity, you must specify a positive value. Required if the policy type is SimpleScaling. (Not used with any other policy type.)
  --cooldown: int # A cooldown period, in seconds, that applies to a specific simple scaling policy. When a cooldown period is specified here, it overrides the default cooldown. Valid only if the policy type is SimpleScaling. For more information, see Scaling cooldowns for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/Cooldown.html) in the Amazon EC2 Auto Scaling User Guide. Default: None
  --metric-aggregation-type: string # The aggregation type for the CloudWatch metrics. The valid values are Minimum, Maximum, and Average. If the aggregation type is null, the value is treated as Average. Valid only if the policy type is StepScaling.
  --step-adjustments: list # A set of adjustments that enable you to scale based on the size of the alarm breach. Required if the policy type is StepScaling. (Not used with any other policy type.)
  --estimated-instance-warmup: int # Not needed if the default instance warmup is defined for the group. The estimated time, in seconds, until a newly launched instance can contribute to the CloudWatch metrics. This warm-up period applies to instances launched due to a specific target tracking or step scaling policy. When a warm-up period is specified here, it overrides the default instance warmup. Valid only if the policy type is TargetTrackingScaling or StepScaling. The default is to use the value for the default instance warmup defined for the group. If default instance warmup is null, then EstimatedInstanceWarmup falls back to the value of default cooldown.
  --target-tracking-configuration: record # A target tracking scaling policy. Provides support for predefined or custom metrics. The following predefined metrics are available: ASGAverageCPUUtilization ASGAverageNetworkIn ASGAverageNetworkOut ALBRequestCountPerTarget If you specify ALBRequestCountPerTarget for the metric, you must specify the ResourceLabel property with the PredefinedMetricSpecification. For more information, see TargetTrackingConfiguration (https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_TargetTrackingConfiguration.html) in the Amazon EC2 Auto Scaling API Reference. Required if the policy type is TargetTrackingScaling.
  --enabled: oneof<nothing, bool> # Indicates whether the scaling policy is enabled or disabled. The default is enabled. For more information, see Disabling a scaling policy for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-enable-disable-scaling-policy.html) in the Amazon EC2 Auto Scaling User Guide.
  --predictive-scaling-configuration: record # A predictive scaling policy. Provides support for predefined and custom metrics. Predefined metrics include CPU utilization, network in/out, and the Application Load Balancer request count. For more information, see PredictiveScalingConfiguration (https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_PredictiveScalingConfiguration.html) in the Amazon EC2 Auto Scaling API Reference. Required if the policy type is PredictiveScaling.
  --action: string@action-completer-52 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: PolicyName, var: policy_name, required: true}, {name: PolicyType, var: policy_type}, {name: AdjustmentType, var: adjustment_type}, {name: MinAdjustmentStep, var: min_adjustment_step}, {name: MinAdjustmentMagnitude, var: min_adjustment_magnitude}, {name: ScalingAdjustment, var: scaling_adjustment}, {name: Cooldown, var: cooldown}, {name: MetricAggregationType, var: metric_aggregation_type}, {name: StepAdjustments, var: step_adjustments, style: multi}, {name: EstimatedInstanceWarmup, var: estimated_instance_warmup}, {name: TargetTrackingConfiguration, var: target_tracking_configuration, style: multi}, {name: Enabled, var: enabled}, {name: PredictiveScalingConfiguration, var: predictive_scaling_configuration, style: multi}, {name: Action, var: action, required: true, default: PutScalingPolicy}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, policy_name: $policy_name, policy_type: $policy_type, adjustment_type: $adjustment_type, min_adjustment_step: $min_adjustment_step, min_adjustment_magnitude: $min_adjustment_magnitude, scaling_adjustment: $scaling_adjustment, cooldown: $cooldown, metric_aggregation_type: $metric_aggregation_type, step_adjustments: $step_adjustments, estimated_instance_warmup: $estimated_instance_warmup, target_tracking_configuration: $target_tracking_configuration, enabled: $enabled, predictive_scaling_configuration: $predictive_scaling_configuration, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a scaling policy for an Auto Scaling group. Scaling policies are used to scale an Auto Scaling group based on configurable metrics. If no policies are defined, the dynamic scaling and predictive scaling features are not used. For more information about using dynamic scaling, see Target tracking scaling policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html) and Step and simple scaling policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html) in the Amazon EC2 Auto Scaling User Guide. For more information about using predictive scaling, see Predictive scaling for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html) in the Amazon EC2 Auto Scaling User Guide. You can view the scaling policies for an Auto Scaling group using the DescribePolicies API call. If you are no longer using a scaling policy, you can delete it by calling the DeletePolicy API.
#
# POST /
# operationId: POST_PutScalingPolicy
export def "post-put-scaling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-52 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: PutScalingPolicy}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a scheduled scaling action for an Auto Scaling group. For more information, see Scheduled scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html) in the Amazon EC2 Auto Scaling User Guide. You can view the scheduled actions for an Auto Scaling group using the DescribeScheduledActions API call. If you are no longer using a scheduled action, you can delete it by calling the DeleteScheduledAction API. If you try to schedule your action in the past, Amazon EC2 Auto Scaling returns an error message.
#
# GET /
# operationId: GET_PutScheduledUpdateGroupAction
export def "get-put-scheduled-update-group-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --scheduled-action-name: string # The name of this scaling action. (required)
  --time: string # This property is no longer used. (format: date-time)
  --start-time: string # The date and time for this action to start, in YYYY-MM-DDThh:mm:ssZ format in UTC/GMT only and in quotes (for example, "2021-06-01T00:00:00Z"). If you specify Recurrence and StartTime, Amazon EC2 Auto Scaling performs the action at this time, and then performs the action based on the specified recurrence. (format: date-time)
  --end-time: string # The date and time for the recurring schedule to end, in UTC. For example, "2021-06-01T00:00:00Z". (format: date-time)
  --recurrence: string # The recurring schedule for this action. This format consists of five fields separated by white spaces: [Minute] [Hour] [Day_of_Month] [Month_of_Year] [Day_of_Week]. The value must be in quotes (for example, "30 0 1 1,6,12 *"). For more information about this format, see Crontab (http://crontab.org). When StartTime and EndTime are specified with Recurrence, they form the boundaries of when the recurring action starts and stops. Cron expressions use Universal Coordinated Time (UTC) by default.
  --min-size: int # The minimum size of the Auto Scaling group.
  --max-size: int # The maximum size of the Auto Scaling group.
  --desired-capacity: int # The desired capacity is the initial capacity of the Auto Scaling group after the scheduled action runs and the capacity it attempts to maintain. It can scale beyond this capacity if you add more scaling conditions. You must specify at least one of the following properties: MaxSize, MinSize, or DesiredCapacity.
  --time-zone: string # Specifies the time zone for a cron expression. If a time zone is not provided, UTC is used by default. Valid values are the canonical names of the IANA time zones, derived from the IANA Time Zone Database (such as Etc/GMT+9 or Pacific/Tahiti). For more information, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
  --action: string@action-completer-53 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ScheduledActionName, var: scheduled_action_name, required: true}, {name: Time, var: time}, {name: StartTime, var: start_time}, {name: EndTime, var: end_time}, {name: Recurrence, var: recurrence}, {name: MinSize, var: min_size}, {name: MaxSize, var: max_size}, {name: DesiredCapacity, var: desired_capacity}, {name: TimeZone, var: time_zone}, {name: Action, var: action, required: true, default: PutScheduledUpdateGroupAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, scheduled_action_name: $scheduled_action_name, time: $time, start_time: $start_time, end_time: $end_time, recurrence: $recurrence, min_size: $min_size, max_size: $max_size, desired_capacity: $desired_capacity, time_zone: $time_zone, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a scheduled scaling action for an Auto Scaling group. For more information, see Scheduled scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html) in the Amazon EC2 Auto Scaling User Guide. You can view the scheduled actions for an Auto Scaling group using the DescribeScheduledActions API call. If you are no longer using a scheduled action, you can delete it by calling the DeleteScheduledAction API. If you try to schedule your action in the past, Amazon EC2 Auto Scaling returns an error message.
#
# POST /
# operationId: POST_PutScheduledUpdateGroupAction
export def "post-put-scheduled-update-group-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-53 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: PutScheduledUpdateGroupAction}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a warm pool for the specified Auto Scaling group. A warm pool is a pool of pre-initialized EC2 instances that sits alongside the Auto Scaling group. Whenever your application needs to scale out, the Auto Scaling group can draw on the warm pool to meet its new desired capacity. For more information and example configurations, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide. This operation must be called from the Region in which the Auto Scaling group was created. This operation cannot be called on an Auto Scaling group that has a mixed instances policy or a launch template or launch configuration that requests Spot Instances. You can view the instances in the warm pool using the DescribeWarmPool API call. If you are no longer using a warm pool, you can delete it by calling the DeleteWarmPool API.
#
# GET /
# operationId: GET_PutWarmPool
export def "get-put-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --max-group-prepared-capacity: int # Specifies the maximum number of instances that are allowed to be in the warm pool or in any state except Terminated for the Auto Scaling group. This is an optional property. Specify it only if you do not want the warm pool size to be determined by the difference between the group's maximum capacity and its desired capacity. If a value for MaxGroupPreparedCapacity is not specified, Amazon EC2 Auto Scaling launches and maintains the difference between the group's maximum capacity and its desired capacity. If you specify a value for MaxGroupPreparedCapacity, Amazon EC2 Auto Scaling uses the difference between the MaxGroupPreparedCapacity and the desired capacity instead. The size of the warm pool is dynamic. Only when MaxGroupPreparedCapacity and MinSize are set to the same value does the warm pool have an absolute size. If the desired capacity of the Auto Scaling group is higher than the MaxGroupPreparedCapacity, the capacity of the warm pool is 0, unless you specify a value for MinSize. To remove a value that you previously set, include the property but specify -1 for the value.
  --min-size: int # Specifies the minimum number of instances to maintain in the warm pool. This helps you to ensure that there is always a certain number of warmed instances available to handle traffic spikes. Defaults to 0 if not specified.
  --pool-state: string@pool-state-completer # Sets the instance state to transition to after the lifecycle actions are complete. Default is Stopped.
  --instance-reuse-policy: record # Indicates whether instances in the Auto Scaling group can be returned to the warm pool on scale in. The default is to terminate instances in the Auto Scaling group when the group scales in.
  --action: string@action-completer-54 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: MaxGroupPreparedCapacity, var: max_group_prepared_capacity}, {name: MinSize, var: min_size}, {name: PoolState, var: pool_state}, {name: InstanceReusePolicy, var: instance_reuse_policy, style: multi}, {name: Action, var: action, required: true, default: PutWarmPool}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, max_group_prepared_capacity: $max_group_prepared_capacity, min_size: $min_size, pool_state: $pool_state, instance_reuse_policy: $instance_reuse_policy, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates or updates a warm pool for the specified Auto Scaling group. A warm pool is a pool of pre-initialized EC2 instances that sits alongside the Auto Scaling group. Whenever your application needs to scale out, the Auto Scaling group can draw on the warm pool to meet its new desired capacity. For more information and example configurations, see Warm pools for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html) in the Amazon EC2 Auto Scaling User Guide. This operation must be called from the Region in which the Auto Scaling group was created. This operation cannot be called on an Auto Scaling group that has a mixed instances policy or a launch template or launch configuration that requests Spot Instances. You can view the instances in the warm pool using the DescribeWarmPool API call. If you are no longer using a warm pool, you can delete it by calling the DeleteWarmPool API.
#
# POST /
# operationId: POST_PutWarmPool
export def "post-put-warm-pool" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-54 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: PutWarmPool}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Records a heartbeat for the lifecycle action associated with the specified token or instance. This extends the timeout by the length of time defined using the PutLifecycleHook API call. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_RecordLifecycleActionHeartbeat
export def "get-record-lifecycle-action-heartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lifecycle-hook-name: string # The name of the lifecycle hook. (required)
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --lifecycle-action-token: string # A token that uniquely identifies a specific lifecycle action associated with an instance. Amazon EC2 Auto Scaling sends this token to the notification target that you specified when you created the lifecycle hook.
  --instance-id: string # The ID of the instance.
  --action: string@action-completer-55 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: LifecycleHookName, var: lifecycle_hook_name, required: true}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: LifecycleActionToken, var: lifecycle_action_token}, {name: InstanceId, var: instance_id}, {name: Action, var: action, required: true, default: RecordLifecycleActionHeartbeat}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    lifecycle_hook_name: $lifecycle_hook_name, auto_scaling_group_name: $auto_scaling_group_name, lifecycle_action_token: $lifecycle_action_token, instance_id: $instance_id, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Records a heartbeat for the lifecycle action associated with the specified token or instance. This extends the timeout by the length of time defined using the PutLifecycleHook API call. This step is a part of the procedure for adding a lifecycle hook to an Auto Scaling group: (Optional) Create a launch template or launch configuration with a user data script that runs while an instance is in a wait state due to a lifecycle hook. (Optional) Create a Lambda function and a rule that allows Amazon EventBridge to invoke your Lambda function when an instance is put into a wait state due to a lifecycle hook. (Optional) Create a notification target and an IAM role. The target can be either an Amazon SQS queue or an Amazon SNS topic. The role allows Amazon EC2 Auto Scaling to publish lifecycle notifications to the target. Create the lifecycle hook. Specify whether the hook is used when the instances launch or terminate. If you need more time, record the lifecycle action heartbeat to keep the instance in a wait state. If you finish before the timeout period ends, send a callback by using the CompleteLifecycleAction API call. For more information, see Amazon EC2 Auto Scaling lifecycle hooks (https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_RecordLifecycleActionHeartbeat
export def "post-record-lifecycle-action-heartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-55 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: RecordLifecycleActionHeartbeat}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes the specified suspended auto scaling processes, or all suspended process, for the specified Auto Scaling group. For more information, see Suspending and resuming scaling processes (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_ResumeProcesses
export def "get-resume-processes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --scaling-processes: list<string> # One or more of the following processes: Launch Terminate AddToLoadBalancer AlarmNotification AZRebalance HealthCheck InstanceRefresh ReplaceUnhealthy ScheduledActions If you omit this property, all processes are specified.
  --action: string@action-completer-56 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ScalingProcesses, var: scaling_processes, style: multi}, {name: Action, var: action, required: true, default: ResumeProcesses}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, scaling_processes: $scaling_processes, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resumes the specified suspended auto scaling processes, or all suspended process, for the specified Auto Scaling group. For more information, see Suspending and resuming scaling processes (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_ResumeProcesses
export def "post-resume-processes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-56 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: ResumeProcesses}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an instance refresh that is in progress and rolls back any changes that it made. Amazon EC2 Auto Scaling replaces any instances that were replaced during the instance refresh. This restores your Auto Scaling group to the configuration that it was using before the start of the instance refresh. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. A rollback is not supported in the following situations: There is no desired configuration specified for the instance refresh. The Auto Scaling group has a launch template that uses an Amazon Web Services Systems Manager parameter instead of an AMI ID for the ImageId property. The Auto Scaling group uses the launch template's $Latest or $Default version. When you receive a successful response from this operation, Amazon EC2 Auto Scaling immediately begins replacing instances. You can check the status of this operation through the DescribeInstanceRefreshes API operation.
#
# GET /
# operationId: GET_RollbackInstanceRefresh
export def "get-rollback-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group.
  --action: string@action-completer-57 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name}, {name: Action, var: action, required: true, default: RollbackInstanceRefresh}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancels an instance refresh that is in progress and rolls back any changes that it made. Amazon EC2 Auto Scaling replaces any instances that were replaced during the instance refresh. This restores your Auto Scaling group to the configuration that it was using before the start of the instance refresh. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group after you make configuration changes. A rollback is not supported in the following situations: There is no desired configuration specified for the instance refresh. The Auto Scaling group has a launch template that uses an Amazon Web Services Systems Manager parameter instead of an AMI ID for the ImageId property. The Auto Scaling group uses the launch template's $Latest or $Default version. When you receive a successful response from this operation, Amazon EC2 Auto Scaling immediately begins replacing instances. You can check the status of this operation through the DescribeInstanceRefreshes API operation.
#
# POST /
# operationId: POST_RollbackInstanceRefresh
export def "post-rollback-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-57 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: RollbackInstanceRefresh}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the size of the specified Auto Scaling group. If a scale-in activity occurs as a result of a new DesiredCapacity value that is lower than the current size of the group, the Auto Scaling group uses its termination policy to determine which instances to terminate. For more information, see Manual scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-manual-scaling.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_SetDesiredCapacity
export def "get-set-desired-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --desired-capacity: int # The desired capacity is the initial capacity of the Auto Scaling group after this operation completes and the capacity it attempts to maintain. (required)
  --honor-cooldown: oneof<nothing, bool> # Indicates whether Amazon EC2 Auto Scaling waits for the cooldown period to complete before initiating a scaling activity to set your Auto Scaling group to its new capacity. By default, Amazon EC2 Auto Scaling does not honor the cooldown period during manual scaling activities.
  --action: string@action-completer-58 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: DesiredCapacity, var: desired_capacity, required: true}, {name: HonorCooldown, var: honor_cooldown}, {name: Action, var: action, required: true, default: SetDesiredCapacity}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, desired_capacity: $desired_capacity, honor_cooldown: $honor_cooldown, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the size of the specified Auto Scaling group. If a scale-in activity occurs as a result of a new DesiredCapacity value that is lower than the current size of the group, the Auto Scaling group uses its termination policy to determine which instances to terminate. For more information, see Manual scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-manual-scaling.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_SetDesiredCapacity
export def "post-set-desired-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-58 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: SetDesiredCapacity}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the health status of the specified instance. For more information, see Health checks for Auto Scaling instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_SetInstanceHealth
export def "get-set-instance-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-id: string # The ID of the instance. (required)
  --health-status: string # The health status of the instance. Set to Healthy to have the instance remain in service. Set to Unhealthy to have the instance be out of service. Amazon EC2 Auto Scaling terminates and replaces the unhealthy instance. (required)
  --should-respect-grace-period: oneof<nothing, bool> # If the Auto Scaling group of the specified instance has a HealthCheckGracePeriod specified for the group, by default, this call respects the grace period. Set this to False, to have the call not respect the grace period associated with the group. For more information about the health check grace period, see CreateAutoScalingGroup (https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_CreateAutoScalingGroup.html) in the Amazon EC2 Auto Scaling API Reference.
  --action: string@action-completer-59 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: InstanceId, var: instance_id, required: true}, {name: HealthStatus, var: health_status, required: true}, {name: ShouldRespectGracePeriod, var: should_respect_grace_period}, {name: Action, var: action, required: true, default: SetInstanceHealth}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, health_status: $health_status, should_respect_grace_period: $should_respect_grace_period, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the health status of the specified instance. For more information, see Health checks for Auto Scaling instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_SetInstanceHealth
export def "post-set-instance-health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-59 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: SetInstanceHealth}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the instance protection settings of the specified instances. This operation cannot be called on instances in a warm pool. For more information about preventing instances that are part of an Auto Scaling group from terminating on scale in, see Using instance scale-in protection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-instance-protection.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of instance IDs, which is 50 per Auto Scaling group, the call fails.
#
# GET /
# operationId: GET_SetInstanceProtection
export def "get-set-instance-protection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-ids: list<string> # One or more instance IDs. You can specify up to 50 instances. (required)
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --protected-from-scale-in: oneof<nothing, bool> # Indicates whether the instance is protected from termination by Amazon EC2 Auto Scaling when scaling in. (required)
  --action: string@action-completer-60 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: InstanceIds, var: instance_ids, style: multi, required: true}, {name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ProtectedFromScaleIn, var: protected_from_scale_in, required: true}, {name: Action, var: action, required: true, default: SetInstanceProtection}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    instance_ids: $instance_ids, auto_scaling_group_name: $auto_scaling_group_name, protected_from_scale_in: $protected_from_scale_in, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the instance protection settings of the specified instances. This operation cannot be called on instances in a warm pool. For more information about preventing instances that are part of an Auto Scaling group from terminating on scale in, see Using instance scale-in protection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-instance-protection.html) in the Amazon EC2 Auto Scaling User Guide. If you exceed your maximum limit of instance IDs, which is 50 per Auto Scaling group, the call fails.
#
# POST /
# operationId: POST_SetInstanceProtection
export def "post-set-instance-protection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-60 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: SetInstanceProtection}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an instance refresh. During an instance refresh, Amazon EC2 Auto Scaling performs a rolling update of instances in an Auto Scaling group. Instances are terminated first and then replaced, which temporarily reduces the capacity available within your Auto Scaling group. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group. This feature is helpful, for example, when you have a new AMI or a new user data script. You just need to create a new launch template that specifies the new AMI or user data script. Then start an instance refresh to immediately begin the process of updating instances in the group. If successful, the request's response contains a unique ID that you can use to track the progress of the instance refresh. To query its status, call the DescribeInstanceRefreshes API. To describe the instance refreshes that have already run, call the DescribeInstanceRefreshes API. To cancel an instance refresh that is in progress, use the CancelInstanceRefresh API. An instance refresh might fail for several reasons, such as EC2 launch failures, misconfigured health checks, or not ignoring or allowing the termination of instances that are in Standby state or protected from scale in. You can monitor for failed EC2 launches using the scaling activities. To find the scaling activities, call the DescribeScalingActivities API. If you enable auto rollback, your Auto Scaling group will be rolled back automatically when the instance refresh fails. You can enable this feature before starting an instance refresh by specifying the AutoRollback property in the instance refresh preferences. Otherwise, to roll back an instance refresh before it finishes, use the RollbackInstanceRefresh API.
#
# GET /
# operationId: GET_StartInstanceRefresh
export def "get-start-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --strategy: string@strategy-completer # The strategy to use for the instance refresh. The only valid value is Rolling.
  --desired-configuration: record # The desired configuration. For example, the desired configuration can specify a new launch template or a new version of the current launch template. Once the instance refresh succeeds, Amazon EC2 Auto Scaling updates the settings of the Auto Scaling group to reflect the new desired configuration. When you specify a new launch template or a new version of the current launch template for your desired configuration, consider enabling the SkipMatching property in preferences. If it's enabled, Amazon EC2 Auto Scaling skips replacing instances that already use the specified launch template and instance types. This can help you reduce the number of replacements that are required to apply updates.
  --preferences: record # Sets your preferences for the instance refresh so that it performs as expected when you start it. Includes the instance warmup time, the minimum healthy percentage, and the behaviors that you want Amazon EC2 Auto Scaling to use if instances that are in Standby state or protected from scale in are found. You can also choose to enable additional features, such as the following: Auto rollback Checkpoints Skip matching
  --action: string@action-completer-61 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: Strategy, var: strategy}, {name: DesiredConfiguration, var: desired_configuration, style: multi}, {name: Preferences, var: preferences, style: multi}, {name: Action, var: action, required: true, default: StartInstanceRefresh}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, strategy: $strategy, desired_configuration: $desired_configuration, preferences: $preferences, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts an instance refresh. During an instance refresh, Amazon EC2 Auto Scaling performs a rolling update of instances in an Auto Scaling group. Instances are terminated first and then replaced, which temporarily reduces the capacity available within your Auto Scaling group. This operation is part of the instance refresh feature (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html) in Amazon EC2 Auto Scaling, which helps you update instances in your Auto Scaling group. This feature is helpful, for example, when you have a new AMI or a new user data script. You just need to create a new launch template that specifies the new AMI or user data script. Then start an instance refresh to immediately begin the process of updating instances in the group. If successful, the request's response contains a unique ID that you can use to track the progress of the instance refresh. To query its status, call the DescribeInstanceRefreshes API. To describe the instance refreshes that have already run, call the DescribeInstanceRefreshes API. To cancel an instance refresh that is in progress, use the CancelInstanceRefresh API. An instance refresh might fail for several reasons, such as EC2 launch failures, misconfigured health checks, or not ignoring or allowing the termination of instances that are in Standby state or protected from scale in. You can monitor for failed EC2 launches using the scaling activities. To find the scaling activities, call the DescribeScalingActivities API. If you enable auto rollback, your Auto Scaling group will be rolled back automatically when the instance refresh fails. You can enable this feature before starting an instance refresh by specifying the AutoRollback property in the instance refresh preferences. Otherwise, to roll back an instance refresh before it finishes, use the RollbackInstanceRefresh API.
#
# POST /
# operationId: POST_StartInstanceRefresh
export def "post-start-instance-refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-61 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: StartInstanceRefresh}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspends the specified auto scaling processes, or all processes, for the specified Auto Scaling group. If you suspend either the Launch or Terminate process types, it can prevent other process types from functioning properly. For more information, see Suspending and resuming scaling processes (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) in the Amazon EC2 Auto Scaling User Guide. To resume processes that have been suspended, call the ResumeProcesses API.
#
# GET /
# operationId: GET_SuspendProcesses
export def "get-suspend-processes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --scaling-processes: list<string> # One or more of the following processes: Launch Terminate AddToLoadBalancer AlarmNotification AZRebalance HealthCheck InstanceRefresh ReplaceUnhealthy ScheduledActions If you omit this property, all processes are specified.
  --action: string@action-completer-62 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: ScalingProcesses, var: scaling_processes, style: multi}, {name: Action, var: action, required: true, default: SuspendProcesses}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, scaling_processes: $scaling_processes, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suspends the specified auto scaling processes, or all processes, for the specified Auto Scaling group. If you suspend either the Launch or Terminate process types, it can prevent other process types from functioning properly. For more information, see Suspending and resuming scaling processes (https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) in the Amazon EC2 Auto Scaling User Guide. To resume processes that have been suspended, call the ResumeProcesses API.
#
# POST /
# operationId: POST_SuspendProcesses
export def "post-suspend-processes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-62 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: SuspendProcesses}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Terminates the specified instance and optionally adjusts the desired group size. This operation cannot be called on instances in a warm pool. This call simply makes a termination request. The instance is not terminated immediately. When an instance is terminated, the instance status changes to terminated. You can't connect to or start an instance after you've terminated it. If you do not specify the option to decrement the desired capacity, Amazon EC2 Auto Scaling launches instances to replace the ones that are terminated. By default, Amazon EC2 Auto Scaling balances instances across all Availability Zones. If you decrement the desired capacity, your Auto Scaling group can become unbalanced between Availability Zones. Amazon EC2 Auto Scaling tries to rebalance the group, and rebalancing might terminate instances in other zones. For more information, see Rebalancing activities (https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html#AutoScalingBehavior.InstanceUsage) in the Amazon EC2 Auto Scaling User Guide.
#
# GET /
# operationId: GET_TerminateInstanceInAutoScalingGroup
export def "get-terminate-instance-in-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --instance-id: string # The ID of the instance. (required)
  --should-decrement-desired-capacity: oneof<nothing, bool> # Indicates whether terminating the instance also decrements the size of the Auto Scaling group. (required)
  --action: string@action-completer-63 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: InstanceId, var: instance_id, required: true}, {name: ShouldDecrementDesiredCapacity, var: should_decrement_desired_capacity, required: true}, {name: Action, var: action, required: true, default: TerminateInstanceInAutoScalingGroup}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    instance_id: $instance_id, should_decrement_desired_capacity: $should_decrement_desired_capacity, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Terminates the specified instance and optionally adjusts the desired group size. This operation cannot be called on instances in a warm pool. This call simply makes a termination request. The instance is not terminated immediately. When an instance is terminated, the instance status changes to terminated. You can't connect to or start an instance after you've terminated it. If you do not specify the option to decrement the desired capacity, Amazon EC2 Auto Scaling launches instances to replace the ones that are terminated. By default, Amazon EC2 Auto Scaling balances instances across all Availability Zones. If you decrement the desired capacity, your Auto Scaling group can become unbalanced between Availability Zones. Amazon EC2 Auto Scaling tries to rebalance the group, and rebalancing might terminate instances in other zones. For more information, see Rebalancing activities (https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html#AutoScalingBehavior.InstanceUsage) in the Amazon EC2 Auto Scaling User Guide.
#
# POST /
# operationId: POST_TerminateInstanceInAutoScalingGroup
export def "post-terminate-instance-in-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-63 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: TerminateInstanceInAutoScalingGroup}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# We strongly recommend that all Auto Scaling groups use launch templates to ensure full functionality for Amazon EC2 Auto Scaling and Amazon EC2. Updates the configuration for the specified Auto Scaling group. To update an Auto Scaling group, specify the name of the group and the property that you want to change. Any properties that you don't specify are not changed by this update request. The new settings take effect on any scaling activities after this call returns. If you associate a new launch configuration or template with an Auto Scaling group, all new instances will get the updated configuration. Existing instances continue to run with the configuration that they were originally launched with. When you update a group to specify a mixed instances policy instead of a launch configuration or template, existing instances may be replaced to match the new purchasing options that you specified in the policy. For example, if the group currently has 100% On-Demand capacity and the policy specifies 50% Spot capacity, this means that half of your instances will be gradually terminated and relaunched as Spot Instances. When replacing instances, Amazon EC2 Auto Scaling launches new instances before terminating the old ones, so that updating your group does not compromise the performance or availability of your application. Note the following about changing DesiredCapacity, MaxSize, or MinSize: If a scale-in activity occurs as a result of a new DesiredCapacity value that is lower than the current size of the group, the Auto Scaling group uses its termination policy to determine which instances to terminate. If you specify a new value for MinSize without specifying a value for DesiredCapacity, and the new MinSize is larger than the current size of the group, this sets the group's DesiredCapacity to the new MinSize value. If you specify a new value for MaxSize without specifying a value for DesiredCapacity, and the new MaxSize is smaller than the current size of the group, this sets the group's DesiredCapacity to the new MaxSize value. To see which properties have been set, call the DescribeAutoScalingGroups API. To view the scaling policies for an Auto Scaling group, call the DescribePolicies API. If the group has scaling policies, you can update them by calling the PutScalingPolicy API.
#
# GET /
# operationId: GET_UpdateAutoScalingGroup
export def "get-update-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scaling-group-name: string # The name of the Auto Scaling group. (required)
  --launch-configuration-name: string # The name of the launch configuration. If you specify LaunchConfigurationName in your update request, you can't specify LaunchTemplate or MixedInstancesPolicy.
  --launch-template: record # The launch template and version to use to specify the updates. If you specify LaunchTemplate in your update request, you can't specify LaunchConfigurationName or MixedInstancesPolicy.
  --mixed-instances-policy: record # The mixed instances policy. For more information, see Auto Scaling groups with multiple instance types and purchase options (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-mixed-instances-groups.html) in the Amazon EC2 Auto Scaling User Guide.
  --min-size: int # The minimum size of the Auto Scaling group.
  --max-size: int # The maximum size of the Auto Scaling group. With a mixed instances policy that uses instance weighting, Amazon EC2 Auto Scaling may need to go above MaxSize to meet your capacity requirements. In this event, Amazon EC2 Auto Scaling will never go above MaxSize by more than your largest instance weight (weights that define how many units each instance contributes to the desired capacity of the group).
  --desired-capacity: int # The desired capacity is the initial capacity of the Auto Scaling group after this operation completes and the capacity it attempts to maintain. This number must be greater than or equal to the minimum size of the group and less than or equal to the maximum size of the group.
  --default-cooldown: int # Only needed if you use simple scaling policies. The amount of time, in seconds, between one scaling activity ending and another one starting due to simple scaling policies. For more information, see Scaling cooldowns for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/Cooldown.html) in the Amazon EC2 Auto Scaling User Guide.
  --availability-zones: list<string> # One or more Availability Zones for the group.
  --health-check-type: string # A comma-separated value string of one or more health check types. The valid values are EC2, ELB, and VPC_LATTICE. EC2 is the default health check and cannot be disabled. For more information, see Health checks for Auto Scaling instances (https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) in the Amazon EC2 Auto Scaling User Guide. Only specify EC2 if you must clear a value that was previously set.
  --health-check-grace-period: int # The amount of time, in seconds, that Amazon EC2 Auto Scaling waits before checking the health status of an EC2 instance that has come into service and marking it unhealthy due to a failed health check. This is useful if your instances do not immediately pass their health checks after they enter the InService state. For more information, see Set the health check grace period for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/health-check-grace-period.html) in the Amazon EC2 Auto Scaling User Guide.
  --placement-group: string # The name of an existing placement group into which to launch your instances. For more information, see Placement groups (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/placement-groups.html) in the Amazon EC2 User Guide for Linux Instances. A cluster placement group is a logical grouping of instances within a single Availability Zone. You cannot specify multiple Availability Zones and a cluster placement group.
  --vpc-zone-identifier: string # A comma-separated list of subnet IDs for a virtual private cloud (VPC). If you specify VPCZoneIdentifier with AvailabilityZones, the subnets that you specify must reside in those Availability Zones.
  --termination-policies: list<string> # A policy or a list of policies that are used to select the instances to terminate. The policies are executed in the order that you list them. For more information, see Work with Amazon EC2 Auto Scaling termination policies (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-termination-policies.html) in the Amazon EC2 Auto Scaling User Guide. Valid values: Default | AllocationStrategy | ClosestToNextInstanceHour | NewestInstance | OldestInstance | OldestLaunchConfiguration | OldestLaunchTemplate | arn:aws:lambda:region:account-id:function:my-function:my-alias
  --new-instances-protected-from-scale-in: oneof<nothing, bool> # Indicates whether newly launched instances are protected from termination by Amazon EC2 Auto Scaling when scaling in. For more information about preventing instances from terminating on scale in, see Using instance scale-in protection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-instance-protection.html) in the Amazon EC2 Auto Scaling User Guide.
  --service-linked-role-arn: string # The Amazon Resource Name (ARN) of the service-linked role that the Auto Scaling group uses to call other Amazon Web Services on your behalf. For more information, see Service-linked roles (https://docs.aws.amazon.com/autoscaling/ec2/userguide/autoscaling-service-linked-role.html) in the Amazon EC2 Auto Scaling User Guide.
  --max-instance-lifetime: int # The maximum amount of time, in seconds, that an instance can be in service. The default is null. If specified, the value must be either 0 or a number equal to or greater than 86,400 seconds (1 day). To clear a previously set value, specify a new value of 0. For more information, see Replacing Auto Scaling instances based on maximum instance lifetime (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-max-instance-lifetime.html) in the Amazon EC2 Auto Scaling User Guide.
  --capacity-rebalance: oneof<nothing, bool> # Enables or disables Capacity Rebalancing. For more information, see Use Capacity Rebalancing to handle Amazon EC2 Spot Interruptions (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html) in the Amazon EC2 Auto Scaling User Guide.
  --context: string # Reserved.
  --desired-capacity-type: string # The unit of measurement for the value specified for desired capacity. Amazon EC2 Auto Scaling supports DesiredCapacityType for attribute-based instance type selection only. For more information, see Creating an Auto Scaling group using attribute-based instance type selection (https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-asg-instance-type-requirements.html) in the Amazon EC2 Auto Scaling User Guide. By default, Amazon EC2 Auto Scaling specifies units, which translates into number of instances. Valid values: units | vcpu | memory-mib
  --default-instance-warmup: int # The amount of time, in seconds, until a new instance is considered to have finished initializing and resource consumption to become stable after it enters the InService state. During an instance refresh, Amazon EC2 Auto Scaling waits for the warm-up period after it replaces an instance before it moves on to replacing the next instance. Amazon EC2 Auto Scaling also waits for the warm-up period before aggregating the metrics for new instances with existing instances in the Amazon CloudWatch metrics that are used for scaling, resulting in more reliable usage data. For more information, see Set the default instance warmup for an Auto Scaling group (https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-default-instance-warmup.html) in the Amazon EC2 Auto Scaling User Guide. To manage various warm-up settings at the group level, we recommend that you set the default instance warmup, even if it is set to 0 seconds. To remove a value that you previously set, include the property but specify -1 for the value. However, we strongly recommend keeping the default instance warmup enabled by specifying a value of 0 or other nominal value.
  --action: string@action-completer-64 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AutoScalingGroupName, var: auto_scaling_group_name, required: true}, {name: LaunchConfigurationName, var: launch_configuration_name}, {name: LaunchTemplate, var: launch_template, style: multi}, {name: MixedInstancesPolicy, var: mixed_instances_policy, style: multi}, {name: MinSize, var: min_size}, {name: MaxSize, var: max_size}, {name: DesiredCapacity, var: desired_capacity}, {name: DefaultCooldown, var: default_cooldown}, {name: AvailabilityZones, var: availability_zones, style: multi}, {name: HealthCheckType, var: health_check_type}, {name: HealthCheckGracePeriod, var: health_check_grace_period}, {name: PlacementGroup, var: placement_group}, {name: VPCZoneIdentifier, var: vpc_zone_identifier}, {name: TerminationPolicies, var: termination_policies, style: multi}, {name: NewInstancesProtectedFromScaleIn, var: new_instances_protected_from_scale_in}, {name: ServiceLinkedRoleARN, var: service_linked_role_arn}, {name: MaxInstanceLifetime, var: max_instance_lifetime}, {name: CapacityRebalance, var: capacity_rebalance}, {name: Context, var: context}, {name: DesiredCapacityType, var: desired_capacity_type}, {name: DefaultInstanceWarmup, var: default_instance_warmup}, {name: Action, var: action, required: true, default: UpdateAutoScalingGroup}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auto_scaling_group_name: $auto_scaling_group_name, launch_configuration_name: $launch_configuration_name, launch_template: $launch_template, mixed_instances_policy: $mixed_instances_policy, min_size: $min_size, max_size: $max_size, desired_capacity: $desired_capacity, default_cooldown: $default_cooldown, availability_zones: $availability_zones, health_check_type: $health_check_type, health_check_grace_period: $health_check_grace_period, placement_group: $placement_group, vpc_zone_identifier: $vpc_zone_identifier, termination_policies: $termination_policies, new_instances_protected_from_scale_in: $new_instances_protected_from_scale_in, service_linked_role_arn: $service_linked_role_arn, max_instance_lifetime: $max_instance_lifetime, capacity_rebalance: $capacity_rebalance, context: $context, desired_capacity_type: $desired_capacity_type, default_instance_warmup: $default_instance_warmup, action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# We strongly recommend that all Auto Scaling groups use launch templates to ensure full functionality for Amazon EC2 Auto Scaling and Amazon EC2. Updates the configuration for the specified Auto Scaling group. To update an Auto Scaling group, specify the name of the group and the property that you want to change. Any properties that you don't specify are not changed by this update request. The new settings take effect on any scaling activities after this call returns. If you associate a new launch configuration or template with an Auto Scaling group, all new instances will get the updated configuration. Existing instances continue to run with the configuration that they were originally launched with. When you update a group to specify a mixed instances policy instead of a launch configuration or template, existing instances may be replaced to match the new purchasing options that you specified in the policy. For example, if the group currently has 100% On-Demand capacity and the policy specifies 50% Spot capacity, this means that half of your instances will be gradually terminated and relaunched as Spot Instances. When replacing instances, Amazon EC2 Auto Scaling launches new instances before terminating the old ones, so that updating your group does not compromise the performance or availability of your application. Note the following about changing DesiredCapacity, MaxSize, or MinSize: If a scale-in activity occurs as a result of a new DesiredCapacity value that is lower than the current size of the group, the Auto Scaling group uses its termination policy to determine which instances to terminate. If you specify a new value for MinSize without specifying a value for DesiredCapacity, and the new MinSize is larger than the current size of the group, this sets the group's DesiredCapacity to the new MinSize value. If you specify a new value for MaxSize without specifying a value for DesiredCapacity, and the new MaxSize is smaller than the current size of the group, this sets the group's DesiredCapacity to the new MaxSize value. To see which properties have been set, call the DescribeAutoScalingGroups API. To view the scaling policies for an Auto Scaling group, call the DescribePolicies API. If the group has scaling policies, you can update them by calling the PutScalingPolicy API.
#
# POST /
# operationId: POST_UpdateAutoScalingGroup
export def "post-update-auto-scaling-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-64 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: Action, var: action, required: true, default: UpdateAutoScalingGroup}, {name: Version, var: version, required: true, default: "2011-01-01"}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action: $action, version: $version, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
