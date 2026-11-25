# Auto-generated client for AWS Proton v2020-07-20
# Source: https://api.apis.guru/v2/specs/amazonaws.com/proton/2020-07-20/openapi.json
# Auth: --token flag or $env.AWS_PROTON_TOKEN

const CLIENT = {
  base_url: "http://proton.us-east-1.amazonaws.com"
  token_env_var: "AWS_PROTON_TOKEN"
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

def base-url-completer [] { ["http://proton.us-east-1.amazonaws.com" "http://proton.us-east-2.amazonaws.com" "http://proton.us-west-1.amazonaws.com" "http://proton.us-west-2.amazonaws.com" "http://proton.us-gov-west-1.amazonaws.com" "http://proton.us-gov-east-1.amazonaws.com" "http://proton.ca-central-1.amazonaws.com" "http://proton.eu-north-1.amazonaws.com" "http://proton.eu-west-1.amazonaws.com" "http://proton.eu-west-2.amazonaws.com" "http://proton.eu-west-3.amazonaws.com" "http://proton.eu-central-1.amazonaws.com" "http://proton.eu-south-1.amazonaws.com" "http://proton.af-south-1.amazonaws.com" "http://proton.ap-northeast-1.amazonaws.com" "http://proton.ap-northeast-2.amazonaws.com" "http://proton.ap-northeast-3.amazonaws.com" "http://proton.ap-southeast-1.amazonaws.com" "http://proton.ap-southeast-2.amazonaws.com" "http://proton.ap-east-1.amazonaws.com" "http://proton.ap-south-1.amazonaws.com" "http://proton.sa-east-1.amazonaws.com" "http://proton.me-south-1.amazonaws.com" "https://proton.us-east-1.amazonaws.com" "https://proton.us-east-2.amazonaws.com" "https://proton.us-west-1.amazonaws.com" "https://proton.us-west-2.amazonaws.com" "https://proton.us-gov-west-1.amazonaws.com" "https://proton.us-gov-east-1.amazonaws.com" "https://proton.ca-central-1.amazonaws.com" "https://proton.eu-north-1.amazonaws.com" "https://proton.eu-west-1.amazonaws.com" "https://proton.eu-west-2.amazonaws.com" "https://proton.eu-west-3.amazonaws.com" "https://proton.eu-central-1.amazonaws.com" "https://proton.eu-south-1.amazonaws.com" "https://proton.af-south-1.amazonaws.com" "https://proton.ap-northeast-1.amazonaws.com" "https://proton.ap-northeast-2.amazonaws.com" "https://proton.ap-northeast-3.amazonaws.com" "https://proton.ap-southeast-1.amazonaws.com" "https://proton.ap-southeast-2.amazonaws.com" "https://proton.ap-east-1.amazonaws.com" "https://proton.ap-south-1.amazonaws.com" "https://proton.sa-east-1.amazonaws.com" "https://proton.me-south-1.amazonaws.com" "http://proton.cn-north-1.amazonaws.com.cn" "http://proton.cn-northwest-1.amazonaws.com.cn" "https://proton.cn-north-1.amazonaws.com.cn" "https://proton.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AwsProton20200720.AcceptEnvironmentAccountConnection"] }
def x-amz-target-completer-1 [] { ["AwsProton20200720.CancelComponentDeployment"] }
def x-amz-target-completer-2 [] { ["AwsProton20200720.CancelEnvironmentDeployment"] }
def x-amz-target-completer-3 [] { ["AwsProton20200720.CancelServiceInstanceDeployment"] }
def x-amz-target-completer-4 [] { ["AwsProton20200720.CancelServicePipelineDeployment"] }
def x-amz-target-completer-5 [] { ["AwsProton20200720.CreateComponent"] }
def x-amz-target-completer-6 [] { ["AwsProton20200720.CreateEnvironment"] }
def x-amz-target-completer-7 [] { ["AwsProton20200720.CreateEnvironmentAccountConnection"] }
def provisioning-completer [] { ["CUSTOMER_MANAGED"] }
def x-amz-target-completer-8 [] { ["AwsProton20200720.CreateEnvironmentTemplate"] }
def x-amz-target-completer-9 [] { ["AwsProton20200720.CreateEnvironmentTemplateVersion"] }
def provider-completer [] { ["BITBUCKET" "GITHUB" "GITHUB_ENTERPRISE"] }
def x-amz-target-completer-10 [] { ["AwsProton20200720.CreateRepository"] }
def x-amz-target-completer-11 [] { ["AwsProton20200720.CreateService"] }
def x-amz-target-completer-12 [] { ["AwsProton20200720.CreateServiceInstance"] }
def repository-provider-completer [] { ["BITBUCKET" "GITHUB" "GITHUB_ENTERPRISE"] }
def x-amz-target-completer-13 [] { ["AwsProton20200720.CreateServiceSyncConfig"] }
def pipeline-provisioning-completer [] { ["CUSTOMER_MANAGED"] }
def x-amz-target-completer-14 [] { ["AwsProton20200720.CreateServiceTemplate"] }
def x-amz-target-completer-15 [] { ["AwsProton20200720.CreateServiceTemplateVersion"] }
def template-type-completer [] { ["ENVIRONMENT" "SERVICE"] }
def x-amz-target-completer-16 [] { ["AwsProton20200720.CreateTemplateSyncConfig"] }
def x-amz-target-completer-17 [] { ["AwsProton20200720.DeleteComponent"] }
def x-amz-target-completer-18 [] { ["AwsProton20200720.DeleteEnvironment"] }
def x-amz-target-completer-19 [] { ["AwsProton20200720.DeleteEnvironmentAccountConnection"] }
def x-amz-target-completer-20 [] { ["AwsProton20200720.DeleteEnvironmentTemplate"] }
def x-amz-target-completer-21 [] { ["AwsProton20200720.DeleteEnvironmentTemplateVersion"] }
def x-amz-target-completer-22 [] { ["AwsProton20200720.DeleteRepository"] }
def x-amz-target-completer-23 [] { ["AwsProton20200720.DeleteService"] }
def x-amz-target-completer-24 [] { ["AwsProton20200720.DeleteServiceSyncConfig"] }
def x-amz-target-completer-25 [] { ["AwsProton20200720.DeleteServiceTemplate"] }
def x-amz-target-completer-26 [] { ["AwsProton20200720.DeleteServiceTemplateVersion"] }
def x-amz-target-completer-27 [] { ["AwsProton20200720.DeleteTemplateSyncConfig"] }
def x-amz-target-completer-28 [] { ["AwsProton20200720.GetAccountSettings"] }
def x-amz-target-completer-29 [] { ["AwsProton20200720.GetComponent"] }
def x-amz-target-completer-30 [] { ["AwsProton20200720.GetEnvironment"] }
def x-amz-target-completer-31 [] { ["AwsProton20200720.GetEnvironmentAccountConnection"] }
def x-amz-target-completer-32 [] { ["AwsProton20200720.GetEnvironmentTemplate"] }
def x-amz-target-completer-33 [] { ["AwsProton20200720.GetEnvironmentTemplateVersion"] }
def x-amz-target-completer-34 [] { ["AwsProton20200720.GetRepository"] }
def sync-type-completer [] { ["SERVICE_SYNC" "TEMPLATE_SYNC"] }
def x-amz-target-completer-35 [] { ["AwsProton20200720.GetRepositorySyncStatus"] }
def x-amz-target-completer-36 [] { ["AwsProton20200720.GetResourcesSummary"] }
def x-amz-target-completer-37 [] { ["AwsProton20200720.GetService"] }
def x-amz-target-completer-38 [] { ["AwsProton20200720.GetServiceInstance"] }
def x-amz-target-completer-39 [] { ["AwsProton20200720.GetServiceInstanceSyncStatus"] }
def x-amz-target-completer-40 [] { ["AwsProton20200720.GetServiceSyncBlockerSummary"] }
def x-amz-target-completer-41 [] { ["AwsProton20200720.GetServiceSyncConfig"] }
def x-amz-target-completer-42 [] { ["AwsProton20200720.GetServiceTemplate"] }
def x-amz-target-completer-43 [] { ["AwsProton20200720.GetServiceTemplateVersion"] }
def x-amz-target-completer-44 [] { ["AwsProton20200720.GetTemplateSyncConfig"] }
def x-amz-target-completer-45 [] { ["AwsProton20200720.GetTemplateSyncStatus"] }
def x-amz-target-completer-46 [] { ["AwsProton20200720.ListComponentOutputs"] }
def x-amz-target-completer-47 [] { ["AwsProton20200720.ListComponentProvisionedResources"] }
def x-amz-target-completer-48 [] { ["AwsProton20200720.ListComponents"] }
def requested-by-completer [] { ["ENVIRONMENT_ACCOUNT" "MANAGEMENT_ACCOUNT"] }
def x-amz-target-completer-49 [] { ["AwsProton20200720.ListEnvironmentAccountConnections"] }
def x-amz-target-completer-50 [] { ["AwsProton20200720.ListEnvironmentOutputs"] }
def x-amz-target-completer-51 [] { ["AwsProton20200720.ListEnvironmentProvisionedResources"] }
def x-amz-target-completer-52 [] { ["AwsProton20200720.ListEnvironmentTemplateVersions"] }
def x-amz-target-completer-53 [] { ["AwsProton20200720.ListEnvironmentTemplates"] }
def x-amz-target-completer-54 [] { ["AwsProton20200720.ListEnvironments"] }
def x-amz-target-completer-55 [] { ["AwsProton20200720.ListRepositories"] }
def x-amz-target-completer-56 [] { ["AwsProton20200720.ListRepositorySyncDefinitions"] }
def x-amz-target-completer-57 [] { ["AwsProton20200720.ListServiceInstanceOutputs"] }
def x-amz-target-completer-58 [] { ["AwsProton20200720.ListServiceInstanceProvisionedResources"] }
def sort-by-completer [] { ["createdAt" "deploymentStatus" "environmentName" "lastDeploymentAttemptedAt" "name" "serviceName" "templateName"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def x-amz-target-completer-59 [] { ["AwsProton20200720.ListServiceInstances"] }
def x-amz-target-completer-60 [] { ["AwsProton20200720.ListServicePipelineOutputs"] }
def x-amz-target-completer-61 [] { ["AwsProton20200720.ListServicePipelineProvisionedResources"] }
def x-amz-target-completer-62 [] { ["AwsProton20200720.ListServiceTemplateVersions"] }
def x-amz-target-completer-63 [] { ["AwsProton20200720.ListServiceTemplates"] }
def x-amz-target-completer-64 [] { ["AwsProton20200720.ListServices"] }
def x-amz-target-completer-65 [] { ["AwsProton20200720.ListTagsForResource"] }
def status-completer [] { ["FAILED" "IN_PROGRESS" "SUCCEEDED"] }
def x-amz-target-completer-66 [] { ["AwsProton20200720.NotifyResourceDeploymentStatusChange"] }
def x-amz-target-completer-67 [] { ["AwsProton20200720.RejectEnvironmentAccountConnection"] }
def x-amz-target-completer-68 [] { ["AwsProton20200720.TagResource"] }
def x-amz-target-completer-69 [] { ["AwsProton20200720.UntagResource"] }
def x-amz-target-completer-70 [] { ["AwsProton20200720.UpdateAccountSettings"] }
def deployment-type-completer [] { ["CURRENT_VERSION" "NONE"] }
def x-amz-target-completer-71 [] { ["AwsProton20200720.UpdateComponent"] }
def deployment-type-completer-1 [] { ["CURRENT_VERSION" "MAJOR_VERSION" "MINOR_VERSION" "NONE"] }
def x-amz-target-completer-72 [] { ["AwsProton20200720.UpdateEnvironment"] }
def x-amz-target-completer-73 [] { ["AwsProton20200720.UpdateEnvironmentAccountConnection"] }
def x-amz-target-completer-74 [] { ["AwsProton20200720.UpdateEnvironmentTemplate"] }
def status-completer-1 [] { ["DRAFT" "PUBLISHED" "REGISTRATION_FAILED" "REGISTRATION_IN_PROGRESS"] }
def x-amz-target-completer-75 [] { ["AwsProton20200720.UpdateEnvironmentTemplateVersion"] }
def x-amz-target-completer-76 [] { ["AwsProton20200720.UpdateService"] }
def x-amz-target-completer-77 [] { ["AwsProton20200720.UpdateServiceInstance"] }
def x-amz-target-completer-78 [] { ["AwsProton20200720.UpdateServicePipeline"] }
def x-amz-target-completer-79 [] { ["AwsProton20200720.UpdateServiceSyncBlocker"] }
def x-amz-target-completer-80 [] { ["AwsProton20200720.UpdateServiceSyncConfig"] }
def x-amz-target-completer-81 [] { ["AwsProton20200720.UpdateServiceTemplate"] }
def x-amz-target-completer-82 [] { ["AwsProton20200720.UpdateServiceTemplateVersion"] }
def x-amz-target-completer-83 [] { ["AwsProton20200720.UpdateTemplateSyncConfig"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    accept-environment-account-connection: "record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>"
    cancel-component-deployment: "record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>"
    cancel-environment-deployment: "record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    cancel-service-instance-deployment: "record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    cancel-service-pipeline-deployment: "record<pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    create-component: "record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>"
    create-environment: "record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    create-environment-account-connection: "record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>"
    create-environment-template: "record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>"
    create-environment-template-version: "record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>>"
    create-repository: "record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>>"
    create-service: "record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>>"
    create-service-instance: "record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    create-service-sync-config: "record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>>"
    create-service-template: "record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>"
    create-service-template-version: "record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>>"
    create-template-sync-config: "record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>>"
    delete-component: "record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>"
    delete-environment: "record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    delete-environment-account-connection: "record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>"
    delete-environment-template: "record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>"
    delete-environment-template-version: "record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>>"
    delete-repository: "record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>>"
    delete-service: "record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>>"
    delete-service-sync-config: "record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>>"
    delete-service-template: "record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>"
    delete-service-template-version: "record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>>"
    delete-template-sync-config: "record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>>"
    get-account-settings: "record<accountSettings: record<pipelineCodebuildRoleArn: string, pipelineProvisioningRepository: record<arn: string, branch: string, name: string, provider: string>, pipelineServiceRoleArn: string>>"
    get-component: "record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>"
    get-environment: "record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    get-environment-account-connection: "record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>"
    get-environment-template: "record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>"
    get-environment-template-version: "record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>>"
    get-repository: "record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>>"
    get-repository-sync-status: "record<latestSync: record<events: list<record>, startedAt: string, status: string>>"
    get-resources-summary: "record<counts: record<components: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, environmentTemplates: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, environments: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, pipelines: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, serviceInstances: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, serviceTemplates: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, services: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>>>"
    get-service: "record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>>"
    get-service-instance: "record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    get-service-instance-sync-status: "record<desiredState: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, latestSuccessfulSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>, latestSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>>"
    get-service-sync-blocker-summary: "record<serviceSyncBlockerSummary: record<latestBlockers: list<record>, serviceInstanceName: string, serviceName: string>>"
    get-service-sync-config: "record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>>"
    get-service-template: "record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>"
    get-service-template-version: "record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>>"
    get-template-sync-config: "record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>>"
    get-template-sync-status: "record<desiredState: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, latestSuccessfulSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>, latestSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>>"
    list-component-outputs: "record<nextToken: string, outputs: table<key: string, valueString: string>>"
    list-component-provisioned-resources: "record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>>"
    list-components: "record<components: table<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string>, nextToken: string>"
    list-environment-account-connections: "record<environmentAccountConnections: table<arn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>, nextToken: string>"
    list-environment-outputs: "record<nextToken: string, outputs: table<key: string, valueString: string>>"
    list-environment-provisioned-resources: "record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>>"
    list-environment-template-versions: "record<nextToken: string, templateVersions: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, status: string, statusMessage: string, templateName: string>>"
    list-environment-templates: "record<nextToken: string, templates: table<arn: string, createdAt: string, description: string, displayName: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>"
    list-environments: "record<environments: table<arn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, nextToken: string>"
    list-repositories: "record<nextToken: string, repositories: table<arn: string, connectionArn: string, name: string, provider: string>>"
    list-repository-sync-definitions: "record<nextToken: string, syncDefinitions: table<branch: string, directory: string, parent: string, target: string>>"
    list-service-instance-outputs: "record<nextToken: string, outputs: table<key: string, valueString: string>>"
    list-service-instance-provisioned-resources: "record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>>"
    list-service-instances: "record<nextToken: string, serviceInstances: table<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    list-service-pipeline-outputs: "record<nextToken: string, outputs: table<key: string, valueString: string>>"
    list-service-pipeline-provisioned-resources: "record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>>"
    list-service-template-versions: "record<nextToken: string, templateVersions: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, status: string, statusMessage: string, templateName: string>>"
    list-service-templates: "record<nextToken: string, templates: table<arn: string, createdAt: string, description: string, displayName: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>"
    list-services: "record<nextToken: string, services: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, name: string, status: string, statusMessage: string, templateName: string>>"
    list-tags-for-resource: "record<nextToken: string, tags: table<key: string, value: string>>"
    notify-resource-deployment-status-change: "record"
    reject-environment-account-connection: "record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>"
    tag-resource: "record"
    untag-resource: "record"
    update-account-settings: "record<accountSettings: record<pipelineCodebuildRoleArn: string, pipelineProvisioningRepository: record<arn: string, branch: string, name: string, provider: string>, pipelineServiceRoleArn: string>>"
    update-component: "record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>"
    update-environment: "record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    update-environment-account-connection: "record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>"
    update-environment-template: "record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>"
    update-environment-template-version: "record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>>"
    update-service: "record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>>"
    update-service-instance: "record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    update-service-pipeline: "record<pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>"
    update-service-sync-blocker: "record<serviceInstanceName: string, serviceName: string, serviceSyncBlocker: record<contexts: list<record>, createdAt: string, createdReason: string, id: string, resolvedAt: string, resolvedReason: string, status: string, type: string>>"
    update-service-sync-config: "record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>>"
    update-service-template: "record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>"
    update-service-template-version: "record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>>"
    update-template-sync-config: "record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-environment-account-connection" "cancel-component-deployment" "cancel-environment-deployment" "cancel-service-instance-deployment" "cancel-service-pipeline-deployment" "create-component" "create-environment" "create-environment-account-connection" "create-environment-template" "create-environment-template-version" "create-repository" "create-service" "create-service-instance" "create-service-sync-config" "create-service-template" "create-service-template-version" "create-template-sync-config" "delete-component" "delete-environment" "delete-environment-account-connection" "delete-environment-template" "delete-environment-template-version" "delete-repository" "delete-service" "delete-service-sync-config" "delete-service-template" "delete-service-template-version" "delete-template-sync-config" "get-account-settings" "get-component" "get-environment" "get-environment-account-connection" "get-environment-template" "get-environment-template-version" "get-repository" "get-repository-sync-status" "get-resources-summary" "get-service" "get-service-instance" "get-service-instance-sync-status" "get-service-sync-blocker-summary" "get-service-sync-config" "get-service-template" "get-service-template-version" "get-template-sync-config" "get-template-sync-status" "list-component-outputs" "list-component-provisioned-resources" "list-components" "list-environment-account-connections" "list-environment-outputs" "list-environment-provisioned-resources" "list-environment-template-versions" "list-environment-templates" "list-environments" "list-repositories" "list-repository-sync-definitions" "list-service-instance-outputs" "list-service-instance-provisioned-resources" "list-service-instances" "list-service-pipeline-outputs" "list-service-pipeline-provisioned-resources" "list-service-template-versions" "list-service-templates" "list-services" "list-tags-for-resource" "notify-resource-deployment-status-change" "reject-environment-account-connection" "tag-resource" "untag-resource" "update-account-settings" "update-component" "update-environment" "update-environment-account-connection" "update-environment-template" "update-environment-template-version" "update-service" "update-service-instance" "update-service-pipeline" "update-service-sync-blocker" "update-service-sync-config" "update-service-template" "update-service-template-version" "update-template-sync-config" "commands"] | sort) } | get name | first)
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

# In a management account, an environment account connection request is accepted. When the environment account connection request is accepted, Proton can use the associated IAM role to provision environment infrastructure resources in the associated environment account. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# Returns: record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>
# operationId: AcceptEnvironmentAccountConnection
export def "accept-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer # required
  id: string # The ID of the environment account connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.AcceptEnvironmentAccountConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to cancel a component deployment (for a component that is in the IN_PROGRESS deployment status). For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>
# operationId: CancelComponentDeployment
export def "cancel-component-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  component_name: string # The name of the component with the deployment to cancel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CancelComponentDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentName, var: component_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, component_name: $component_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to cancel an environment deployment on an UpdateEnvironment action, if the deployment is IN_PROGRESS. For more information, see Update an environment (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-update.html) in the Proton User guide. The following list includes potential cancellation scenarios. If the cancellation attempt succeeds, the resulting deployment state is CANCELLED. If the cancellation attempt fails, the resulting deployment state is FAILED. If the current UpdateEnvironment action succeeds before the cancellation attempt starts, the resulting deployment state is SUCCEEDED and the cancellation attempt has no effect.
#
# POST /
# Returns: record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: CancelEnvironmentDeployment
export def "cancel-environment-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  environment_name: string # The name of the environment with the deployment to cancel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CancelEnvironmentDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentName, var: environment_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, environment_name: $environment_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to cancel a service instance deployment on an UpdateServiceInstance action, if the deployment is IN_PROGRESS. For more information, see Update a service instance (https://docs.aws.amazon.com/proton/latest/userguide/ag-svc-instance-update.html) in the Proton User guide. The following list includes potential cancellation scenarios. If the cancellation attempt succeeds, the resulting deployment state is CANCELLED. If the cancellation attempt fails, the resulting deployment state is FAILED. If the current UpdateServiceInstance action succeeds before the cancellation attempt starts, the resulting deployment state is SUCCEEDED and the cancellation attempt has no effect.
#
# POST /
# Returns: record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: CancelServiceInstanceDeployment
export def "cancel-service-instance-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  service_instance_name: string # The name of the service instance with the deployment to cancel.
  service_name: string # The name of the service with the service instance deployment to cancel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CancelServiceInstanceDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceInstanceName, var: service_instance_name}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_instance_name: $service_instance_name, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempts to cancel a service pipeline deployment on an UpdateServicePipeline action, if the deployment is IN_PROGRESS. For more information, see Update a service pipeline (https://docs.aws.amazon.com/proton/latest/userguide/ag-svc-pipeline-update.html) in the Proton User guide. The following list includes potential cancellation scenarios. If the cancellation attempt succeeds, the resulting deployment state is CANCELLED. If the cancellation attempt fails, the resulting deployment state is FAILED. If the current UpdateServicePipeline action succeeds before the cancellation attempt starts, the resulting deployment state is SUCCEEDED and the cancellation attempt has no effect.
#
# POST /
# Returns: record<pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: CancelServicePipelineDeployment
export def "cancel-service-pipeline-deployment" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  service_name: string # The name of the service with the service pipeline deployment to cancel.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CancelServicePipelineDeployment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Proton component. A component is an infrastructure extension for a service instance. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>
# operationId: CreateComponent
export def "create-component" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  --client-token: string # The client token for the created component.
  --description: string # An optional customer-provided description of the component. (format: password)
  --environment-name: string # The name of the Proton environment that you want to associate this component with. You must specify this when you don't specify serviceInstanceName and serviceName.
  manifest: string # A path to a manifest file that lists the Infrastructure as Code (IaC) file, template language, and rendering engine for infrastructure that a custom component provisions. (format: password)
  name: string # The customer-provided name of the component.
  --service-instance-name: string # The name of the service instance that you want to attach this component to. If you don't specify this, the component isn't attached to any service instance. Specify both serviceInstanceName and serviceName or neither of them.
  --service-name: string # The name of the service that serviceInstanceName is associated with. If you don't specify this, the component isn't attached to any service instance. Specify both serviceInstanceName and serviceName or neither of them.
  --service-spec: string # The service spec that you want the component to use to access service inputs. Set this only when you attach the component to a service instance. (format: password)
  --tags: list # An optional list of metadata items that you can associate with the Proton component. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_file: string # A path to the Infrastructure as Code (IaC) file describing infrastructure that a custom component provisions. Components support a single IaC file, even if you use Terraform as your template language. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateComponent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: description, var: description}, {name: environmentName, var: environment_name}, {name: manifest, var: manifest}, {name: name, var: name}, {name: serviceInstanceName, var: service_instance_name}, {name: serviceName, var: service_name}, {name: serviceSpec, var: service_spec}, {name: tags, var: tags}, {name: templateFile, var: template_file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, description: $description, environment_name: $environment_name, manifest: $manifest, name: $name, service_instance_name: $service_instance_name, service_name: $service_name, service_spec: $service_spec, tags: $tags, template_file: $template_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deploy a new environment. An Proton environment is created from an environment template that defines infrastructure and resources that can be shared across services. You can provision environments using the following methods: Amazon Web Services-managed provisioning: Proton makes direct calls to provision your resources. Self-managed provisioning: Proton makes pull requests on your repository to provide compiled infrastructure as code (IaC) files that your IaC engine uses to provision resources. For more information, see Environments (https://docs.aws.amazon.com/proton/latest/userguide/ag-environments.html) and Provisioning methods (https://docs.aws.amazon.com/proton/latest/userguide/ag-works-prov-methods.html) in the Proton User Guide.
#
# POST /
# Returns: record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: CreateEnvironment
export def "create-environment" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  --codebuild-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that allows Proton to provision infrastructure using CodeBuild-based provisioning on your behalf. To use CodeBuild-based provisioning for the environment or for any service instance running in the environment, specify either the environmentAccountConnectionId or codebuildRoleArn parameter.
  --component-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that Proton uses when provisioning directly defined components in this environment. It determines the scope of infrastructure that a component can provision. You must specify componentRoleArn to allow directly defined components to be associated with this environment. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  --description: string # A description of the environment that's being created and deployed. (format: password)
  --environment-account-connection-id: string # The ID of the environment account connection that you provide if you're provisioning your environment infrastructure resources to an environment account. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide. To use Amazon Web Services-managed provisioning for the environment, specify either the environmentAccountConnectionId or protonServiceRoleArn parameter and omit the provisioningRepository parameter.
  name: string # The name of the environment.
  --proton-service-role-arn: string # The Amazon Resource Name (ARN) of the Proton service role that allows Proton to make calls to other services on your behalf. To use Amazon Web Services-managed provisioning for the environment, specify either the environmentAccountConnectionId or protonServiceRoleArn parameter and omit the provisioningRepository parameter.
  --provisioning-repository: record # Detail input data for a linked repository branch. — shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
  spec: string # A YAML formatted string that provides inputs as defined in the environment template bundle schema file. For more information, see Environments (https://docs.aws.amazon.com/proton/latest/userguide/ag-environments.html) in the Proton User Guide. (format: password)
  --tags: list # An optional list of metadata items that you can associate with the Proton environment. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_major_version: string # The major version of the environment template.
  --template-minor-version: string # The minor version of the environment template.
  template_name: string # The name of the environment template. For more information, see Environment Templates (https://docs.aws.amazon.com/proton/latest/userguide/ag-templates.html) in the Proton User Guide.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateEnvironment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: codebuildRoleArn, var: codebuild_role_arn}, {name: componentRoleArn, var: component_role_arn}, {name: description, var: description}, {name: environmentAccountConnectionId, var: environment_account_connection_id}, {name: name, var: name}, {name: protonServiceRoleArn, var: proton_service_role_arn}, {name: provisioningRepository, var: provisioning_repository}, {name: spec, var: spec}, {name: tags, var: tags}, {name: templateMajorVersion, var: template_major_version}, {name: templateMinorVersion, var: template_minor_version}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, codebuild_role_arn: $codebuild_role_arn, component_role_arn: $component_role_arn, description: $description, environment_account_connection_id: $environment_account_connection_id, name: $name, proton_service_role_arn: $proton_service_role_arn, provisioning_repository: $provisioning_repository, spec: $spec, tags: $tags, template_major_version: $template_major_version, template_minor_version: $template_minor_version, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an environment account connection in an environment account so that environment infrastructure resources can be provisioned in the environment account from a management account. An environment account connection is a secure bi-directional connection between a management account and an environment account that maintains authorization and permissions. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# Returns: record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>
# operationId: CreateEnvironmentAccountConnection
export def "create-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  --client-token: string # When included, if two identical requests are made with the same client token, Proton returns the environment account connection that the first request created.
  --codebuild-role-arn: string # The Amazon Resource Name (ARN) of an IAM service role in the environment account. Proton uses this role to provision infrastructure resources using CodeBuild-based provisioning in the associated environment account.
  --component-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that Proton uses when provisioning directly defined components in the associated environment account. It determines the scope of infrastructure that a component can provision in the account. You must specify componentRoleArn to allow directly defined components to be associated with any environments running in this account. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  environment_name: string # The name of the Proton environment that's created in the associated management account.
  management_account_id: string # The ID of the management account that accepts or rejects the environment account connection. You create and manage the Proton environment in this account. If the management account accepts the environment account connection, Proton can use the associated IAM role to provision environment infrastructure resources in the associated environment account.
  --role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that's created in the environment account. Proton uses this role to provision infrastructure resources in the associated environment account.
  --tags: list # An optional list of metadata items that you can associate with the Proton environment account connection. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateEnvironmentAccountConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: codebuildRoleArn, var: codebuild_role_arn}, {name: componentRoleArn, var: component_role_arn}, {name: environmentName, var: environment_name}, {name: managementAccountId, var: management_account_id}, {name: roleArn, var: role_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, codebuild_role_arn: $codebuild_role_arn, component_role_arn: $component_role_arn, environment_name: $environment_name, management_account_id: $management_account_id, role_arn: $role_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an environment template for Proton. For more information, see Environment Templates (https://docs.aws.amazon.com/proton/latest/userguide/ag-templates.html) in the Proton User Guide. You can create an environment template in one of the two following ways: Register and publish a standard environment template that instructs Proton to deploy and manage environment infrastructure. Register and publish a customer managed environment template that connects Proton to your existing provisioned infrastructure that you manage. Proton doesn't manage your existing provisioned infrastructure. To create an environment template for customer provisioned and managed infrastructure, include the provisioning parameter and set the value to CUSTOMER_MANAGED. For more information, see Register and publish an environment template (https://docs.aws.amazon.com/proton/latest/userguide/template-create.html) in the Proton User Guide.
#
# POST /
# Returns: record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>
# operationId: CreateEnvironmentTemplate
export def "create-environment-template" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  --description: string # A description of the environment template. (format: password)
  --display-name: string # The environment template name as displayed in the developer interface. (format: password)
  --encryption-key: string # A customer provided encryption key that Proton uses to encrypt data.
  name: string # The name of the environment template.
  --provisioning: string@provisioning-completer # When included, indicates that the environment template is for customer provisioned and managed infrastructure.
  --tags: list # An optional list of metadata items that you can associate with the Proton environment template. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateEnvironmentTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: encryptionKey, var: encryption_key}, {name: name, var: name}, {name: provisioning, var: provisioning}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, display_name: $display_name, encryption_key: $encryption_key, name: $name, provisioning: $provisioning, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new major or minor version of an environment template. A major version of an environment template is a version that isn't backwards compatible. A minor version of an environment template is a version that's backwards compatible within its major version.
#
# POST /
# Returns: record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>>
# operationId: CreateEnvironmentTemplateVersion
export def "create-environment-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  --client-token: string # When included, if two identical requests are made with the same client token, Proton returns the environment template version that the first request created.
  --description: string # A description of the new version of an environment template. (format: password)
  --major-version: string # To create a new minor version of the environment template, include major Version. To create a new major and minor version of the environment template, exclude major Version.
  source: record # Template version source data. — shape: {s3?: record}
  --tags: list # An optional list of metadata items that you can associate with the Proton environment template version. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_name: string # The name of the environment template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateEnvironmentTemplateVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: description, var: description}, {name: majorVersion, var: major_version}, {name: source, var: source}, {name: tags, var: tags}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, description: $description, major_version: $major_version, source: $source, tags: $tags, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create and register a link to a repository. Proton uses the link to repeatedly access the repository, to either push to it (self-managed provisioning) or pull from it (template sync). You can share a linked repository across multiple resources (like environments using self-managed provisioning, or synced templates). When you create a repository link, Proton creates a service-linked role (https://docs.aws.amazon.com/proton/latest/userguide/using-service-linked-roles.html) for you. For more information, see Self-managed provisioning (https://docs.aws.amazon.com/proton/latest/userguide/ag-works-prov-methods.html#ag-works-prov-methods-self), Template bundles (https://docs.aws.amazon.com/proton/latest/userguide/ag-template-authoring.html#ag-template-bundles), and Template sync configurations (https://docs.aws.amazon.com/proton/latest/userguide/ag-template-sync-configs.html) in the Proton User Guide.
#
# POST /
# Returns: record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>>
# operationId: CreateRepository
export def "create-repository" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  connection_arn: string # The Amazon Resource Name (ARN) of your AWS CodeStar connection that connects Proton to your repository provider account. For more information, see Setting up for Proton (https://docs.aws.amazon.com/proton/latest/userguide/setting-up-for-service.html) in the Proton User Guide.
  --encryption-key: string # The ARN of your customer Amazon Web Services Key Management Service (Amazon Web Services KMS) key.
  name: string # The repository name (for example, myrepos/myrepo).
  provider: string@provider-completer # The repository provider.
  --tags: list # An optional list of metadata items that you can associate with the Proton repository. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: connectionArn, var: connection_arn}, {name: encryptionKey, var: encryption_key}, {name: name, var: name}, {name: provider, var: provider}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, connection_arn: $connection_arn, encryption_key: $encryption_key, name: $name, provider: $provider, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an Proton service. An Proton service is an instantiation of a service template and often includes several service instances and pipeline. For more information, see Services (https://docs.aws.amazon.com/proton/latest/userguide/ag-services.html) in the Proton User Guide.
#
# POST /
# Returns: record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>>
# operationId: CreateService
export def "create-service" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  --branch-name: string # The name of the code repository branch that holds the code that's deployed in Proton. Don't include this parameter if your service template doesn't include a service pipeline.
  --description: string # A description of the Proton service. (format: password)
  name: string # The service name.
  --repository-connection-arn: string # The Amazon Resource Name (ARN) of the repository connection. For more information, see Setting up an AWS CodeStar connection (https://docs.aws.amazon.com/proton/latest/userguide/setting-up-for-service.html#setting-up-vcontrol) in the Proton User Guide. Don't include this parameter if your service template doesn't include a service pipeline.
  --repository-id: string # The ID of the code repository. Don't include this parameter if your service template doesn't include a service pipeline.
  spec: string # A link to a spec file that provides inputs as defined in the service template bundle schema file. The spec file is in YAML format. Don’t include pipeline inputs in the spec if your service template doesn’t include a service pipeline. For more information, see Create a service (https://docs.aws.amazon.com/proton/latest/userguide/ag-create-svc.html) in the Proton User Guide. (format: password)
  --tags: list # An optional list of metadata items that you can associate with the Proton service. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_major_version: string # The major version of the service template that was used to create the service.
  --template-minor-version: string # The minor version of the service template that was used to create the service.
  template_name: string # The name of the service template that's used to create the service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: branchName, var: branch_name}, {name: description, var: description}, {name: name, var: name}, {name: repositoryConnectionArn, var: repository_connection_arn}, {name: repositoryId, var: repository_id}, {name: spec, var: spec}, {name: tags, var: tags}, {name: templateMajorVersion, var: template_major_version}, {name: templateMinorVersion, var: template_minor_version}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, branch_name: $branch_name, description: $description, name: $name, repository_connection_arn: $repository_connection_arn, repository_id: $repository_id, spec: $spec, tags: $tags, template_major_version: $template_major_version, template_minor_version: $template_minor_version, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a service instance.
#
# POST /
# Returns: record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: CreateServiceInstance
export def "create-service-instance" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  --client-token: string # The client token of the service instance to create.
  name: string # The name of the service instance to create.
  service_name: string # The name of the service the service instance is added to.
  spec: string # The spec for the service instance you want to create. (format: password)
  --tags: list # An optional list of metadata items that you can associate with the Proton service instance. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  --template-major-version: string # To create a new major and minor version of the service template, exclude major Version.
  --template-minor-version: string # To create a new minor version of the service template, include a major Version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateServiceInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: name, var: name}, {name: serviceName, var: service_name}, {name: spec, var: spec}, {name: tags, var: tags}, {name: templateMajorVersion, var: template_major_version}, {name: templateMinorVersion, var: template_minor_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, name: $name, service_name: $service_name, spec: $spec, tags: $tags, template_major_version: $template_major_version, template_minor_version: $template_minor_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create the Proton Ops configuration file.
#
# POST /
# Returns: record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>>
# operationId: CreateServiceSyncConfig
export def "create-service-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  branch: string # The repository branch for your Proton Ops file.
  file_path: string # The path to the Proton Ops file.
  repository_name: string # The repository name.
  repository_provider: string@repository-provider-completer # The provider type for your repository.
  service_name: string # The name of the service the Proton Ops file is for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateServiceSyncConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: filePath, var: file_path}, {name: repositoryName, var: repository_name}, {name: repositoryProvider, var: repository_provider}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, branch: $branch, file_path: $file_path, repository_name: $repository_name, repository_provider: $repository_provider, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a service template. The administrator creates a service template to define standardized infrastructure and an optional CI/CD service pipeline. Developers, in turn, select the service template from Proton. If the selected service template includes a service pipeline definition, they provide a link to their source code repository. Proton then deploys and manages the infrastructure defined by the selected service template. For more information, see Proton templates (https://docs.aws.amazon.com/proton/latest/userguide/ag-templates.html) in the Proton User Guide.
#
# POST /
# Returns: record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>
# operationId: CreateServiceTemplate
export def "create-service-template" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  --description: string # A description of the service template. (format: password)
  --display-name: string # The name of the service template as displayed in the developer interface. (format: password)
  --encryption-key: string # A customer provided encryption key that's used to encrypt data.
  name: string # The name of the service template.
  --pipeline-provisioning: string@pipeline-provisioning-completer # By default, Proton provides a service pipeline for your service. When this parameter is included, it indicates that an Proton service pipeline isn't provided for your service. After it's included, it can't be changed. For more information, see Template bundles (https://docs.aws.amazon.com/proton/latest/userguide/ag-template-authoring.html#ag-template-bundles) in the Proton User Guide.
  --tags: list # An optional list of metadata items that you can associate with the Proton service template. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateServiceTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: encryptionKey, var: encryption_key}, {name: name, var: name}, {name: pipelineProvisioning, var: pipeline_provisioning}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, display_name: $display_name, encryption_key: $encryption_key, name: $name, pipeline_provisioning: $pipeline_provisioning, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new major or minor version of a service template. A major version of a service template is a version that isn't backward compatible. A minor version of a service template is a version that's backward compatible within its major version.
#
# POST /
# Returns: record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>>
# operationId: CreateServiceTemplateVersion
export def "create-service-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  --client-token: string # When included, if two identical requests are made with the same client token, Proton returns the service template version that the first request created.
  compatible_environment_templates: list # An array of environment template objects that are compatible with the new service template version. A service instance based on this service template version can run in environments based on compatible templates. — item shape: {majorVersion: string, templateName: string}
  --description: string # A description of the new version of a service template. (format: password)
  --major-version: string # To create a new minor version of the service template, include a major Version. To create a new major and minor version of the service template, exclude major Version.
  source: record # Template version source data. — shape: {s3?: record}
  --supported-component-sources: list<string> # An array of supported component sources. Components with supported sources can be attached to service instances based on this service template version. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  --tags: list # An optional list of metadata items that you can associate with the Proton service template version. A tag is a key-value pair. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide. — item shape: {key: string, value: string}
  template_name: string # The name of the service template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateServiceTemplateVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: compatibleEnvironmentTemplates, var: compatible_environment_templates}, {name: description, var: description}, {name: majorVersion, var: major_version}, {name: source, var: source}, {name: supportedComponentSources, var: supported_component_sources}, {name: tags, var: tags}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, compatible_environment_templates: $compatible_environment_templates, description: $description, major_version: $major_version, source: $source, supported_component_sources: $supported_component_sources, tags: $tags, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set up a template to create new template versions automatically by tracking a linked repository. A linked repository is a repository that has been registered with Proton. For more information, see CreateRepository. When a commit is pushed to your linked repository, Proton checks for changes to your repository template bundles. If it detects a template bundle change, a new major or minor version of its template is created, if the version doesn’t already exist. For more information, see Template sync configurations (https://docs.aws.amazon.com/proton/latest/userguide/ag-template-sync-configs.html) in the Proton User Guide.
#
# POST /
# Returns: record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>>
# operationId: CreateTemplateSyncConfig
export def "create-template-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  branch: string # The repository branch for your template.
  repository_name: string # The repository name (for example, myrepos/myrepo).
  repository_provider: string@repository-provider-completer # The provider type for your repository.
  --subdirectory: string # A repository subdirectory path to your template bundle directory. When included, Proton limits the template bundle search to this repository directory.
  template_name: string # The name of your registered template.
  template_type: string@template-type-completer # The type of the registered template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.CreateTemplateSyncConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: repositoryName, var: repository_name}, {name: repositoryProvider, var: repository_provider}, {name: subdirectory, var: subdirectory}, {name: templateName, var: template_name}, {name: templateType, var: template_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, branch: $branch, repository_name: $repository_name, repository_provider: $repository_provider, subdirectory: $subdirectory, template_name: $template_name, template_type: $template_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Proton component resource. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>
# operationId: DeleteComponent
export def "delete-component" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  name: string # The name of the component to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteComponent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an environment.
#
# POST /
# Returns: record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: DeleteEnvironment
export def "delete-environment" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  name: string # The name of the environment to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteEnvironment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# In an environment account, delete an environment account connection. After you delete an environment account connection that’s in use by an Proton environment, Proton can’t manage the environment infrastructure resources until a new environment account connection is accepted for the environment account and associated environment. You're responsible for cleaning up provisioned resources that remain without an environment connection. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# Returns: record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>
# operationId: DeleteEnvironmentAccountConnection
export def "delete-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  id: string # The ID of the environment account connection to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteEnvironmentAccountConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If no other major or minor versions of an environment template exist, delete the environment template.
#
# POST /
# Returns: record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>
# operationId: DeleteEnvironmentTemplate
export def "delete-environment-template" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  name: string # The name of the environment template to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteEnvironmentTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If no other minor versions of an environment template exist, delete a major version of the environment template if it's not the Recommended version. Delete the Recommended version of the environment template if no other major versions or minor versions of the environment template exist. A major version of an environment template is a version that's not backward compatible. Delete a minor version of an environment template if it isn't the Recommended version. Delete a Recommended minor version of the environment template if no other minor versions of the environment template exist. A minor version of an environment template is a version that's backward compatible.
#
# POST /
# Returns: record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>>
# operationId: DeleteEnvironmentTemplateVersion
export def "delete-environment-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  major_version: string # The environment template major version to delete.
  minor_version: string # The environment template minor version to delete.
  template_name: string # The name of the environment template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteEnvironmentTemplateVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: majorVersion, var: major_version}, {name: minorVersion, var: minor_version}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, major_version: $major_version, minor_version: $minor_version, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# De-register and unlink your repository.
#
# POST /
# Returns: record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>>
# operationId: DeleteRepository
export def "delete-repository" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  name: string # The repository name.
  provider: string@provider-completer # The repository provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: provider, var: provider}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a service, with its instances and pipeline. You can't delete a service if it has any service instances that have components attached to them. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>>
# operationId: DeleteService
export def "delete-service" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  name: string # The name of the service to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the Proton Ops file.
#
# POST /
# Returns: record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>>
# operationId: DeleteServiceSyncConfig
export def "delete-service-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  service_name: string # The name of the service that you want to delete the service sync configuration for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteServiceSyncConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If no other major or minor versions of the service template exist, delete the service template.
#
# POST /
# Returns: record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>
# operationId: DeleteServiceTemplate
export def "delete-service-template" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  name: string # The name of the service template to delete.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteServiceTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# If no other minor versions of a service template exist, delete a major version of the service template if it's not the Recommended version. Delete the Recommended version of the service template if no other major versions or minor versions of the service template exist. A major version of a service template is a version that isn't backwards compatible. Delete a minor version of a service template if it's not the Recommended version. Delete a Recommended minor version of the service template if no other minor versions of the service template exist. A minor version of a service template is a version that's backwards compatible.
#
# POST /
# Returns: record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>>
# operationId: DeleteServiceTemplateVersion
export def "delete-service-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  major_version: string # The service template major version to delete.
  minor_version: string # The service template minor version to delete.
  template_name: string # The name of the service template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteServiceTemplateVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: majorVersion, var: major_version}, {name: minorVersion, var: minor_version}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, major_version: $major_version, minor_version: $minor_version, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a template sync configuration.
#
# POST /
# Returns: record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>>
# operationId: DeleteTemplateSyncConfig
export def "delete-template-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  template_name: string # The template name.
  template_type: string@template-type-completer # The template type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.DeleteTemplateSyncConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: templateName, var: template_name}, {name: templateType, var: template_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, template_name: $template_name, template_type: $template_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detail data for Proton account-wide settings.
#
# POST /
# Returns: record<accountSettings: record<pipelineCodebuildRoleArn: string, pipelineProvisioningRepository: record<arn: string, branch: string, name: string, provider: string>, pipelineServiceRoleArn: string>>
# operationId: GetAccountSettings
export def "get-account-settings" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetAccountSettings"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for a component. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>
# operationId: GetComponent
export def "get-component" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  name: string # The name of the component that you want to get the detailed data for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetComponent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for an environment.
#
# POST /
# Returns: record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: GetEnvironment
export def "get-environment" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  name: string # The name of the environment that you want to get the detailed data for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetEnvironment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# In an environment account, get the detailed data for an environment account connection. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# Returns: record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>
# operationId: GetEnvironmentAccountConnection
export def "get-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  id: string # The ID of the environment account connection that you want to get the detailed data for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetEnvironmentAccountConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for an environment template.
#
# POST /
# Returns: record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>
# operationId: GetEnvironmentTemplate
export def "get-environment-template" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  name: string # The name of the environment template that you want to get the detailed data for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetEnvironmentTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for a major or minor version of an environment template.
#
# POST /
# Returns: record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>>
# operationId: GetEnvironmentTemplateVersion
export def "get-environment-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  major_version: string # To get environment template major version detail data, include major Version.
  minor_version: string # To get environment template minor version detail data, include minorVersion.
  template_name: string # The name of the environment template a version of which you want to get detailed data for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetEnvironmentTemplateVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: majorVersion, var: major_version}, {name: minorVersion, var: minor_version}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, major_version: $major_version, minor_version: $minor_version, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detail data for a linked repository.
#
# POST /
# Returns: record<repository: record<arn: string, connectionArn: string, encryptionKey: string, name: string, provider: string>>
# operationId: GetRepository
export def "get-repository" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  name: string # The repository name, for example myrepos/myrepo.
  provider: string@provider-completer # The repository provider.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetRepository"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: provider, var: provider}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, provider: $provider
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the sync status of a repository used for Proton template sync. For more information about template sync, see . A repository sync status isn't tied to the Proton Repository resource (or any other Proton resource). Therefore, tags on an Proton Repository resource have no effect on this action. Specifically, you can't use these tags to control access to this action using Attribute-based access control (ABAC). For more information about ABAC, see ABAC (https://docs.aws.amazon.com/proton/latest/userguide/security_iam_service-with-iam.html#security_iam_service-with-iam-tags) in the Proton User Guide.
#
# POST /
# Returns: record<latestSync: record<events: list<record>, startedAt: string, status: string>>
# operationId: GetRepositorySyncStatus
export def "get-repository-sync-status" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  branch: string # The repository branch.
  repository_name: string # The repository name.
  repository_provider: string@repository-provider-completer # The repository provider.
  sync_type: string@sync-type-completer # The repository sync type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetRepositorySyncStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: repositoryName, var: repository_name}, {name: repositoryProvider, var: repository_provider}, {name: syncType, var: sync_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, branch: $branch, repository_name: $repository_name, repository_provider: $repository_provider, sync_type: $sync_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get counts of Proton resources. For infrastructure-provisioning resources (environments, services, service instances, pipelines), the action returns staleness counts. A resource is stale when it's behind the recommended version of the Proton template that it uses and it needs an update to become current. The action returns staleness counts (counts of resources that are up-to-date, behind a template major version, or behind a template minor version), the total number of resources, and the number of resources that are in a failed state, grouped by resource type. Components, environments, and service templates return less information - see the components, environments, and serviceTemplates field descriptions. For context, the action also returns the total number of each type of Proton template in the Amazon Web Services account. For more information, see Proton dashboard (https://docs.aws.amazon.com/proton/latest/userguide/monitoring-dashboard.html) in the Proton User Guide.
#
# POST /
# Returns: record<counts: record<components: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, environmentTemplates: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, environments: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, pipelines: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, serviceInstances: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, serviceTemplates: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>, services: record<behindMajor: int, behindMinor: int, failed: int, total: int, upToDate: int>>>
# operationId: GetResourcesSummary
export def "get-resources-summary" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetResourcesSummary"}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for a service.
#
# POST /
# Returns: record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>>
# operationId: GetService
export def "get-service" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  name: string # The name of the service that you want to get the detailed data for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for a service instance. A service instance is an instantiation of service template and it runs in a specific environment.
#
# POST /
# Returns: record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: GetServiceInstance
export def "get-service-instance" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  name: string # The name of a service instance that you want to get the detailed data for.
  service_name: string # The name of the service that you want the service instance input for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetServiceInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the status of the synced service instance.
#
# POST /
# Returns: record<desiredState: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, latestSuccessfulSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>, latestSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>>
# operationId: GetServiceInstanceSyncStatus
export def "get-service-instance-sync-status" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  service_instance_name: string # The name of the service instance that you want the sync status input for.
  service_name: string # The name of the service that the service instance belongs to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetServiceInstanceSyncStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceInstanceName, var: service_instance_name}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_instance_name: $service_instance_name, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for the service sync blocker summary.
#
# POST /
# Returns: record<serviceSyncBlockerSummary: record<latestBlockers: list<record>, serviceInstanceName: string, serviceName: string>>
# operationId: GetServiceSyncBlockerSummary
export def "get-service-sync-blocker-summary" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  --service-instance-name: string # The name of the service instance that you want to get the service sync blocker summary for. If given bothe the instance name and the service name, only the instance is blocked.
  service_name: string # The name of the service that you want to get the service sync blocker summary for. If given only the service name, all instances are blocked.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetServiceSyncBlockerSummary"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceInstanceName, var: service_instance_name}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_instance_name: $service_instance_name, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed information for the service sync configuration.
#
# POST /
# Returns: record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>>
# operationId: GetServiceSyncConfig
export def "get-service-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  service_name: string # The name of the service that you want to get the service sync configuration for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetServiceSyncConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for a service template.
#
# POST /
# Returns: record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>
# operationId: GetServiceTemplate
export def "get-service-template" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  name: string # The name of the service template that you want to get detailed data for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetServiceTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detailed data for a major or minor version of a service template.
#
# POST /
# Returns: record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>>
# operationId: GetServiceTemplateVersion
export def "get-service-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  major_version: string # To get service template major version detail data, include major Version.
  minor_version: string # To get service template minor version detail data, include minorVersion.
  template_name: string # The name of the service template a version of which you want to get detailed data for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetServiceTemplateVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: majorVersion, var: major_version}, {name: minorVersion, var: minor_version}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, major_version: $major_version, minor_version: $minor_version, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get detail data for a template sync configuration.
#
# POST /
# Returns: record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>>
# operationId: GetTemplateSyncConfig
export def "get-template-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  template_name: string # The template name.
  template_type: string@template-type-completer # The template type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetTemplateSyncConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: templateName, var: template_name}, {name: templateType, var: template_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, template_name: $template_name, template_type: $template_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the status of a template sync.
#
# POST /
# Returns: record<desiredState: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, latestSuccessfulSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>, latestSync: record<events: list<record>, initialRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>, startedAt: string, status: string, target: string, targetRevision: record<branch: string, directory: string, repositoryName: string, repositoryProvider: string, sha: string>>>
# operationId: GetTemplateSyncStatus
export def "get-template-sync-status" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  template_name: string # The template name.
  template_type: string@template-type-completer # The template type.
  template_version: string # The template major version.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.GetTemplateSyncStatus"}]
    body: {content_type: "application/json", kind: json, fields: [{name: templateName, var: template_name}, {name: templateType, var: template_type}, {name: templateVersion, var: template_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, template_name: $template_name, template_type: $template_type, template_version: $template_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of component Infrastructure as Code (IaC) outputs. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<nextToken: string, outputs: table<key: string, valueString: string>>
# operationId: ListComponentOutputs
export def "list-component-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  component_name: string # The name of the component whose outputs you want.
  --body-next-token: string # A token that indicates the location of the next output in the array of outputs, after the list of outputs that was previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListComponentOutputs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentName, var: component_name}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, component_name: $component_name, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List provisioned resources for a component with details. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>>
# operationId: ListComponentProvisionedResources
export def "list-component-provisioned-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  component_name: string # The name of the component whose provisioned resources you want.
  --body-next-token: string # A token that indicates the location of the next provisioned resource in the array of provisioned resources, after the list of provisioned resources that was previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListComponentProvisionedResources"}]
    body: {content_type: "application/json", kind: json, fields: [{name: componentName, var: component_name}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, component_name: $component_name, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List components with summary data. You can filter the result list by environment, service, or a single service instance. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<components: table<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string>, nextToken: string>
# operationId: ListComponents
export def "list-components" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  --environment-name: string # The name of an environment for result list filtering. Proton returns components associated with the environment or attached to service instances running in it.
  --body-max-results: int # The maximum number of components to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next component in the array of components, after the list of components that was previously requested. (spec name: nextToken)
  --service-instance-name: string # The name of a service instance for result list filtering. Proton returns the component attached to the service instance, if any.
  --service-name: string # The name of a service for result list filtering. Proton returns components attached to service instances of the service.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListComponents"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentName, var: environment_name}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: serviceInstanceName, var: service_instance_name}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, environment_name: $environment_name, body_max_results: $body_max_results, body_next_token: $body_next_token, service_instance_name: $service_instance_name, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# View a list of environment account connections. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# Returns: record<environmentAccountConnections: table<arn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>, nextToken: string>
# operationId: ListEnvironmentAccountConnections
export def "list-environment-account-connections" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  --environment-name: string # The environment name that's associated with each listed environment account connection.
  --body-max-results: int # The maximum number of environment account connections to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next environment account connection in the array of environment account connections, after the list of environment account connections that was previously requested. (spec name: nextToken)
  requested_by: string@requested-by-completer # The type of account making the ListEnvironmentAccountConnections request.
  --statuses: list<string> # The status details for each listed environment account connection.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListEnvironmentAccountConnections"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentName, var: environment_name}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: requestedBy, var: requested_by}, {name: statuses, var: statuses}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, environment_name: $environment_name, body_max_results: $body_max_results, body_next_token: $body_next_token, requested_by: $requested_by, statuses: $statuses
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the infrastructure as code outputs for your environment.
#
# POST /
# Returns: record<nextToken: string, outputs: table<key: string, valueString: string>>
# operationId: ListEnvironmentOutputs
export def "list-environment-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50 # required
  environment_name: string # The environment name.
  --body-next-token: string # A token that indicates the location of the next environment output in the array of environment outputs, after the list of environment outputs that was previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListEnvironmentOutputs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentName, var: environment_name}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, environment_name: $environment_name, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List the provisioned resources for your environment.
#
# POST /
# Returns: record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>>
# operationId: ListEnvironmentProvisionedResources
export def "list-environment-provisioned-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51 # required
  environment_name: string # The environment name.
  --body-next-token: string # A token that indicates the location of the next environment provisioned resource in the array of environment provisioned resources, after the list of environment provisioned resources that was previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListEnvironmentProvisionedResources"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentName, var: environment_name}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, environment_name: $environment_name, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List major or minor versions of an environment template with detail data.
#
# POST /
# Returns: record<nextToken: string, templateVersions: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, status: string, statusMessage: string, templateName: string>>
# operationId: ListEnvironmentTemplateVersions
export def "list-environment-template-versions" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  --major-version: string # To view a list of minor of versions under a major version of an environment template, include major Version. To view a list of major versions of an environment template, exclude major Version.
  --body-max-results: int # The maximum number of major or minor versions of an environment template to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next major or minor version in the array of major or minor versions of an environment template, after the list of major or minor versions that was previously requested. (spec name: nextToken)
  template_name: string # The name of the environment template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListEnvironmentTemplateVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: majorVersion, var: major_version}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, major_version: $major_version, body_max_results: $body_max_results, body_next_token: $body_next_token, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List environment templates.
#
# POST /
# Returns: record<nextToken: string, templates: table<arn: string, createdAt: string, description: string, displayName: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>
# operationId: ListEnvironmentTemplates
export def "list-environment-templates" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  --body-max-results: int # The maximum number of environment templates to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next environment template in the array of environment templates, after the list of environment templates that was previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListEnvironmentTemplates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List environments with detail data summaries.
#
# POST /
# Returns: record<environments: table<arn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, nextToken: string>
# operationId: ListEnvironments
export def "list-environments" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --environment-templates: list # An array of the versions of the environment template. — item shape: {majorVersion: string, templateName: string}
  --body-max-results: int # The maximum number of environments to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next environment in the array of environments, after the list of environments that was previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListEnvironments"}]
    body: {content_type: "application/json", kind: json, fields: [{name: environmentTemplates, var: environment_templates}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, environment_templates: $environment_templates, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List linked repositories with detail data.
#
# POST /
# Returns: record<nextToken: string, repositories: table<arn: string, connectionArn: string, name: string, provider: string>>
# operationId: ListRepositories
export def "list-repositories" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  --body-max-results: int # The maximum number of repositories to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next repository in the array of repositories, after the list of repositories previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListRepositories"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List repository sync definitions with detail data.
#
# POST /
# Returns: record<nextToken: string, syncDefinitions: table<branch: string, directory: string, parent: string, target: string>>
# operationId: ListRepositorySyncDefinitions
export def "list-repository-sync-definitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56 # required
  --body-next-token: string # A token that indicates the location of the next repository sync definition in the array of repository sync definitions, after the list of repository sync definitions previously requested. (spec name: nextToken)
  repository_name: string # The repository name.
  repository_provider: string@repository-provider-completer # The repository provider.
  sync_type: string@sync-type-completer # The sync type. The only supported value is TEMPLATE_SYNC.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListRepositorySyncDefinitions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: repositoryName, var: repository_name}, {name: repositoryProvider, var: repository_provider}, {name: syncType, var: sync_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, repository_name: $repository_name, repository_provider: $repository_provider, sync_type: $sync_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list service of instance Infrastructure as Code (IaC) outputs.
#
# POST /
# Returns: record<nextToken: string, outputs: table<key: string, valueString: string>>
# operationId: ListServiceInstanceOutputs
export def "list-service-instance-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57 # required
  --body-next-token: string # A token that indicates the location of the next output in the array of outputs, after the list of outputs that was previously requested. (spec name: nextToken)
  service_instance_name: string # The name of the service instance whose outputs you want.
  service_name: string # The name of the service that serviceInstanceName is associated to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListServiceInstanceOutputs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: serviceInstanceName, var: service_instance_name}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, service_instance_name: $service_instance_name, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List provisioned resources for a service instance with details.
#
# POST /
# Returns: record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>>
# operationId: ListServiceInstanceProvisionedResources
export def "list-service-instance-provisioned-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-58 # required
  --body-next-token: string # A token that indicates the location of the next provisioned resource in the array of provisioned resources, after the list of provisioned resources that was previously requested. (spec name: nextToken)
  service_instance_name: string # The name of the service instance whose provisioned resources you want.
  service_name: string # The name of the service that serviceInstanceName is associated to.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListServiceInstanceProvisionedResources"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: serviceInstanceName, var: service_instance_name}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, service_instance_name: $service_instance_name, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List service instances with summary data. This action lists service instances of all services in the Amazon Web Services account.
#
# POST /
# Returns: record<nextToken: string, serviceInstances: table<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: ListServiceInstances
export def "list-service-instances" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  --filters: list # An array of filtering criteria that scope down the result list. By default, all service instances in the Amazon Web Services account are returned. — item shape: {key?: "name"|"deploymentStatus"|"templateName"|"serviceName"|"deployedTemplateVersionStatus"|"environmentName"|"lastDeploymentAttemptedAtBefore"|"lastDeploymentAttemptedAtAfter"|"createdAtBefore"|"createdAtAfter", value?: string}
  --body-max-results: int # The maximum number of service instances to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next service in the array of service instances, after the list of service instances that was previously requested. (spec name: nextToken)
  --service-name: string # The name of the service that the service instance belongs to.
  --sort-by: string@sort-by-completer # The field that the result list is sorted by. When you choose to sort by serviceName, service instances within each service are sorted by service instance name. Default: serviceName
  --sort-order: string@sort-order-completer # Result list sort order. Default: ASCENDING
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListServiceInstances"}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: serviceName, var: service_name}, {name: sortBy, var: sort_by}, {name: sortOrder, var: sort_order}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token, service_name: $service_name, sort_by: $sort_by, sort_order: $sort_order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of service pipeline Infrastructure as Code (IaC) outputs.
#
# POST /
# Returns: record<nextToken: string, outputs: table<key: string, valueString: string>>
# operationId: ListServicePipelineOutputs
export def "list-service-pipeline-outputs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-60 # required
  --body-next-token: string # A token that indicates the location of the next output in the array of outputs, after the list of outputs that was previously requested. (spec name: nextToken)
  service_name: string # The name of the service whose pipeline's outputs you want.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListServicePipelineOutputs"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List provisioned resources for a service and pipeline with details.
#
# POST /
# Returns: record<nextToken: string, provisionedResources: table<identifier: string, name: string, provisioningEngine: string>>
# operationId: ListServicePipelineProvisionedResources
export def "list-service-pipeline-provisioned-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-61 # required
  --body-next-token: string # A token that indicates the location of the next provisioned resource in the array of provisioned resources, after the list of provisioned resources that was previously requested. (spec name: nextToken)
  service_name: string # The name of the service whose pipeline's provisioned resources you want.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListServicePipelineProvisionedResources"}]
    body: {content_type: "application/json", kind: json, fields: [{name: nextToken, var: body_next_token}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_next_token: $body_next_token, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List major or minor versions of a service template with detail data.
#
# POST /
# Returns: record<nextToken: string, templateVersions: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, status: string, statusMessage: string, templateName: string>>
# operationId: ListServiceTemplateVersions
export def "list-service-template-versions" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  --major-version: string # To view a list of minor of versions under a major version of a service template, include major Version. To view a list of major versions of a service template, exclude major Version.
  --body-max-results: int # The maximum number of major or minor versions of a service template to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next major or minor version in the array of major or minor versions of a service template, after the list of major or minor versions that was previously requested. (spec name: nextToken)
  template_name: string # The name of the service template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListServiceTemplateVersions"}]
    body: {content_type: "application/json", kind: json, fields: [{name: majorVersion, var: major_version}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, major_version: $major_version, body_max_results: $body_max_results, body_next_token: $body_next_token, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List service templates with detail data.
#
# POST /
# Returns: record<nextToken: string, templates: table<arn: string, createdAt: string, description: string, displayName: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>
# operationId: ListServiceTemplates
export def "list-service-templates" [
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  --body-max-results: int # The maximum number of service templates to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next service template in the array of service templates, after the list of service templates previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListServiceTemplates"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List services with summaries of detail data.
#
# POST /
# Returns: record<nextToken: string, services: table<arn: string, createdAt: string, description: string, lastModifiedAt: string, name: string, status: string, statusMessage: string, templateName: string>>
# operationId: ListServices
export def "list-services" [
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  --body-max-results: int # The maximum number of services to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next service in the array of services, after the list of services that was previously requested. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListServices"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List tags for a resource. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide.
#
# POST /
# Returns: record<nextToken: string, tags: table<key: string, value: string>>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  --body-max-results: int # The maximum number of tags to list. (spec name: maxResults)
  --body-next-token: string # A token that indicates the location of the next resource tag in the array of resource tags, after the list of resource tags that was previously requested. (spec name: nextToken)
  resource_arn: string # The Amazon Resource Name (ARN) of the resource for the listed tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.ListTagsForResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: resourceArn, var: resource_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, body_max_results: $body_max_results, body_next_token: $body_next_token, resource_arn: $resource_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Notify Proton of status changes to a provisioned resource when you use self-managed provisioning. For more information, see Self-managed provisioning (https://docs.aws.amazon.com/proton/latest/userguide/ag-works-prov-methods.html#ag-works-prov-methods-self) in the Proton User Guide.
#
# POST /
# Returns: record
# operationId: NotifyResourceDeploymentStatusChange
export def "notify-resource-deployment-status-change" [
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  --deployment-id: string # The deployment ID for your provisioned resource.
  --outputs: list # The provisioned resource state change detail data that's returned by Proton. — item shape: {key?: string, valueString?: string}
  resource_arn: string # The provisioned resource Amazon Resource Name (ARN).
  --status: string@status-completer # The state that a PR-based deployment can be updated to.
  --status-message: string # The deployment status message for your provisioned resource. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.NotifyResourceDeploymentStatusChange"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentId, var: deployment_id}, {name: outputs, var: outputs}, {name: resourceArn, var: resource_arn}, {name: status, var: status}, {name: statusMessage, var: status_message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_id: $deployment_id, outputs: $outputs, resource_arn: $resource_arn, status: $status, status_message: $status_message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# In a management account, reject an environment account connection from another environment account. After you reject an environment account connection request, you can't accept or use the rejected environment account connection. You can’t reject an environment account connection that's connected to an environment. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# Returns: record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>
# operationId: RejectEnvironmentAccountConnection
export def "reject-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  id: string # The ID of the environment account connection to reject.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.RejectEnvironmentAccountConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Tag a resource. A tag is a key-value pair of metadata that you associate with an Proton resource. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide.
#
# POST /
# Returns: record
# operationId: TagResource
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the Proton resource to apply customer tags to.
  tags: list # A list of customer tags to apply to the Proton resource. — item shape: {key: string, value: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.TagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a customer tag from a resource. A tag is a key-value pair of metadata associated with an Proton resource. For more information, see Proton resources and tagging (https://docs.aws.amazon.com/proton/latest/userguide/resources.html) in the Proton User Guide.
#
# POST /
# Returns: record
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-69 # required
  resource_arn: string # The Amazon Resource Name (ARN) of the resource to remove customer tags from.
  tag_keys: list<string> # A list of customer tag keys that indicate the customer tags to be removed from the resource.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UntagResource"}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceArn, var: resource_arn}, {name: tagKeys, var: tag_keys}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, resource_arn: $resource_arn, tag_keys: $tag_keys
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Proton settings that are used for multiple services in the Amazon Web Services account.
#
# POST /
# Returns: record<accountSettings: record<pipelineCodebuildRoleArn: string, pipelineProvisioningRepository: record<arn: string, branch: string, name: string, provider: string>, pipelineServiceRoleArn: string>>
# operationId: UpdateAccountSettings
export def "update-account-settings" [
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
  --x-amz-target: string@x-amz-target-completer-70 # required
  --delete-pipeline-provisioning-repository: oneof<nothing, bool> # Set to true to remove a configured pipeline repository from the account settings. Don't set this field if you are updating the configured pipeline repository.
  --pipeline-codebuild-role-arn: string # The Amazon Resource Name (ARN) of the service role you want to use for provisioning pipelines. Proton assumes this role for CodeBuild-based provisioning.
  --pipeline-provisioning-repository: record # Detail input data for a linked repository branch. — shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
  --pipeline-service-role-arn: string # The Amazon Resource Name (ARN) of the service role you want to use for provisioning pipelines. Assumed by Proton for Amazon Web Services-managed provisioning, and by customer-owned automation for self-managed provisioning. To remove a previously configured ARN, specify an empty string.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateAccountSettings"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deletePipelineProvisioningRepository, var: delete_pipeline_provisioning_repository}, {name: pipelineCodebuildRoleArn, var: pipeline_codebuild_role_arn}, {name: pipelineProvisioningRepository, var: pipeline_provisioning_repository}, {name: pipelineServiceRoleArn, var: pipeline_service_role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, delete_pipeline_provisioning_repository: $delete_pipeline_provisioning_repository, pipeline_codebuild_role_arn: $pipeline_codebuild_role_arn, pipeline_provisioning_repository: $pipeline_provisioning_repository, pipeline_service_role_arn: $pipeline_service_role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a component. There are a few modes for updating a component. The deploymentType field defines the mode. You can't update a component while its deployment status, or the deployment status of a service instance attached to it, is IN_PROGRESS. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<component: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, lastModifiedAt: string, name: string, serviceInstanceName: string, serviceName: string, serviceSpec: string>>
# operationId: UpdateComponent
export def "update-component" [
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
  --x-amz-target: string@x-amz-target-completer-71 # required
  --client-token: string # The client token for the updated component.
  deployment_type: string@deployment-type-completer # The deployment type. It defines the mode for updating a component, as follows: NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. You can only specify description in this mode. CURRENT_VERSION In this mode, the component is deployed and updated with the new serviceSpec, templateSource, and/or type that you provide. Only requested parameters are updated.
  --description: string # An optional customer-provided description of the component. (format: password)
  name: string # The name of the component to update.
  --service-instance-name: string # The name of the service instance that you want to attach this component to. Don't specify to keep the component's current service instance attachment. Specify an empty string to detach the component from the service instance it's attached to. Specify non-empty values for both serviceInstanceName and serviceName or for neither of them.
  --service-name: string # The name of the service that serviceInstanceName is associated with. Don't specify to keep the component's current service instance attachment. Specify an empty string to detach the component from the service instance it's attached to. Specify non-empty values for both serviceInstanceName and serviceName or for neither of them.
  --service-spec: string # The service spec that you want the component to use to access service inputs. Set this only when the component is attached to a service instance. (format: password)
  --template-file: string # A path to the Infrastructure as Code (IaC) file describing infrastructure that a custom component provisions. Components support a single IaC file, even if you use Terraform as your template language. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateComponent"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: deploymentType, var: deployment_type}, {name: description, var: description}, {name: name, var: name}, {name: serviceInstanceName, var: service_instance_name}, {name: serviceName, var: service_name}, {name: serviceSpec, var: service_spec}, {name: templateFile, var: template_file}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, deployment_type: $deployment_type, description: $description, name: $name, service_instance_name: $service_instance_name, service_name: $service_name, service_spec: $service_spec, template_file: $template_file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an environment. If the environment is associated with an environment account connection, don't update or include the protonServiceRoleArn and provisioningRepository parameter to update or connect to an environment account connection. You can only update to a new environment account connection if that connection was created in the same environment account that the current environment account connection was created in. The account connection must also be associated with the current environment. If the environment isn't associated with an environment account connection, don't update or include the environmentAccountConnectionId parameter. You can't update or connect the environment to an environment account connection if it isn't already associated with an environment connection. You can update either the environmentAccountConnectionId or protonServiceRoleArn parameter and value. You can’t update both. If the environment was configured for Amazon Web Services-managed provisioning, omit the provisioningRepository parameter. If the environment was configured for self-managed provisioning, specify the provisioningRepository parameter and omit the protonServiceRoleArn and environmentAccountConnectionId parameters. For more information, see Environments (https://docs.aws.amazon.com/proton/latest/userguide/ag-environments.html) and Provisioning methods (https://docs.aws.amazon.com/proton/latest/userguide/ag-works-prov-methods.html) in the Proton User Guide. There are four modes for updating an environment. The deploymentType field defines the mode. NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the environment is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include minor or major version parameters when you use this deployment-type. MINOR_VERSION In this mode, the environment is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can also specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the environment is deployed and updated with the published, recommended (latest) major and minor version of the current template, by default. You can also specify a different major version that's higher than the major version in use and a minor version.
#
# POST /
# Returns: record<environment: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, description: string, environmentAccountConnectionId: string, environmentAccountId: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, protonServiceRoleArn: string, provisioning: string, provisioningRepository: record<arn: string, branch: string, name: string, provider: string>, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: UpdateEnvironment
export def "update-environment" [
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
  --x-amz-target: string@x-amz-target-completer-72 # required
  --codebuild-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that allows Proton to provision infrastructure using CodeBuild-based provisioning on your behalf.
  --component-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that Proton uses when provisioning directly defined components in this environment. It determines the scope of infrastructure that a component can provision. The environment must have a componentRoleArn to allow directly defined components to be associated with the environment. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  deployment_type: string@deployment-type-completer-1 # There are four modes for updating an environment. The deploymentType field defines the mode. NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the environment is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include major or minor version parameters when you use this deployment-type. MINOR_VERSION In this mode, the environment is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can also specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the environment is deployed and updated with the published, recommended (latest) major and minor version of the current template, by default. You can also specify a different major version that is higher than the major version in use and a minor version (optional).
  --description: string # A description of the environment update. (format: password)
  --environment-account-connection-id: string # The ID of the environment account connection. You can only update to a new environment account connection if it was created in the same environment account that the current environment account connection was created in and is associated with the current environment.
  name: string # The name of the environment to update.
  --proton-service-role-arn: string # The Amazon Resource Name (ARN) of the Proton service role that allows Proton to make API calls to other services your behalf.
  --provisioning-repository: record # Detail input data for a linked repository branch. — shape: {branch: string, name: string, provider: "GITHUB"|"GITHUB_ENTERPRISE"|"BITBUCKET"}
  --spec: string # The formatted specification that defines the update. (format: password)
  --template-major-version: string # The major version of the environment to update.
  --template-minor-version: string # The minor version of the environment to update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateEnvironment"}]
    body: {content_type: "application/json", kind: json, fields: [{name: codebuildRoleArn, var: codebuild_role_arn}, {name: componentRoleArn, var: component_role_arn}, {name: deploymentType, var: deployment_type}, {name: description, var: description}, {name: environmentAccountConnectionId, var: environment_account_connection_id}, {name: name, var: name}, {name: protonServiceRoleArn, var: proton_service_role_arn}, {name: provisioningRepository, var: provisioning_repository}, {name: spec, var: spec}, {name: templateMajorVersion, var: template_major_version}, {name: templateMinorVersion, var: template_minor_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, codebuild_role_arn: $codebuild_role_arn, component_role_arn: $component_role_arn, deployment_type: $deployment_type, description: $description, environment_account_connection_id: $environment_account_connection_id, name: $name, proton_service_role_arn: $proton_service_role_arn, provisioning_repository: $provisioning_repository, spec: $spec, template_major_version: $template_major_version, template_minor_version: $template_minor_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# In an environment account, update an environment account connection to use a new IAM role. For more information, see Environment account connections (https://docs.aws.amazon.com/proton/latest/userguide/ag-env-account-connections.html) in the Proton User guide.
#
# POST /
# Returns: record<environmentAccountConnection: record<arn: string, codebuildRoleArn: string, componentRoleArn: string, environmentAccountId: string, environmentName: string, id: string, lastModifiedAt: string, managementAccountId: string, requestedAt: string, roleArn: string, status: string>>
# operationId: UpdateEnvironmentAccountConnection
export def "update-environment-account-connection" [
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
  --x-amz-target: string@x-amz-target-completer-73 # required
  --codebuild-role-arn: string # The Amazon Resource Name (ARN) of an IAM service role in the environment account. Proton uses this role to provision infrastructure resources using CodeBuild-based provisioning in the associated environment account.
  --component-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that Proton uses when provisioning directly defined components in the associated environment account. It determines the scope of infrastructure that a component can provision in the account. The environment account connection must have a componentRoleArn to allow directly defined components to be associated with any environments running in the account. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  id: string # The ID of the environment account connection to update.
  --role-arn: string # The Amazon Resource Name (ARN) of the IAM service role that's associated with the environment account connection to update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateEnvironmentAccountConnection"}]
    body: {content_type: "application/json", kind: json, fields: [{name: codebuildRoleArn, var: codebuild_role_arn}, {name: componentRoleArn, var: component_role_arn}, {name: id, var: id}, {name: roleArn, var: role_arn}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, codebuild_role_arn: $codebuild_role_arn, component_role_arn: $component_role_arn, id: $id, role_arn: $role_arn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an environment template.
#
# POST /
# Returns: record<environmentTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, provisioning: string, recommendedVersion: string>>
# operationId: UpdateEnvironmentTemplate
export def "update-environment-template" [
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
  --x-amz-target: string@x-amz-target-completer-74 # required
  --description: string # A description of the environment template update. (format: password)
  --display-name: string # The name of the environment template to update as displayed in the developer interface. (format: password)
  name: string # The name of the environment template to update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateEnvironmentTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, display_name: $display_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a major or minor version of an environment template.
#
# POST /
# Returns: record<environmentTemplateVersion: record<arn: string, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, templateName: string>>
# operationId: UpdateEnvironmentTemplateVersion
export def "update-environment-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-75 # required
  --description: string # A description of environment template version to update. (format: password)
  major_version: string # To update a major version of an environment template, include major Version.
  minor_version: string # To update a minor version of an environment template, include minorVersion.
  --status: string@status-completer-1 # The status of the environment template minor version to update.
  template_name: string # The name of the environment template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateEnvironmentTemplateVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: majorVersion, var: major_version}, {name: minorVersion, var: minor_version}, {name: status, var: status}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, major_version: $major_version, minor_version: $minor_version, status: $status, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a service description or use a spec to add and delete service instances. Existing service instances and the service pipeline can't be edited using this API. They can only be deleted. Use the description parameter to modify the description. Edit the spec parameter to add or delete instances. You can't delete a service instance (remove it from the spec) if it has an attached component. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<service: record<arn: string, branchName: string, createdAt: string, description: string, lastModifiedAt: string, name: string, pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>, repositoryConnectionArn: string, repositoryId: string, spec: string, status: string, statusMessage: string, templateName: string>>
# operationId: UpdateService
export def "update-service" [
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
  --x-amz-target: string@x-amz-target-completer-76 # required
  --description: string # The edited service description. (format: password)
  name: string # The name of the service to edit.
  --spec: string # Lists the service instances to add and the existing service instances to remain. Omit the existing service instances to delete from the list. Don't include edits to the existing service instances or pipeline. For more information, see Edit a service (https://docs.aws.amazon.com/proton/latest/userguide/ag-svc-update.html) in the Proton User Guide. (format: password)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateService"}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: spec, var: spec}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, name: $name, spec: $spec
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a service instance. There are a few modes for updating a service instance. The deploymentType field defines the mode. You can't update a service instance while its deployment status, or the deployment status of a component attached to it, is IN_PROGRESS. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
#
# POST /
# Returns: record<serviceInstance: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, environmentName: string, lastClientRequestToken: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, name: string, serviceName: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: UpdateServiceInstance
export def "update-service-instance" [
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
  --x-amz-target: string@x-amz-target-completer-77 # required
  --client-token: string # The client token of the service instance to update.
  deployment_type: string@deployment-type-completer-1 # The deployment type. It defines the mode for updating a service instance, as follows: NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the service instance is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include major or minor version parameters when you use this deployment type. MINOR_VERSION In this mode, the service instance is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can also specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the service instance is deployed and updated with the published, recommended (latest) major and minor version of the current template, by default. You can specify a different major version that's higher than the major version in use and a minor version.
  name: string # The name of the service instance to update.
  service_name: string # The name of the service that the service instance belongs to.
  --spec: string # The formatted specification that defines the service instance update. (format: password)
  --template-major-version: string # The major version of the service template to update.
  --template-minor-version: string # The minor version of the service template to update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateServiceInstance"}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: deploymentType, var: deployment_type}, {name: name, var: name}, {name: serviceName, var: service_name}, {name: spec, var: spec}, {name: templateMajorVersion, var: template_major_version}, {name: templateMinorVersion, var: template_minor_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, client_token: $client_token, deployment_type: $deployment_type, name: $name, service_name: $service_name, spec: $spec, template_major_version: $template_major_version, template_minor_version: $template_minor_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the service pipeline. There are four modes for updating a service pipeline. The deploymentType field defines the mode. NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the service pipeline is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include major or minor version parameters when you use this deployment-type. MINOR_VERSION In this mode, the service pipeline is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the service pipeline is deployed and updated with the published, recommended (latest) major and minor version of the current template by default. You can specify a different major version that's higher than the major version in use and a minor version.
#
# POST /
# Returns: record<pipeline: record<arn: string, createdAt: string, deploymentStatus: string, deploymentStatusMessage: string, lastDeploymentAttemptedAt: string, lastDeploymentSucceededAt: string, spec: string, templateMajorVersion: string, templateMinorVersion: string, templateName: string>>
# operationId: UpdateServicePipeline
export def "update-service-pipeline" [
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
  --x-amz-target: string@x-amz-target-completer-78 # required
  deployment_type: string@deployment-type-completer-1 # The deployment type. There are four modes for updating a service pipeline. The deploymentType field defines the mode. NONE In this mode, a deployment doesn't occur. Only the requested metadata parameters are updated. CURRENT_VERSION In this mode, the service pipeline is deployed and updated with the new spec that you provide. Only requested parameters are updated. Don’t include major or minor version parameters when you use this deployment-type. MINOR_VERSION In this mode, the service pipeline is deployed and updated with the published, recommended (latest) minor version of the current major version in use, by default. You can specify a different minor version of the current major version in use. MAJOR_VERSION In this mode, the service pipeline is deployed and updated with the published, recommended (latest) major and minor version of the current template, by default. You can specify a different major version that's higher than the major version in use and a minor version.
  service_name: string # The name of the service to that the pipeline is associated with.
  spec: string # The spec for the service pipeline to update. (format: password)
  --template-major-version: string # The major version of the service template that was used to create the service that the pipeline is associated with.
  --template-minor-version: string # The minor version of the service template that was used to create the service that the pipeline is associated with.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateServicePipeline"}]
    body: {content_type: "application/json", kind: json, fields: [{name: deploymentType, var: deployment_type}, {name: serviceName, var: service_name}, {name: spec, var: spec}, {name: templateMajorVersion, var: template_major_version}, {name: templateMinorVersion, var: template_minor_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, deployment_type: $deployment_type, service_name: $service_name, spec: $spec, template_major_version: $template_major_version, template_minor_version: $template_minor_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the service sync blocker by resolving it.
#
# POST /
# Returns: record<serviceInstanceName: string, serviceName: string, serviceSyncBlocker: record<contexts: list<record>, createdAt: string, createdReason: string, id: string, resolvedAt: string, resolvedReason: string, status: string, type: string>>
# operationId: UpdateServiceSyncBlocker
export def "update-service-sync-blocker" [
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
  --x-amz-target: string@x-amz-target-completer-79 # required
  id: string # The ID of the service sync blocker.
  resolved_reason: string # The reason the service sync blocker was resolved.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateServiceSyncBlocker"}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: resolvedReason, var: resolved_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, id: $id, resolved_reason: $resolved_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the Proton Ops config file.
#
# POST /
# Returns: record<serviceSyncConfig: record<branch: string, filePath: string, repositoryName: string, repositoryProvider: string, serviceName: string>>
# operationId: UpdateServiceSyncConfig
export def "update-service-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-80 # required
  branch: string # The name of the code repository branch where the Proton Ops file is found.
  file_path: string # The path to the Proton Ops file.
  repository_name: string # The name of the repository where the Proton Ops file is found.
  repository_provider: string@repository-provider-completer # The name of the repository provider where the Proton Ops file is found.
  service_name: string # The name of the service the Proton Ops file is for.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateServiceSyncConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: filePath, var: file_path}, {name: repositoryName, var: repository_name}, {name: repositoryProvider, var: repository_provider}, {name: serviceName, var: service_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, branch: $branch, file_path: $file_path, repository_name: $repository_name, repository_provider: $repository_provider, service_name: $service_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a service template.
#
# POST /
# Returns: record<serviceTemplate: record<arn: string, createdAt: string, description: string, displayName: string, encryptionKey: string, lastModifiedAt: string, name: string, pipelineProvisioning: string, recommendedVersion: string>>
# operationId: UpdateServiceTemplate
export def "update-service-template" [
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
  --x-amz-target: string@x-amz-target-completer-81 # required
  --description: string # A description of the service template update. (format: password)
  --display-name: string # The name of the service template to update that's displayed in the developer interface. (format: password)
  name: string # The name of the service template to update.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateServiceTemplate"}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, description: $description, display_name: $display_name, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a major or minor version of a service template.
#
# POST /
# Returns: record<serviceTemplateVersion: record<arn: string, compatibleEnvironmentTemplates: list<record>, createdAt: string, description: string, lastModifiedAt: string, majorVersion: string, minorVersion: string, recommendedMinorVersion: string, schema: string, status: string, statusMessage: string, supportedComponentSources: list<string>, templateName: string>>
# operationId: UpdateServiceTemplateVersion
export def "update-service-template-version" [
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
  --x-amz-target: string@x-amz-target-completer-82 # required
  --compatible-environment-templates: list # An array of environment template objects that are compatible with this service template version. A service instance based on this service template version can run in environments based on compatible templates. — item shape: {majorVersion: string, templateName: string}
  --description: string # A description of a service template version to update. (format: password)
  major_version: string # To update a major version of a service template, include major Version.
  minor_version: string # To update a minor version of a service template, include minorVersion.
  --status: string@status-completer-1 # The status of the service template minor version to update.
  --supported-component-sources: list<string> # An array of supported component sources. Components with supported sources can be attached to service instances based on this service template version. A change to supportedComponentSources doesn't impact existing component attachments to instances based on this template version. A change only affects later associations. For more information about components, see Proton components (https://docs.aws.amazon.com/proton/latest/userguide/ag-components.html) in the Proton User Guide.
  template_name: string # The name of the service template.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateServiceTemplateVersion"}]
    body: {content_type: "application/json", kind: json, fields: [{name: compatibleEnvironmentTemplates, var: compatible_environment_templates}, {name: description, var: description}, {name: majorVersion, var: major_version}, {name: minorVersion, var: minor_version}, {name: status, var: status}, {name: supportedComponentSources, var: supported_component_sources}, {name: templateName, var: template_name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, compatible_environment_templates: $compatible_environment_templates, description: $description, major_version: $major_version, minor_version: $minor_version, status: $status, supported_component_sources: $supported_component_sources, template_name: $template_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update template sync configuration parameters, except for the templateName and templateType. Repository details (branch, name, and provider) should be of a linked repository. A linked repository is a repository that has been registered with Proton. For more information, see CreateRepository.
#
# POST /
# Returns: record<templateSyncConfig: record<branch: string, repositoryName: string, repositoryProvider: string, subdirectory: string, templateName: string, templateType: string>>
# operationId: UpdateTemplateSyncConfig
export def "update-template-sync-config" [
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
  --x-amz-target: string@x-amz-target-completer-83 # required
  branch: string # The repository branch for your template.
  repository_name: string # The repository name (for example, myrepos/myrepo).
  repository_provider: string@repository-provider-completer # The repository provider.
  --subdirectory: string # A subdirectory path to your template bundle version. When included, limits the template bundle search to this repository directory.
  template_name: string # The synced template name.
  template_type: string@template-type-completer # The synced template type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}, {name: X-Amz-Target, var: x_amz_target, required: true, default: "AwsProton20200720.UpdateTemplateSyncConfig"}]
    body: {content_type: "application/json", kind: json, fields: [{name: branch, var: branch}, {name: repositoryName, var: repository_name}, {name: repositoryProvider, var: repository_provider}, {name: subdirectory, var: subdirectory}, {name: templateName, var: template_name}, {name: templateType, var: template_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, x_amz_target: $x_amz_target, branch: $branch, repository_name: $repository_name, repository_provider: $repository_provider, subdirectory: $subdirectory, template_name: $template_name, template_type: $template_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
