# Auto-generated client for AWS MediaTailor v2018-04-23
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mediatailor/2018-04-23/openapi.json
# Auth: --token flag or $env.AWS_MEDIATAILOR_TOKEN

const CLIENT = {
  base_url: "http://api.mediatailor.us-east-1.amazonaws.com"
  token_env_var: "AWS_MEDIATAILOR_TOKEN"
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

def base-url-completer [] { ["http://api.mediatailor.us-east-1.amazonaws.com" "http://api.mediatailor.us-east-2.amazonaws.com" "http://api.mediatailor.us-west-1.amazonaws.com" "http://api.mediatailor.us-west-2.amazonaws.com" "http://api.mediatailor.us-gov-west-1.amazonaws.com" "http://api.mediatailor.us-gov-east-1.amazonaws.com" "http://api.mediatailor.ca-central-1.amazonaws.com" "http://api.mediatailor.eu-north-1.amazonaws.com" "http://api.mediatailor.eu-west-1.amazonaws.com" "http://api.mediatailor.eu-west-2.amazonaws.com" "http://api.mediatailor.eu-west-3.amazonaws.com" "http://api.mediatailor.eu-central-1.amazonaws.com" "http://api.mediatailor.eu-south-1.amazonaws.com" "http://api.mediatailor.af-south-1.amazonaws.com" "http://api.mediatailor.ap-northeast-1.amazonaws.com" "http://api.mediatailor.ap-northeast-2.amazonaws.com" "http://api.mediatailor.ap-northeast-3.amazonaws.com" "http://api.mediatailor.ap-southeast-1.amazonaws.com" "http://api.mediatailor.ap-southeast-2.amazonaws.com" "http://api.mediatailor.ap-east-1.amazonaws.com" "http://api.mediatailor.ap-south-1.amazonaws.com" "http://api.mediatailor.sa-east-1.amazonaws.com" "http://api.mediatailor.me-south-1.amazonaws.com" "https://api.mediatailor.us-east-1.amazonaws.com" "https://api.mediatailor.us-east-2.amazonaws.com" "https://api.mediatailor.us-west-1.amazonaws.com" "https://api.mediatailor.us-west-2.amazonaws.com" "https://api.mediatailor.us-gov-west-1.amazonaws.com" "https://api.mediatailor.us-gov-east-1.amazonaws.com" "https://api.mediatailor.ca-central-1.amazonaws.com" "https://api.mediatailor.eu-north-1.amazonaws.com" "https://api.mediatailor.eu-west-1.amazonaws.com" "https://api.mediatailor.eu-west-2.amazonaws.com" "https://api.mediatailor.eu-west-3.amazonaws.com" "https://api.mediatailor.eu-central-1.amazonaws.com" "https://api.mediatailor.eu-south-1.amazonaws.com" "https://api.mediatailor.af-south-1.amazonaws.com" "https://api.mediatailor.ap-northeast-1.amazonaws.com" "https://api.mediatailor.ap-northeast-2.amazonaws.com" "https://api.mediatailor.ap-northeast-3.amazonaws.com" "https://api.mediatailor.ap-southeast-1.amazonaws.com" "https://api.mediatailor.ap-southeast-2.amazonaws.com" "https://api.mediatailor.ap-east-1.amazonaws.com" "https://api.mediatailor.ap-south-1.amazonaws.com" "https://api.mediatailor.sa-east-1.amazonaws.com" "https://api.mediatailor.me-south-1.amazonaws.com" "http://api.mediatailor.cn-north-1.amazonaws.com.cn" "http://api.mediatailor.cn-northwest-1.amazonaws.com.cn" "https://api.mediatailor.cn-north-1.amazonaws.com.cn" "https://api.mediatailor.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def playback-mode-completer [] { ["LINEAR" "LOOP"] }
def tier-completer [] { ["BASIC" "STANDARD"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    configure-logs-for-channel: "record<ChannelName: string, LogTypes: list<string>>"
    configure-logs-for-playback-configuration: "record<PercentEnabled: int, PlaybackConfigurationName: string>"
    create-channel: "record<Arn: string, ChannelName: string, ChannelState: string, CreationTime: string, FillerSlate: record<SourceLocationName: string, VodSourceName: string>, LastModifiedTime: string, Outputs: table<DashPlaylistSettings: record, HlsPlaylistSettings: record, ManifestName: string, PlaybackUrl: string, SourceGroup: string>, PlaybackMode: string, Tags: record, Tier: string>"
    delete-channel: "record"
    describe-channel: "record<Arn: string, ChannelName: string, ChannelState: string, CreationTime: string, FillerSlate: record<SourceLocationName: string, VodSourceName: string>, LastModifiedTime: string, LogConfiguration: record<LogTypes: list<string>>, Outputs: table<DashPlaylistSettings: record, HlsPlaylistSettings: record, ManifestName: string, PlaybackUrl: string, SourceGroup: string>, PlaybackMode: string, Tags: record, Tier: string>"
    update-channel: "record<Arn: string, ChannelName: string, ChannelState: string, CreationTime: string, FillerSlate: record<SourceLocationName: string, VodSourceName: string>, LastModifiedTime: string, Outputs: table<DashPlaylistSettings: record, HlsPlaylistSettings: record, ManifestName: string, PlaybackUrl: string, SourceGroup: string>, PlaybackMode: string, Tags: record, Tier: string>"
    create-live-source: "record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, LiveSourceName: string, SourceLocationName: string, Tags: record>"
    delete-live-source: "record"
    describe-live-source: "record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, LiveSourceName: string, SourceLocationName: string, Tags: record>"
    update-live-source: "record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, LiveSourceName: string, SourceLocationName: string, Tags: record>"
    create-prefetch-schedule: "record<Arn: string, Consumption: record<AvailMatchingCriteria: list<record>, EndTime: string, StartTime: string>, Name: string, PlaybackConfigurationName: string, Retrieval: record<DynamicVariables: record, EndTime: string, StartTime: string>, StreamId: string>"
    delete-prefetch-schedule: "record"
    get-prefetch-schedule: "record<Arn: string, Consumption: record<AvailMatchingCriteria: list<record>, EndTime: string, StartTime: string>, Name: string, PlaybackConfigurationName: string, Retrieval: record<DynamicVariables: record, EndTime: string, StartTime: string>, StreamId: string>"
    create-program: "record<AdBreaks: table<MessageType: string, OffsetMillis: int, Slate: record, SpliceInsertMessage: record, TimeSignalMessage: record>, Arn: string, ChannelName: string, ClipRange: record<EndOffsetMillis: int>, CreationTime: string, DurationMillis: int, LiveSourceName: string, ProgramName: string, ScheduledStartTime: string, SourceLocationName: string, VodSourceName: string>"
    delete-program: "record"
    describe-program: "record<AdBreaks: table<MessageType: string, OffsetMillis: int, Slate: record, SpliceInsertMessage: record, TimeSignalMessage: record>, Arn: string, ChannelName: string, ClipRange: record<EndOffsetMillis: int>, CreationTime: string, DurationMillis: int, LiveSourceName: string, ProgramName: string, ScheduledStartTime: string, SourceLocationName: string, VodSourceName: string>"
    update-program: "record<AdBreaks: table<MessageType: string, OffsetMillis: int, Slate: record, SpliceInsertMessage: record, TimeSignalMessage: record>, Arn: string, ChannelName: string, ClipRange: record<EndOffsetMillis: int>, CreationTime: string, DurationMillis: int, LiveSourceName: string, ProgramName: string, ScheduledStartTime: string, SourceLocationName: string, VodSourceName: string>"
    create-source-location: "record<AccessConfiguration: record<AccessType: string, SecretsManagerAccessTokenConfiguration: record<HeaderName: string, SecretArn: string, SecretStringKey: string>>, Arn: string, CreationTime: string, DefaultSegmentDeliveryConfiguration: record<BaseUrl: string>, HttpConfiguration: record<BaseUrl: string>, LastModifiedTime: string, SegmentDeliveryConfigurations: table<BaseUrl: string, Name: string>, SourceLocationName: string, Tags: record>"
    delete-source-location: "record"
    describe-source-location: "record<AccessConfiguration: record<AccessType: string, SecretsManagerAccessTokenConfiguration: record<HeaderName: string, SecretArn: string, SecretStringKey: string>>, Arn: string, CreationTime: string, DefaultSegmentDeliveryConfiguration: record<BaseUrl: string>, HttpConfiguration: record<BaseUrl: string>, LastModifiedTime: string, SegmentDeliveryConfigurations: table<BaseUrl: string, Name: string>, SourceLocationName: string, Tags: record>"
    update-source-location: "record<AccessConfiguration: record<AccessType: string, SecretsManagerAccessTokenConfiguration: record<HeaderName: string, SecretArn: string, SecretStringKey: string>>, Arn: string, CreationTime: string, DefaultSegmentDeliveryConfiguration: record<BaseUrl: string>, HttpConfiguration: record<BaseUrl: string>, LastModifiedTime: string, SegmentDeliveryConfigurations: table<BaseUrl: string, Name: string>, SourceLocationName: string, Tags: record>"
    create-vod-source: "record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, SourceLocationName: string, Tags: record, VodSourceName: string>"
    delete-vod-source: "record"
    describe-vod-source: "record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, SourceLocationName: string, Tags: record, VodSourceName: string>"
    update-vod-source: "record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, SourceLocationName: string, Tags: record, VodSourceName: string>"
    delete-channel-policy: "record"
    get-channel-policy: "record<Policy: string>"
    put-channel-policy: "record"
    delete-playback-configuration: "record"
    get-playback-configuration: "record<AdDecisionServerUrl: string, AvailSuppression: record<Mode: string, Value: string>, Bumper: record<EndUrl: string, StartUrl: string>, CdnConfiguration: record<AdSegmentUrlPrefix: string, ContentSegmentUrlPrefix: string>, ConfigurationAliases: record, DashConfiguration: record<ManifestEndpointPrefix: string, MpdLocation: string, OriginManifestType: string>, HlsConfiguration: record<ManifestEndpointPrefix: string>, LivePreRollConfiguration: record<AdDecisionServerUrl: string, MaxDurationSeconds: int>, LogConfiguration: record<PercentEnabled: int>, ManifestProcessingRules: record<AdMarkerPassthrough: record<Enabled: bool>>, Name: string, PersonalizationThresholdSeconds: int, PlaybackConfigurationArn: string, PlaybackEndpointPrefix: string, SessionInitializationEndpointPrefix: string, SlateAdUrl: string, Tags: record, TranscodeProfileName: string, VideoContentSourceUrl: string>"
    get-channel-schedule: "record<Items: table<ApproximateDurationSeconds: int, ApproximateStartTime: string, Arn: string, ChannelName: string, LiveSourceName: string, ProgramName: string, ScheduleAdBreaks: list, ScheduleEntryType: string, SourceLocationName: string, VodSourceName: string>, NextToken: string>"
    list-alerts: "record<Items: table<AlertCode: string, AlertMessage: string, LastModifiedTime: string, RelatedResourceArns: list, ResourceArn: string>, NextToken: string>"
    list-channels: "record<Items: table<Arn: string, ChannelName: string, ChannelState: string, CreationTime: string, FillerSlate: record, LastModifiedTime: string, LogConfiguration: record, Outputs: list, PlaybackMode: string, Tags: record, Tier: string>, NextToken: string>"
    list-live-sources: "record<Items: table<Arn: string, CreationTime: string, HttpPackageConfigurations: list, LastModifiedTime: string, LiveSourceName: string, SourceLocationName: string, Tags: record>, NextToken: string>"
    list-playback-configurations: "record<Items: table<AdDecisionServerUrl: string, AvailSuppression: record, Bumper: record, CdnConfiguration: record, ConfigurationAliases: record, DashConfiguration: record, HlsConfiguration: record, LivePreRollConfiguration: record, LogConfiguration: record, ManifestProcessingRules: record, Name: string, PersonalizationThresholdSeconds: int, PlaybackConfigurationArn: string, PlaybackEndpointPrefix: string, SessionInitializationEndpointPrefix: string, SlateAdUrl: string, Tags: record, TranscodeProfileName: string, VideoContentSourceUrl: string>, NextToken: string>"
    list-prefetch-schedules: "record<Items: table<Arn: string, Consumption: record, Name: string, PlaybackConfigurationName: string, Retrieval: record, StreamId: string>, NextToken: string>"
    list-source-locations: "record<Items: table<AccessConfiguration: record, Arn: string, CreationTime: string, DefaultSegmentDeliveryConfiguration: record, HttpConfiguration: record, LastModifiedTime: string, SegmentDeliveryConfigurations: list, SourceLocationName: string, Tags: record>, NextToken: string>"
    list-tags-for-resource: "record<Tags: record>"
    list-vod-sources: "record<Items: table<Arn: string, CreationTime: string, HttpPackageConfigurations: list, LastModifiedTime: string, SourceLocationName: string, Tags: record, VodSourceName: string>, NextToken: string>"
    put-playback-configuration: "record<AdDecisionServerUrl: string, AvailSuppression: record<Mode: string, Value: string>, Bumper: record<EndUrl: string, StartUrl: string>, CdnConfiguration: record<AdSegmentUrlPrefix: string, ContentSegmentUrlPrefix: string>, ConfigurationAliases: record, DashConfiguration: record<ManifestEndpointPrefix: string, MpdLocation: string, OriginManifestType: string>, HlsConfiguration: record<ManifestEndpointPrefix: string>, LivePreRollConfiguration: record<AdDecisionServerUrl: string, MaxDurationSeconds: int>, LogConfiguration: record<PercentEnabled: int>, ManifestProcessingRules: record<AdMarkerPassthrough: record<Enabled: bool>>, Name: string, PersonalizationThresholdSeconds: int, PlaybackConfigurationArn: string, PlaybackEndpointPrefix: string, SessionInitializationEndpointPrefix: string, SlateAdUrl: string, Tags: record, TranscodeProfileName: string, VideoContentSourceUrl: string>"
    start-channel: "record"
    stop-channel: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["configure-logs-for-channel" "configure-logs-for-playback-configuration" "create-channel" "delete-channel" "describe-channel" "update-channel" "create-live-source" "delete-live-source" "describe-live-source" "update-live-source" "create-prefetch-schedule" "delete-prefetch-schedule" "get-prefetch-schedule" "create-program" "delete-program" "describe-program" "update-program" "create-source-location" "delete-source-location" "describe-source-location" "update-source-location" "create-vod-source" "delete-vod-source" "describe-vod-source" "update-vod-source" "delete-channel-policy" "get-channel-policy" "put-channel-policy" "delete-playback-configuration" "get-playback-configuration" "get-channel-schedule" "list-alerts" "list-channels" "list-live-sources" "list-playback-configurations" "list-prefetch-schedules" "list-source-locations" "list-tags-for-resource" "tag-resource" "list-vod-sources" "put-playback-configuration" "start-channel" "stop-channel" "untag-resource" "commands"] | sort) } | get name | first)
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

# Configures Amazon CloudWatch log settings for a channel.
#
# PUT /configureLogs/channel
# Returns: record<ChannelName: string, LogTypes: list<string>>
# operationId: ConfigureLogsForChannel
export def "configure-logs-for-channel" [
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
  channel_name: string # The name of the channel.
  log_types: list<string> # The types of logs to collect.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/configureLogs/channel"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: ChannelName, var: channel_name}, {name: LogTypes, var: log_types}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, channel_name: $channel_name, log_types: $log_types
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Amazon CloudWatch log settings for a playback configuration.
#
# PUT /configureLogs/playbackConfiguration
# Returns: record<PercentEnabled: int, PlaybackConfigurationName: string>
# operationId: ConfigureLogsForPlaybackConfiguration
export def "configure-logs-for-playback-configuration" [
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
  percent_enabled: int # The percentage of session logs that MediaTailor sends to your Cloudwatch Logs account. For example, if your playback configuration has 1000 sessions and percentEnabled is set to 60, MediaTailor sends logs for 600 of the sessions to CloudWatch Logs. MediaTailor decides at random which of the playback configuration sessions to send logs for. If you want to view logs for a specific session, you can use the debug log mode (https://docs.aws.amazon.com/mediatailor/latest/ug/debug-log-mode.html). Valid values: 0 - 100
  playback_configuration_name: string # The name of the playback configuration.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/configureLogs/playbackConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: PercentEnabled, var: percent_enabled}, {name: PlaybackConfigurationName, var: playback_configuration_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, percent_enabled: $percent_enabled, playback_configuration_name: $playback_configuration_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a channel. For information about MediaTailor channels, see Working with channels (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-channels.html) in the MediaTailor User Guide.
#
# POST /channel/{ChannelName}
# Returns: record<Arn: string, ChannelName: string, ChannelState: string, CreationTime: string, FillerSlate: record<SourceLocationName: string, VodSourceName: string>, LastModifiedTime: string, Outputs: table<DashPlaylistSettings: record, HlsPlaylistSettings: record, ManifestName: string, PlaybackUrl: string, SourceGroup: string>, PlaybackMode: string, Tags: record, Tier: string>
# operationId: CreateChannel
export def "create-channel" [
  channel_name: string
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
  --filler-slate: record # Slate VOD source configuration. — shape: {SourceLocationName?: string, VodSourceName?: string}
  outputs: list # An object that represents an object in the CreateChannel request. — item shape: {DashPlaylistSettings?: record, HlsPlaylistSettings?: record, ManifestName: string, SourceGroup: string}
  playback_mode: string@playback-mode-completer # The type of playback mode to use for this channel. LINEAR - The programs in the schedule play once back-to-back in the schedule. LOOP - The programs in the schedule play back-to-back in an endless loop. When the last program in the schedule stops playing, playback loops back to the first program in the schedule.
  --tags: record # The tags to assign to the channel. Tags are key-value pairs that you can associate with Amazon resources to help with organization, access control, and cost tracking. For more information, see Tagging AWS Elemental MediaTailor Resources (https://docs.aws.amazon.com/mediatailor/latest/ug/tagging.html).
  --tier: string@tier-completer # The tier of the channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channel/{ChannelName}"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: FillerSlate, var: filler_slate}, {name: Outputs, var: outputs}, {name: PlaybackMode, var: playback_mode}, {name: tags, var: tags}, {name: Tier, var: tier}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filler_slate: $filler_slate, outputs: $outputs, playback_mode: $playback_mode, tags: $tags, tier: $tier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a channel. For information about MediaTailor channels, see Working with channels (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-channels.html) in the MediaTailor User Guide.
#
# DELETE /channel/{ChannelName}
# Returns: record
# operationId: DeleteChannel
export def "delete-channel" [
  channel_name: string
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
    path: "/channel/{ChannelName}"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a channel. For information about MediaTailor channels, see Working with channels (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-channels.html) in the MediaTailor User Guide.
#
# GET /channel/{ChannelName}
# Returns: record<Arn: string, ChannelName: string, ChannelState: string, CreationTime: string, FillerSlate: record<SourceLocationName: string, VodSourceName: string>, LastModifiedTime: string, LogConfiguration: record<LogTypes: list<string>>, Outputs: table<DashPlaylistSettings: record, HlsPlaylistSettings: record, ManifestName: string, PlaybackUrl: string, SourceGroup: string>, PlaybackMode: string, Tags: record, Tier: string>
# operationId: DescribeChannel
export def "describe-channel" [
  channel_name: string
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
    path: "/channel/{ChannelName}"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a channel. For information about MediaTailor channels, see Working with channels (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-channels.html) in the MediaTailor User Guide.
#
# PUT /channel/{ChannelName}
# Returns: record<Arn: string, ChannelName: string, ChannelState: string, CreationTime: string, FillerSlate: record<SourceLocationName: string, VodSourceName: string>, LastModifiedTime: string, Outputs: table<DashPlaylistSettings: record, HlsPlaylistSettings: record, ManifestName: string, PlaybackUrl: string, SourceGroup: string>, PlaybackMode: string, Tags: record, Tier: string>
# operationId: UpdateChannel
export def "update-channel" [
  channel_name: string
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
  --filler-slate: record # Slate VOD source configuration. — shape: {SourceLocationName?: string, VodSourceName?: string}
  outputs: list # An object that represents an object in the CreateChannel request. — item shape: {DashPlaylistSettings?: record, HlsPlaylistSettings?: record, ManifestName: string, SourceGroup: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/channel/{ChannelName}"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: FillerSlate, var: filler_slate}, {name: Outputs, var: outputs}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filler_slate: $filler_slate, outputs: $outputs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The live source configuration.
#
# POST /sourceLocation/{SourceLocationName}/liveSource/{LiveSourceName}
# Returns: record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, LiveSourceName: string, SourceLocationName: string, Tags: record>
# operationId: CreateLiveSource
export def "create-live-source" [
  source_location_name: string
  live_source_name: string
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
  http_package_configurations: list # The VOD source's HTTP package configuration settings. — item shape: {Path: string, SourceGroup: string, Type: "DASH"|"HLS"}
  --tags: record # The tags to assign to the live source. Tags are key-value pairs that you can associate with Amazon resources to help with organization, access control, and cost tracking. For more information, see Tagging AWS Elemental MediaTailor Resources (https://docs.aws.amazon.com/mediatailor/latest/ug/tagging.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sourceLocation/{SourceLocationName}/liveSource/{LiveSourceName}"
    path_params: [{name: SourceLocationName, var: source_location_name}, {name: LiveSourceName, var: live_source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: HttpPackageConfigurations, var: http_package_configurations}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, live_source_name: $live_source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, http_package_configurations: $http_package_configurations, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The live source to delete.
#
# DELETE /sourceLocation/{SourceLocationName}/liveSource/{LiveSourceName}
# Returns: record
# operationId: DeleteLiveSource
export def "delete-live-source" [
  source_location_name: string
  live_source_name: string
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
    path: "/sourceLocation/{SourceLocationName}/liveSource/{LiveSourceName}"
    path_params: [{name: SourceLocationName, var: source_location_name}, {name: LiveSourceName, var: live_source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, live_source_name: $live_source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The live source to describe.
#
# GET /sourceLocation/{SourceLocationName}/liveSource/{LiveSourceName}
# Returns: record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, LiveSourceName: string, SourceLocationName: string, Tags: record>
# operationId: DescribeLiveSource
export def "describe-live-source" [
  source_location_name: string
  live_source_name: string
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
    path: "/sourceLocation/{SourceLocationName}/liveSource/{LiveSourceName}"
    path_params: [{name: SourceLocationName, var: source_location_name}, {name: LiveSourceName, var: live_source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, live_source_name: $live_source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a live source's configuration.
#
# PUT /sourceLocation/{SourceLocationName}/liveSource/{LiveSourceName}
# Returns: record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, LiveSourceName: string, SourceLocationName: string, Tags: record>
# operationId: UpdateLiveSource
export def "update-live-source" [
  source_location_name: string
  live_source_name: string
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
  http_package_configurations: list # The VOD source's HTTP package configuration settings. — item shape: {Path: string, SourceGroup: string, Type: "DASH"|"HLS"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sourceLocation/{SourceLocationName}/liveSource/{LiveSourceName}"
    path_params: [{name: SourceLocationName, var: source_location_name}, {name: LiveSourceName, var: live_source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: HttpPackageConfigurations, var: http_package_configurations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, live_source_name: $live_source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, http_package_configurations: $http_package_configurations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a prefetch schedule for a playback configuration. A prefetch schedule allows you to tell MediaTailor to fetch and prepare certain ads before an ad break happens. For more information about ad prefetching, see Using ad prefetching (https://docs.aws.amazon.com/mediatailor/latest/ug/prefetching-ads.html) in the MediaTailor User Guide.
#
# POST /prefetchSchedule/{PlaybackConfigurationName}/{Name}
# Returns: record<Arn: string, Consumption: record<AvailMatchingCriteria: list<record>, EndTime: string, StartTime: string>, Name: string, PlaybackConfigurationName: string, Retrieval: record<DynamicVariables: record, EndTime: string, StartTime: string>, StreamId: string>
# operationId: CreatePrefetchSchedule
export def "create-prefetch-schedule" [
  playback_configuration_name: string
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
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  consumption: record # A complex type that contains settings that determine how and when that MediaTailor places prefetched ads into upcoming ad breaks. — shape: {AvailMatchingCriteria?: list, EndTime?: string, StartTime?: string}
  retrieval: record # A complex type that contains settings governing when MediaTailor prefetches ads, and which dynamic variables that MediaTailor includes in the request to the ad decision server. — shape: {DynamicVariables?: record, EndTime?: string, StartTime?: string}
  --stream-id: string # An optional stream identifier that MediaTailor uses to prefetch ads for multiple streams that use the same playback configuration. If StreamId is specified, MediaTailor returns all of the prefetch schedules with an exact match on StreamId. If not specified, MediaTailor returns all of the prefetch schedules for the playback configuration, regardless of StreamId.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prefetchSchedule/{PlaybackConfigurationName}/{Name}"
    path_params: [{name: PlaybackConfigurationName, var: playback_configuration_name}, {name: Name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Consumption, var: consumption}, {name: Retrieval, var: retrieval}, {name: StreamId, var: stream_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playback_configuration_name: $playback_configuration_name, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, consumption: $consumption, retrieval: $retrieval, stream_id: $stream_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a prefetch schedule for a specific playback configuration. If you call DeletePrefetchSchedule on an expired prefetch schedule, MediaTailor returns an HTTP 404 status code. For more information about ad prefetching, see Using ad prefetching (https://docs.aws.amazon.com/mediatailor/latest/ug/prefetching-ads.html) in the MediaTailor User Guide.
#
# DELETE /prefetchSchedule/{PlaybackConfigurationName}/{Name}
# Returns: record
# operationId: DeletePrefetchSchedule
export def "delete-prefetch-schedule" [
  playback_configuration_name: string
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
    path: "/prefetchSchedule/{PlaybackConfigurationName}/{Name}"
    path_params: [{name: PlaybackConfigurationName, var: playback_configuration_name}, {name: Name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    playback_configuration_name: $playback_configuration_name, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a prefetch schedule for a playback configuration. A prefetch schedule allows you to tell MediaTailor to fetch and prepare certain ads before an ad break happens. For more information about ad prefetching, see Using ad prefetching (https://docs.aws.amazon.com/mediatailor/latest/ug/prefetching-ads.html) in the MediaTailor User Guide.
#
# GET /prefetchSchedule/{PlaybackConfigurationName}/{Name}
# Returns: record<Arn: string, Consumption: record<AvailMatchingCriteria: list<record>, EndTime: string, StartTime: string>, Name: string, PlaybackConfigurationName: string, Retrieval: record<DynamicVariables: record, EndTime: string, StartTime: string>, StreamId: string>
# operationId: GetPrefetchSchedule
export def "get-prefetch-schedule" [
  playback_configuration_name: string
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
    path: "/prefetchSchedule/{PlaybackConfigurationName}/{Name}"
    path_params: [{name: PlaybackConfigurationName, var: playback_configuration_name}, {name: Name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playback_configuration_name: $playback_configuration_name, name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a program within a channel. For information about programs, see Working with programs (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-programs.html) in the MediaTailor User Guide.
#
# POST /channel/{ChannelName}/program/{ProgramName}
# Returns: record<AdBreaks: table<MessageType: string, OffsetMillis: int, Slate: record, SpliceInsertMessage: record, TimeSignalMessage: record>, Arn: string, ChannelName: string, ClipRange: record<EndOffsetMillis: int>, CreationTime: string, DurationMillis: int, LiveSourceName: string, ProgramName: string, ScheduledStartTime: string, SourceLocationName: string, VodSourceName: string>
# operationId: CreateProgram
export def "create-program" [
  channel_name: string
  program_name: string
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
  --ad-breaks: list # The ad break configuration settings. — item shape: {MessageType?: "SPLICE_INSERT"|"TIME_SIGNAL", OffsetMillis?: int, Slate?: record, SpliceInsertMessage?: record, TimeSignalMessage?: record}
  --live-source-name: string # The name of the LiveSource for this Program.
  schedule_configuration: record # Schedule configuration parameters. A channel must be stopped before changes can be made to the schedule. — shape: {ClipRange?: record, Transition?: record}
  source_location_name: string # The name of the source location.
  --vod-source-name: string # The name that's used to refer to a VOD source.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channel/{ChannelName}/program/{ProgramName}"
    path_params: [{name: ChannelName, var: channel_name}, {name: ProgramName, var: program_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AdBreaks, var: ad_breaks}, {name: LiveSourceName, var: live_source_name}, {name: ScheduleConfiguration, var: schedule_configuration}, {name: SourceLocationName, var: source_location_name}, {name: VodSourceName, var: vod_source_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, program_name: $program_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, ad_breaks: $ad_breaks, live_source_name: $live_source_name, schedule_configuration: $schedule_configuration, source_location_name: $source_location_name, vod_source_name: $vod_source_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a program within a channel. For information about programs, see Working with programs (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-programs.html) in the MediaTailor User Guide.
#
# DELETE /channel/{ChannelName}/program/{ProgramName}
# Returns: record
# operationId: DeleteProgram
export def "delete-program" [
  channel_name: string
  program_name: string
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
    path: "/channel/{ChannelName}/program/{ProgramName}"
    path_params: [{name: ChannelName, var: channel_name}, {name: ProgramName, var: program_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, program_name: $program_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a program within a channel. For information about programs, see Working with programs (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-programs.html) in the MediaTailor User Guide.
#
# GET /channel/{ChannelName}/program/{ProgramName}
# Returns: record<AdBreaks: table<MessageType: string, OffsetMillis: int, Slate: record, SpliceInsertMessage: record, TimeSignalMessage: record>, Arn: string, ChannelName: string, ClipRange: record<EndOffsetMillis: int>, CreationTime: string, DurationMillis: int, LiveSourceName: string, ProgramName: string, ScheduledStartTime: string, SourceLocationName: string, VodSourceName: string>
# operationId: DescribeProgram
export def "describe-program" [
  channel_name: string
  program_name: string
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
    path: "/channel/{ChannelName}/program/{ProgramName}"
    path_params: [{name: ChannelName, var: channel_name}, {name: ProgramName, var: program_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, program_name: $program_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a program within a channel.
#
# PUT /channel/{ChannelName}/program/{ProgramName}
# Returns: record<AdBreaks: table<MessageType: string, OffsetMillis: int, Slate: record, SpliceInsertMessage: record, TimeSignalMessage: record>, Arn: string, ChannelName: string, ClipRange: record<EndOffsetMillis: int>, CreationTime: string, DurationMillis: int, LiveSourceName: string, ProgramName: string, ScheduledStartTime: string, SourceLocationName: string, VodSourceName: string>
# operationId: UpdateProgram
export def "update-program" [
  channel_name: string
  program_name: string
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
  --ad-breaks: list # The ad break configuration settings. — item shape: {MessageType?: "SPLICE_INSERT"|"TIME_SIGNAL", OffsetMillis?: int, Slate?: record, SpliceInsertMessage?: record, TimeSignalMessage?: record}
  schedule_configuration: record # Schedule configuration parameters. — shape: {ClipRange?: record, Transition?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/channel/{ChannelName}/program/{ProgramName}"
    path_params: [{name: ChannelName, var: channel_name}, {name: ProgramName, var: program_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AdBreaks, var: ad_breaks}, {name: ScheduleConfiguration, var: schedule_configuration}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, program_name: $program_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, ad_breaks: $ad_breaks, schedule_configuration: $schedule_configuration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a source location. A source location is a container for sources. For more information about source locations, see Working with source locations (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-source-locations.html) in the MediaTailor User Guide.
#
# POST /sourceLocation/{SourceLocationName}
# Returns: record<AccessConfiguration: record<AccessType: string, SecretsManagerAccessTokenConfiguration: record<HeaderName: string, SecretArn: string, SecretStringKey: string>>, Arn: string, CreationTime: string, DefaultSegmentDeliveryConfiguration: record<BaseUrl: string>, HttpConfiguration: record<BaseUrl: string>, LastModifiedTime: string, SegmentDeliveryConfigurations: table<BaseUrl: string, Name: string>, SourceLocationName: string, Tags: record>
# operationId: CreateSourceLocation
export def "create-source-location" [
  source_location_name: string
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
  --access-configuration: record # Access configuration parameters. — shape: {AccessType?: "S3_SIGV4"|"SECRETS_MANAGER_ACCESS_TOKEN", SecretsManagerAccessTokenConfiguration?: record}
  --default-segment-delivery-configuration: record # The optional configuration for a server that serves segments. Use this if you want the segment delivery server to be different from the source location server. For example, you can configure your source location server to be an origination server, such as MediaPackage, and the segment delivery server to be a content delivery network (CDN), such as CloudFront. If you don't specify a segment delivery server, then the source location server is used. — shape: {BaseUrl?: string}
  http_configuration: record # The HTTP configuration for the source location. — shape: {BaseUrl?: string}
  --segment-delivery-configurations: list # A list of the segment delivery configurations associated with this resource. — item shape: {BaseUrl?: string, Name?: string}
  --tags: record # The tags to assign to the source location. Tags are key-value pairs that you can associate with Amazon resources to help with organization, access control, and cost tracking. For more information, see Tagging AWS Elemental MediaTailor Resources (https://docs.aws.amazon.com/mediatailor/latest/ug/tagging.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sourceLocation/{SourceLocationName}"
    path_params: [{name: SourceLocationName, var: source_location_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccessConfiguration, var: access_configuration}, {name: DefaultSegmentDeliveryConfiguration, var: default_segment_delivery_configuration}, {name: HttpConfiguration, var: http_configuration}, {name: SegmentDeliveryConfigurations, var: segment_delivery_configurations}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, access_configuration: $access_configuration, default_segment_delivery_configuration: $default_segment_delivery_configuration, http_configuration: $http_configuration, segment_delivery_configurations: $segment_delivery_configurations, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a source location. A source location is a container for sources. For more information about source locations, see Working with source locations (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-source-locations.html) in the MediaTailor User Guide.
#
# DELETE /sourceLocation/{SourceLocationName}
# Returns: record
# operationId: DeleteSourceLocation
export def "delete-source-location" [
  source_location_name: string
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
    path: "/sourceLocation/{SourceLocationName}"
    path_params: [{name: SourceLocationName, var: source_location_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Describes a source location. A source location is a container for sources. For more information about source locations, see Working with source locations (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-source-locations.html) in the MediaTailor User Guide.
#
# GET /sourceLocation/{SourceLocationName}
# Returns: record<AccessConfiguration: record<AccessType: string, SecretsManagerAccessTokenConfiguration: record<HeaderName: string, SecretArn: string, SecretStringKey: string>>, Arn: string, CreationTime: string, DefaultSegmentDeliveryConfiguration: record<BaseUrl: string>, HttpConfiguration: record<BaseUrl: string>, LastModifiedTime: string, SegmentDeliveryConfigurations: table<BaseUrl: string, Name: string>, SourceLocationName: string, Tags: record>
# operationId: DescribeSourceLocation
export def "describe-source-location" [
  source_location_name: string
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
    path: "/sourceLocation/{SourceLocationName}"
    path_params: [{name: SourceLocationName, var: source_location_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a source location. A source location is a container for sources. For more information about source locations, see Working with source locations (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-source-locations.html) in the MediaTailor User Guide.
#
# PUT /sourceLocation/{SourceLocationName}
# Returns: record<AccessConfiguration: record<AccessType: string, SecretsManagerAccessTokenConfiguration: record<HeaderName: string, SecretArn: string, SecretStringKey: string>>, Arn: string, CreationTime: string, DefaultSegmentDeliveryConfiguration: record<BaseUrl: string>, HttpConfiguration: record<BaseUrl: string>, LastModifiedTime: string, SegmentDeliveryConfigurations: table<BaseUrl: string, Name: string>, SourceLocationName: string, Tags: record>
# operationId: UpdateSourceLocation
export def "update-source-location" [
  source_location_name: string
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
  --access-configuration: record # Access configuration parameters. — shape: {AccessType?: "S3_SIGV4"|"SECRETS_MANAGER_ACCESS_TOKEN", SecretsManagerAccessTokenConfiguration?: record}
  --default-segment-delivery-configuration: record # The optional configuration for a server that serves segments. Use this if you want the segment delivery server to be different from the source location server. For example, you can configure your source location server to be an origination server, such as MediaPackage, and the segment delivery server to be a content delivery network (CDN), such as CloudFront. If you don't specify a segment delivery server, then the source location server is used. — shape: {BaseUrl?: string}
  http_configuration: record # The HTTP configuration for the source location. — shape: {BaseUrl?: string}
  --segment-delivery-configurations: list # A list of the segment delivery configurations associated with this resource. — item shape: {BaseUrl?: string, Name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sourceLocation/{SourceLocationName}"
    path_params: [{name: SourceLocationName, var: source_location_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AccessConfiguration, var: access_configuration}, {name: DefaultSegmentDeliveryConfiguration, var: default_segment_delivery_configuration}, {name: HttpConfiguration, var: http_configuration}, {name: SegmentDeliveryConfigurations, var: segment_delivery_configurations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, access_configuration: $access_configuration, default_segment_delivery_configuration: $default_segment_delivery_configuration, http_configuration: $http_configuration, segment_delivery_configurations: $segment_delivery_configurations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The VOD source configuration parameters.
#
# POST /sourceLocation/{SourceLocationName}/vodSource/{VodSourceName}
# Returns: record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, SourceLocationName: string, Tags: record, VodSourceName: string>
# operationId: CreateVodSource
export def "create-vod-source" [
  source_location_name: string
  vod_source_name: string
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
  http_package_configurations: list # The VOD source's HTTP package configuration settings. — item shape: {Path: string, SourceGroup: string, Type: "DASH"|"HLS"}
  --tags: record # The tags to assign to the VOD source. Tags are key-value pairs that you can associate with Amazon resources to help with organization, access control, and cost tracking. For more information, see Tagging AWS Elemental MediaTailor Resources (https://docs.aws.amazon.com/mediatailor/latest/ug/tagging.html).
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sourceLocation/{SourceLocationName}/vodSource/{VodSourceName}"
    path_params: [{name: SourceLocationName, var: source_location_name}, {name: VodSourceName, var: vod_source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: HttpPackageConfigurations, var: http_package_configurations}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, vod_source_name: $vod_source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, http_package_configurations: $http_package_configurations, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The video on demand (VOD) source to delete.
#
# DELETE /sourceLocation/{SourceLocationName}/vodSource/{VodSourceName}
# Returns: record
# operationId: DeleteVodSource
export def "delete-vod-source" [
  source_location_name: string
  vod_source_name: string
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
    path: "/sourceLocation/{SourceLocationName}/vodSource/{VodSourceName}"
    path_params: [{name: SourceLocationName, var: source_location_name}, {name: VodSourceName, var: vod_source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, vod_source_name: $vod_source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides details about a specific video on demand (VOD) source in a specific source location.
#
# GET /sourceLocation/{SourceLocationName}/vodSource/{VodSourceName}
# Returns: record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, SourceLocationName: string, Tags: record, VodSourceName: string>
# operationId: DescribeVodSource
export def "describe-vod-source" [
  source_location_name: string
  vod_source_name: string
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
    path: "/sourceLocation/{SourceLocationName}/vodSource/{VodSourceName}"
    path_params: [{name: SourceLocationName, var: source_location_name}, {name: VodSourceName, var: vod_source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, vod_source_name: $vod_source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a VOD source's configuration.
#
# PUT /sourceLocation/{SourceLocationName}/vodSource/{VodSourceName}
# Returns: record<Arn: string, CreationTime: string, HttpPackageConfigurations: table<Path: string, SourceGroup: string, Type: string>, LastModifiedTime: string, SourceLocationName: string, Tags: record, VodSourceName: string>
# operationId: UpdateVodSource
export def "update-vod-source" [
  source_location_name: string
  vod_source_name: string
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
  http_package_configurations: list # The VOD source's HTTP package configuration settings. — item shape: {Path: string, SourceGroup: string, Type: "DASH"|"HLS"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sourceLocation/{SourceLocationName}/vodSource/{VodSourceName}"
    path_params: [{name: SourceLocationName, var: source_location_name}, {name: VodSourceName, var: vod_source_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: HttpPackageConfigurations, var: http_package_configurations}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, vod_source_name: $vod_source_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, http_package_configurations: $http_package_configurations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The channel policy to delete.
#
# DELETE /channel/{ChannelName}/policy
# Returns: record
# operationId: DeleteChannelPolicy
export def "delete-channel-policy" [
  channel_name: string
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
    path: "/channel/{ChannelName}/policy"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the channel's IAM policy. IAM policies are used to control access to your channel.
#
# GET /channel/{ChannelName}/policy
# Returns: record<Policy: string>
# operationId: GetChannelPolicy
export def "get-channel-policy" [
  channel_name: string
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
    path: "/channel/{ChannelName}/policy"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates an IAM policy for the channel. IAM policies are used to control access to your channel.
#
# PUT /channel/{ChannelName}/policy
# Returns: record
# operationId: PutChannelPolicy
export def "put-channel-policy" [
  channel_name: string
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
  policy: string # Adds an IAM role that determines the permissions of your channel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/channel/{ChannelName}/policy"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: Policy, var: policy}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, policy: $policy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a playback configuration. For information about MediaTailor configurations, see Working with configurations in AWS Elemental MediaTailor (https://docs.aws.amazon.com/mediatailor/latest/ug/configurations.html).
#
# DELETE /playbackConfiguration/{Name}
# Returns: record
# operationId: DeletePlaybackConfiguration
export def "delete-playback-configuration" [
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
    path: "/playbackConfiguration/{Name}"
    path_params: [{name: Name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a playback configuration. For information about MediaTailor configurations, see Working with configurations in AWS Elemental MediaTailor (https://docs.aws.amazon.com/mediatailor/latest/ug/configurations.html).
#
# GET /playbackConfiguration/{Name}
# Returns: record<AdDecisionServerUrl: string, AvailSuppression: record<Mode: string, Value: string>, Bumper: record<EndUrl: string, StartUrl: string>, CdnConfiguration: record<AdSegmentUrlPrefix: string, ContentSegmentUrlPrefix: string>, ConfigurationAliases: record, DashConfiguration: record<ManifestEndpointPrefix: string, MpdLocation: string, OriginManifestType: string>, HlsConfiguration: record<ManifestEndpointPrefix: string>, LivePreRollConfiguration: record<AdDecisionServerUrl: string, MaxDurationSeconds: int>, LogConfiguration: record<PercentEnabled: int>, ManifestProcessingRules: record<AdMarkerPassthrough: record<Enabled: bool>>, Name: string, PersonalizationThresholdSeconds: int, PlaybackConfigurationArn: string, PlaybackEndpointPrefix: string, SessionInitializationEndpointPrefix: string, SlateAdUrl: string, Tags: record, TranscodeProfileName: string, VideoContentSourceUrl: string>
# operationId: GetPlaybackConfiguration
export def "get-playback-configuration" [
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
    path: "/playbackConfiguration/{Name}"
    path_params: [{name: Name, var: name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about your channel's schedule.
#
# GET /channel/{ChannelName}/schedule
# Returns: record<Items: table<ApproximateDurationSeconds: int, ApproximateStartTime: string, Arn: string, ChannelName: string, LiveSourceName: string, ProgramName: string, ScheduleAdBreaks: list, ScheduleEntryType: string, SourceLocationName: string, VodSourceName: string>, NextToken: string>
# operationId: GetChannelSchedule
export def "get-channel-schedule" [
  channel_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --duration-minutes: string # The duration in minutes of the channel schedule.
  --max-results: int # The maximum number of channel schedules that you want MediaTailor to return in response to the current request. If there are more than MaxResults channel schedules, use the value of NextToken in the response to get the next page of results.
  --next-token: string # (Optional) If the playback configuration has more than MaxResults channel schedules, use NextToken to get the second and subsequent pages of results. For the first GetChannelScheduleRequest request, omit this value. For the second and subsequent requests, get the value of NextToken from the previous response and specify that value for NextToken in the request. If the previous response didn't include a NextToken element, there are no more channel schedules to get.
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
    path: "/channel/{ChannelName}/schedule"
    path_params: [{name: ChannelName, var: channel_name}]
    query: [{name: durationMinutes, var: duration_minutes}, {name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, duration_minutes: $duration_minutes, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the alerts that are associated with a MediaTailor channel assembly resource.
#
# GET /alerts
# Returns: record<Items: table<AlertCode: string, AlertMessage: string, LastModifiedTime: string, RelatedResourceArns: list, ResourceArn: string>, NextToken: string>
# operationId: ListAlerts
export def "list-alerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of alerts that you want MediaTailor to return in response to the current request. If there are more than MaxResults alerts, use the value of NextToken in the response to get the next page of results.
  --next-token: string # Pagination token returned by the list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
  --resource-arn: string # The Amazon Resource Name (ARN) of the resource. (required)
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
    path: "/alerts"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: resourceArn, var: resource_arn, required: true}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, resource_arn: $resource_arn, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves information about the channels that are associated with the current AWS account.
#
# GET /channels
# Returns: record<Items: table<Arn: string, ChannelName: string, ChannelState: string, CreationTime: string, FillerSlate: record, LastModifiedTime: string, LogConfiguration: record, Outputs: list, PlaybackMode: string, Tags: record, Tier: string>, NextToken: string>
# operationId: ListChannels
export def "list-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of channels that you want MediaTailor to return in response to the current request. If there are more than MaxResults channels, use the value of NextToken in the response to get the next page of results.
  --next-token: string # Pagination token returned by the list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
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
    path: "/channels"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the live sources contained in a source location. A source represents a piece of content.
#
# GET /sourceLocation/{SourceLocationName}/liveSources
# Returns: record<Items: table<Arn: string, CreationTime: string, HttpPackageConfigurations: list, LastModifiedTime: string, LiveSourceName: string, SourceLocationName: string, Tags: record>, NextToken: string>
# operationId: ListLiveSources
export def "list-live-sources" [
  source_location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of live sources that you want MediaTailor to return in response to the current request. If there are more than MaxResults live sources, use the value of NextToken in the response to get the next page of results.
  --next-token: string # Pagination token returned by the list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
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
    path: "/sourceLocation/{SourceLocationName}/liveSources"
    path_params: [{name: SourceLocationName, var: source_location_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves existing playback configurations. For information about MediaTailor configurations, see Working with Configurations in AWS Elemental MediaTailor (https://docs.aws.amazon.com/mediatailor/latest/ug/configurations.html).
#
# GET /playbackConfigurations
# Returns: record<Items: table<AdDecisionServerUrl: string, AvailSuppression: record, Bumper: record, CdnConfiguration: record, ConfigurationAliases: record, DashConfiguration: record, HlsConfiguration: record, LivePreRollConfiguration: record, LogConfiguration: record, ManifestProcessingRules: record, Name: string, PersonalizationThresholdSeconds: int, PlaybackConfigurationArn: string, PlaybackEndpointPrefix: string, SessionInitializationEndpointPrefix: string, SlateAdUrl: string, Tags: record, TranscodeProfileName: string, VideoContentSourceUrl: string>, NextToken: string>
# operationId: ListPlaybackConfigurations
export def "list-playback-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of playback configurations that you want MediaTailor to return in response to the current request. If there are more than MaxResults playback configurations, use the value of NextToken in the response to get the next page of results.
  --next-token: string # Pagination token returned by the list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
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
    path: "/playbackConfigurations"
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the prefetch schedules for a playback configuration.
#
# POST /prefetchSchedule/{PlaybackConfigurationName}
# Returns: record<Items: table<Arn: string, Consumption: record, Name: string, PlaybackConfigurationName: string, Retrieval: record, StreamId: string>, NextToken: string>
# operationId: ListPrefetchSchedules
export def "list-prefetch-schedules" [
  playback_configuration_name: string
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
  --body-max-results: int # The maximum number of prefetch schedules that you want MediaTailor to return in response to the current request. If there are more than MaxResults prefetch schedules, use the value of NextToken in the response to get the next page of results. (spec name: MaxResults)
  --body-next-token: string # (Optional) If the playback configuration has more than MaxResults prefetch schedules, use NextToken to get the second and subsequent pages of results. For the first ListPrefetchSchedulesRequest request, omit this value. For the second and subsequent requests, get the value of NextToken from the previous response and specify that value for NextToken in the request. If the previous response didn't include a NextToken element, there are no more prefetch schedules to get. (spec name: NextToken)
  --stream-id: string # An optional filtering parameter whereby MediaTailor filters the prefetch schedules to include only specific streams.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/prefetchSchedule/{PlaybackConfigurationName}"
    path_params: [{name: PlaybackConfigurationName, var: playback_configuration_name}]
    query: [{name: MaxResults, var: max_results}, {name: NextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: MaxResults, var: body_max_results}, {name: NextToken, var: body_next_token}, {name: StreamId, var: stream_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    playback_configuration_name: $playback_configuration_name, max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token, stream_id: $stream_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the source locations for a channel. A source location defines the host server URL, and contains a list of sources.
#
# GET /sourceLocations
# Returns: record<Items: table<AccessConfiguration: record, Arn: string, CreationTime: string, DefaultSegmentDeliveryConfiguration: record, HttpConfiguration: record, LastModifiedTime: string, SegmentDeliveryConfigurations: list, SourceLocationName: string, Tags: record>, NextToken: string>
# operationId: ListSourceLocations
export def "list-source-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of source locations that you want MediaTailor to return in response to the current request. If there are more than MaxResults source locations, use the value of NextToken in the response to get the next page of results.
  --next-token: string # Pagination token returned by the list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
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
    path: "/sourceLocations"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A list of tags that are associated with this resource. Tags are key-value pairs that you can associate with Amazon resources to help with organization, access control, and cost tracking. For more information, see Tagging AWS Elemental MediaTailor Resources (https://docs.aws.amazon.com/mediatailor/latest/ug/tagging.html).
#
# GET /tags/{ResourceArn}
# Returns: record<Tags: record>
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
    path: "/tags/{ResourceArn}"
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

# The resource to tag. Tags are key-value pairs that you can associate with Amazon resources to help with organization, access control, and cost tracking. For more information, see Tagging AWS Elemental MediaTailor Resources (https://docs.aws.amazon.com/mediatailor/latest/ug/tagging.html).
#
# POST /tags/{ResourceArn}
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
  tags: record # The tags to assign to the resource. Tags are key-value pairs that you can associate with Amazon resources to help with organization, access control, and cost tracking. For more information, see Tagging AWS Elemental MediaTailor Resources (https://docs.aws.amazon.com/mediatailor/latest/ug/tagging.html).
]: any -> any {
  $in | http-request {
    method: post
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists the VOD sources contained in a source location. A source represents a piece of content.
#
# GET /sourceLocation/{SourceLocationName}/vodSources
# Returns: record<Items: table<Arn: string, CreationTime: string, HttpPackageConfigurations: list, LastModifiedTime: string, SourceLocationName: string, Tags: record, VodSourceName: string>, NextToken: string>
# operationId: ListVodSources
export def "list-vod-sources" [
  source_location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # The maximum number of VOD sources that you want MediaTailor to return in response to the current request. If there are more than MaxResults VOD sources, use the value of NextToken in the response to get the next page of results.
  --next-token: string # Pagination token returned by the list request when results exceed the maximum allowed. Use the token to fetch the next page of results.
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
    path: "/sourceLocation/{SourceLocationName}/vodSources"
    path_params: [{name: SourceLocationName, var: source_location_name}]
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}, {name: MaxResults, var: qp_max_results}, {name: NextToken, var: qp_next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    source_location_name: $source_location_name, max_results: $max_results, next_token: $next_token, qp_max_results: $qp_max_results, qp_next_token: $qp_next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a playback configuration. For information about MediaTailor configurations, see Working with configurations in AWS Elemental MediaTailor (https://docs.aws.amazon.com/mediatailor/latest/ug/configurations.html).
#
# PUT /playbackConfiguration
# Returns: record<AdDecisionServerUrl: string, AvailSuppression: record<Mode: string, Value: string>, Bumper: record<EndUrl: string, StartUrl: string>, CdnConfiguration: record<AdSegmentUrlPrefix: string, ContentSegmentUrlPrefix: string>, ConfigurationAliases: record, DashConfiguration: record<ManifestEndpointPrefix: string, MpdLocation: string, OriginManifestType: string>, HlsConfiguration: record<ManifestEndpointPrefix: string>, LivePreRollConfiguration: record<AdDecisionServerUrl: string, MaxDurationSeconds: int>, LogConfiguration: record<PercentEnabled: int>, ManifestProcessingRules: record<AdMarkerPassthrough: record<Enabled: bool>>, Name: string, PersonalizationThresholdSeconds: int, PlaybackConfigurationArn: string, PlaybackEndpointPrefix: string, SessionInitializationEndpointPrefix: string, SlateAdUrl: string, Tags: record, TranscodeProfileName: string, VideoContentSourceUrl: string>
# operationId: PutPlaybackConfiguration
export def "put-playback-configuration" [
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
  --ad-decision-server-url: string # The URL for the ad decision server (ADS). This includes the specification of static parameters and placeholders for dynamic parameters. AWS Elemental MediaTailor substitutes player-specific and session-specific parameters as needed when calling the ADS. Alternately, for testing you can provide a static VAST URL. The maximum length is 25,000 characters.
  --avail-suppression: record # The configuration for avail suppression, also known as ad suppression. For more information about ad suppression, see Ad Suppression (https://docs.aws.amazon.com/mediatailor/latest/ug/ad-behavior.html). — shape: {Mode?: "OFF"|"BEHIND_LIVE_EDGE", Value?: string}
  --bumper: record # The configuration for bumpers. Bumpers are short audio or video clips that play at the start or before the end of an ad break. To learn more about bumpers, see Bumpers (https://docs.aws.amazon.com/mediatailor/latest/ug/bumpers.html). — shape: {EndUrl?: string, StartUrl?: string}
  --cdn-configuration: record # The configuration for using a content delivery network (CDN), like Amazon CloudFront, for content and ad segment management. — shape: {AdSegmentUrlPrefix?: string, ContentSegmentUrlPrefix?: string}
  --configuration-aliases: record # The predefined aliases for dynamic variables.
  --dash-configuration: record # The configuration for DASH PUT operations. — shape: {MpdLocation?: string, OriginManifestType?: "SINGLE_PERIOD"|"MULTI_PERIOD"}
  --live-pre-roll-configuration: record # The configuration for pre-roll ad insertion. — shape: {AdDecisionServerUrl?: string, MaxDurationSeconds?: int}
  --manifest-processing-rules: record # The configuration for manifest processing rules. Manifest processing rules enable customization of the personalized manifests created by MediaTailor. — shape: {AdMarkerPassthrough?: record}
  name: string # The identifier for the playback configuration.
  --personalization-threshold-seconds: int # Defines the maximum duration of underfilled ad time (in seconds) allowed in an ad break. If the duration of underfilled ad time exceeds the personalization threshold, then the personalization of the ad break is abandoned and the underlying content is shown. This feature applies to ad replacement in live and VOD streams, rather than ad insertion, because it relies on an underlying content stream. For more information about ad break behavior, including ad replacement and insertion, see Ad Behavior in AWS Elemental MediaTailor (https://docs.aws.amazon.com/mediatailor/latest/ug/ad-behavior.html).
  --slate-ad-url: string # The URL for a high-quality video asset to transcode and use to fill in time that's not used by ads. AWS Elemental MediaTailor shows the slate to fill in gaps in media content. Configuring the slate is optional for non-VPAID configurations. For VPAID, the slate is required because MediaTailor provides it in the slots that are designated for dynamic ad content. The slate must be a high-quality asset that contains both audio and video.
  --tags: record # The tags to assign to the playback configuration. Tags are key-value pairs that you can associate with Amazon resources to help with organization, access control, and cost tracking. For more information, see Tagging AWS Elemental MediaTailor Resources (https://docs.aws.amazon.com/mediatailor/latest/ug/tagging.html).
  --transcode-profile-name: string # The name that is used to associate this playback configuration with a custom transcode profile. This overrides the dynamic transcoding defaults of MediaTailor. Use this only if you have already set up custom profiles with the help of AWS Support.
  --video-content-source-url: string # The URL prefix for the parent manifest for the stream, minus the asset ID. The maximum length is 512 characters.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/playbackConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: AdDecisionServerUrl, var: ad_decision_server_url}, {name: AvailSuppression, var: avail_suppression}, {name: Bumper, var: bumper}, {name: CdnConfiguration, var: cdn_configuration}, {name: ConfigurationAliases, var: configuration_aliases}, {name: DashConfiguration, var: dash_configuration}, {name: LivePreRollConfiguration, var: live_pre_roll_configuration}, {name: ManifestProcessingRules, var: manifest_processing_rules}, {name: Name, var: name}, {name: PersonalizationThresholdSeconds, var: personalization_threshold_seconds}, {name: SlateAdUrl, var: slate_ad_url}, {name: tags, var: tags}, {name: TranscodeProfileName, var: transcode_profile_name}, {name: VideoContentSourceUrl, var: video_content_source_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, ad_decision_server_url: $ad_decision_server_url, avail_suppression: $avail_suppression, bumper: $bumper, cdn_configuration: $cdn_configuration, configuration_aliases: $configuration_aliases, dash_configuration: $dash_configuration, live_pre_roll_configuration: $live_pre_roll_configuration, manifest_processing_rules: $manifest_processing_rules, name: $name, personalization_threshold_seconds: $personalization_threshold_seconds, slate_ad_url: $slate_ad_url, tags: $tags, transcode_profile_name: $transcode_profile_name, video_content_source_url: $video_content_source_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a channel. For information about MediaTailor channels, see Working with channels (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-channels.html) in the MediaTailor User Guide.
#
# PUT /channel/{ChannelName}/start
# Returns: record
# operationId: StartChannel
export def "start-channel" [
  channel_name: string
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
    path: "/channel/{ChannelName}/start"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Stops a channel. For information about MediaTailor channels, see Working with channels (https://docs.aws.amazon.com/mediatailor/latest/ug/channel-assembly-channels.html) in the MediaTailor User Guide.
#
# PUT /channel/{ChannelName}/stop
# Returns: record
# operationId: StopChannel
export def "stop-channel" [
  channel_name: string
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
    path: "/channel/{ChannelName}/stop"
    path_params: [{name: ChannelName, var: channel_name}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_name: $channel_name, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The resource to untag.
#
# DELETE /tags/{ResourceArn}
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
  --tag-keys: list<string> # The tag keys associated with the resource. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/tags/{ResourceArn}"
    path_params: [{name: ResourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
